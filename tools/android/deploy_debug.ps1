$ErrorActionPreference = "Stop"

$ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $ROOT

$ADB = "C:\Users\Admin\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$APK = ".\build\app\outputs\flutter-apk\app-debug.apk"
$PACKAGE = "com.example.body_battery"

Write-Host "========================================"
Write-Host "BUILD + INSTALL ANDROID DEBUG"
Write-Host "ROOT: $ROOT"
Write-Host "========================================"

Write-Host ""
Write-Host "FLUTTER ANALYZE"
flutter analyze

Write-Host ""
Write-Host "BUILD APK"
flutter build apk --debug

Write-Host ""
Write-Host "ADB DEVICES"
& $ADB devices -l

Write-Host ""
Write-Host "INSTALL APK"
& $ADB -s emulator-5554 install --no-streaming -r $APK

Write-Host ""
Write-Host "LAUNCH APP"
& $ADB -s emulator-5554 shell monkey -p $PACKAGE -c android.intent.category.LAUNCHER 1

Write-Host ""
Write-Host "DEPLOY PASS"
