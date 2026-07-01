param(
  [Parameter(Mandatory = $true)]
  [string]$DataPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputDir
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$PageWidth = 1240
$PageHeight = 1754
$PdfPageWidth = 595.28
$PdfPageHeight = 841.89
$Margin = 90
$Bottom = 110
$ContentWidth = $PageWidth - (2 * $Margin)
$Green = [System.Drawing.Color]::FromArgb(18, 74, 46)
$Dark = [System.Drawing.Color]::FromArgb(6, 39, 27)
$Ink = [System.Drawing.Color]::FromArgb(21, 26, 24)
$Muted = [System.Drawing.Color]::FromArgb(99, 112, 106)
$ColorLine = [System.Drawing.Color]::FromArgb(217, 224, 219)
$Soft = [System.Drawing.Color]::FromArgb(232, 240, 235)
$Paper = [System.Drawing.Color]::White
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

function Get-FontFamilyName {
  $families = [System.Drawing.FontFamily]::Families | ForEach-Object { $_.Name }
  if ($families -contains 'Gotham') { return 'Gotham' }
  return 'Arial'
}

$FontFamilyName = Get-FontFamilyName

function New-DocFont {
  param(
    [Parameter(Mandatory = $true)][single]$Size,
    [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
  )

  return New-Object System.Drawing.Font($FontFamilyName, $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
}

function ConvertTo-WrappedLines {
  param(
    [string]$Text,
    [Parameter(Mandatory = $true)][System.Drawing.Font]$Font,
    [Parameter(Mandatory = $true)][single]$MaxWidth
  )

  $clean = ($Text -replace '\s+', ' ').Trim()
  if ([string]::IsNullOrWhiteSpace($clean)) { return @() }

  $lines = @()
  $current = ''
  foreach ($word in ($clean -split ' ')) {
    $candidate = if ($current.Length -gt 0) { "$current $word" } else { $word }
    if ($script:Graphics.MeasureString($candidate, $Font).Width -le $MaxWidth) {
      $current = $candidate
      continue
    }

    if ($current.Length -gt 0) {
      $lines += $current
      $current = ''
    }

    if ($script:Graphics.MeasureString($word, $Font).Width -le $MaxWidth) {
      $current = $word
      continue
    }

    $chunk = ''
    foreach ($char in $word.ToCharArray()) {
      $candidateChunk = "$chunk$char"
      if ($script:Graphics.MeasureString($candidateChunk, $Font).Width -le $MaxWidth) {
        $chunk = $candidateChunk
      } else {
        if ($chunk.Length -gt 0) { $lines += $chunk }
        $chunk = [string]$char
      }
    }
    $current = $chunk
  }

  if ($current.Length -gt 0) { $lines += $current }
  return $lines
}

function Test-PlaceholderText {
  param([string]$Text)

  if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
  return ($Text -match '\.{4,}|_{4,}')
}

function Add-FormField {
  param(
    [Parameter(Mandatory = $true)][single]$X,
    [Parameter(Mandatory = $true)][single]$Y,
    [Parameter(Mandatory = $true)][single]$W,
    [Parameter(Mandatory = $true)][single]$H,
    [switch]$Multiline
  )

  if ($W -lt 28 -or $H -lt 16) { return }
  $script:FieldNo += 1
  [void]$script:Fields.Add([pscustomobject]@{
    Page = $script:PageNo
    Name = "$($script:DocSlug)_field_$('{0:000}' -f $script:FieldNo)"
    X = [single]$X
    Y = [single]$Y
    W = [single]$W
    H = [single]$H
    Multiline = [bool]$Multiline
  })
}

function Save-CurrentPage {
  if ($null -eq $script:Bitmap) { return }

  $footerFont = New-DocFont -Size 18 -Style ([System.Drawing.FontStyle]::Bold)
  $smallFont = New-DocFont -Size 16
  $greenBrush = New-Object System.Drawing.SolidBrush($Green)
  $mutedBrush = New-Object System.Drawing.SolidBrush($Muted)
  $linePen = New-Object System.Drawing.Pen($ColorLine, 1)

  try {
    $script:Graphics.DrawLine($linePen, $Margin, $PageHeight - 76, $PageWidth - $Margin, $PageHeight - 76)
    $script:Graphics.DrawString('FIXON Tools & Tech', $footerFont, $greenBrush, [single]$Margin, [single]($PageHeight - 58))
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Far
    $script:Graphics.DrawString("strona $($script:PageNo)", $smallFont, $mutedBrush, (New-Object System.Drawing.RectangleF([single]$Margin, [single]($PageHeight - 58), [single]$ContentWidth, [single]30)), $format)
    $format.Dispose()

    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
    $quality = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $quality.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]76)
    $stream = New-Object System.IO.MemoryStream
    $script:Bitmap.Save($stream, $codec, $quality)
    [void]$script:Pages.Add($stream.ToArray())
    $stream.Dispose()
    $quality.Dispose()
  } finally {
    $footerFont.Dispose()
    $smallFont.Dispose()
    $greenBrush.Dispose()
    $mutedBrush.Dispose()
    $linePen.Dispose()
    $script:Graphics.Dispose()
    $script:Bitmap.Dispose()
    $script:Graphics = $null
    $script:Bitmap = $null
  }
}

function Start-NewPage {
  if ($script:PageNo -gt 0) { Save-CurrentPage }

  $script:PageNo += 1
  $script:Bitmap = New-Object System.Drawing.Bitmap($PageWidth, $PageHeight)
  $script:Bitmap.SetResolution(150, 150)
  $script:Graphics = [System.Drawing.Graphics]::FromImage($script:Bitmap)
  $script:Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $script:Graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
  $script:Graphics.Clear($Paper)

  if ($script:PageNo -eq 1) {
    $rect = New-Object System.Drawing.Rectangle(0, 0, $PageWidth, 365)
    $heroBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $Dark, $Green, 0)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $softWhiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210, 255, 255, 255))
    $kickerFont = New-DocFont -Size 18 -Style ([System.Drawing.FontStyle]::Bold)
    $titleFont = New-DocFont -Size 54 -Style ([System.Drawing.FontStyle]::Bold)
    $subtitleFont = New-DocFont -Size 24
    try {
      $script:Graphics.FillRectangle($heroBrush, $rect)
      $script:Graphics.DrawString('FIXON TOOLS & TECH', $kickerFont, $softWhiteBrush, [single]$Margin, [single]96)
      Draw-WrappedText -Text $script:DocTitle.ToUpperInvariant() -Font $titleFont -Brush $whiteBrush -X $Margin -MaxWidth $ContentWidth -LineHeight 60 -MaxLines 3 -StartY 158 | Out-Null
      if (-not [string]::IsNullOrWhiteSpace($script:DocSubtitle)) {
        Draw-WrappedText -Text $script:DocSubtitle -Font $subtitleFont -Brush $softWhiteBrush -X $Margin -MaxWidth $ContentWidth -LineHeight 34 -MaxLines 2 -StartY 292 | Out-Null
      }
    } finally {
      $heroBrush.Dispose()
      $whiteBrush.Dispose()
      $softWhiteBrush.Dispose()
      $kickerFont.Dispose()
      $titleFont.Dispose()
      $subtitleFont.Dispose()
    }
    $script:Y = 440
  } else {
    $headerFont = New-DocFont -Size 17 -Style ([System.Drawing.FontStyle]::Bold)
    $greenBrush = New-Object System.Drawing.SolidBrush($Green)
    try {
      $script:Graphics.DrawString('FIXON | formularz dokumentu', $headerFont, $greenBrush, [single]$Margin, [single]42)
    } finally {
      $headerFont.Dispose()
      $greenBrush.Dispose()
    }
    $script:Y = $Margin
  }
}

