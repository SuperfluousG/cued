$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$output = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'cued.ico'
$sizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
$images = New-Object System.Collections.Generic.List[byte[]]

function New-RoundedRectanglePath {
    param(
        [float] $X,
        [float] $Y,
        [float] $Width,
        [float] $Height,
        [float] $Radius
    )

    $diameter = $Radius * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

foreach ($size in $sizes) {
    $bitmap = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $stream = New-Object System.IO.MemoryStream

    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        $scale = $size / 256.0
        $background = New-RoundedRectanglePath 2 2 252 252 52
        $matrix = New-Object System.Drawing.Drawing2D.Matrix
        $matrix.Scale($scale, $scale)
        $background.Transform($matrix)
        $backgroundBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 238, 116, 79))
        $graphics.FillPath($backgroundBrush, $background)

        $ghost = New-Object System.Drawing.Drawing2D.GraphicsPath
        $ghost.AddBezier(128 * $scale, 43 * $scale, 82 * $scale, 43 * $scale, 52 * $scale, 79 * $scale, 52 * $scale, 126 * $scale)
        $ghost.AddLine(52 * $scale, 207 * $scale, 78 * $scale, 181 * $scale)
        $ghost.AddLine(78 * $scale, 181 * $scale, 103 * $scale, 207 * $scale)
        $ghost.AddLine(103 * $scale, 207 * $scale, 128 * $scale, 181 * $scale)
        $ghost.AddLine(128 * $scale, 181 * $scale, 153 * $scale, 207 * $scale)
        $ghost.AddLine(153 * $scale, 207 * $scale, 178 * $scale, 181 * $scale)
        $ghost.AddLine(178 * $scale, 181 * $scale, 204 * $scale, 207 * $scale)
        $ghost.AddLine(204 * $scale, 207 * $scale, 204 * $scale, 126 * $scale)
        $ghost.AddBezier(204 * $scale, 126 * $scale, 204 * $scale, 79 * $scale, 174 * $scale, 43 * $scale, 128 * $scale, 43 * $scale)
        $ghost.CloseFigure()
        $ghostBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 30, 30, 30))
        $graphics.FillPath($ghostBrush, $ghost)

        $eyeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 248, 247, 244))
        $graphics.FillEllipse($eyeBrush, 88 * $scale, 103 * $scale, 22 * $scale, 31 * $scale)
        $graphics.FillEllipse($eyeBrush, 146 * $scale, 103 * $scale, 22 * $scale, 31 * $scale)

        $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
        $images.Add($stream.ToArray())
    }
    finally {
        if ($eyeBrush) { $eyeBrush.Dispose() }
        if ($ghostBrush) { $ghostBrush.Dispose() }
        if ($ghost) { $ghost.Dispose() }
        if ($backgroundBrush) { $backgroundBrush.Dispose() }
        if ($matrix) { $matrix.Dispose() }
        if ($background) { $background.Dispose() }
        $stream.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$file = [System.IO.File]::Open($output, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
$writer = New-Object System.IO.BinaryWriter($file)

try {
    $writer.Write([uint16]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]$images.Count)

    $offset = 6 + (16 * $images.Count)
    for ($index = 0; $index -lt $images.Count; $index++) {
        $size = $sizes[$index]
        $dimension = if ($size -eq 256) { 0 } else { $size }
        $writer.Write([byte]$dimension)
        $writer.Write([byte]$dimension)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]32)
        $writer.Write([uint32]$images[$index].Length)
        $writer.Write([uint32]$offset)
        $offset += $images[$index].Length
    }

    foreach ($image in $images) {
        $writer.Write($image)
    }
}
finally {
    $writer.Dispose()
    $file.Dispose()
}

Write-Host "Built $output"
