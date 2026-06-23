$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "BODY BATTERY V4.2 PLAY READY AUDIT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$newPackage = "vn.mlcbst.radarkietsuc"
$oldPackage = "com.example.body_battery"
$appName = "Radar Kiệt Sức"

Write-Host "VERSION"

$pubspec = Get-Content .\pubspec.yaml -Raw

if ($pubspec -match "(?m)^version:\s*1\.0\.0\+1$") {
    Write-Host "OK   version: 1.0.0+1"
}

if ($pubspec -notmatch "(?m)^version:\s*1\.0\.0\+1$") {
    Write-Host "MISS version: 1.0.0+1"
    $missing += "version"
}

Write-Host ""
Write-Host "ANDROID PACKAGE"

$gradle = Get-Content .\android\app\build.gradle.kts -Raw

if ($gradle -match "namespace = `"$newPackage`"") {
    Write-Host "OK   namespace $newPackage"
}

if ($gradle -notmatch "namespace = `"$newPackage`"") {
    Write-Host "MISS namespace $newPackage"
    $missing += "namespace"
}

if ($gradle -match "applicationId = `"$newPackage`"") {
    Write-Host "OK   applicationId $newPackage"
}

if ($gradle -notmatch "applicationId = `"$newPackage`"") {
    Write-Host "MISS applicationId $newPackage"
    $missing += "applicationId"
}

Write-Host ""
Write-Host "ANDROID LABEL"

$manifest = Get-Content .\android\app\src\main\AndroidManifest.xml -Raw

if ($manifest -match [regex]::Escape('android:label="' + $appName + '"')) {
    Write-Host "OK   app label $appName"
}

if ($manifest -notmatch [regex]::Escape('android:label="' + $appName + '"')) {
    Write-Host "MISS app label $appName"
    $missing += "app_label"
}

Write-Host ""
Write-Host "KOTLIN PACKAGE"

$kotlinPath = ".\android\app\src\main\kotlin\vn\mlcbst\radarkietsuc\MainActivity.kt"

if (Test-Path $kotlinPath) {
    Write-Host "OK   $kotlinPath"
}

if (-not (Test-Path $kotlinPath)) {
    Write-Host "MISS $kotlinPath"
    $missing += "MainActivity_path"
}

if (Test-Path $kotlinPath) {
    $kotlin = Get-Content $kotlinPath -Raw

    if ($kotlin -match "package $newPackage") {
        Write-Host "OK   Kotlin package $newPackage"
    }

    if ($kotlin -notmatch "package $newPackage") {
        Write-Host "MISS Kotlin package $newPackage"
        $missing += "Kotlin_package"
    }
}

Write-Host ""
Write-Host "SEARCH OLD PACKAGE"

$oldHits = Get-ChildItem `
.\android `
-Recurse `
-File |
Where-Object {
    $_.FullName -notmatch "\\build\\"
} |
Select-String `
-Pattern $oldPackage `
-SimpleMatch `
-ErrorAction SilentlyContinue

if ($oldHits) {
    Write-Host "BAD  old package still found"
    $oldHits | Format-Table -Wrap
    $missing += "old_package_found"
}

if (-not $oldHits) {
    Write-Host "OK   old package not found"
}

Write-Host ""
Write-Host "FLUTTER ANALYZE"
flutter analyze

Write-Host ""
Write-Host "BUILD OUTPUTS"

$apk = ".\build\app\outputs\flutter-apk\app-release.apk"
$aab = ".\build\app\outputs\bundle\release\app-release.aab"

if (Test-Path $apk) {
    $apkItem = Get-Item $apk
    Write-Host "OK   APK $($apkItem.Length) bytes"
}

if (-not (Test-Path $apk)) {
    Write-Host "MISS APK release"
    $missing += "apk_release"
}

if (Test-Path $aab) {
    $aabItem = Get-Item $aab
    Write-Host "OK   AAB $($aabItem.Length) bytes"
}

if (-not (Test-Path $aab)) {
    Write-Host "MISS AAB release"
    $missing += "aab_release"
}

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "BODY BATTERY V4.2 PLAY READY AUDIT PASS"
}

if ($missing.Count -ne 0) {
    Write-Host "BODY BATTERY V4.2 PLAY READY AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