function Ensure-Space {
  param([Parameter(Mandatory = $true)][single]$Height)

  if (($script:Y + $Height) -gt ($PageHeight - $Bottom)) {
    Start-NewPage
  }
}

function Draw-WrappedText {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [Parameter(Mandatory = $true)][System.Drawing.Font]$Font,
    [Parameter(Mandatory = $true)][System.Drawing.Brush]$Brush,
    [Parameter(Mandatory = $true)][single]$X,
    [Parameter(Mandatory = $true)][single]$MaxWidth,
    [Parameter(Mandatory = $true)][single]$LineHeight,
    [int]$MaxLines = 0,
    [single]$StartY = -1
  )

  $lines = ConvertTo-WrappedLines -Text $Text -Font $Font -MaxWidth $MaxWidth
  if ($MaxLines -gt 0 -and $lines.Count -gt $MaxLines) {
    $lines = $lines | Select-Object -First $MaxLines
  }

  $drawY = if ($StartY -ge 0) { $StartY } else { $script:Y }
  foreach ($line in $lines) {
    $script:Graphics.DrawString($line, $Font, $Brush, $X, $drawY)
    $drawY += $LineHeight
  }

  return ($lines.Count * $LineHeight)
}

function Draw-Paragraph {
  param([Parameter(Mandatory = $true)][string]$Text)

  $font = New-DocFont -Size 23
  $brush = New-Object System.Drawing.SolidBrush($Ink)
  try {
    $lines = ConvertTo-WrappedLines -Text $Text -Font $font -MaxWidth $ContentWidth
    if ($lines.Count -eq 0) { return }
    $height = ($lines.Count * 36) + 16
    Ensure-Space -Height $height
    $startY = $script:Y
    foreach ($line in $lines) {
      $script:Graphics.DrawString($line, $font, $brush, [single]$Margin, [single]$script:Y)
      $script:Y += 36
    }
    if (Test-PlaceholderText -Text $Text) {
      Add-FormField -X ($Margin + 6) -Y ($startY + 2) -W ($ContentWidth - 12) -H ([Math]::Max(30, ($lines.Count * 34))) -Multiline:($lines.Count -gt 1)
    }
    $script:Y += 16
  } finally {
    $font.Dispose()
    $brush.Dispose()
  }
}

