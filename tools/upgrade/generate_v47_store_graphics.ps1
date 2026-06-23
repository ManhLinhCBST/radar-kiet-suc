Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Set-Location "D:\body_battery"

New-Item -ItemType Directory -Force .\play_assets\icons | Out-Null
New-Item -ItemType Directory -Force .\play_assets\feature_graphic | Out-Null

function New-RadarIcon {
    param(
        [string]$OutPath
    )

    $w = 512
    $h = 512

    $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)

    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h

    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 10, 70, 95),
        [System.Drawing.Color]::FromArgb(255, 25, 150, 135),
        45
    )

    $g.FillRectangle($bg, $rect)

    $centerX = 256
    $centerY = 256

    $penSoft = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 255, 255, 255), 5)
    $penStrong = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210, 255, 255, 255), 8)
    $penPulse = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(230, 255, 210, 95), 10)

    foreach ($r in @(72, 128, 184)) {
        $g.DrawEllipse($penSoft, $centerX - $r, $centerY - $r, $r * 2, $r * 2)
    }

    $g.DrawLine($penStrong, $centerX, $centerY, 392, 130)
    $g.DrawLine($penSoft, 80, $centerY, 432, $centerY)
    $g.DrawLine($penSoft, $centerX, 80, $centerX, 432)

    $points = @(
        (New-Object System.Drawing.Point 112, 292),
        (New-Object System.Drawing.Point 158, 292),
        (New-Object System.Drawing.Point 184, 224),
        (New-Object System.Drawing.Point 222, 356),
        (New-Object System.Drawing.Point 262, 178),
        (New-Object System.Drawing.Point 306, 292),
        (New-Object System.Drawing.Point 400, 292)
    )

    $g.DrawLines($penPulse, $points)

    $dotBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 220, 100))
    $g.FillEllipse($dotBrush, $centerX - 18, $centerY - 18, 36, 36)

    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $g.Dispose()
    $bmp.Dispose()
}

function New-FeatureGraphic {
    param(
        [string]$OutPath
    )

    $w = 1024
    $h = 500

    $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)

    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h

    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(12, 68, 92),
        [System.Drawing.Color]::FromArgb(28, 150, 135),
        20
    )

    $g.FillRectangle($bg, $rect)

    $circlePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(75, 255, 255, 255), 5)

    foreach ($r in @(80, 145, 210, 280)) {
        $g.DrawEllipse($circlePen, 720 - $r, 250 - $r, $r * 2, $r * 2)
    }

    $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 255, 255, 255), 5)
    $g.DrawLine($linePen, 720, 250, 930, 92)

    $pulsePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(240, 255, 215, 95), 8)
    $pulse = @(
        (New-Object System.Drawing.Point 650, 270),
        (New-Object System.Drawing.Point 688, 270),
        (New-Object System.Drawing.Point 708, 220),
        (New-Object System.Drawing.Point 740, 325),
        (New-Object System.Drawing.Point 775, 188),
        (New-Object System.Drawing.Point 815, 270),
        (New-Object System.Drawing.Point 910, 270)
    )
    $g.DrawLines($pulsePen, $pulse)

    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
    $softWhite = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 238, 250, 252))
    $yellow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 215, 95))

    $fontTitle = New-Object System.Drawing.Font("Arial", 58, [System.Drawing.FontStyle]::Bold)
    $fontSub = New-Object System.Drawing.Font("Arial", 27, [System.Drawing.FontStyle]::Regular)
    $fontSmall = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Regular)

    $g.DrawString("Radar Kiệt Sức", $fontTitle, $white, 64, 92)
    $g.DrawString("Theo dõi hao mòn, phục hồi và xu hướng cơ thể", $fontSub, $softWhite, 68, 174)
    $g.DrawString("Wellness self-tracking • không chẩn đoán • không thay thế bác sĩ", $fontSmall, $yellow, 70, 236)

    $cardBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 255, 255, 255))
    $cardPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 255, 255, 255), 2)

    $card1 = New-Object System.Drawing.Rectangle 72, 310, 210, 78
    $card2 = New-Object System.Drawing.Rectangle 304, 310, 210, 78

    $g.FillRectangle($cardBrush, $card1)
    $g.DrawRectangle($cardPen, $card1)
    $g.FillRectangle($cardBrush, $card2)
    $g.DrawRectangle($cardPen, $card2)

    $fontCard = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Bold)

    $g.DrawString("Chỉ số hao mòn", $fontCard, $white, 90, 326)
    $g.DrawString("Xu hướng phục hồi", $fontCard, $white, 322, 326)

    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $g.Dispose()
    $bmp.Dispose()
}

New-RadarIcon -OutPath ".\play_assets\icons\app_icon_512.png"
New-FeatureGraphic -OutPath ".\play_assets\feature_graphic\feature_graphic_1024x500.png"

Write-Host "ASSETS CREATED"

Get-Item .\play_assets\icons\app_icon_512.png |
Select-Object FullName,Length,LastWriteTime |
Format-List

Get-Item .\play_assets\feature_graphic\feature_graphic_1024x500.png |
Select-Object FullName,Length,LastWriteTime |
Format-List
