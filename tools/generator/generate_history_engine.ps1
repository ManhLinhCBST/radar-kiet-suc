$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"

$OUT_FILE =
"$ROOT\assets\data\history_engine.json"

$engine = [pscustomobject]@{

    version = "1.0.0"

    windows = @(

        @{
            id = "daily"
            days = 1
        }

        @{
            id = "weekly"
            days = 7
        }

        @{
            id = "monthly"
            days = 30
        }

        @{
            id = "quarterly"
            days = 90
        }
    )

    minimum_samples = 3
}

$engine |
ConvertTo-Json -Depth 20 |
Set-Content `
$OUT_FILE `
-Encoding UTF8

Write-Host ""
Write-Host "HISTORY ENGINE GENERATED"
Write-Host ""