function Draw-ListItem {
  param([Parameter(Mandatory = $true)][string]$Text)

  $font = New-DocFont -Size 23
  $brush = New-Object System.Drawing.SolidBrush($Ink)
  try {
    $indent = 34
    $lines = ConvertTo-WrappedLines -Text $Text -Font $font -MaxWidth ($ContentWidth - $indent)
    if ($lines.Count -eq 0) { return }
    Ensure-Space -Height (($lines.Count * 34) + 10)
    $script:Graphics.DrawString('-', $font, $brush, [single]$Margin, [single]$script:Y)
    foreach ($line in $lines) {
      $script:Graphics.DrawString($line, $font, $brush, [single]($Margin + $indent), [single]$script:Y)
      $script:Y += 34
    }
    $script:Y += 10
  } finally {
    $font.Dispose()
    $brush.Dispose()
  }
}

function Draw-Heading {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [int]$Level = 2
  )

  $size = if ($Level -eq 2) { 34 } else { 28 }
  $lineHeight = if ($Level -eq 2) { 42 } else { 36 }
  $font = New-DocFont -Size $size -Style ([System.Drawing.FontStyle]::Bold)
  $brush = New-Object System.Drawing.SolidBrush($(if ($Level -eq 2) { $Green } else { $Dark }))
  try {
    $lines = ConvertTo-WrappedLines -Text $Text.ToUpperInvariant() -Font $font -MaxWidth $ContentWidth
    if ($lines.Count -eq 0) { return }
    Ensure-Space -Height (($lines.Count * $lineHeight) + 44)
    $script:Y += if ($Level -eq 2) { 26 } else { 16 }
    foreach ($line in $lines) {
      $script:Graphics.DrawString($line, $font, $brush, [single]$Margin, [single]$script:Y)
      $script:Y += $lineHeight
    }
    $script:Y += 14
  } finally {
    $font.Dispose()
    $brush.Dispose()
  }
}

function Draw-Kicker {
  param([Parameter(Mandatory = $true)][string]$Text)

  $font = New-DocFont -Size 17 -Style ([System.Drawing.FontStyle]::Bold)
  $greenBrush = New-Object System.Drawing.SolidBrush($Green)
  $softBrush = New-Object System.Drawing.SolidBrush($Soft)
  try {
    Ensure-Space -Height 48
    $label = $Text.ToUpperInvariant()
    $width = [Math]::Min($ContentWidth, $script:Graphics.MeasureString($label, $font).Width + 26)
    $script:Graphics.FillRectangle($softBrush, [single]$Margin, [single]($script:Y - 18), [single]$width, [single]34)
    $script:Graphics.DrawString($label, $font, $greenBrush, [single]($Margin + 13), [single]($script:Y - 11))
    $script:Y += 36
  } finally {
    $font.Dispose()
    $greenBrush.Dispose()
    $softBrush.Dispose()
  }
}

