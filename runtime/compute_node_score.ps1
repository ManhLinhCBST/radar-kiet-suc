$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"

$RISK_FILE = "$ROOT\runtime\output\risk_output.json"
$NODE_FILE = "$ROOT\assets\data\node_engine.json"
$OUT_FILE = "$ROOT\runtime\output\node_score_output.json"

$r = Get-Content $RISK_FILE -Raw | ConvertFrom-Json
$n = Get-Content $NODE_FILE -Raw | ConvertFrom-Json

$nodeRows = @()

foreach ($node in $n.nodes) {
    $score = 0
    $details = @()

    foreach ($q in $node.questions) {
        $riskRow = $r.risks | Where-Object { $_.question_id -eq $q.question_id }

        if (-not $riskRow) {
            throw "Missing risk for question: $($q.question_id)"
        }

        $contribution = [double]$riskRow.risk * ([double]$q.internal_weight / 100)

        $details += [pscustomobject]@{
            question_id = $q.question_id
            value = $riskRow.value
            band = $riskRow.band
            risk = $riskRow.risk
            internal_weight = $q.internal_weight
            contribution = [math]::Round($contribution * 100, 2)
        }

        $score += $contribution
    }

    $nodeRows += [pscustomobject]@{
        node = $node.id
        node_weight = $node.node_weight
        question_count = $node.question_count
        node_score = [math]::Round($score * 100, 2)
        details = $details
    }
}

$systemScore = 0

foreach ($node in $nodeRows) {
    $systemScore += ([double]$node.node_score) * ([double]$node.node_weight / 100)
}

$result = [pscustomobject]@{
    date = $r.date
    system_score = [math]::Round($systemScore, 2)
    nodes = $nodeRows
}

$result |
ConvertTo-Json -Depth 30 |
Set-Content $OUT_FILE -Encoding UTF8

Write-Host "NODE SCORE RUNTIME OK"
Write-Host "DATE:" $r.date
Write-Host "SYSTEM SCORE:" ([math]::Round($systemScore, 2))
Write-Host "OUTPUT:" $OUT_FILE
