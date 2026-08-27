#!/usr/bin/env pwsh
# utsusemi.ps1 — one-shot implementation runner; each run works in its own worktree.
#
# Usage:
#   ./utsusemi.ps1 [guidance...]
#   ./utsusemi.ps1 -Resume <run-id> [guidance...]
#
# Behavior:
#   - A new run gets a fresh worktree at .utsusemi/worktrees/<run-id> on branch
#     utsusemi/<run-id>, cut from the integration branch (whatever is checked
#     out when the run starts); the agent CLI runs once inside it. The
#     integration branch stays yours while the run is in flight: spec-layer
#     edits and new PRD tasks can land on it at any time.
#   - After the agent exits, the run is integrated deterministically: rebase
#     onto the integration branch, re-run the pass gate (.utsusemi/gate.ps1),
#     fast-forward the branch, remove the worktree. On a rebase conflict or a red gate nothing is
#     integrated and the worktree stays for inspection — this script never
#     resolves anything; escalation is the invoker's job.
#   - -Resume <run-id> starts a fresh agent context inside an existing run
#     worktree (interrupted or deliberately paused runs).
#   - Concurrent runs are supported: integration is serialized by a lock, and
#     per-task claims (.utsusemi/claims/<task-id>, owner-checked at integration)
#     keep two runs from landing the same task.
#
# Environment:
#   UTSUSEMI_CMD — agent command that reads the prompt on stdin; split on
#               whitespace. Default: claude --dangerously-skip-permissions -p
#   UTSUSEMI_LOCK_TIMEOUT — seconds a finished run waits for the integration
#               lock before giving up (default 900). A waiter never removes
#               the lock itself.
#   .utsusemi/env.ps1 — optional repo knobs, dot-sourced before the run and the
#               gate (agent/model via UTSUSEMI_CMD, shared build caches, …).
#               Values already set in the invoking environment win.

