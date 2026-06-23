$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "BODY BATTERY V4.5 GITHUB PAGES AUDIT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$githubUsername = "ManhLinhCBST"
$repoName = "radar-kiet-suc"

$privacyUrl = "https://$githubUsername.github.io/$repoName/privacy-policy.html"
$privacyUrlEn = "https://$githubUsername.github.io/$repoName/privacy-policy-en.html"
$homeUrl = "https://$githubUsername.github.io/$repoName/"

Write-Host "EXPECTED URL"
Write-Host $homeUrl
Write-Host $privacyUrl
Write-Host $privacyUrlEn
Write-Host ""

$files = @(
    ".\docs\index.html",
    ".\docs\privacy-policy.html",
    ".\docs\privacy-policy-en.html",
    ".\play_console\privacy_policy_url_final.txt"
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

Write-Host ""
Write-Host "GIT REMOTE"

$remote = git remote -v

if ($remote -match "github.com") {
    Write-Host "OK   GitHub remote found"
}

if ($remote -notmatch "github.com") {
    Write-Host "MISS GitHub remote"
    $missing += "github_remote"
}

if ($remote -match "ManhLinhCBST/radar-kiet-suc") {
    Write-Host "OK   correct repo remote"
}

if ($remote -notmatch "ManhLinhCBST/radar-kiet-suc") {
    Write-Host "MISS correct repo remote"
    $missing += "repo_remote"
}

Write-Host ""
Write-Host "URL FILE CHECK"

$urlFile = Get-Content .\play_console\privacy_policy_url_final.txt -Raw

if ($urlFile -match [regex]::Escape($privacyUrl)) {
    Write-Host "OK   privacy URL saved"
}

if ($urlFile -notmatch [regex]::Escape($privacyUrl)) {
    Write-Host "MISS privacy URL saved"
    $missing += "privacy_url_saved"
}

if ($urlFile -match "vn.mlcbst.radarkietsuc") {
    Write-Host "OK   package saved"
}

if ($urlFile -notmatch "vn.mlcbst.radarkietsuc") {
    Write-Host "MISS package saved"
    $missing += "package_saved"
}

Write-Host ""
Write-Host "ONLINE URL CHECK"

try {
    $responseHome = Invoke-WebRequest -Uri $homeUrl -UseBasicParsing -TimeoutSec 20

    if ($responseHome.StatusCode -eq 200) {
        Write-Host "OK   home URL HTTP 200"
    }

    if ($responseHome.StatusCode -ne 200) {
        Write-Host "BAD  home URL status $($responseHome.StatusCode)"
        $missing += "home_url_status"
    }
}
catch {
    Write-Host "BAD  Cannot open home URL"
    Write-Host $_.Exception.Message
    $missing += "home_url_online"
}

try {
    $response = Invoke-WebRequest -Uri $privacyUrl -UseBasicParsing -TimeoutSec 20

    if ($response.StatusCode -eq 200) {
        Write-Host "OK   privacy URL HTTP 200"
    }

    if ($response.StatusCode -ne 200) {
        Write-Host "BAD  privacy URL status $($response.StatusCode)"
        $missing += "privacy_url_status"
    }

    if ($response.Content -match "Radar Kiệt Sức") {
        Write-Host "OK   privacy URL content app name"
    }

    if ($response.Content -notmatch "Radar Kiệt Sức") {
        Write-Host "MISS privacy URL content app name"
        $missing += "privacy_url_content"
    }

    if ($response.Content -match "vn.mlcbst.radarkietsuc") {
        Write-Host "OK   privacy URL content package"
    }

    if ($response.Content -notmatch "vn.mlcbst.radarkietsuc") {
        Write-Host "MISS privacy URL content package"
        $missing += "privacy_url_package"
    }
}
catch {
    Write-Host "BAD  Cannot open privacy URL"
    Write-Host $_.Exception.Message
    $missing += "privacy_url_online"
}

try {
    $responseEn = Invoke-WebRequest -Uri $privacyUrlEn -UseBasicParsing -TimeoutSec 20

    if ($responseEn.StatusCode -eq 200) {
        Write-Host "OK   privacy EN URL HTTP 200"
    }

    if ($responseEn.StatusCode -ne 200) {
        Write-Host "BAD  privacy EN URL status $($responseEn.StatusCode)"
        $missing += "privacy_en_url_status"
    }

    if ($responseEn.Content -match "Privacy Policy") {
        Write-Host "OK   privacy EN content"
    }

    if ($responseEn.Content -notmatch "Privacy Policy") {
        Write-Host "MISS privacy EN content"
        $missing += "privacy_en_content"
    }
}
catch {
    Write-Host "BAD  Cannot open privacy EN URL"
    Write-Host $_.Exception.Message
    $missing += "privacy_en_url_online"
}

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "BODY BATTERY V4.5 GITHUB PAGES AUDIT PASS"
}

if ($missing.Count -ne 0) {
    Write-Host "BODY BATTERY V4.5 GITHUB PAGES AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
