param(
    [string]$CurrentDailyFile = ""
)

$ErrorActionPreference = "Stop"

$ROOT = Split-Path $PSScriptRoot -Parent

$HISTORY_DIR = "$ROOT\runtime\history"
$OUT_FILE = "$ROOT\runtime\output\trajectory_output.json"

$records = @()

if (Test-Path $HISTORY_DIR) {
    $files =
    Get-ChildItem $HISTORY_DIR -Filter "*.json" |
    Sort-Object Name

    foreach ($file in $files) {
        $records += Get-Content $file.FullName -Raw | ConvertFrom-Json
    }
}

if (-not [string]::IsNullOrWhiteSpace($CurrentDailyFile)) {
    if (-not (Test-Path $CurrentDailyFile)) {
        throw "Current daily file not found: $CurrentDailyFile"
    }

    $currentRecord =
    Get-Content $CurrentDailyFile -Raw |
    ConvertFrom-Json

    if ([string]::IsNullOrWhiteSpace($currentRecord.date)) {
        throw "Current daily file missing date"
    }

    $records =
    $records |
    Where-Object {
        $_.date -ne $currentRecord.date
    }

    $records += $currentRecord
}

$records =
@(
    $records |
    Where-Object {
        $null -ne $_ -and
        -not [string]::IsNullOrWhiteSpace($_.date)
    } |
    Sort-Object date
)

if ($records.Count -lt 2) {
    $result = [pscustomobject]@{
        version = "3.0.0"
        status = "not_enough_data"
        message = "Cần ít nhất 2 ngày dữ liệu để tính xu hướng."
        sample_count = $records.Count
    }

    $result |
    ConvertTo-Json -Depth 20 |
    Set-Content $OUT_FILE -Encoding UTF8

    Write-Host "TRAJECTORY NOT ENOUGH DATA"
    Write-Host "SAMPLES:" $records.Count
    Write-Host "OUTPUT:" $OUT_FILE
    exit
}

$current = $records[$records.Count - 1]
$previous = $records[$records.Count - 2]

function Get-Direction($delta) {
    if ($delta -le -2) { return "improving" }
    if ($delta -ge 2) { return "worsening" }
    return "flat"
}

function Get-Magnitude($delta) {
    $abs = [math]::Abs([double]$delta)

    if ($abs -lt 2) { return "none" }
    if ($abs -lt 5) { return "mild" }
    if ($abs -lt 10) { return "moderate" }
    return "strong"
}

function Get-TrajectoryState($delta) {
    if ($delta -le -10) { return "recovering" }
    if ($delta -le -2) { return "mild_recovering" }
    if ($delta -lt 2) { return "stable" }
    if ($delta -lt 10) { return "mild_declining" }
    if ($delta -lt 20) { return "declining" }
    return "collapsing"
}

function Get-TrajectoryMessage($state) {
    switch ($state) {
        "recovering" {
            return "Rủi ro đang giảm rõ. Hệ có dấu hiệu hồi lại tốt so với lần đo trước."
        }
        "mild_recovering" {
            return "Rủi ro đang giảm nhẹ. Hệ có dấu hiệu tốt lên nhưng chưa đủ mạnh để gọi là hồi phục rõ."
        }
        "stable" {
            return "Rủi ro gần như không đổi. Hệ đang tương đối ổn định nhưng vẫn cần theo dõi."
        }
        "mild_declining" {
            return "Rủi ro đang tăng nhẹ. Hệ có dấu hiệu xấu đi sớm, nên điều chỉnh trước khi tụt thêm."
        }
        "declining" {
            return "Rủi ro đang tăng rõ. Hệ có dấu hiệu xấu đi và cần giảm tải sớm."
        }
        "collapsing" {
            return "Rủi ro tăng nhanh. Hệ có dấu hiệu lao dốc, nên ưu tiên phục hồi và giảm tải ngay."
        }
        default {
            return "Chưa xác định được xu hướng."
        }
    }
}

$systemDelta =
[math]::Round(
    ([double]$current.system.score - [double]$previous.system.score),
    2
)

$systemState = Get-TrajectoryState $systemDelta

$nodeTrajectories = @()

foreach ($curNode in $current.diagnostics) {
    $prevNode =
    $previous.diagnostics |
    Where-Object {
        $_.node -eq $curNode.node
    }

    if (-not $prevNode) {
        continue
    }

    $delta =
    [math]::Round(
        ([double]$curNode.node_score - [double]$prevNode.node_score),
        2
    )

    $state = Get-TrajectoryState $delta

    $nodeTrajectories += [pscustomobject]@{
        node = $curNode.node
        name = $curNode.name

        previous_score = $prevNode.node_score
        current_score = $curNode.node_score
        delta = $delta

        direction = Get-Direction $delta
        magnitude = Get-Magnitude $delta
        state = $state
        message = Get-TrajectoryMessage $state
    }
}

$worsening =
$nodeTrajectories |
Where-Object {
    $_.direction -eq "worsening"
} |
Sort-Object delta -Descending |
Select-Object -First 3

$improving =
$nodeTrajectories |
Where-Object {
    $_.direction -eq "improving"
} |
Sort-Object delta |
Select-Object -First 3

$result = [pscustomobject]@{
    version = "3.0.0"
    status = "ok"
    sample_count = $records.Count

    previous_date = $previous.date
    current_date = $current.date

    system = @{
        previous_score = $previous.system.score
        current_score = $current.system.score
        delta = $systemDelta
        direction = Get-Direction $systemDelta
        magnitude = Get-Magnitude $systemDelta
        state = $systemState
        message = Get-TrajectoryMessage $systemState
    }

    nodes = $nodeTrajectories
    worsening_nodes = $worsening
    improving_nodes = $improving
}

$result |
ConvertTo-Json -Depth 100 |
Set-Content $OUT_FILE -Encoding UTF8

Write-Host "TRAJECTORY RUNTIME V3 OK"
Write-Host "SAMPLES:" $records.Count
Write-Host "FROM:" $previous.date
Write-Host "TO:" $current.date
Write-Host "SYSTEM DELTA:" $systemDelta
Write-Host "DIRECTION:" (Get-Direction $systemDelta)
Write-Host "MAGNITUDE:" (Get-Magnitude $systemDelta)
Write-Host "STATE:" $systemState
Write-Host ""

Write-Host "WORSENING:"
$worsening |
Select name,previous_score,current_score,delta,direction,magnitude,state |
Format-Table

Write-Host "IMPROVING:"
$improving |
Select name,previous_score,current_score,delta,direction,magnitude,state |
Format-Table

Write-Host "OUTPUT:" $OUT_FILE
