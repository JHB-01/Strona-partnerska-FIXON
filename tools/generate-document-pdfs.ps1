param(
  [Parameter(Mandatory = $true)]
  [string]$OutputDir,

  [Parameter(Mandatory = $true)]
  [string]$ManifestPath,

  [string]$OnlySlug = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.Drawing

$wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
$PageWidth = 1240
$PageHeight = 1754
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

function Get-NodeText {
  param([Parameter(Mandatory = $true)][System.Xml.XmlNode]$Node)

  $sb = New-Object System.Text.StringBuilder
  function Walk {
    param([System.Xml.XmlNode]$Current)

    if ($Current.LocalName -eq 't') {
      [void]$sb.Append($Current.InnerText)
      return
    }

    if ($Current.LocalName -eq 'tab') {
      [void]$sb.Append("`t")
      return
    }

    if ($Current.LocalName -eq 'br' -or $Current.LocalName -eq 'cr') {
      [void]$sb.Append("`n")
      return
    }

    foreach ($child in $Current.ChildNodes) {
      Walk $child
    }
  }

  Walk $Node
  return ($sb.ToString() -replace "`r", '')
}

function Get-ParagraphStyle {
  param(
    [Parameter(Mandatory = $true)][System.Xml.XmlNode]$Paragraph,
    [Parameter(Mandatory = $true)][System.Xml.XmlNamespaceManager]$Ns
  )

  $styleNode = $Paragraph.SelectSingleNode('./w:pPr/w:pStyle', $Ns)
  if ($null -eq $styleNode) { return '' }
  return $styleNode.GetAttribute('val', $wNs)
}

function New-TextBlock {
  param(
    [string]$Text,
    [string]$Style = ''
  )

  $text = ($Text -replace '\s+', ' ').Trim()
  if ([string]::IsNullOrWhiteSpace($text)) { return $null }

  if ($text -match '^ROZDZIAŁ\s+\d+') {
    return [pscustomobject]@{ Type = 'kicker'; Text = $text; Level = 0; Rows = $null }
  }

  if ($Style -match 'Heading1|Nag.*1|Tyt') {
    return [pscustomobject]@{ Type = 'heading'; Text = $text; Level = 2; Rows = $null }
  }

  if ($Style -match 'Heading2|Nag.*2') {
    return [pscustomobject]@{ Type = 'heading'; Text = $text; Level = 3; Rows = $null }
  }

  if ($text -match '^§\s*\d+') {
    return [pscustomobject]@{ Type = 'heading'; Text = $text; Level = 2; Rows = $null }
  }

  if ($text -match '^\d+\.\d+\.\s+') {
    return [pscustomobject]@{ Type = 'heading'; Text = $text; Level = 3; Rows = $null }
  }

  if ($text -match '^\d+\.\s+' -and $text.Length -lt 160) {
    return [pscustomobject]@{ Type = 'heading'; Text = $text; Level = 3; Rows = $null }
  }

  if ($text.Length -le 120 -and $text -cmatch '^[A-ZĄĆĘŁŃÓŚŹŻ0-9 .,&:;()/-]+$' -and $text -notmatch '^[A-Z]\)$') {
    return [pscustomobject]@{ Type = 'heading'; Text = $text; Level = 2; Rows = $null }
  }

  if ($text -match '^([a-z]\)|[0-9]+\)|•|- )\s*') {
    $item = [regex]::Replace($text, '^([a-z]\)|[0-9]+\)|•|- )\s*', '')
    return [pscustomobject]@{ Type = 'list'; Text = $item; Level = 0; Rows = $null }
  }

  return [pscustomobject]@{ Type = 'paragraph'; Text = $text; Level = 0; Rows = $null }
}

function Split-LongParagraphText {
  param([Parameter(Mandatory = $true)][string]$Text)

  $expanded = $Text
  $expanded = $expanded -replace '(ROZDZIAŁ\s+\d+)', "`n`$1`n"
  $expanded = $expanded -replace '(?<!^)(\d+\.\d+\.\s*)', "`n`$1"
  $expanded = $expanded -replace '(?<!^)(§\s*\d+\.\s*)', "`n`$1"
  return $expanded -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 }
}

function Get-TableBlock {
  param(
    [Parameter(Mandatory = $true)][System.Xml.XmlNode]$Table,
    [Parameter(Mandatory = $true)][System.Xml.XmlNamespaceManager]$Ns
  )

  $rows = @()
  foreach ($row in $Table.SelectNodes('./w:tr', $Ns)) {
    $cells = @()
    foreach ($cell in $row.SelectNodes('./w:tc', $Ns)) {
      $paragraphs = @()
      foreach ($p in $cell.SelectNodes('./w:p', $Ns)) {
        $line = (Get-NodeText -Node $p).Trim()
        if ($line.Length -gt 0) {
          $paragraphs += ($line -replace '\s+', ' ')
        }
      }
      if ($paragraphs.Count -eq 0) { $paragraphs += '' }
      $cells += ($paragraphs -join "`n")
    }
    if ($cells.Count -gt 0) { $rows += ,$cells }
  }

  if ($rows.Count -eq 0) { return $null }
  return [pscustomobject]@{ Type = 'table'; Text = 'Tabela'; Level = 0; Rows = $rows }
}

