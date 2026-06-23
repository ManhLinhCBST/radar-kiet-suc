$ErrorActionPreference = "Stop"

$ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $ROOT

Write-Host "========================================"
Write-Host "FLUTTER RUNTIME V2 AUDIT"
Write-Host "ROOT: $ROOT"
Write-Host "========================================"
Write-Host ""

$requiredAssets = @(
    "assets\data\question_library.json",
    "assets\data\observation_engine.json",
    "assets\data\node_engine.json",
    "assets\data\meaning_engine.json",
    "assets\data\recommendation_engine.json",
    "assets\data\history_engine.json",
    "assets\data\trajectory_engine.json"
)

$missing = @()

Write-Host "ASSET FILES"
foreach ($file in $requiredAssets) {
    if (Test-Path $file) {
        Write-Host "OK   $file"
    }
    else {
        Write-Host "MISS $file"
        $missing += $file
    }
}

Write-Host ""
Write-Host "PUBSPEC ASSETS"

$pubspec = Get-Content .\pubspec.yaml -Raw

foreach ($file in $requiredAssets) {
    $assetPath = $file -replace "\\","/"

    if ($pubspec -match [regex]::Escape($assetPath)) {
        Write-Host "OK   $assetPath"
    }
    else {
        Write-Host "MISS $assetPath"
        $missing += "pubspec:$assetPath"
    }
}

Write-Host ""
Write-Host "DART FILES"

$dartFiles = @(
    "lib\app_runtime.dart",
    "lib\main.dart"
)

foreach ($file in $dartFiles) {
    if (Test-Path $file) {
        Write-Host "OK   $file"
    }
    else {
        Write-Host "MISS $file"
        $missing += $file
    }
}

Write-Host ""
Write-Host "DART RUNTIME IMPORT CHECK"

$appRuntime = Get-Content .\lib\app_runtime.dart -Raw
$main = Get-Content .\lib\main.dart -Raw

$checks = @(
    "assets/data/question_library.json",
    "assets/data/observation_engine.json",
    "assets/data/node_engine.json",
    "assets/data/meaning_engine.json",
    "assets/data/recommendation_engine.json",
    "class AppRuntime",
    "RuntimeResult",
    "ObservationRule",
    "NodeRule",
    "MeaningRule",
    "RecommendationRule"
)

foreach ($pattern in $checks) {
    if ($appRuntime -match [regex]::Escape($pattern)) {
        Write-Host "OK   $pattern"
    }
    else {
        Write-Host "MISS $pattern"
        $missing += "app_runtime:$pattern"
    }
}

if ($main -match "AppRuntime.load") {
    Write-Host "OK   main.dart uses AppRuntime.load"
}
else {
    Write-Host "MISS main.dart uses AppRuntime.load"
    $missing += "main:AppRuntime.load"
}

if ($main -match "Runtime V2") {
    Write-Host "OK   main.dart shows Runtime V2"
}
else {
    Write-Host "WARN main.dart does not show Runtime V2 text"
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

if ($q.questions.Count -ne 32) {
    $missing += "question_count_not_32"
}

if ($o.observations.Count -ne 32) {
    $missing += "observation_count_not_32"
}

if ($n.nodes.Count -ne 8) {
    $missing += "node_count_not_8"
}

if ($m.nodes.Count -ne 8) {
    $missing += "meaning_count_not_8"
}

if ($r.nodes.Count -ne 8) {
    $missing += "recommendation_count_not_8"
}

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "FLUTTER RUNTIME V2 AUDIT PASS"
}
else {
    Write-Host "FLUTTER RUNTIME V2 AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
