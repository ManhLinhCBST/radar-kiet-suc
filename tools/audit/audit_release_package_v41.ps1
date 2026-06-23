$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "RELEASE PACKAGE V4.1 AUDIT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$apk = Get-ChildItem .\release -Filter "RadarKietSuc_v4.0_*.apk" |
Sort-Object LastWriteTime -Descending |
Select-Object -First 1

$zip = Get-ChildItem .\release -Filter "RadarKietSuc_V4_Release_Test_*.zip" |
Sort-Object LastWriteTime -Descending |
Select-Object -First 1

if ($null -ne $apk) {
    Write-Host "OK   APK:" $apk.Name
    Write-Host "SIZE_BYTES:" $apk.Length
}

if ($null -eq $apk) {
    Write-Host "MISS APK"
    $missing += "APK"
}

if ($null -ne $zip) {
    Write-Host "OK   ZIP:" $zip.Name
    Write-Host "SIZE_BYTES:" $zip.Length
}

if ($null -eq $zip) {
    Write-Host "MISS ZIP"
    $missing += "ZIP"
}

$required = @(
    ".\release\VERSION_INFO.txt",
    ".\release\INSTALL_GUIDE.txt"
)

foreach ($file in $required) {
    if (Test-Path $file) {
        Write-Host "OK   $file"
    }

    if (-not (Test-Path $file)) {
        Write-Host "MISS $file"
        $missing += $file
    }
}

if ($null -ne $apk) {
    $hashFile = ".\release\$($apk.BaseName).sha256.txt"

    if (Test-Path $hashFile) {
        Write-Host "OK   $hashFile"
    }

    if (-not (Test-Path $hashFile)) {
        Write-Host "MISS $hashFile"
        $missing += $hashFile
    }
}

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "RELEASE PACKAGE V4.1 AUDIT PASS"
}

if ($missing.Count -ne 0) {
    Write-Host "RELEASE PACKAGE V4.1 AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