[CmdletBinding()]
param(
    [string]$Resume,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Guidance
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

function Fail([int]$Code, [string]$Message) {
    [Console]::Error.WriteLine($Message)
    exit $Code
}

function Wait-IntegrationLock {
    $Timeout = if ($env:UTSUSEMI_LOCK_TIMEOUT) { [int]$env:UTSUSEMI_LOCK_TIMEOUT } else { 900 }
    $Waited = 0
    while ($true) {
        try {
            New-Item -ItemType Directory -Path $Lock -ErrorAction Stop | Out-Null
            break
        }
        catch {
            if ($Waited -ge $Timeout) {
                $Holder = if (Test-Path "$Lock/pid") { Get-Content "$Lock/pid" } else { 'unknown' }
                Fail 6 "INTEGRATE LOCKED OUT: $Lock held for ${Timeout}s (holder pid: $Holder); worktree kept at $Wt. if that integration is dead, remove the lock and rerun: Remove-Item -Recurse $Lock; ./utsusemi.ps1 -Resume $RunId"
            }
            Start-Sleep -Seconds 2
            $Waited += 2
        }
    }
    Set-Content -Path "$Lock/pid" -Value $PID
}

function Assert-Claims {
    $DoneIds = @(git -C $Wt diff "$Base..HEAD" -- PRD.md | Where-Object { $_ -match '^\+- \[x\] (T\d+):' } | ForEach-Object { $Matches[1] })
    foreach ($Id in $DoneIds) {
        $OwnerFile = ".utsusemi/claims/$Id/owner"
        $Owner = if (Test-Path -LiteralPath $OwnerFile) { (Get-Content -LiteralPath $OwnerFile -Raw).Trim() } else { '' }
        if ($Owner -ne "utsusemi/$RunId") {
            Fail 7 "INTEGRATE REFUSED: $Id was checked off without an owned claim; worktree kept at $Wt."
        }
    }
}

function Remove-OwnClaims {
    if (-not (Test-Path -LiteralPath '.utsusemi/claims')) { return }
    Get-ChildItem -LiteralPath '.utsusemi/claims' -Directory | ForEach-Object {
        $of = Join-Path $_.FullName 'owner'
        if ((Test-Path -LiteralPath $of) -and ((Get-Content -LiteralPath $of -Raw).Trim() -eq "utsusemi/$RunId")) {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
    }
}

if (-not (Test-Path -LiteralPath '.utsusemi/prompt.md')) {
    Fail 1 "error: .utsusemi/prompt.md not found in $PSScriptRoot."
}
if (-not (Test-Path -LiteralPath '.utsusemi/gate.ps1')) {
    Fail 1 "error: .utsusemi/gate.ps1 not found in $PSScriptRoot — integration would have nothing to verify against."
}

$Base = git symbolic-ref --quiet --short HEAD
if ($LASTEXITCODE -ne 0 -or -not $Base) {
    Fail 1 "error: detached HEAD; check out the integration branch first."
}

$InvokerUtsusemiCmd = $env:UTSUSEMI_CMD
if (Test-Path -LiteralPath '.utsusemi/env.ps1') { . ./.utsusemi/env.ps1 }
if ($InvokerUtsusemiCmd) { $env:UTSUSEMI_CMD = $InvokerUtsusemiCmd }
$UtsusemiCmd = if ($env:UTSUSEMI_CMD) { $env:UTSUSEMI_CMD } else { 'claude --dangerously-skip-permissions -p' }

$Parts = $UtsusemiCmd.Trim() -split '\s+'
$Exe = $Parts[0]
$CmdArgs = if ($Parts.Count -gt 1) { $Parts[1..($Parts.Count - 1)] } else { @() }
if (-not (Get-Command $Exe -ErrorAction SilentlyContinue)) {
    Fail 1 "error: '$Exe' not found on PATH."
}

if ($Resume) {
    $RunId = $Resume
    $Wt = ".utsusemi/worktrees/$RunId"
    if (-not (Test-Path -LiteralPath $Wt)) { Fail 1 "error: no run worktree at $Wt." }
}
else {
    $RunId = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $PID
    $Wt = ".utsusemi/worktrees/$RunId"
    New-Item -ItemType Directory -Force -Path '.utsusemi/worktrees' | Out-Null
    git worktree add --quiet $Wt -b "utsusemi/$RunId" $Base
    if ($LASTEXITCODE -ne 0) { Fail 1 "error: git worktree add failed." }
    git -C $Wt branch --quiet --set-upstream-to=$Base
}

$Prompt = Get-Content -LiteralPath (Join-Path $Wt '.utsusemi/prompt.md') -Raw
if ($Guidance -and $Guidance.Count -gt 0) {
    $Prompt += "`n`n## Guidance from the invoker`n`n" + ($Guidance -join ' ')
    Write-Host "=== Implementation run $RunId (guided) ==="
}
else {
    Write-Host "=== Implementation run $RunId ==="
}
Write-Host ""

Push-Location -LiteralPath $Wt
$Prompt | & $Exe @CmdArgs
$AgentExit = $LASTEXITCODE
Pop-Location
if ($AgentExit -ne 0) {
    Fail 2 "RUN FAILED: agent exited non-zero; worktree kept at $Wt (./utsusemi.ps1 -Resume $RunId)."
}

$GatePath = Join-Path $Wt '.utsusemi/gate.ps1'
if (-not (Test-Path -LiteralPath $GatePath)) {
    Fail 4 "INTEGRATE FAILED: no pass gate at .utsusemi/gate.ps1; worktree kept at $Wt."
}

$Lock = '.utsusemi/integrate.lock'
Wait-IntegrationLock
try {
    git -C $Wt -c core.longpaths=true rebase --quiet $Base
    if ($LASTEXITCODE -ne 0) {
        git -C $Wt rebase --abort 2>$null
        Fail 3 "INTEGRATE CONFLICT: utsusemi/$RunId does not rebase onto ${Base}; worktree kept at $Wt for the invoker."
    }

    Push-Location -LiteralPath $Wt
    try {
        & ./.utsusemi/gate.ps1
        $GateExit = $LASTEXITCODE
    }
    catch {
        $GateExit = 1
    }
    finally {
        Pop-Location
    }
    if ($GateExit -ne 0) {
        Fail 4 "INTEGRATE GATE RED: rebased utsusemi/$RunId fails the gate; worktree kept at $Wt for the invoker."
    }

    Assert-Claims

    $Current = git symbolic-ref --quiet --short HEAD
    if ($Current -ne $Base) {
        Fail 5 "INTEGRATE BLOCKED: the checked-out branch changed since the run started (expected $Base); worktree kept at $Wt."
    }
    $Before = git rev-parse $Base
    git merge --ff-only --quiet "utsusemi/$RunId"
    if ($LASTEXITCODE -ne 0) {
        Fail 5 "INTEGRATE BLOCKED: fast-forward of $Base refused (uncommitted changes in the way?). recover with: git merge --ff-only utsusemi/$RunId && git worktree remove --force $Wt && git branch -D utsusemi/$RunId"
    }
    git worktree remove --force $Wt
    git branch --quiet -D "utsusemi/$RunId"
    Remove-OwnClaims

    Write-Host ""
    Write-Host "INTEGRATED into ${Base}:"
    git log --oneline "$Before..$Base" | ForEach-Object { Write-Host "  $_" }
}
finally {
    Remove-Item -LiteralPath $Lock -Recurse -Force -ErrorAction SilentlyContinue
}
