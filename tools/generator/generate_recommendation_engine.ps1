$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"

$SEED_FILE = "$ROOT\assets\data\recommendation_seed.json"
$MEANING_FILE = "$ROOT\assets\data\meaning_engine.json"
$OUT_FILE = "$ROOT\assets\data\recommendation_engine.json"

$s = Get-Content $SEED_FILE -Raw | ConvertFrom-Json
$m = Get-Content $MEANING_FILE -Raw | ConvertFrom-Json

$missing = @()

foreach ($mn in $m.nodes) {
    $seedNode = $s.nodes | Where-Object { $_.id -eq $mn.id }

    if (-not $seedNode) {
        $missing += $mn.id
    }
}

if ($missing.Count -gt 0) {
    throw "Missing recommendation seed for nodes: $($missing -join ', ')"
}

$rules = @()

foreach ($mn in $m.nodes) {
    $seedNode = $s.nodes | Where-Object { $_.id -eq $mn.id }

    $rules += [pscustomobject]@{
        id = $mn.id
        name = $mn.name
        node_weight = $mn.node_weight
        medium_actions = $seedNode.medium_actions
        high_actions = $seedNode.high_actions
    }
}

$engine = [pscustomobject]@{
    version = "1.0.0"
    generated_from = @(
        "recommendation_seed.json",
        "meaning_engine.json"
    )
    score_semantics = $s.score_semantics
    action_policy = @{
        top_node_count = 3
        actions_per_node = 2
        max_total_actions = 6
    }
    nodes = $rules
}

$engine |
ConvertTo-Json -Depth 40 |
Set-Content $OUT_FILE -Encoding UTF8

Write-Host "RECOMMENDATION ENGINE GENERATED"
Write-Host "VERSION:" $engine.version
Write-Host "NODES:" $engine.nodes.Count
Write-Host "OUTPUT:" $OUT_FILE