function Draw-Table {
  param([Parameter(Mandatory = $true)]$Rows)

  $rowsArray = @($Rows)
  if ($rowsArray.Count -eq 0) { return }
  $colCount = 1
  foreach ($rowItem in $rowsArray) {
    $rowArray = @($rowItem)
    $colCount = [Math]::Max($colCount, $rowArray.Count)
  }

  $cellWidth = $ContentWidth / $colCount
  $pad = 12
  $headerFont = New-DocFont -Size $(if ($colCount -gt 5) { 15 } else { 17 }) -Style ([System.Drawing.FontStyle]::Bold)
  $bodyFont = New-DocFont -Size $(if ($colCount -gt 5) { 14 } else { 16 })
  $lineHeight = if ($colCount -gt 5) { 21 } else { 24 }
  $pen = New-Object System.Drawing.Pen($ColorLine, 1)
  $fieldPen = New-Object System.Drawing.Pen($Green, 2)
  $fieldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(252, 255, 252))
  $softBrush = New-Object System.Drawing.SolidBrush($Soft)
  $altBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(251, 252, 250))
  $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
  $darkBrush = New-Object System.Drawing.SolidBrush($Dark)
  $inkBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 48, 45))

  try {
    Ensure-Space -Height 62
    $script:Y += 12
    for ($rowIndex = 0; $rowIndex -lt $rowsArray.Count; $rowIndex++) {
      $isHeader = $rowIndex -eq 0
      $font = if ($isHeader) { $headerFont } else { $bodyFont }
      $rowArray = @($rowsArray[$rowIndex])
      $cellLines = @()
      $rowHeight = 0

      for ($col = 0; $col -lt $colCount; $col++) {
        $cellText = if ($col -lt $rowArray.Count) { [string]$rowArray[$col] } else { '' }
        $lines = ConvertTo-WrappedLines -Text $cellText -Font $font -MaxWidth ($cellWidth - (2 * $pad))
        if ($lines.Count -eq 0) { $lines = @('') }
        $cellLines += ,$lines
        $rowHeight = [Math]::Max($rowHeight, ($lines.Count * $lineHeight) + (2 * $pad))
      }

      $rowHeight = [Math]::Max($rowHeight, 46)
      if ($rowHeight -gt ($PageHeight - $Bottom - $Margin)) {
        $rowHeight = $PageHeight - $Bottom - $Margin
      }
      Ensure-Space -Height ($rowHeight + 8)

      for ($col = 0; $col -lt $colCount; $col++) {
        $cellText = if ($col -lt $rowArray.Count) { [string]$rowArray[$col] } else { '' }
        $isField = Test-PlaceholderText -Text $cellText
        $x = $Margin + ($col * $cellWidth)
        $fillBrush = if ($isField) { $fieldBrush } elseif ($isHeader) { $softBrush } elseif ($rowIndex % 2 -eq 0) { $altBrush } else { $whiteBrush }
        $textBrush = if ($isHeader) { $darkBrush } else { $inkBrush }
        $script:Graphics.FillRectangle($fillBrush, [single]$x, [single]$script:Y, [single]$cellWidth, [single]$rowHeight)
        $script:Graphics.DrawRectangle($(if ($isField) { $fieldPen } else { $pen }), [single]$x, [single]$script:Y, [single]$cellWidth, [single]$rowHeight)
        if (-not $isField) {
          $textY = $script:Y + $pad
          foreach ($line in $cellLines[$col]) {
            if ($textY -lt ($script:Y + $rowHeight - $lineHeight)) {
              $script:Graphics.DrawString($line, $font, $textBrush, [single]($x + $pad), [single]$textY)
            }
            $textY += $lineHeight
          }
        } else {
          Add-FormField -X ($x + 5) -Y ($script:Y + 5) -W ($cellWidth - 10) -H ($rowHeight - 10) -Multiline:($rowHeight -gt 72)
        }
      }
      $script:Y += $rowHeight
    }
    $script:Y += 26
  } finally {
    $headerFont.Dispose()
    $bodyFont.Dispose()
    $pen.Dispose()
    $fieldPen.Dispose()
    $fieldBrush.Dispose()
    $softBrush.Dispose()
    $altBrush.Dispose()
    $whiteBrush.Dispose()
    $darkBrush.Dispose()
    $inkBrush.Dispose()
  }
}

function Draw-FallbackFormSection {
  Draw-Heading -Text 'POTWIERDZENIE DOKUMENTU' -Level 2
  $rows = @(
    @('Partner / podmiot', '........................................'),
    @('Data potwierdzenia', '........................................'),
    @('Osoba potwierdzajaca', '........................................'),
    @('Uwagi', '................................................................................................................................'),
    @('Podpis / akceptacja', '........................................')
  )
  Draw-Table -Rows $rows
}

function Join-Bytes {
  param([Parameter(Mandatory = $true)][object[]]$Parts)

  $stream = New-Object System.IO.MemoryStream
  foreach ($part in $Parts) {
    $bytes = if ($part -is [byte[]]) { $part } else { [System.Text.Encoding]::ASCII.GetBytes([string]$part) }
    $stream.Write($bytes, 0, $bytes.Length)
  }
  $result = $stream.ToArray()
  $stream.Dispose()
  return $result
}

