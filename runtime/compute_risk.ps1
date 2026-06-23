param(
    [string]$SnapshotFile = ""
)

$ErrorActionPreference = "Stop"

$ROOT = Split-Path $PSScriptRoot -Parent

if ([string]::IsNullOrWhiteSpace($SnapshotFile)) {
    $SnapshotFile = "$ROOT\runtime\samples\sample_day_2026_06_22.json"
}

$OBS_FILE = "$ROOT\assets\data\observation_engine.json"
$OUT_FILE = "$ROOT\runtime\output\risk_output.json"

if (-not (Test-Path $SnapshotFile)) {
    throw "Snapshot file not found: $SnapshotFile"
}

$o = Get-Content $OBS_FILE -Raw | ConvertFrom-Json
$s = Get-Content $SnapshotFile -Raw | ConvertFrom-Json

function Clamp01($x) {
    if ($x -lt 0) { return 0 }
    if ($x -gt 1) { return 1 }
    return $x
}

function Get-Band($value, $obs) {
    if ($value -ge $obs.green_min -and $value -le $obs.green_max) {
        return "green"
    }

    if ($value -ge $obs.yellow_min -and $value -le $obs.yellow_max) {
        return "yellow"
    }

    if ($value -ge $obs.red_min -and $value -le $obs.red_max) {
        return "red"
    }

    return "out_of_band"
}

function Map-BandRisk($value, $bandMin, $bandMax, $riskLow, $riskHigh, $curve) {
    $bandMin = [double]$bandMin
    $bandMax = [double]$bandMax
    $value = [double]$value

    if ($bandMax -eq $bandMin) {
        return ($riskLow + $riskHigh) / 2
    }

    $t = ($value - $bandMin) / ($bandMax - $bandMin)
    $t = Clamp01 $t

    if ($curve -eq "low_is_bad") {
        $t = 1 - $t
    }

    return $riskLow + (($riskHigh - $riskLow) * $t)
}

function Compute-Risk($value, $obs) {
    $value = [double]$value

    if ($null -ne $obs.valid_min -and $value -lt [double]$obs.valid_min) {
        throw "Value below valid_min for $($obs.question_id): $value"
    }

    if ($null -ne $obs.valid_max -and $value -gt [double]$obs.valid_max) {
        throw "Value above valid_max for $($obs.question_id): $value"
    }

    $band = Get-Band $value $obs

    if ($band -eq "green") {
        return Map-BandRisk $value $obs.green_min $obs.green_max 0.00 0.39 $obs.risk_curve
    }

    if ($band -eq "yellow") {
        return Map-BandRisk $value $obs.yellow_min $obs.yellow_max 0.40 0.69 $obs.risk_curve
    }

    if ($band -eq "red") {
        return Map-BandRisk $value $obs.red_min $obs.red_max 0.70 1.00 $obs.risk_curve
    }

    if ($band -eq "out_of_band") {
        if ($obs.risk_curve -eq "low_is_bad") {
            if ($value -lt [double]$obs.red_min) { return 1.00 }
            if ($value -gt [double]$obs.green_max) { return 0.00 }
        }

        if ($obs.risk_curve -eq "high_is_bad") {
            if ($value -lt [double]$obs.green_min) { return 0.00 }
            if ($value -gt [double]$obs.red_max) { return 1.00 }
        }

        throw "Value out of all bands for $($obs.question_id): $value"
    }

    throw "Unknown band for $($obs.question_id): $band"
}

$rows = @()

foreach ($obs in $o.observations) {
    $qid = $obs.question_id

    if (-not $s.answers.PSObject.Properties.Name.Contains($qid)) {
        throw "Missing answer: $qid"
    }

    try {
        $value = [double]$s.answers.$qid
    }
    catch {
        throw "Invalid numeric answer for $qid"
    }

    $band = Get-Band $value $obs
    $risk = Compute-Risk $value $obs

    $rows += [pscustomobject]@{
        question_id = $qid
        node = $obs.node
        value = $value
        band = $band
        risk = [math]::Round($risk, 4)
    }
}

$result = [pscustomobject]@{
    date = $s.date
    source_snapshot = $SnapshotFile
    risk_count = $rows.Count
    risk_semantics = "0-1, càng cao nghĩa là rủi ro hao mòn / kiệt sức càng cao."
    risks = $rows
}

$result |
ConvertTo-Json -Depth 30 |
Set-Content $OUT_FILE -Encoding UTF8

Write-Host "RISK RUNTIME OK"
Write-Host "DATE:" $s.date
Write-Host "RISKS:" $rows.Count
Write-Host "OUTPUT:" $OUT_FILE
