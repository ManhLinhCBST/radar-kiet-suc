$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "RADAR KIET SUC V4.6.1 UI COPY AUDIT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$main = Get-Content .\lib\main.dart -Raw -Encoding UTF8
$appRuntime = Get-Content .\lib\app_runtime.dart -Raw -Encoding UTF8
$gitignore = Get-Content .\.gitignore -Raw -Encoding UTF8

$allCode = $main + "`n" + $appRuntime

Write-Host "REQUIRED COPY"

$required = @(
    "Check-in nhanh mỗi ngày",
    "câu quan sát",
    "trục theo dõi",
    "Trục là gì?",
    "Các điểm nghẽn chính",
    "Chọn 1–2 việc nhỏ"
)

foreach ($item in $required) {
    if ($main.Contains($item)) {
        Write-Host "OK   $item"
    }

    if (-not $main.Contains($item)) {
        Write-Host "MISS $item"
        $missing += $item
    }
}

Write-Host ""
Write-Host "BANNED TECHNICAL OR BROKEN COPY"

$banned = @(
    "Runtime V3",
    "engine JSON",
    "meaning_engine.json",
    "recommendation_engine.json",
    "Node là gì?",
    "Full 32 câu",
    'Quan sát ${runtime.observationRules.length} luật',
    'Trục ${runtime.nodeRules.length} luật',
    "AppBản",
    "Bản chạy",
    "chạyResult",
    "chạyAction"
)

foreach ($item in $banned) {
    if ($main.Contains($item)) {
        Write-Host "BAD  $item"
        $missing += "banned:$item"
    }

    if (-not $main.Contains($item)) {
        Write-Host "OK   not found: $item"
    }
}

Write-Host ""
Write-Host "RUNTIME IDENTIFIERS STILL VALID"

$validIdentifiers = @(
    "AppRuntime",
    "RuntimeResult",
    "RuntimeAction"
)

foreach ($item in $validIdentifiers) {
    if ($allCode.Contains($item)) {
        Write-Host "OK   $item"
    }

    if (-not $allCode.Contains($item)) {
        Write-Host "MISS $item"
        $missing += "missing identifier:$item"
    }
}

Write-Host ""
Write-Host "RAW SCREENSHOTS IGNORE"

if ($gitignore.Contains("play_assets/screenshots/raw/")) {
    Write-Host "OK   raw screenshots ignored"
}

if (-not $gitignore.Contains("play_assets/screenshots/raw/")) {
    Write-Host "MISS raw screenshots ignored"
    $missing += "gitignore raw screenshots"
}

Write-Host ""
Write-Host "FLUTTER ANALYZE"

flutter analyze

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "RADAR KIET SUC V4.6.1 UI COPY AUDIT PASS"
}

if ($missing.Count -ne 0) {
    Write-Host "RADAR KIET SUC V4.6.1 UI COPY AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