function Format-PdfNumber {
  param([Parameter(Mandatory = $true)][double]$Number)
  return $Number.ToString('0.##', $InvariantCulture)
}

function Escape-PdfString {
  param([string]$Text)
  if ($null -eq $Text) { return '' }
  return (($Text -replace '\\', '\\') -replace '\(', '\(') -replace '\)', '\)'
}

function Convert-FieldRect {
  param([Parameter(Mandatory = $true)]$Field)

  $x1 = ([double]$Field.X) * $PdfPageWidth / $PageWidth
  $x2 = ([double]($Field.X + $Field.W)) * $PdfPageWidth / $PageWidth
  $y1 = $PdfPageHeight - (([double]($Field.Y + $Field.H)) * $PdfPageHeight / $PageHeight)
  $y2 = $PdfPageHeight - (([double]$Field.Y) * $PdfPageHeight / $PageHeight)
  return "$(Format-PdfNumber $x1) $(Format-PdfNumber $y1) $(Format-PdfNumber $x2) $(Format-PdfNumber $y2)"
}

function Write-PdfFromJpegsWithForms {
  param(
    [Parameter(Mandatory = $true)][System.Collections.ArrayList]$Images,
    [Parameter(Mandatory = $true)][System.Collections.ArrayList]$Fields,
    [Parameter(Mandatory = $true)][string]$Path
  )

  $pageW = '595.28'
  $pageH = '841.89'
  $pageCount = $Images.Count
  $pageStartId = 4
  $fieldStartId = $pageStartId + ($pageCount * 3)

  for ($i = 0; $i -lt $Fields.Count; $i++) {
    $Fields[$i] | Add-Member -NotePropertyName ObjectId -NotePropertyValue ($fieldStartId + $i) -Force
  }

  $fieldRefs = @()
  foreach ($field in $Fields) { $fieldRefs += "$($field.ObjectId) 0 R" }

  $objects = New-Object System.Collections.ArrayList
  $acro = if ($fieldRefs.Count -gt 0) {
    " /AcroForm << /Fields [$($fieldRefs -join ' ')] /NeedAppearances true /DR << /Font << /Helv 3 0 R >> >> /DA (/Helv 9 Tf 0 0 0 rg) >>"
  } else {
    ''
  }
  [void]$objects.Add([System.Text.Encoding]::ASCII.GetBytes("<< /Type /Catalog /Pages 2 0 R$acro >>"))

  $kids = @()
  for ($i = 0; $i -lt $pageCount; $i++) {
    $kids += "$($pageStartId + ($i * 3)) 0 R"
  }
  [void]$objects.Add([System.Text.Encoding]::ASCII.GetBytes("<< /Type /Pages /Kids [$($kids -join ' ')] /Count $pageCount >>"))
  [void]$objects.Add([System.Text.Encoding]::ASCII.GetBytes('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'))

  for ($i = 0; $i -lt $pageCount; $i++) {
    $pageId = $pageStartId + ($i * 3)
    $contentId = $pageId + 1
    $imageId = $pageId + 2
    $imageName = "Im$($i + 1)"
    $content = "q`n$pageW 0 0 $pageH 0 0 cm`n/$imageName Do`nQ`n"
    $contentBytes = [System.Text.Encoding]::ASCII.GetBytes($content)
    $imageBytes = [byte[]]$Images[$i]
    $annots = @()
    foreach ($field in $Fields) {
      if ([int]$field.Page -eq ($i + 1)) { $annots += "$($field.ObjectId) 0 R" }
    }
    $annotsPart = if ($annots.Count -gt 0) { " /Annots [$($annots -join ' ')]" } else { '' }

    [void]$objects.Add([System.Text.Encoding]::ASCII.GetBytes("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageW $pageH] /Resources << /Font << /Helv 3 0 R >> /XObject << /$imageName $imageId 0 R >> >> /Contents $contentId 0 R$annotsPart >>"))
    [void]$objects.Add((Join-Bytes @("<< /Length $($contentBytes.Length) >>`nstream`n", $contentBytes, "`nendstream")))
    [void]$objects.Add((Join-Bytes @("<< /Type /XObject /Subtype /Image /Width $PageWidth /Height $PageHeight /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length $($imageBytes.Length) >>`nstream`n", $imageBytes, "`nendstream")))
  }

  foreach ($field in $Fields) {
    $rect = Convert-FieldRect -Field $field
    $name = Escape-PdfString -Text ([string]$field.Name)
    $flags = if ($field.Multiline) { 4096 } else { 0 }
    $pageId = $pageStartId + (([int]$field.Page - 1) * 3)
    $obj = "<< /Type /Annot /Subtype /Widget /FT /Tx /T ($name) /Rect [$rect] /F 4 /P $pageId 0 R /MK << /BC [0.07 0.29 0.18] /BG [1 1 1] >> /BS << /W 0.8 /S /S >> /DA (/Helv 9 Tf 0.08 0.08 0.08 rg) /Q 0 /Ff $flags >>"
    [void]$objects.Add([System.Text.Encoding]::ASCII.GetBytes($obj))
  }

  $stream = New-Object System.IO.MemoryStream
  $header = [System.Text.Encoding]::ASCII.GetBytes("%PDF-1.4`n%FIXON_FORM`n")
  $stream.Write($header, 0, $header.Length)
  $offsets = New-Object System.Collections.ArrayList
  [void]$offsets.Add(0)

  for ($i = 0; $i -lt $objects.Count; $i++) {
    [void]$offsets.Add($stream.Position)
    $prefix = [System.Text.Encoding]::ASCII.GetBytes("$($i + 1) 0 obj`n")
    $suffix = [System.Text.Encoding]::ASCII.GetBytes("`nendobj`n")
    $obj = [byte[]]$objects[$i]
    $stream.Write($prefix, 0, $prefix.Length)
    $stream.Write($obj, 0, $obj.Length)
    $stream.Write($suffix, 0, $suffix.Length)
  }

  $xrefStart = $stream.Position
  $xref = "xref`n0 $($objects.Count + 1)`n0000000000 65535 f `n"
  for ($i = 1; $i -lt $offsets.Count; $i++) {
    $xref += ('{0:0000000000} 00000 n ' -f [int64]$offsets[$i]) + "`n"
  }
  $xref += "trailer`n<< /Size $($objects.Count + 1) /Root 1 0 R >>`nstartxref`n$xrefStart`n%%EOF"
  $xrefBytes = [System.Text.Encoding]::ASCII.GetBytes($xref)
  $stream.Write($xrefBytes, 0, $xrefBytes.Length)

  [System.IO.File]::WriteAllBytes($Path, $stream.ToArray())
  $stream.Dispose()
}

