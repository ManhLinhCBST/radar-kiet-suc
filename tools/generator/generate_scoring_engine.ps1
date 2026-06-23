$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"
$DATA = Join-Path $ROOT "assets\data"
$QUESTION_FILE = Join-Path $DATA "question_library.json"
$OUT_FILE = Join-Path $DATA "scoring_engine.json"

$q = Get-Content $QUESTION_FILE -Raw | ConvertFrom-Json

$importanceWeight = @{
    "critical" = 5
    "high"     = 4
    "medium"   = 3
    "low"      = 2
}

$questions = @()

foreach ($item in $q.questions) {
    if (-not $item.id) { throw "Missing id" }
    if (-not $item.node) { throw "Missing node for $($item.id)" }
    if (-not $item.risk_direction) { throw "Missing risk_direction for $($item.id)" }
    if (-not $item.priority) { throw "Missing priority for $($item.id)" }

    $base = $importanceWeight[$item.priority]

    if (-not $base) {
        throw "Unknown priority $($item.priority) in $($item.id)"
    }

    $questions += [pscustomobject]@{
        id = $item.id
        node = $item.node
        risk_direction = $item.risk_direction
        raw_weight = $base
    }
}

$totalRaw = ($questions | Measure-Object raw_weight -Sum).Sum

$rules = @()

foreach ($item in $questions) {
    $weight = [math]::Round(($item.raw_weight / $totalRaw) * 100, 2)

    $rules += [pscustomobject]@{
        question_id = $item.id
        node = $item.node
        risk_direction = $item.risk_direction
        weight = $weight
    }
}

$engine = [pscustomobject]@{
    version = "1.0.0"
    generated_from = "question_library.json"
    formula = "weighted_risk_sum"
    score_range = @{
        min = 0
        max = 100
        meaning = "Điểm càng cao nghĩa là nguy cơ hao mòn / kiệt sức càng cao."
    }
    normalization = @{
        low_is_bad = "risk = 1 - normalized_value"
        high_is_bad = "risk = normalized_value"
    }
    rules = $rules
}

$engine |
ConvertTo-Json -Depth 20 |
Set-Content $OUT_FILE -Encoding UTF8

Write-Host "GENERATED: scoring_engine.json"
Write-Host "RULES:" $rules.Count
Write-Host "TOTAL WEIGHT:" (($rules | Measure-Object weight -Sum).Sum)
