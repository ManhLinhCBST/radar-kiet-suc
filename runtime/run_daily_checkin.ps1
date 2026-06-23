param(
    [string]$SnapshotFile = "",
    [switch]$NoSaveHistory,
    [switch]$NoTrajectory
)

$ErrorActionPreference = "Stop"

$ROOT = Split-Path $PSScriptRoot -Parent

if ([string]::IsNullOrWhiteSpace($SnapshotFile)) {
    $SnapshotFile = "$ROOT\runtime\samples\sample_day_2026_06_22.json"
}

$OUT_DIR = "$ROOT\runtime\output"
$FINAL_OUT = "$OUT_DIR\daily_checkin_output.json"
$TRAJECTORY_OUT = "$OUT_DIR\trajectory_output.json"

if (-not (Test-Path $SnapshotFile)) {
    throw "Snapshot file not found: $SnapshotFile"
}

New-Item -ItemType Directory -Force $OUT_DIR | Out-Null

Write-Host ""
Write-Host "DAILY CHECKIN PIPELINE V3 START"
Write-Host "SNAPSHOT:" $SnapshotFile
Write-Host ""

& "$PSScriptRoot\compute_risk.ps1" -SnapshotFile $SnapshotFile
Write-Host ""

& "$PSScriptRoot\compute_node_score.ps1"
Write-Host ""

& "$PSScriptRoot\compute_diagnostic.ps1"
Write-Host ""

& "$PSScriptRoot\compute_recommendation.ps1"
Write-Host ""

$risk = Get-Content "$OUT_DIR\risk_output.json" -Raw | ConvertFrom-Json
$node = Get-Content "$OUT_DIR\node_score_output.json" -Raw | ConvertFrom-Json
$diag = Get-Content "$OUT_DIR\diagnostic_output.json" -Raw | ConvertFrom-Json
$rec = Get-Content "$OUT_DIR\recommendation_output.json" -Raw | ConvertFrom-Json

$baseFinal = [pscustomobject]@{
    version = "3.0.0"
    date = $rec.date
    source_snapshot = $SnapshotFile

    system = @{
        score = $rec.system_score
        level = $rec.system_level
        summary = $rec.summary
        score_semantics = "Điểm càng cao nghĩa là rủi ro hao mòn / kiệt sức càng cao."
    }

    top_risks = $diag.top_risks
    diagnostics = $diag.diagnostics
    recommendations = $rec.recommended_actions

    trajectory = $null

    artifacts = @{
        risk_output = "$OUT_DIR\risk_output.json"
        node_score_output = "$OUT_DIR\node_score_output.json"
        diagnostic_output = "$OUT_DIR\diagnostic_output.json"
        recommendation_output = "$OUT_DIR\recommendation_output.json"
        trajectory_output = "$OUT_DIR\trajectory_output.json"
    }
}

$baseFinal |
ConvertTo-Json -Depth 100 |
Set-Content $FINAL_OUT -Encoding UTF8

$trajectory = $null

if (-not $NoTrajectory) {
    & "$PSScriptRoot\compute_trajectory.ps1" -CurrentDailyFile $FINAL_OUT
    Write-Host ""

    if (Test-Path $TRAJECTORY_OUT) {
        $trajectory =
        Get-Content $TRAJECTORY_OUT -Raw |
        ConvertFrom-Json
    }
}

$final = [pscustomobject]@{
    version = "3.0.0"
    date = $rec.date
    source_snapshot = $SnapshotFile

    system = @{
        score = $rec.system_score
        level = $rec.system_level
        summary = $rec.summary
        score_semantics = "Điểm càng cao nghĩa là rủi ro hao mòn / kiệt sức càng cao."
    }

    top_risks = $diag.top_risks
    diagnostics = $diag.diagnostics
    recommendations = $rec.recommended_actions

    trajectory = $trajectory

    artifacts = @{
        risk_output = "$OUT_DIR\risk_output.json"
        node_score_output = "$OUT_DIR\node_score_output.json"
        diagnostic_output = "$OUT_DIR\diagnostic_output.json"
        recommendation_output = "$OUT_DIR\recommendation_output.json"
        trajectory_output = "$OUT_DIR\trajectory_output.json"
    }
}

$final |
ConvertTo-Json -Depth 100 |
Set-Content $FINAL_OUT -Encoding UTF8

if (-not $NoSaveHistory) {
    & "$PSScriptRoot\save_daily_history.ps1" -DailyFile $FINAL_OUT
    Write-Host ""
}

Write-Host "DAILY CHECKIN PIPELINE V3 OK"
Write-Host "DATE:" $final.date
Write-Host "SYSTEM SCORE:" $final.system.score
Write-Host "SYSTEM LEVEL:" $final.system.level
Write-Host "FINAL OUTPUT:" $FINAL_OUT
Write-Host ""

Write-Host "SUMMARY:"
Write-Host $final.system.summary
Write-Host ""

Write-Host "TOP RISKS:"
$final.top_risks |
Select name,node_score,level |
Format-Table

if ($null -ne $final.trajectory -and $final.trajectory.status -eq "ok") {
    Write-Host "TRAJECTORY:"
    Write-Host "FROM:" $final.trajectory.previous_date
    Write-Host "TO:" $final.trajectory.current_date
    Write-Host "DELTA:" $final.trajectory.system.delta
    Write-Host "DIRECTION:" $final.trajectory.system.direction
    Write-Host "STATE:" $final.trajectory.system.state
    Write-Host $final.trajectory.system.message
    Write-Host ""

    Write-Host "IMPROVING NODES:"
    $final.trajectory.improving_nodes |
    Select name,delta,direction,magnitude,state |
    Format-Table
}
elseif ($null -ne $final.trajectory) {
    Write-Host "TRAJECTORY:"
    Write-Host $final.trajectory.message
    Write-Host ""
}

Write-Host "RECOMMENDATIONS:"
$final.recommendations |
Select name,title,priority,duration_minutes,effort |
Format-Table -Wrap

