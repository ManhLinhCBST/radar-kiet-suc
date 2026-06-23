$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"

$OUT_FILE =
"$ROOT\assets\data\trajectory_engine.json"

$engine = [pscustomobject]@{

    version = "1.0.0"

    improving_threshold = 10

    stable_threshold = 5

    declining_threshold = -10

    states = @(

        @{
            id = "recovering"
            min = 10
            message =
            "Hệ đang hồi phục."
        }

        @{
            id = "stable"
            min = -5
            max = 9
            message =
            "Hệ tương đối ổn định."
        }

        @{
            id = "declining"
            min = -20
            max = -6
            message =
            "Hệ đang suy giảm."
        }

        @{
            id = "collapsing"
            max = -21
            message =
            "Hệ đang lao dốc."
        }
    )
}

$engine |
ConvertTo-Json -Depth 20 |
Set-Content `
$OUT_FILE `
-Encoding UTF8

Write-Host ""
Write-Host "TRAJECTORY ENGINE GENERATED"
Write-Host ""
