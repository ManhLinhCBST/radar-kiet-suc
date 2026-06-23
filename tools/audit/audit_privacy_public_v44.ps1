$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "BODY BATTERY V4.4 PRIVACY PUBLIC AUDIT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$files = @(
    ".\docs\index.html",
    ".\docs\privacy-policy.html",
    ".\docs\privacy-policy-en.html",
    ".\lib\privacy_policy_text.dart",
    ".\play_console\privacy_policy_public_url_template.txt",
    ".\tools\upgrade\apply_v44_privacy_public_ready.ps1"
)

Write-Host "FILES"
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "OK   $file"
    }

    if (-not (Test-Path $file)) {
        Write-Host "MISS $file"
        $missing += $file
    }
}

$main = Get-Content .\lib\main.dart -Raw
$dartPolicy = Get-Content .\lib\privacy_policy_text.dart -Raw
$privacyHtml = Get-Content .\docs\privacy-policy.html -Raw
$urlTemplate = Get-Content .\play_console\privacy_policy_public_url_template.txt -Raw

Write-Host ""
Write-Host "CONTENT CHECKS"

$checks = @(
    @{ Name = "main import"; Body = $main; Text = "privacy_policy_text.dart" },
    @{ Name = "main page"; Body = $main; Text = "class PrivacyPolicyPage extends StatelessWidget" },
    @{ Name = "main tooltip"; Body = $main; Text = "Quyền riêng tư" },
    @{ Name = "main icon"; Body = $main; Text = "Icons.privacy_tip_outlined" },
    @{ Name = "main text ref"; Body = $main; Text = "privacyPolicyViText" },
    @{ Name = "dart vi policy"; Body = $dartPolicy; Text = "privacyPolicyViText" },
    @{ Name = "dart en policy"; Body = $dartPolicy; Text = "privacyPolicyEnText" },
    @{ Name = "html title"; Body = $privacyHtml; Text = "CHÍNH SÁCH QUYỀN RIÊNG TƯ" },
    @{ Name = "html package"; Body = $privacyHtml; Text = "vn.mlcbst.radarkietsuc" },
    @{ Name = "url template"; Body = $urlTemplate; Text = "privacy-policy.html" }
)

foreach ($check in $checks) {
    if ($check.Body -match [regex]::Escape($check.Text)) {
        Write-Host "OK   $($check.Name)"
    }

    if ($check.Body -notmatch [regex]::Escape($check.Text)) {
        Write-Host "MISS $($check.Name)"
        $missing += $check.Name
    }
}

Write-Host ""
Write-Host "FLUTTER ANALYZE"
flutter analyze

Write-Host ""
Write-Host "AAB CHECK"

$aab = ".\build\app\outputs\bundle\release\app-release.aab"

if (Test-Path $aab) {
    $aabItem = Get-Item $aab
    Write-Host "OK   AAB $($aabItem.Length) bytes"
}

if (-not (Test-Path $aab)) {
    Write-Host "MISS AAB"
    $missing += "AAB"
}

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "BODY BATTERY V4.4 PRIVACY PUBLIC AUDIT PASS"
}

if ($missing.Count -ne 0) {
    Write-Host "BODY BATTERY V4.4 PRIVACY PUBLIC AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
