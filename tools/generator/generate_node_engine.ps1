$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"
$DATA = Join-Path $ROOT "assets\data"
$QUESTION_FILE = Join-Path $DATA "question_library.json"
$OUT_FILE = Join-Path $DATA "node_engine.json"

$q = Get-Content $QUESTION_FILE -Raw | ConvertFrom-Json

$nodeWeights = @{
    "nap" = 15
    "chuyen_hoa" = 10
    "du_tru" = 20
    "tai" = 20
    "phuc_hoi" = 10
    "thich_nghi" = 10
    "hao_mon" = 10
    "mat_kiem_soat" = 5
}

$priorityWeights = @{
    "critical" = 5
    "high" = 4
    "medium" = 3
    "low" = 2
}

$nodes = @()

foreach ($nodeId in $nodeWeights.Keys) {

    $nodeQuestions = @($q.questions | Where-Object { $_.node -eq $nodeId })

    if ($nodeQuestions.Count -eq 0) {
        throw "Node has no questions: $nodeId"
    }

    $rawTotal = 0
    foreach ($item in $nodeQuestions) {
        if (-not $priorityWeights.ContainsKey($item.priority)) {
            throw "Unknown priority $($item.priority) in $($item.id)"
        }
        $rawTotal += $priorityWeights[$item.priority]
    }

    $questionRules = @()
    $running = 0

    for ($i = 0; $i -lt $nodeQuestions.Count; $i++) {
        $item = $nodeQuestions[$i]
        $raw = $priorityWeights[$item.priority]

        if ($i -eq $nodeQuestions.Count - 1) {
            $internalWeight = [math]::Round(100 - $running, 2)
        } else {
            $internalWeight = [math]::Round(($raw / $rawTotal) * 100, 2)
            $running += $internalWeight
        }

        $questionRules += [pscustomobject]@{
            question_id = $item.id
            title = $item.title
            input_type = $item.input_type
            min = $item.min
            max = $item.max
            risk_direction = $item.risk_direction
            priority = $item.priority
            internal_weight = $internalWeight
            normalization = if ($item.risk_direction -eq "low_is_bad") {
                "risk = 1 - ((answer - min) / (max - min))"
            } elseif ($item.risk_direction -eq "high_is_bad") {
                "risk = (answer - min) / (max - min)"
            } else {
                throw "Unknown risk_direction $($item.risk_direction) in $($item.id)"
            }
        }
    }

    $nodes += [pscustomobject]@{
        id = $nodeId
        node_weight = $nodeWeights[$nodeId]
        question_count = $nodeQuestions.Count
        questions = $questionRules
    }
}

$engine = [pscustomobject]@{
    version = "2.0.0"
    generated_from = "question_library.json"
    node_score_formula = "sum(question_risk * internal_weight)"
    system_score_formula = "sum(node_score * node_weight)"
    score_range = @{
        min = 0
        max = 100
    }
    nodes = $nodes
}

$engine |
ConvertTo-Json -Depth 30 |
Set-Content $OUT_FILE -Encoding UTF8

Write-Host "NODE ENGINE GENERATED"
Write-Host "VERSION: 2.0.0"
Write-Host "NODES:" $nodes.Count
Write-Host "NODE WEIGHT TOTAL:" (($nodes | Measure-Object node_weight -Sum).Sum)
