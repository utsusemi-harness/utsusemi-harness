#!/usr/bin/env pwsh
# Packaging workaround: https://github.com/hainet50b/utsusemi-harness/issues/1
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Initializer = Join-Path $ScriptDir 'skills\utsusemi-harness\init.ps1'

& $Initializer @args
exit $LASTEXITCODE
