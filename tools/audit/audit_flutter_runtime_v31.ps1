$ErrorActionPreference = "Stop"

$ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $ROOT

Write-Host "========================================"
Write-Host "FLUTTER RUNTIME V3.1 AUDIT"
Write-Host "ROOT: $ROOT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$files = @(
    "lib\app_runtime.dart",
    "lib\local_history.dart",
    "lib\main.dart",
    "assets\data\question_library.json",
    "assets\data\observation_engine.json",
    "assets\data\node_engine.json",
    "assets\data\meaning_engine.json",
    "assets\data\recommendation_engine.json",
    "assets\data\history_engine.json",
    "assets\data\trajectory_engine.json"
)

Write-Host "FILES"
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "OK   $file"
    }
    else {
        Write-Host "MISS $file"
        $missing += $file
    }
}

Write-Host ""
Write-Host "V3.1 SYMBOLS"

$main = Get-Content .\lib\main.dart -Raw
$history = Get-Content .\lib\local_history.dart -Raw

$checks = @(
    @{ File = "main"; Text = "_seedDemoHistory"; Body = $main },
    @{ File = "main"; Text = "onSeedDemo"; Body = $main },
    @{ File = "main"; Text = "Tạo dữ liệu mẫu 3 ngày"; Body = $main },
    @{ File = "main"; Text = "Icons.auto_fix_high"; Body = $main },
    @{ File = "history"; Text = "seedDemo3Days"; Body = $history },
    @{ File = "history"; Text = "_demoRecord"; Body = $history },
    @{ File = "history"; Text = "Dữ liệu mẫu"; Body = $history },
    @{ File = "history"; Text = "_scoreLevel"; Body = $history }
)

foreach ($check in $checks) {
    if ($check.Body -match [regex]::Escape($check.Text)) {
        Write-Host "OK   $($check.File):$($check.Text)"
    }
    else {
        Write-Host "MISS $($check.File):$($check.Text)"
        $missing += "$($check.File):$($check.Text)"
    }
}

Write-Host ""
Write-Host "FLUTTER ANALYZE"
flutter analyze

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "FLUTTER RUNTIME V3.1 AUDIT PASS"
}
else {
    Write-Host "FLUTTER RUNTIME V3.1 AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
