$ErrorActionPreference = "Stop"

$ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $ROOT

Write-Host "========================================"
Write-Host "FLUTTER RUNTIME V3.3 AUDIT"
Write-Host "ROOT: $ROOT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$main = Get-Content .\lib\main.dart -Raw

$checks = @(
    "class HelpPage extends StatelessWidget",
    "class _HelpBlock extends StatelessWidget",
    "Cách đọc chỉ số",
    "Chỉ số hao mòn là gì?",
    "Cách đọc điểm 0–100",
    "Vì sao điểm cao là xấu?",
    "Node là gì?",
    "Cách đọc xu hướng",
    "Giới hạn an toàn",
    "Khi nào không tự xử lý?",
    "Icons.help_outline"
)

foreach ($check in $checks) {
    if ($main -match [regex]::Escape($check)) {
        Write-Host "OK   $check"
    }
    else {
        Write-Host "MISS $check"
        $missing += $check
    }
}

Write-Host ""
Write-Host "FLUTTER ANALYZE"
flutter analyze

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "FLUTTER RUNTIME V3.3 AUDIT PASS"
}
else {
    Write-Host "FLUTTER RUNTIME V3.3 AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
