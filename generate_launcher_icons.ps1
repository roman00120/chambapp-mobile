param(
    [Parameter(Mandatory = $true)]
    [string] $SourcePath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$resRoot = Join-Path $PSScriptRoot 'android\app\src\main\res'
$source = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $SourcePath))

function Write-TransparentIcon {
    param(
        [string] $Destination,
        [int] $CanvasSize,
        [double] $ContentScale
    )

    $canvas = New-Object System.Drawing.Bitmap(
        $CanvasSize,
        $CanvasSize,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

        $box = [int][Math]::Floor($CanvasSize * $ContentScale)
        $ratio = [Math]::Min($box / $source.Width, $box / $source.Height)
        $width = [int][Math]::Round($source.Width * $ratio)
        $height = [int][Math]::Round($source.Height * $ratio)
        $x = [int][Math]::Floor(($CanvasSize - $width) / 2)
        $y = [int][Math]::Floor(($CanvasSize - $height) / 2)

        $graphics.DrawImage($source, $x, $y, $width, $height)
        $canvas.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $canvas.Dispose()
    }
}

try {
    $densities = @{
        'mdpi' = 48
        'hdpi' = 72
        'xhdpi' = 96
        'xxhdpi' = 144
        'xxxhdpi' = 192
    }

    foreach ($entry in $densities.GetEnumerator()) {
        $folder = Join-Path $resRoot "mipmap-$($entry.Key)"
        Write-TransparentIcon (Join-Path $folder 'ic_launcher.png') $entry.Value 1.0
        Write-TransparentIcon (Join-Path $folder 'ic_launcher_round.png') $entry.Value 1.0
        Write-TransparentIcon (Join-Path $folder 'ic_launcher_foreground.png') ($entry.Value * 2.25) 0.70
    }
}
finally {
    $source.Dispose()
}
