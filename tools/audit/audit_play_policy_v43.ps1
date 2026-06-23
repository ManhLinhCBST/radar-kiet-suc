$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "BODY BATTERY V4.3 PLAY POLICY AUDIT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$files = @(
    ".\play_console\privacy_policy_vi.txt",
    ".\play_console\data_safety_draft_vi.txt",
    ".\play_console\health_declaration_draft_vi.txt",
    ".\play_console\store_listing_draft_vi.txt"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "OK   $file"
    }

    if (-not (Test-Path $file)) {
        Write-Host "MISS $file"
        $missing += $file
    }
}

$privacy = Get-Content .\play_console\privacy_policy_vi.txt -Raw
$data = Get-Content .\play_console\data_safety_draft_vi.txt -Raw
$health = Get-Content .\play_console\health_declaration_draft_vi.txt -Raw
$listing = Get-Content .\play_console\store_listing_draft_vi.txt -Raw

$checks = @(
    @{ Name = "privacy app name"; Body = $privacy; Text = "Radar Kiệt Sức" },
    @{ Name = "privacy no diagnosis"; Body = $privacy; Text = "không đưa ra chẩn đoán y khoa" },
    @{ Name = "privacy local storage"; Body = $privacy; Text = "lưu cục bộ trên thiết bị" },
    @{ Name = "privacy contact email"; Body = $privacy; Text = "tuequangedu@gmail.com" },
    @{ Name = "data package"; Body = $data; Text = "vn.mlcbst.radarkietsuc" },
    @{ Name = "data no server"; Body = $data; Text = "không gửi dữ liệu lên máy chủ" },
    @{ Name = "data no sharing"; Body = $data; Text = "không tự động chia sẻ" },
    @{ Name = "health wellness"; Body = $health; Text = "Wellness" },
    @{ Name = "health no treatment"; Body = $health; Text = "Không" },
    @{ Name = "listing short"; Body = $listing; Text = "Theo dõi hao mòn" },
    @{ Name = "listing safety"; Body = $listing; Text = "không thay thế bác sĩ" }
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
