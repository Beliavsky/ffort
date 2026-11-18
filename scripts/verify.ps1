# Windows PowerShell entry point. Requires Python 3, fpm, gfortran and a compatible C compiler on PATH.
$ErrorActionPreference = 'Stop'
python (Join-Path $PSScriptRoot 'verify.py')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
