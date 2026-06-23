$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

Set-Location "D:\body_battery"

Write-Host "========================================"
Write-Host "RADAR KIET SUC V4.7 STORE ASSETS AUDIT"
Write-Host "========================================"
Write-Host ""

$missing = @()

$icon = ".\play_assets\icons\app_icon_512.png"
$feature = ".\play_assets\feature_graphic\feature_graphic_1024x500.png"
$listing = ".\play_assets\store_listing\store_listing_vi.txt"
$screenshotDir = ".\play_assets\screenshots\phone"

Write-Host "FILES"

foreach ($file in @($icon, $feature, $listing)) {
    if (Test-Path $file) {
        Write-Host "OK   $file"
    }

    if (-not (Test-Path $file)) {
        Write-Host "MISS $file"
        $missing += $file
    }
}

Write-Host ""
Write-Host "IMAGE DIMENSIONS"

if (Test-Path $icon) {
    $img = [System.Drawing.Image]::FromFile((Resolve-Path $icon))
    if ($img.Width -eq 512 -and $img.Height -eq 512) {
        Write-Host "OK   icon 512x512"
    }
    if ($img.Width -ne 512 -or $img.Height -ne 512) {
        Write-Host "MISS icon dimension $($img.Width)x$($img.Height)"
        $missing += "icon dimension"
    }
    $img.Dispose()

    $iconSize = (Get-Item $icon).Length
    if ($iconSize -le 1048576) {
        Write-Host "OK   icon <= 1024KB"
    }
    if ($iconSize -gt 1048576) {
        Write-Host "MISS icon too large"
        $missing += "icon size"
    }
}

if (Test-Path $feature) {
    $img = [System.Drawing.Image]::FromFile((Resolve-Path $feature))
    if ($img.Width -eq 1024 -and $img.Height -eq 500) {
        Write-Host "OK   feature 1024x500"
    }
    if ($img.Width -ne 1024 -or $img.Height -ne 500) {
        Write-Host "MISS feature dimension $($img.Width)x$($img.Height)"
        $missing += "feature dimension"
    }
    $img.Dispose()
}

Write-Host ""
Write-Host "STORE LISTING TEXT"

if (Test-Path $listing) {
    $text = Get-Content $listing -Raw -Encoding UTF8

    if ($text.Contains("Radar Kiệt Sức")) {
        Write-Host "OK   app name"
    }

    if (-not $text.Contains("Radar Kiệt Sức")) {
        Write-Host "MISS app name"
        $missing += "app name"
    }

    if ($text.Contains("SHORT DESCRIPTION")) {
        Write-Host "OK   short description section"
    }

    if (-not $text.Contains("SHORT DESCRIPTION")) {
        Write-Host "MISS short description section"
        $missing += "short description section"
    }

    if ($text.Contains("FULL DESCRIPTION")) {
        Write-Host "OK   full description section"
    }

    if (-not $text.Contains("FULL DESCRIPTION")) {
        Write-Host "MISS full description section"
        $missing += "full description section"
    }

    if ($text.Contains("không chẩn đoán") -and $text.Contains("không điều trị") -and $text.Contains("không thay thế bác sĩ")) {
        Write-Host "OK   safety disclaimer"
    }

    if (-not ($text.Contains("không chẩn đoán") -and $text.Contains("không điều trị") -and $text.Contains("không thay thế bác sĩ"))) {
        Write-Host "MISS safety disclaimer"
        $missing += "safety disclaimer"
    }

    $short = "Theo dõi hao mòn, phục hồi và xu hướng sức khỏe hằng ngày"
    if ($short.Length -le 80) {
        Write-Host "OK   short description <= 80 chars ($($short.Length))"
    }

    if ($short.Length -gt 80) {
        Write-Host "MISS short description too long ($($short.Length))"
        $missing += "short description length"
    }

    if ($text.Length -le 4000) {
        Write-Host "OK   listing text <= 4000 chars ($($text.Length))"
    }

    if ($text.Length -gt 4000) {
        Write-Host "MISS listing text too long ($($text.Length))"
        $missing += "listing length"
    }
}

Write-Host ""
Write-Host "SCREENSHOTS"

if (Test-Path $screenshotDir) {
    $screens = Get-ChildItem $screenshotDir -Filter "*.png" -File

    if ($screens.Count -ge 2) {
        Write-Host "OK   at least 2 screenshots ($($screens.Count))"
    }

    if ($screens.Count -lt 2) {
        Write-Host "MISS at least 2 screenshots ($($screens.Count))"
        $missing += "screenshots count"
    }

    foreach ($screen in $screens) {
        $img = [System.Drawing.Image]::FromFile($screen.FullName)
        $min = [Math]::Min($img.Width, $img.Height)
        $max = [Math]::Max($img.Width, $img.Height)

        if ($min -ge 320 -and $max -le 3840 -and $max -le ($min * 2)) {
            Write-Host "OK   $($screen.Name) $($img.Width)x$($img.Height)"
        }

        if (-not ($min -ge 320 -and $max -le 3840 -and $max -le ($min * 2))) {
            Write-Host "MISS $($screen.Name) $($img.Width)x$($img.Height)"
            $missing += "screenshot dimension:$($screen.Name)"
        }

        $img.Dispose()
    }
}

if (-not (Test-Path $screenshotDir)) {
    Write-Host "MISS screenshot dir"
    $missing += "screenshot dir"
}

Write-Host ""
Write-Host "RESULT"

if ($missing.Count -eq 0) {
    Write-Host "RADAR KIET SUC V4.7 STORE ASSETS AUDIT PASS"
}

if ($missing.Count -ne 0) {
    Write-Host "RADAR KIET SUC V4.7 STORE ASSETS AUDIT FAIL"
    $missing | ForEach-Object { Write-Host " - $_" }
    exit 1
}
