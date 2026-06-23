$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "BODY BATTERY V4.3 PLAY POLICY AUDIT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$files = @(
    ".\play_console\privacy_policy_vi.txt",
    ".\play_console\privacy_policy_en.txt",
    ".\play_console\data_safety_draft_vi.txt",
    ".\play_console\health_declaration_draft_vi.txt",
    ".\play_console\store_listing_draft_vi.txt",
    ".\play_console\play_console_checklist_vi.txt"
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

$privacyVi = Get-Content .\play_console\privacy_policy_vi.txt -Raw
$privacyEn = Get-Content .\play_console\privacy_policy_en.txt -Raw
$data = Get-Content .\play_console\data_safety_draft_vi.txt -Raw
$health = Get-Content .\play_console\health_declaration_draft_vi.txt -Raw
$listing = Get-Content .\play_console\store_listing_draft_vi.txt -Raw
$checklist = Get-Content .\play_console\play_console_checklist_vi.txt -Raw

Write-Host ""
Write-Host "CONTENT CHECKS"

$checks = @(
    @{ Name = "privacy vi app name"; Body = $privacyVi; Text = "Radar Kiệt Sức" },
    @{ Name = "privacy vi package"; Body = $privacyVi; Text = "vn.mlcbst.radarkietsuc" },
    @{ Name = "privacy vi no diagnosis"; Body = $privacyVi; Text = "không đưa ra chẩn đoán y khoa" },
    @{ Name = "privacy vi local storage"; Body = $privacyVi; Text = "lưu cục bộ trên thiết bị" },
    @{ Name = "privacy vi contact email"; Body = $privacyVi; Text = "tuequangedu@gmail.com" },
    @{ Name = "privacy en app name"; Body = $privacyEn; Text = "Radar Kiệt Sức" },
    @{ Name = "privacy en no medical device"; Body = $privacyEn; Text = "not a medical device" },
    @{ Name = "data package"; Body = $data; Text = "vn.mlcbst.radarkietsuc" },
    @{ Name = "data no server"; Body = $data; Text = "không gửi dữ liệu lên máy chủ" },
    @{ Name = "data no sharing"; Body = $data; Text = "không tự động chia sẻ" },
    @{ Name = "data health self assessment"; Body = $data; Text = "health self-assessment" },
    @{ Name = "health wellness"; Body = $health; Text = "Wellness" },
    @{ Name = "health no diagnosis"; Body = $health; Text = "Không" },
    @{ Name = "health no health connect"; Body = $health; Text = "Health Connect" },
    @{ Name = "listing short"; Body = $listing; Text = "Theo dõi hao mòn" },
    @{ Name = "listing safety"; Body = $listing; Text = "không thay thế bác sĩ" },
    @{ Name = "checklist package"; Body = $checklist; Text = "vn.mlcbst.radarkietsuc" },
    @{ Name = "checklist internal testing"; Body = $checklist; Text = "Internal testing" }
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
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "BODY BATTERY V4.3 PLAY POLICY AUDIT PASS"
}

if ($missing.Count -ne 0) {
    Write-Host "BODY BATTERY V4.3 PLAY POLICY AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
