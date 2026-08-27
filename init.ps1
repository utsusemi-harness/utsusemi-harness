#!/usr/bin/env pwsh
# init.ps1 — bootstrap a new project from this template (PowerShell).
#
# Usage:
#   ./init.ps1 <destination-path>
#
# Behavior:
#   1. Copies _project/ to the destination path.
#   2. Runs `git init -b main`.
#
# The template files leave {{PROJECT_NAME}} placeholders literal. The
# conversational LLM driving setup is expected to replace them as part of
# first-time setup, alongside filling in the substantive spec sections.
# See AGENTS.md in the generated project for the order of attention.
#
# Notes:
#   - Refuses to overwrite an existing non-empty destination.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Destination
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Source = Join-Path $ScriptDir '_project'

if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    Write-Error "error: $Source not found; run this script from inside the template repo."
    exit 1
}

if ((Test-Path -LiteralPath $Destination) -and ((Get-ChildItem -Force -LiteralPath $Destination | Measure-Object).Count -gt 0)) {
    Write-Error "error: $Destination already exists and is not empty."
    exit 1
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

# Copy every entry from _project/ (including dotfiles like .gitignore) into
# the destination, preserving structure.
Get-ChildItem -Force -LiteralPath $Source | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
}

Push-Location -LiteralPath $Destination
try {
    & git init -b main | Out-Null
}
finally {
    Pop-Location
}

@"
Initialized at $Destination

Next steps:
  Set-Location '$Destination'
  # 1. Replace {{PROJECT_NAME}} placeholders and fill in PRD.md, README.md,
  #    SPEC/SPEC.md, CONVENTIONS.md together with your conversational LLM.
  # 2. Stage and commit the initial files when ready.
  # 3. Ask your agent to start an implementation run (.\utsusemi.ps1) when the specs are in shape.
"@
