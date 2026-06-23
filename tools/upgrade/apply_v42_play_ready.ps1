$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "APPLY V4.2 PLAY READY PATCH"
Write-Host "========================================"
Write-Host ""

$oldPackage = "com.example.body_battery"
$newPackage = "vn.mlcbst.radarkietsuc"
$appName = "Radar Kiệt Sức"
$versionLine = "version: 1.0.0+1"

$backupRoot = ".\_backups\v42_play_ready_" + (Get-Date -Format "yyyyMMdd_HHmmss")

New-Item `
-ItemType Directory `
-Force `
$backupRoot |
Out-Null

Write-Host "BACKUP ROOT: $backupRoot"

$backupFiles = @(
    ".\pubspec.yaml",
    ".\android\app\build.gradle.kts",
    ".\android\app\src\main\AndroidManifest.xml",
    ".\android\app\src\debug\AndroidManifest.xml",
    ".\android\app\src\profile\AndroidManifest.xml"
)

foreach ($file in $backupFiles) {
    if (Test-Path $file) {
        Copy-Item `
        $file `
        (Join-Path $backupRoot ((Split-Path $file -Leaf) + ".bak")) `
        -Force

        Write-Host "BACKUP OK   $file"
    }

    if (-not (Test-Path $file)) {
        Write-Host "BACKUP SKIP $file"
    }
}

$oldKotlin = ".\android\app\src\main\kotlin\com\example\body_battery\MainActivity.kt"

if (Test-Path $oldKotlin) {
    Copy-Item `
    $oldKotlin `
    (Join-Path $backupRoot "MainActivity.kt.bak") `
    -Force

    Write-Host "BACKUP OK   $oldKotlin"
}

Write-Host ""
Write-Host "PATCH pubspec.yaml VERSION"

$pubspecPath = ".\pubspec.yaml"
$pubspec = Get-Content $pubspecPath -Raw

$pubspec = [regex]::Replace(
    $pubspec,
    "(?m)^version:\s*.+$",
    $versionLine
)

Set-Content `
$pubspecPath `
-Value $pubspec `
-Encoding UTF8

Select-String `
-Path $pubspecPath `
-Pattern "^version:" |
Format-Table -Wrap

Write-Host ""
Write-Host "PATCH android/app/build.gradle.kts PACKAGE"

$gradlePath = ".\android\app\build.gradle.kts"
$gradle = Get-Content $gradlePath -Raw

$gradle = $gradle.Replace(
    "namespace = `"$oldPackage`"",
    "namespace = `"$newPackage`""
)

$gradle = $gradle.Replace(
    "applicationId = `"$oldPackage`"",
    "applicationId = `"$newPackage`""
)

Set-Content `
$gradlePath `
-Value $gradle `
-Encoding UTF8

Select-String `
-Path $gradlePath `
-Pattern "namespace|applicationId|versionCode|versionName" |
Format-Table -Wrap

Write-Host ""
Write-Host "PATCH ANDROID MANIFEST LABELS"

$manifestFiles = Get-ChildItem `
.\android\app\src `
-Recurse `
-Filter AndroidManifest.xml

foreach ($manifest in $manifestFiles) {
    $text = Get-Content $manifest.FullName -Raw

    if ($text -match "android:label=") {
        $text = [regex]::Replace(
            $text,
            'android:label="[^"]*"',
            'android:label="' + $appName + '"'
        )

        Set-Content `
        $manifest.FullName `
        -Value $text `
        -Encoding UTF8

        Write-Host "LABEL PATCHED $($manifest.FullName)"
    }

    if ($text -notmatch "android:label=") {
        Write-Host "LABEL SKIP    $($manifest.FullName)"
    }
}

Select-String `
-Path .\android\app\src\main\AndroidManifest.xml `
-Pattern "android:label" |
Format-Table -Wrap

Write-Host ""
Write-Host "PATCH KOTLIN PACKAGE"

$newKotlinDir = ".\android\app\src\main\kotlin\vn\mlcbst\radarkietsuc"
$newKotlin = Join-Path $newKotlinDir "MainActivity.kt"

New-Item `
-ItemType Directory `
-Force `
$newKotlinDir |
Out-Null

if (Test-Path $oldKotlin) {
    $kotlinText = Get-Content $oldKotlin -Raw

    $kotlinText = $kotlinText.Replace(
        "package $oldPackage",
        "package $newPackage"
    )

    Set-Content `
    $newKotlin `
    -Value $kotlinText `
    -Encoding UTF8

    Remove-Item `
    $oldKotlin `
    -Force

    Write-Host "KOTLIN MOVED TO $newKotlin"
}

if (-not (Test-Path $oldKotlin)) {
    if (Test-Path $newKotlin) {
        $kotlinText = Get-Content $newKotlin -Raw

        $kotlinText = [regex]::Replace(
            $kotlinText,
            "^package\s+.+$",
            "package $newPackage",
            "Multiline"
        )

        Set-Content `
        $newKotlin `
        -Value $kotlinText `
        -Encoding UTF8

        Write-Host "KOTLIN PACKAGE CONFIRMED $newKotlin"
    }
}

$oldDir = ".\android\app\src\main\kotlin\com"

if (Test-Path $oldDir) {
    $remaining = Get-ChildItem $oldDir -Recurse -File -ErrorAction SilentlyContinue

    if ($remaining.Count -eq 0) {
        Remove-Item `
        $oldDir `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue

        Write-Host "OLD KOTLIN EMPTY DIR REMOVED"
    }

    if ($remaining.Count -ne 0) {
        Write-Host "OLD KOTLIN DIR STILL HAS FILES:"
        $remaining | Select-Object FullName | Format-Table -Wrap
    }
}

Write-Host ""
Write-Host "VERIFY PACKAGE STRINGS"

Select-String `
-Path .\android\app\build.gradle.kts, .\android\app\src\main\kotlin\vn\mlcbst\radarkietsuc\MainActivity.kt `
-Pattern "vn.mlcbst.radarkietsuc|com.example.body_battery" |
Format-Table -Wrap

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
    Write-Host "OLD PACKAGE STILL FOUND:"
    $oldHits | Format-Table -Wrap
}

if (-not $oldHits) {
    Write-Host "OLD PACKAGE NOT FOUND IN ANDROID SOURCE"
}

Write-Host ""
Write-Host "V4.2 PATCH DONE"
