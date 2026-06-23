$ErrorActionPreference = "Stop"

$ROOT = Split-Path $PSScriptRoot -Parent

$requiredFiles = @(
    "$ROOT\assets\data\question_library.json",
    "$ROOT\assets\data\observation_engine.json",
    "$ROOT\assets\data\node_engine.json",
    "$ROOT\assets\data\meaning_engine.json",
    "$ROOT\assets\data\recommendation_engine.json",

    "$ROOT\runtime\compute_risk.ps1",
    "$ROOT\runtime\compute_node_score.ps1",
    "$ROOT\runtime\compute_diagnostic.ps1",
    "$ROOT\runtime\compute_recommendation.ps1",
    "$ROOT\runtime\compute_trajectory.ps1",
    "$ROOT\runtime\run_daily_checkin.ps1",
    "$ROOT\runtime\save_daily_history.ps1",

    "$ROOT\runtime\output\daily_checkin_output.json"
)

$missing = @()

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missing += $file
    }
}

if ($missing.Count -gt 0) {
    Write-Host "RUNTIME AUDIT FAIL"
    Write-Host ""
    Write-Host "MISSING FILES:"
    $missing | ForEach-Object { Write-Host $_ }
    exit 1
}

$daily =
Get-Content "$ROOT\runtime\output\daily_checkin_output.json" -Raw |
ConvertFrom-Json

$historyCount = 0

if (Test-Path "$ROOT\runtime\history") {
    $historyCount =
    (Get-ChildItem "$ROOT\runtime\history" -Filter "*.json").Count
}

$errors = @()

if ([string]::IsNullOrWhiteSpace($daily.version)) {
    $errors += "daily_checkin_output missing version"
}

if ([string]::IsNullOrWhiteSpace($daily.date)) {
    $errors += "daily_checkin_output missing date"
}

if ($null -eq $daily.system.score) {
    $errors += "daily_checkin_output missing system.score"
}

if ([string]::IsNullOrWhiteSpace($daily.system.level)) {
    $errors += "daily_checkin_output missing system.level"
}

if ($null -eq $daily.top_risks -or $daily.top_risks.Count -lt 1) {
    $errors += "daily_checkin_output missing top_risks"
}

if ($null -eq $daily.diagnostics -or $daily.diagnostics.Count -lt 8) {
    $errors += "daily_checkin_output diagnostics should have 8 nodes"
}

if ($null -eq $daily.recommendations -or $daily.recommendations.Count -lt 1) {
    $errors += "daily_checkin_output missing recommendations"
}

if ($null -eq $daily.trajectory) {
    $errors += "daily_checkin_output missing trajectory"
}
elseif ($daily.trajectory.status -ne "ok" -and $daily.trajectory.status -ne "not_enough_data") {
    $errors += "trajectory status invalid: $($daily.trajectory.status)"
}

if ($historyCount -lt 2) {
    $errors += "history should have at least 2 daily records for trajectory"
}

if ($errors.Count -gt 0) {
    Write-Host "RUNTIME AUDIT FAIL"
    Write-Host ""
    $errors | ForEach-Object {
        Write-Host "- $_"
    }
    exit 1
}

Write-Host "RUNTIME AUDIT PASS"
Write-Host ""
Write-Host "ROOT:" $ROOT
Write-Host "DAILY VERSION:" $daily.version
Write-Host "DATE:" $daily.date
Write-Host "SYSTEM SCORE:" $daily.system.score
Write-Host "SYSTEM LEVEL:" $daily.system.level
Write-Host "HISTORY COUNT:" $historyCount
Write-Host "TRAJECTORY STATUS:" $daily.trajectory.status

if ($daily.trajectory.status -eq "ok") {
    Write-Host "TRAJECTORY STATE:" $daily.trajectory.system.state
    Write-Host "TRAJECTORY DIRECTION:" $daily.trajectory.system.direction
}

Write-Host ""
Write-Host "TOP RISKS:"
$daily.top_risks |
Select name,node_score,level |
Format-Table

Write-Host "RECOMMENDATIONS:"
$daily.recommendations |
Select name,title,priority,duration_minutes,effort |
Format-Table -Wrap

Write-Host ""
Write-Host "RUNTIME V3 READY FOR FLUTTER = PASS"
