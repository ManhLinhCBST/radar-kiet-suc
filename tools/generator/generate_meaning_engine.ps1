$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"
$DATA = Join-Path $ROOT "assets\data"

$NODE_FILE = Join-Path $DATA "node_engine.json"
$MEANING_SEED = Join-Path $DATA "node_meaning_seed.json"
$OUT_FILE = Join-Path $DATA "meaning_engine.json"

$n = Get-Content $NODE_FILE -Raw | ConvertFrom-Json
$m = Get-Content $MEANING_SEED -Raw | ConvertFrom-Json

$items = @()

foreach ($node in $n.nodes) {
    $seed = $m.nodes | Where-Object { $_.id -eq $node.id }

    if (-not $seed) {
        throw "Missing meaning seed for node: $($node.id)"
    }

    $items += [pscustomobject]@{
        id = $node.id
        name = $seed.name
        node_weight = $node.node_weight
        question_count = $node.question_count
        questions = @($node.questions.question_id)
        bands = @(
            [pscustomobject]@{
                level = "low"
                min = 0
                max = 39
                message = $seed.low_message
            },
            [pscustomobject]@{
                level = "medium"
                min = 40
                max = 69
                message = $seed.medium_message
            },
            [pscustomobject]@{
                level = "high"
                min = 70
                max = 100
                message = $seed.high_message
            }
        )
    }
}

$engine = [pscustomobject]@{
    version = "1.0.0"
    generated_from = @(
        "node_engine.json",
        "node_meaning_seed.json"
    )
    nodes = $items
}

$engine |
ConvertTo-Json -Depth 30 |
Set-Content $OUT_FILE -Encoding UTF8

Write-Host "MEANING ENGINE GENERATED"
Write-Host "NODES:" $items.Count