function Write-DocumentFormPdf {
  param([Parameter(Mandatory = $true)]$Doc)

  $script:DocTitle = [string]$Doc.title
  $script:DocSubtitle = [string]$Doc.subtitle
  $script:DocSlug = [string]$Doc.slug
  $script:Pages = New-Object System.Collections.ArrayList
  $script:Fields = New-Object System.Collections.ArrayList
  $script:FieldNo = 0
  $script:PageNo = 0
  $script:Y = $Margin
  $script:Bitmap = $null
  $script:Graphics = $null

  Start-NewPage
  foreach ($block in @($Doc.blocks)) {
    switch ([string]$block.type) {
      'heading' { Draw-Heading -Text ([string]$block.text) -Level ([int]$block.level) }
      'kicker' { Draw-Kicker -Text ([string]$block.text) }
      'list' { Draw-ListItem -Text ([string]$block.text) }
      'table' { Draw-Table -Rows $block.rows }
      default { Draw-Paragraph -Text ([string]$block.text) }
    }
  }

  if ($script:Fields.Count -eq 0) {
    Draw-FallbackFormSection
  }

  Save-CurrentPage

  $pdfPath = Join-Path $OutputDir "$($Doc.slug).pdf"
  New-Item -ItemType Directory -Path (Split-Path $pdfPath -Parent) -Force | Out-Null
  Write-PdfFromJpegsWithForms -Images $script:Pages -Fields $script:Fields -Path $pdfPath

  return [pscustomobject]@{
    title = $Doc.title
    slug = $Doc.slug
    pdf = $pdfPath
    pages = $script:Pages.Count
    fields = $script:Fields.Count
    size = (Get-Item -LiteralPath $pdfPath).Length
  }
}

$data = Get-Content -LiteralPath $DataPath -Raw -Encoding UTF8 | ConvertFrom-Json
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$results = foreach ($doc in @($data.documents)) {
  Write-DocumentFormPdf -Doc $doc
}

$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputDir 'pdf-formularze-manifest.json') -Encoding UTF8
$results
