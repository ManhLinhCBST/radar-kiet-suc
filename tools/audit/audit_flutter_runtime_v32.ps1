$ErrorActionPreference = "Stop"

$ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $ROOT

Write-Host "========================================"
Write-Host "FLUTTER RUNTIME V3.2 AUDIT"
Write-Host "ROOT: $ROOT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$files = @(
    "lib\app_runtime.dart",
    "lib\local_history.dart",
    "lib\main.dart",
    "tools\audit\audit_flutter_runtime_v31.ps1"
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
Write-Host "V3.2 EXPORT SYMBOLS"

$main = Get-Content .\lib\main.dart -Raw
$history = Get-Content .\lib\local_history.dart -Raw

$checks = @(
    @{ File = "history"; Text = "exportRecordsJson"; Body = $history },
    @{ File = "history"; Text = "body_battery_history_export_v1"; Body = $history },
    @{ File = "history"; Text = "JsonEncoder.withIndent"; Body = $history },
    @{ File = "main"; Text = "package:flutter/services.dart"; Body = $main },
    @{ File = "main"; Text = "_exportHistoryJson"; Body = $main },
    @{ File = "main"; Text = "Clipboard.setData"; Body = $main },
    @{ File = "main"; Text = "ClipboardData"; Body = $main },
    @{ File = "main"; Text = "onExport"; Body = $main },
    @{ File = "main"; Text = "Xuất dữ liệu JSON"; Body = $main },
    @{ File = "main"; Text = "Đã copy lịch sử JSON vào clipboard."; Body = $main },
    @{ File = "main"; Text = "Icons.ios_share"; Body = $main }
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
    Write-Host "FLUTTER RUNTIME V3.2 AUDIT PASS"
}
else {
    Write-Host "FLUTTER RUNTIME V3.2 AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
