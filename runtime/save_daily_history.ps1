param(
    [string]$DailyFile = ""
)

$ErrorActionPreference = "Stop"

$ROOT = Split-Path $PSScriptRoot -Parent

if ([string]::IsNullOrWhiteSpace($DailyFile)) {
    $DailyFile = "$ROOT\runtime\output\daily_checkin_output.json"
}

$HISTORY_DIR = "$ROOT\runtime\history"

if (-not (Test-Path $DailyFile)) {
    throw "Daily output file not found: $DailyFile"
}

New-Item -ItemType Directory -Force $HISTORY_DIR | Out-Null

$d = Get-Content $DailyFile -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($d.date)) {
    throw "Daily output missing date"
}

$outFile = "$HISTORY_DIR\$($d.date).json"

$d |
ConvertTo-Json -Depth 80 |
Set-Content $outFile -Encoding UTF8

Write-Host "DAILY HISTORY SAVED"
Write-Host "DATE:" $d.date
Write-Host "FILE:" $outFile
