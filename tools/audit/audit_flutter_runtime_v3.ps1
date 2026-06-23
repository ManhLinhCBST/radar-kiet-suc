$ErrorActionPreference = "Stop"

$ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $ROOT

Write-Host "========================================"
Write-Host "FLUTTER RUNTIME V3 AUDIT"
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
Write-Host "PUBSPEC"

$pubspec = Get-Content .\pubspec.yaml -Raw

$pubspecPatterns = @(
    "shared_preferences",
    "assets/data/question_library.json",
    "assets/data/observation_engine.json",
    "assets/data/node_engine.json",
    "assets/data/meaning_engine.json",
    "assets/data/recommendation_engine.json",
    "assets/data/history_engine.json",
    "assets/data/trajectory_engine.json"
)

foreach ($pattern in $pubspecPatterns) {
    if ($pubspec -match [regex]::Escape($pattern)) {
        Write-Host "OK   $pattern"
    }
    else {
        Write-Host "MISS $pattern"
        $missing += "pubspec:$pattern"
    }
}

Write-Host ""
Write-Host "DART RUNTIME V3 SYMBOLS"

$main = Get-Content .\lib\main.dart -Raw
$history = Get-Content .\lib\local_history.dart -Raw
$runtime = Get-Content .\lib\app_runtime.dart -Raw

$mainPatterns = @(
    "Runtime V3",
    "HistoryStore",
    "TrajectorySummary",
    "HistoryPage",
    "Lịch sử check-in",
    "Xem kết quả hôm nay"
)

foreach ($pattern in $mainPatterns) {
    if ($main -match [regex]::Escape($pattern)) {
        Write-Host "OK   main:$pattern"
    }
    else {
        Write-Host "MISS main:$pattern"
        $missing += "main:$pattern"
    }
}

$historyPatterns = @(
    "shared_preferences",
    "CheckinRecord",
    "HistoryStore",
    "TrajectorySummary",
    "saveResult",
    "loadRecords",
    "body_battery_checkin_history_v1"
)

foreach ($pattern in $historyPatterns) {
    if ($history -match [regex]::Escape($pattern)) {
        Write-Host "OK   history:$pattern"
    }
    else {
        Write-Host "MISS history:$pattern"
        $missing += "history:$pattern"
    }
}

$runtimePatterns = @(
    "class AppRuntime",
    "RuntimeResult",
    "ObservationRule",
    "NodeRule",
    "MeaningRule",
    "RecommendationRule"
)

foreach ($pattern in $runtimePatterns) {
    if ($runtime -match [regex]::Escape($pattern)) {
        Write-Host "OK   runtime:$pattern"
    }
    else {
        Write-Host "MISS runtime:$pattern"
        $missing += "runtime:$pattern"
    }
}

Write-Host ""
Write-Host "JSON COUNTS"

$q = Get-Content .\assets\data\question_library.json -Raw | ConvertFrom-Json
$o = Get-Content .\assets\data\observation_engine.json -Raw | ConvertFrom-Json
$n = Get-Content .\assets\data\node_engine.json -Raw | ConvertFrom-Json
$m = Get-Content .\assets\data\meaning_engine.json -Raw | ConvertFrom-Json
$r = Get-Content .\assets\data\recommendation_engine.json -Raw | ConvertFrom-Json

Write-Host "question_library questions:" $q.questions.Count
Write-Host "observation rules:" $o.observations.Count
Write-Host "node rules:" $n.nodes.Count
Write-Host "meaning nodes:" $m.nodes.Count
Write-Host "recommendation nodes:" $r.nodes.Count

if ($q.questions.Count -ne 32) { $missing += "question_count_not_32" }
if ($o.observations.Count -ne 32) { $missing += "observation_count_not_32" }
if ($n.nodes.Count -ne 8) { $missing += "node_count_not_8" }
if ($m.nodes.Count -ne 8) { $missing += "meaning_count_not_8" }
if ($r.nodes.Count -ne 8) { $missing += "recommendation_count_not_8" }

Write-Host ""
Write-Host "FLUTTER ANALYZE"
flutter analyze

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "FLUTTER RUNTIME V3 AUDIT PASS"
}
else {
    Write-Host "FLUTTER RUNTIME V3 AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
