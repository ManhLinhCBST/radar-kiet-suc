$ErrorActionPreference = "Stop"

$ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $ROOT

Write-Host "========================================"
Write-Host "FLUTTER RUNTIME V3.4 AUDIT"
Write-Host "ROOT: $ROOT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$main = Get-Content .\lib\main.dart -Raw

$mustHave = @(
    "String _vnEffort",
    "String _vnPriority",
    "rất quan trọng",
    "Quan sát",
    "Trục",
    "mức `$effort",
    "Tạo dữ liệu mẫu kiểm thử 3 ngày"
)

foreach ($item in $mustHave) {
    if ($main -match [regex]::Escape($item)) {
        Write-Host "OK   $item"
    }
    else {
        Write-Host "MISS $item"
        $missing += $item
    }
}

$mustNotHave = @(
    "Observation `${runtime.observationRules.length} rule",
    "Node `${runtime.nodeRules.length} rule",
    "mức `${action.effort}",
    "if (action.priority.isNotEmpty) action.priority"
)

foreach ($item in $mustNotHave) {
    if ($main -match [regex]::Escape($item)) {
        Write-Host "BAD  $item"
        $missing += "BAD:$item"
    }
    else {
        Write-Host "OK_NOT_FOUND   $item"
    }
}

Write-Host ""
Write-Host "FLUTTER ANALYZE"
flutter analyze

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "FLUTTER RUNTIME V3.4 AUDIT PASS"
}
else {
    Write-Host "FLUTTER RUNTIME V3.4 AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
