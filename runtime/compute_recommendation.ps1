$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"

$DIAG_FILE = "$ROOT\runtime\output\diagnostic_output.json"
$REC_FILE = "$ROOT\assets\data\recommendation_engine.json"
$OUT_FILE = "$ROOT\runtime\output\recommendation_output.json"

$d = Get-Content $DIAG_FILE -Raw | ConvertFrom-Json
$re = Get-Content $REC_FILE -Raw | ConvertFrom-Json

function Priority-Rank($priority) {
    switch ($priority) {
        "critical" { return 4 }
        "high" { return 3 }
        "medium" { return 2 }
        "low" { return 1 }
        default { return 0 }
    }
}

function Get-System-Level($score) {
    if ($score -lt 40) { return "low" }
    if ($score -lt 70) { return "medium" }
    return "high"
}

$systemLevel = Get-System-Level ([double]$d.system_score)

$topNodes =
$d.diagnostics |
Sort-Object node_score -Descending |
Select-Object -First $re.action_policy.top_node_count

$actions = @()

foreach ($node in $topNodes) {
    $rule = $re.nodes | Where-Object { $_.id -eq $node.node }

    if (-not $rule) {
        throw "Missing recommendation rule for node: $($node.node)"
    }

    if ($node.level -eq "high") {
        $selected = $rule.high_actions
    }
    else {
        $selected = $rule.medium_actions
    }

    $selected |
    Select-Object -First $re.action_policy.actions_per_node |
    ForEach-Object {
        $actions += [pscustomobject]@{
            node = $node.node
            name = $node.name
            node_score = $node.node_score
            level = $node.level
            action_id = $_.id
            title = $_.title
            detail = $_.detail
            priority = $_.priority
            priority_rank = Priority-Rank $_.priority
            duration_minutes = $_.duration_minutes
            effort = $_.effort
        }
    }
}

$actions =
$actions |
Sort-Object priority_rank,node_score -Descending |
Select-Object -First $re.action_policy.max_total_actions

$summary = ""

if ($systemLevel -eq "low") {
    $summary = "Hôm nay hệ của bạn tương đối ổn. Mục tiêu chính là giữ nhịp và không tự tăng tải."
}
elseif ($systemLevel -eq "medium") {
    $summary = "Hôm nay hệ của bạn đang ở vùng cảnh báo. Nên ưu tiên phục hồi, giảm tải và bảo vệ dự trữ."
}
else {
    $summary = "Hôm nay hệ của bạn đang ở vùng rủi ro cao. Không nên cố bứt tốc; cần giảm tải và phục hồi trước."
}

$result = [pscustomobject]@{
    date = $d.date
    system_score = $d.system_score
    system_level = $systemLevel
    summary = $summary
    top_nodes = $topNodes
    recommended_actions = $actions
}

$result |
ConvertTo-Json -Depth 40 |
Set-Content $OUT_FILE -Encoding UTF8

Write-Host "RECOMMENDATION RUNTIME OK"
Write-Host "DATE:" $d.date
Write-Host "SYSTEM SCORE:" $d.system_score
Write-Host "SYSTEM LEVEL:" $systemLevel
Write-Host ""
Write-Host "SUMMARY:"
Write-Host $summary
Write-Host ""
Write-Host "ACTIONS:"
$actions |
Select name,title,priority,duration_minutes,effort |
Format-Table -Wrap

Write-Host "OUTPUT:" $OUT_FILE
