$ErrorActionPreference = "Stop"

$ROOT = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ADB = "C:\Users\Admin\AppData\Local\Android\Sdk\platform-tools\adb.exe"

Set-Location $ROOT

Write-Host "ROOT:" $ROOT
Write-Host "ADB:" $ADB
Write-Host ""

Write-Host "CHECK DEVICES"
& $ADB devices -l

Write-Host ""
Write-Host "CHECK PACKAGE MANAGER"
& $ADB -s emulator-5554 shell pm list packages | Select-Object -First 5

Write-Host ""
Write-Host "BUILD APK"
flutter build apk --debug

Write-Host ""
Write-Host "INSTALL APK"
& $ADB -s emulator-5554 install --no-streaming -r .\build\app\outputs\flutter-apk\app-debug.apk

Write-Host ""
Write-Host "LAUNCH APP"
& $ADB -s emulator-5554 shell monkey -p com.example.body_battery -c android.intent.category.LAUNCHER 1

Write-Host ""
Write-Host "ANDROID APP DEPLOY PASS"
