$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"

$NODE_SCORE_FILE = "$ROOT\runtime\output\node_score_output.json"
$MEANING_FILE = "$ROOT\assets\data\meaning_engine.json"
$OUT_FILE = "$ROOT\runtime\output\diagnostic_output.json"

$ns = Get-Content $NODE_SCORE_FILE -Raw | ConvertFrom-Json
$m = Get-Content $MEANING_FILE -Raw | ConvertFrom-Json

function Get-Level($score) {
    if ($score -lt 40) { return "low" }
    if ($score -lt 70) { return "medium" }
    return "high"
}

$diagnostics = @()

foreach ($node in $ns.nodes) {
    $meaningNode = $m.nodes | Where-Object { $_.id -eq $node.node }

    if (-not $meaningNode) {
        throw "Missing meaning for node: $($node.node)"
    }

    $level = Get-Level ([double]$node.node_score)

    $band = $meaningNode.bands | Where-Object { $_.level -eq $level }

    if (-not $band) {
        throw "Missing band $level for node: $($node.node)"
    }

    $diagnostics += [pscustomobject]@{
        node = $node.node
        name = $meaningNode.name
        node_score = $node.node_score
        node_weight = $node.node_weight
        level = $level
        message = $band.message
    }
}

$topRisks =
$diagnostics |
Sort-Object node_score -Descending |
Select-Object -First 3

$result = [pscustomobject]@{
    date = $ns.date
    system_score = $ns.system_score
    score_semantics = "Điểm càng cao nghĩa là rủi ro hao mòn / kiệt sức càng cao."
    diagnostics = $diagnostics
    top_risks = $topRisks
}

$result |
ConvertTo-Json -Depth 30 |
Set-Content $OUT_FILE -Encoding UTF8

Write-Host "DIAGNOSTIC RUNTIME OK"
Write-Host "DATE:" $ns.date
Write-Host "SYSTEM SCORE:" $ns.system_score
Write-Host "TOP RISKS:"
$topRisks | Select name,node_score,level | Format-Table
Write-Host "OUTPUT:" $OUT_FILE
