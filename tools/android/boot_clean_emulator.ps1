$ErrorActionPreference = "Stop"

$ADB = "C:\Users\Admin\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$EMULATOR = "C:\Users\Admin\AppData\Local\Android\Sdk\emulator\emulator.exe"
$AVD = "Medium_Phone_API_36.1"

Write-Host "KILL OLD EMULATOR"
& $ADB kill-server

Get-Process emulator,qemu-system-x86_64 -ErrorAction SilentlyContinue |
Stop-Process -Force

Start-Sleep -Seconds 5

Write-Host "START CLEAN EMULATOR"
Start-Process `
-FilePath $EMULATOR `
-ArgumentList @(
    "-avd",
    $AVD,
    "-wipe-data",
    "-no-snapshot-load",
    "-no-snapshot-save",
    "-no-boot-anim",
    "-gpu",
    "swiftshader_indirect"
)

Start-Sleep -Seconds 5

& $ADB start-server

for ($i = 1; $i -le 80; $i++) {
    Write-Host "CHECK $i"

    $devices = & $ADB devices -l
    $devices

    if ($devices -match "emulator-5554\s+device") {
        Write-Host "ADB ONLINE"
        break
    }

    & $ADB reconnect offline | Out-Null
    Start-Sleep -Seconds 3
}

while ((& $ADB -s emulator-5554 shell getprop sys.boot_completed).Trim() -ne "1") {
    Start-Sleep -Seconds 2
    Write-Host "WAITING ANDROID BOOT..."
}

Write-Host "ANDROID BOOT PASS"

Write-Host ""
Write-Host "PACKAGE MANAGER TEST"
& $ADB -s emulator-5554 shell pm list packages | Select-Object -First 5

Write-Host ""
Write-Host "EMULATOR READY"
