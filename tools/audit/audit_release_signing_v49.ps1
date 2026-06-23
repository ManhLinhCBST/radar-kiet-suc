$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "RADAR KIET SUC V4.9 RELEASE SIGNING AUDIT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$gradle = Get-Content .\android\app\build.gradle.kts -Raw -Encoding UTF8
$gitignore = Get-Content .\.gitignore -Raw -Encoding UTF8

Write-Host "SECRET FILES"

if (Test-Path .\android\upload-keystore.jks) {
    Write-Host "OK   android/upload-keystore.jks exists"
}

if (-not (Test-Path .\android\upload-keystore.jks)) {
    Write-Host "MISS android/upload-keystore.jks"
    $missing += "upload-keystore.jks"
}

if (Test-Path .\android\key.properties) {
    Write-Host "OK   android/key.properties exists"
}

if (-not (Test-Path .\android\key.properties)) {
    Write-Host "MISS android/key.properties"
    $missing += "key.properties"
}

Write-Host ""
Write-Host "GITIGNORE"

foreach ($item in @("android/key.properties", "android/upload-keystore.jks", "android/*.jks")) {
    if ($gitignore.Contains($item)) {
        Write-Host "OK   ignored: $item"
    }

    if (-not $gitignore.Contains($item)) {
        Write-Host "MISS ignored: $item"
        $missing += "gitignore:$item"
    }
}

Write-Host ""
Write-Host "GRADLE SIGNING CONFIG"

$required = @(
    "import java.util.Properties",
    "import java.io.FileInputStream",
    "val keystoreProperties",
    "rootProject.file(""key.properties"")",
    "signingConfigs",
    "create(""release"")",
    "keyAlias = keystoreProperties",
    "storeFile = rootProject.file(keystoreProperties",
    "signingConfig = signingConfigs.getByName(""release"")"
)

foreach ($item in $required) {
    if ($gradle.Contains($item)) {
        Write-Host "OK   $item"
    }

    if (-not $gradle.Contains($item)) {
        Write-Host "MISS $item"
        $missing += "gradle:$item"
    }
}

if ($gradle.Contains('signingConfig = signingConfigs.getByName("debug")')) {
    Write-Host "BAD  release still uses debug signing"
    $missing += "release uses debug signing"
}

if (-not $gradle.Contains('signingConfig = signingConfigs.getByName("debug")')) {
    Write-Host "OK   debug signing not used for release"
}

Write-Host ""
Write-Host "FLUTTER ANALYZE"

flutter analyze

Write-Host ""
Write-Host "BUILD RELEASE AAB"

flutter clean
flutter pub get
flutter build appbundle --release

Write-Host ""
Write-Host "AAB"

$aab = ".\build\app\outputs\bundle\release\app-release.aab"

if (Test-Path $aab) {
    Get-Item $aab |
    Select-Object FullName,Length,LastWriteTime |
    Format-List
}

if (-not (Test-Path $aab)) {
    Write-Host "MISS release AAB"
    $missing += "release AAB"
}

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "RADAR KIET SUC V4.9 RELEASE SIGNING AUDIT PASS"
}

if ($missing.Count -ne 0) {
    Write-Host "RADAR KIET SUC V4.9 RELEASE SIGNING AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}

