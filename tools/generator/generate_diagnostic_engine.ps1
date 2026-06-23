$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"

$NODE_FILE =
"$ROOT\assets\data\node_engine.json"

$OUT_FILE =
"$ROOT\assets\data\diagnostic_engine.json"

$n =
Get-Content `
$NODE_FILE `
-Raw |
ConvertFrom-Json

$rules = @()

foreach($node in $n.nodes)
{
    $rules += [pscustomobject]@{

        node =
        $node.id

        low = @{

            threshold = 40

            message =
            "$($node.id) đang suy giảm."
        }

        medium = @{

            threshold = 60

            message =
            "$($node.id) cần chú ý."
        }

        high = @{

            threshold = 80

            message =
            "$($node.id) đang lệch mạnh."
        }
    }
}

$engine = [pscustomobject]@{

    version = "1.0.0"

    generated_from =
    "node_engine.json"

    rules =
    $rules
}

$engine |
ConvertTo-Json `
-Depth 20 |
Set-Content `
$OUT_FILE `
-Encoding UTF8

Write-Host ""
Write-Host "DIAGNOSTIC ENGINE GENERATED"
Write-Host ""

Write-Host "RULES:"
Write-Host $rules.Count
