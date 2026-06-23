$ErrorActionPreference = "Stop"

$ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $ROOT

Write-Host "========================================"
Write-Host "BODY BATTERY V4.0 RELEASE AUDIT"
Write-Host "ROOT: $ROOT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$requiredFiles = @(
    "lib\app_runtime.dart",
    "lib\local_history.dart",
    "lib\main.dart",
    "assets\data\question_library.json",
    "assets\data\observation_engine.json",
    "assets\data\node_engine.json",
    "assets\data\meaning_engine.json",
    "assets\data\recommendation_engine.json",
    "assets\data\history_engine.json",
    "assets\data\trajectory_engine.json",
    "tools\audit\audit_flutter_runtime_v34.ps1"
)

Write-Host "FILES"
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "OK   $file"
    }

    if (-not (Test-Path $file)) {
        Write-Host "MISS $file"
        $missing += $file
    }
}

Write-Host ""
Write-Host "RUNTIME SYMBOLS"

$main = Get-Content .\lib\main.dart -Raw
$runtime = Get-Content .\lib\app_runtime.dart -Raw
$history = Get-Content .\lib\local_history.dart -Raw

$checks = @(
    @{ File = "main"; Text = "Runtime V3"; Body = $main },
    @{ File = "main"; Text = "Cách đọc chỉ số"; Body = $main },
    @{ File = "main"; Text = "Xuất dữ liệu JSON"; Body = $main },
    @{ File = "main"; Text = "Tạo dữ liệu mẫu kiểm thử 3 ngày"; Body = $main },
    @{ File = "main"; Text = "Quan sát"; Body = $main },
    @{ File = "main"; Text = "Trục"; Body = $main },
    @{ File = "runtime"; Text = "class AppRuntime"; Body = $runtime },
    @{ File = "runtime"; Text = "RuntimeResult"; Body = $runtime },
    @{ File = "history"; Text = "HistoryStore"; Body = $history },
    @{ File = "history"; Text = "TrajectorySummary"; Body = $history },
    @{ File = "history"; Text = "exportRecordsJson"; Body = $history }
)

foreach ($check in $checks) {
    if ($check.Body -match [regex]::Escape($check.Text)) {
        Write-Host "OK   $($check.File):$($check.Text)"
    }

    if ($check.Body -notmatch [regex]::Escape($check.Text)) {
        Write-Host "MISS $($check.File):$($check.Text)"
        $missing += "$($check.File):$($check.Text)"
    }
}

Write-Host ""
Write-Host "FLUTTER ANALYZE"
flutter analyze

Write-Host ""
Write-Host "RELEASE APK"

$releaseApk = ".\build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path $releaseApk) {
    $apk = Get-Item $releaseApk
    Write-Host "OK   $releaseApk"
    Write-Host "SIZE_BYTES:" $apk.Length
    Write-Host "LAST_WRITE:" $apk.LastWriteTime
}

if (-not (Test-Path $releaseApk)) {
    Write-Host "MISS $releaseApk"
    $missing += $releaseApk
}

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "BODY BATTERY V4.0 RELEASE AUDIT PASS"
}

if ($missing.Count -ne 0) {
    Write-Host "BODY BATTERY V4.0 RELEASE AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
