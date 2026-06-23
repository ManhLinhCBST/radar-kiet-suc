param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

$ADB = "C:\Users\Admin\AppData\Local\Android\Sdk\platform-tools\adb.exe"

$outDir = ".\play_assets\screenshots\phone"

New-Item `
-ItemType Directory `
-Force `
$outDir |
Out-Null

$safeName = $Name -replace "[^a-zA-Z0-9_\-]", "_"
$fileName = "$safeName.png"
$devicePath = "/sdcard/$fileName"
$localPath = Join-Path $outDir $fileName

& $ADB shell screencap -p $devicePath
& $ADB pull $devicePath $localPath | Out-Host
& $ADB shell rm $devicePath

Write-Host "SCREENSHOT SAVED: $localPath"

Get-Item $localPath |
Select-Object FullName,Length,LastWriteTime |
Format-List