function Get-DocxBlocks {
  param([Parameter(Mandatory = $true)][string]$Path)

  $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
  $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read, $false)
  try {
    $entry = $zip.GetEntry('word/document.xml')
    $stream = $entry.Open()
    try {
      $reader = New-Object System.IO.StreamReader($stream)
      $xmlText = $reader.ReadToEnd()
      $reader.Dispose()
    } finally {
      $stream.Dispose()
    }
  } finally {
    $zip.Dispose()
    $fs.Dispose()
  }

  $xml = New-Object System.Xml.XmlDocument
  $xml.PreserveWhitespace = $false
  $xml.LoadXml($xmlText)
  $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
  $ns.AddNamespace('w', $wNs)

  $blocks = @()
  $body = $xml.SelectSingleNode('//w:body', $ns)
  foreach ($node in $body.ChildNodes) {
    if ($node.LocalName -eq 'p') {
      $rawText = (Get-NodeText -Node $node).Trim()
      if ($rawText.Length -gt 600 -and ($rawText -match 'ROZDZIAŁ|\d+\.\d+\.|§\s*\d+')) {
        $style = Get-ParagraphStyle -Paragraph $node -Ns $ns
        foreach ($part in (Split-LongParagraphText -Text $rawText)) {
          $block = New-TextBlock -Text $part -Style $style
          if ($null -ne $block) { $blocks += $block }
        }
      } else {
        $style = Get-ParagraphStyle -Paragraph $node -Ns $ns
        $block = New-TextBlock -Text $rawText -Style $style
        if ($null -ne $block) { $blocks += $block }
      }
    } elseif ($node.LocalName -eq 'tbl') {
      $block = Get-TableBlock -Table $node -Ns $ns
      if ($null -ne $block) { $blocks += $block }
    }
  }

  return $blocks
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
      $script:Graphics.DrawString('FIXON | dokument programowy', $headerFont, $greenBrush, [single]$Margin, [single]42)
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
    Ensure-Space -Height (($lines.Count * 36) + 16)
    foreach ($line in $lines) {
      $script:Graphics.DrawString($line, $font, $brush, [single]$Margin, [single]$script:Y)
      $script:Y += 36
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
    $script:Graphics.DrawString('•', $font, $brush, [single]$Margin, [single]$script:Y)
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
  param([Parameter(Mandatory = $true)][array]$Rows)

  if ($Rows.Count -eq 0) { return }
  $colCount = ($Rows | ForEach-Object { $_.Count } | Measure-Object -Maximum).Maximum
  if ($colCount -lt 1) { return }

  $cellWidth = $ContentWidth / $colCount
  $pad = 12
  $headerFont = New-DocFont -Size $(if ($colCount -gt 5) { 15 } else { 17 }) -Style ([System.Drawing.FontStyle]::Bold)
  $bodyFont = New-DocFont -Size $(if ($colCount -gt 5) { 14 } else { 16 })
  $lineHeight = if ($colCount -gt 5) { 21 } else { 24 }
  $pen = New-Object System.Drawing.Pen($ColorLine, 1)
  $softBrush = New-Object System.Drawing.SolidBrush($Soft)
  $altBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(251, 252, 250))
  $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
  $darkBrush = New-Object System.Drawing.SolidBrush($Dark)
  $inkBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 48, 45))

  try {
    Ensure-Space -Height 62
    $script:Y += 12
    for ($rowIndex = 0; $rowIndex -lt $Rows.Count; $rowIndex++) {
      $isHeader = $rowIndex -eq 0
      $font = if ($isHeader) { $headerFont } else { $bodyFont }
      $cellLines = @()
      $rowHeight = 0

      for ($col = 0; $col -lt $colCount; $col++) {
        $cellText = if ($col -lt $Rows[$rowIndex].Count) { [string]$Rows[$rowIndex][$col] } else { '' }
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
        $x = $Margin + ($col * $cellWidth)
        $fillBrush = if ($isHeader) { $softBrush } elseif ($rowIndex % 2 -eq 0) { $altBrush } else { $whiteBrush }
        $textBrush = if ($isHeader) { $darkBrush } else { $inkBrush }
        $script:Graphics.FillRectangle($fillBrush, [single]$x, [single]$script:Y, [single]$cellWidth, [single]$rowHeight)
        $script:Graphics.DrawRectangle($pen, [single]$x, [single]$script:Y, [single]$cellWidth, [single]$rowHeight)
        $textY = $script:Y + $pad
        foreach ($line in $cellLines[$col]) {
          if ($textY -lt ($script:Y + $rowHeight - $lineHeight)) {
            $script:Graphics.DrawString($line, $font, $textBrush, [single]($x + $pad), [single]$textY)
          }
          $textY += $lineHeight
        }
      }
      $script:Y += $rowHeight
    }
    $script:Y += 26
  } finally {
    $headerFont.Dispose()
    $bodyFont.Dispose()
    $pen.Dispose()
    $softBrush.Dispose()
    $altBrush.Dispose()
    $whiteBrush.Dispose()
    $darkBrush.Dispose()
    $inkBrush.Dispose()
  }
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

function Write-PdfFromJpegs {
  param(
    [Parameter(Mandatory = $true)][System.Collections.ArrayList]$Images,
    [Parameter(Mandatory = $true)][string]$Path
  )

  $pageW = '595.28'
  $pageH = '841.89'
  $objects = New-Object System.Collections.ArrayList
  [void]$objects.Add([System.Text.Encoding]::ASCII.GetBytes('<< /Type /Catalog /Pages 2 0 R >>'))

  $kids = @()
  for ($i = 0; $i -lt $Images.Count; $i++) {
    $kids += "$((3 + ($i * 3))) 0 R"
  }
  [void]$objects.Add([System.Text.Encoding]::ASCII.GetBytes("<< /Type /Pages /Kids [$($kids -join ' ')] /Count $($Images.Count) >>"))

  for ($i = 0; $i -lt $Images.Count; $i++) {
    $pageId = 3 + ($i * 3)
    $contentId = $pageId + 1
    $imageId = $pageId + 2
    $imageName = "Im$($i + 1)"
    $content = "q`n$pageW 0 0 $pageH 0 0 cm`n/$imageName Do`nQ`n"
    $contentBytes = [System.Text.Encoding]::ASCII.GetBytes($content)
    $imageBytes = [byte[]]$Images[$i]

    [void]$objects.Add([System.Text.Encoding]::ASCII.GetBytes("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageW $pageH] /Resources << /XObject << /$imageName $imageId 0 R >> >> /Contents $contentId 0 R >>"))
    [void]$objects.Add((Join-Bytes @("<< /Length $($contentBytes.Length) >>`nstream`n", $contentBytes, "`nendstream")))
    [void]$objects.Add((Join-Bytes @("<< /Type /XObject /Subtype /Image /Width $PageWidth /Height $PageHeight /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length $($imageBytes.Length) >>`nstream`n", $imageBytes, "`nendstream")))
  }

  $stream = New-Object System.IO.MemoryStream
  $header = [System.Text.Encoding]::ASCII.GetBytes("%PDF-1.4`n%FIXON`n")
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

function Write-DocumentPdf {
  param([Parameter(Mandatory = $true)]$Doc)

  $script:DocTitle = [string]$Doc.Title
  $script:DocSubtitle = [string]$Doc.Subtitle
  $script:Pages = New-Object System.Collections.ArrayList
  $script:PageNo = 0
  $script:Y = $Margin
  $script:Bitmap = $null
  $script:Graphics = $null

  $blocks = Get-DocxBlocks -Path $Doc.Source
  Start-NewPage
  foreach ($block in $blocks) {
    switch ($block.Type) {
      'heading' { Draw-Heading -Text $block.Text -Level $block.Level }
      'kicker' { Draw-Kicker -Text $block.Text }
      'list' { Draw-ListItem -Text $block.Text }
      'table' { Draw-Table -Rows $block.Rows }
      default { Draw-Paragraph -Text $block.Text }
    }
  }
  Save-CurrentPage

  $pdfPath = Join-Path $OutputDir (($Doc.Slug -replace '\.html$', '.pdf') -replace '^', 'pdf\')
  New-Item -ItemType Directory -Path (Split-Path $pdfPath -Parent) -Force | Out-Null
  Write-PdfFromJpegs -Images $script:Pages -Path $pdfPath

  return [pscustomobject]@{
    Title = $Doc.Title
    Pdf = $pdfPath
    Pages = $script:Pages.Count
    Size = (Get-Item -LiteralPath $pdfPath).Length
  }
}

$docs = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$docItems = if ([string]::IsNullOrWhiteSpace($OnlySlug)) {
  $docs.Documents
} else {
  $docs.Documents | Where-Object { $_.Slug -eq $OnlySlug -or $_.Slug -eq "$OnlySlug.html" }
}

$results = foreach ($doc in $docItems) {
  Write-DocumentPdf -Doc $doc
}

$results
