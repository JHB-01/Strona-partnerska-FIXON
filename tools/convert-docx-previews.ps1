param(
  [Parameter(Mandatory = $true)]
  [string]$OutputDir,

  [Parameter(Mandatory = $true)]
  [string]$ManifestPath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

$wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
$script:slugCounts = @{}

function Get-Slug {
  param([Parameter(Mandatory = $true)][string]$Text)

  $normalized = $Text.ToLowerInvariant()
  $normalized = $normalized -replace 'ą','a' -replace 'ć','c' -replace 'ę','e' -replace 'ł','l' -replace 'ń','n' -replace 'ó','o' -replace 'ś','s' -replace 'ź','z' -replace 'ż','z'
  $normalized = $normalized -replace '[^a-z0-9]+','-'
  $normalized = $normalized.Trim('-')
  if ([string]::IsNullOrWhiteSpace($normalized)) { $normalized = 'sekcja' }

  if ($script:slugCounts.ContainsKey($normalized)) {
    $script:slugCounts[$normalized] += 1
    return "$normalized-$($script:slugCounts[$normalized])"
  }

  $script:slugCounts[$normalized] = 1
  return $normalized
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

function Get-ParagraphBlock {
  param(
    [Parameter(Mandatory = $true)][System.Xml.XmlNode]$Paragraph,
    [Parameter(Mandatory = $true)][System.Xml.XmlNamespaceManager]$Ns
  )

  $text = (Get-NodeText -Node $Paragraph).Trim()
  if ([string]::IsNullOrWhiteSpace($text)) { return $null }

  $style = Get-ParagraphStyle -Paragraph $Paragraph -Ns $Ns
  return Get-TextBlock -Text $text -Style $style
}

function Get-TextBlock {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [string]$Style = ''
  )

  $text = $Text -replace '\s+', ' '
  $safe = [System.Net.WebUtility]::HtmlEncode($text)

  if ($text -match '^ROZDZIAŁ\s+\d+') {
    return [pscustomobject]@{ Type = 'kicker'; Plain = $text; Html = "<div class=""chapter-kicker"">$safe</div>"; Level = 0; Id = $null }
  }

  $level = 0
  if ($style -match 'Heading1|Nag.*1|Tyt') {
    $level = 2
  } elseif ($style -match 'Heading2|Nag.*2') {
    $level = 3
  } elseif ($text -match '^§\s*\d+') {
    $level = 2
  } elseif ($text -match '^\d+\.\d+\.\s+') {
    $level = 3
  } elseif ($text -match '^\d+\.\s+' -and $text.Length -lt 160) {
    $level = 3
  } elseif ($text.Length -le 120 -and $text -cmatch '^[A-ZĄĆĘŁŃÓŚŹŻ0-9 .,&:;()/-]+$' -and $text -notmatch '^[A-Z]\)$') {
    $level = 2
  }

  if ($level -gt 0) {
    $id = Get-Slug -Text $text
    return [pscustomobject]@{ Type = 'heading'; Plain = $text; Html = "<h$level id=""$id"">$safe</h$level>"; Level = $level; Id = $id }
  }

  if ($text -match '^([a-z]\)|[0-9]+\)|•|- )\s*') {
    $item = [regex]::Replace($safe, '^([a-z]\)|[0-9]+\)|•|- )\s*', '')
    return [pscustomobject]@{ Type = 'list-item'; Plain = $text; Html = "<li>$item</li>"; Level = 0; Id = $null }
  }

  return [pscustomobject]@{ Type = 'paragraph'; Plain = $text; Html = "<p>$safe</p>"; Level = 0; Id = $null }
}

function Split-LongParagraphText {
  param([Parameter(Mandatory = $true)][string]$Text)

  $expanded = $Text
  $expanded = $expanded -replace '(ROZDZIAŁ\s+\d+)', "`n`$1`n"
  $expanded = $expanded -replace '(?<!^)(\d+\.\d+\.\s*)', "`n`$1"
  $expanded = $expanded -replace '(?<!^)(§\s*\d+\.\s*)', "`n`$1"
  $lines = $expanded -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 }
  return $lines
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
          $paragraphs += [System.Net.WebUtility]::HtmlEncode(($line -replace '\s+', ' '))
        }
      }
      if ($paragraphs.Count -eq 0) { $paragraphs += '&nbsp;' }
      $cells += ($paragraphs -join '<br>')
    }
    if ($cells.Count -gt 0) { $rows += ,$cells }
  }

  if ($rows.Count -eq 0) { return $null }

  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('<div class="table-scroll"><table>')
  for ($i = 0; $i -lt $rows.Count; $i++) {
    $tag = if ($i -eq 0) { 'th' } else { 'td' }
    [void]$sb.AppendLine('<tr>')
    foreach ($cell in $rows[$i]) {
      [void]$sb.AppendLine("<$tag>$cell</$tag>")
    }
    [void]$sb.AppendLine('</tr>')
  }
  [void]$sb.AppendLine('</table></div>')

  return [pscustomobject]@{ Type = 'table'; Plain = 'Tabela'; Html = $sb.ToString(); Level = 0; Id = $null }
}

function Get-DocxBlocks {
  param([Parameter(Mandatory = $true)][string]$Path)

  $script:slugCounts = @{}
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

  $body = $xml.SelectSingleNode('//w:body', $ns)
  $blocks = @()
  foreach ($node in $body.ChildNodes) {
    if ($node.LocalName -eq 'p') {
      $rawText = (Get-NodeText -Node $node).Trim()
      if ($rawText.Length -gt 600 -and ($rawText -match 'ROZDZIAŁ|\d+\.\d+\.|§\s*\d+')) {
        $style = Get-ParagraphStyle -Paragraph $node -Ns $ns
        foreach ($part in (Split-LongParagraphText -Text $rawText)) {
          $block = Get-TextBlock -Text $part -Style $style
          if ($null -ne $block) { $blocks += $block }
        }
      } else {
        $block = Get-ParagraphBlock -Paragraph $node -Ns $ns
        if ($null -ne $block) { $blocks += $block }
      }
    } elseif ($node.LocalName -eq 'tbl') {
      $block = Get-TableBlock -Table $node -Ns $ns
      if ($null -ne $block) { $blocks += $block }
    }
  }

  return $blocks
}

function Convert-BlocksToHtml {
  param(
    [Parameter(Mandatory = $true)][array]$Blocks,
    [Parameter(Mandatory = $true)][string]$DocxHref,
    [Parameter(Mandatory = $true)][string]$PdfHref
  )

  $toc = @()
  $sb = New-Object System.Text.StringBuilder
  $sectionOpen = $false
  $listOpen = $false

  function Close-List {
    if ($script:listOpenForDoc) {
      [void]$script:sbForDoc.AppendLine('</ul>')
      $script:listOpenForDoc = $false
    }
  }

  function Close-Section {
    if ($script:sectionOpenForDoc) {
      Close-List
      [void]$script:sbForDoc.AppendLine('</div></details>')
      $script:sectionOpenForDoc = $false
    }
  }

  $script:sbForDoc = $sb
  $script:sectionOpenForDoc = $false
  $script:listOpenForDoc = $false

  foreach ($block in $Blocks) {
    if ($block.Type -eq 'heading' -and $block.Level -eq 2) {
      Close-Section
      $toc += [pscustomobject]@{ Id = $block.Id; Text = $block.Plain }
      [void]$sb.AppendLine("<details class=""doc-section"" id=""section-$($block.Id)"" open>")
      [void]$sb.AppendLine("<summary><span>$([System.Net.WebUtility]::HtmlEncode($block.Plain))</span></summary>")
      [void]$sb.AppendLine('<div class="doc-section-body">')
      $script:sectionOpenForDoc = $true
      continue
    }

    if (-not $script:sectionOpenForDoc) {
      [void]$sb.AppendLine('<details class="doc-section intro-section" open>')
      [void]$sb.AppendLine('<summary><span>Wprowadzenie</span></summary>')
      [void]$sb.AppendLine('<div class="doc-section-body">')
      $script:sectionOpenForDoc = $true
    }

    if ($block.Type -eq 'list-item') {
      if (-not $script:listOpenForDoc) {
        [void]$sb.AppendLine('<ul>')
        $script:listOpenForDoc = $true
      }
      [void]$sb.AppendLine($block.Html)
    } else {
      Close-List
      [void]$sb.AppendLine($block.Html)
    }
  }

  Close-Section

  $tocHtml = if ($toc.Count -gt 0) {
    (($toc | ForEach-Object { "<a href=""#section-$($_.Id)"">$([System.Net.WebUtility]::HtmlEncode($_.Text))</a>" }) -join "`n")
  } else {
    '<span>Ten dokument nie ma wyodrębnionych sekcji.</span>'
  }

  $downloads = @"
<div class="download-panel">
  <div>
    <strong>Pobierz dokument</strong>
    <p>Szablon DOCX służy do pracy operacyjnej, a PDF do wysyłki lub archiwizacji.</p>
  </div>
  <div class="download-actions">
    <a class="download-button" href="$DocxHref" download>Pobierz szablon DOCX</a>
    <a class="download-button secondary" href="$PdfHref" download>Pobierz szablon PDF</a>
  </div>
</div>
"@

  return [pscustomobject]@{
    Toc = $tocHtml
    Body = $sb.ToString()
    Downloads = $downloads
  }
}

function Copy-Template {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$BaseName,
    [Parameter(Mandatory = $true)][string]$OutputDir
  )

  $docxDir = Join-Path $OutputDir 'docx'
  New-Item -ItemType Directory -Path $docxDir -Force | Out-Null
  $targetName = "$BaseName.docx"
  $targetPath = Join-Path $docxDir $targetName
  Copy-Item -LiteralPath $Source -Destination $targetPath -Force
  return "docx/$targetName"
}

function Write-DocPage {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Doc,
    [Parameter(Mandatory = $true)][string]$OutputDir
  )

  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Doc.Slug)
  $docxHref = Copy-Template -Source $Doc.Source -BaseName $baseName -OutputDir $OutputDir
  $pdfHref = "pdf/$baseName.pdf"
  $blocks = Get-DocxBlocks -Path $Doc.Source
  $converted = Convert-BlocksToHtml -Blocks $blocks -DocxHref $docxHref -PdfHref $pdfHref
  $date = (Get-Item -LiteralPath $Doc.Source).LastWriteTime.ToString('dd.MM.yyyy HH:mm')
  $safeTitle = [System.Net.WebUtility]::HtmlEncode($Doc.Title)
  $safeSubtitle = [System.Net.WebUtility]::HtmlEncode($Doc.Subtitle)
  $safeGroup = [System.Net.WebUtility]::HtmlEncode($Doc.Group)
  $target = Join-Path $OutputDir $Doc.Slug

  $html = @"
<!doctype html>
<html lang="pl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$safeTitle | FIXON</title>
  <style>
    @font-face { font-family: Gotham; src: url("../assets/fonts/Gotham-Book.woff2") format("woff2"), local("Gotham Book"), local("Gotham"); font-weight: 400; font-display: swap; }
    @font-face { font-family: Gotham; src: url("../assets/fonts/Gotham-Bold.woff2") format("woff2"), local("Gotham Bold"), local("Gotham Pro Bold"); font-weight: 700; font-display: swap; }
    @font-face { font-family: Gotham; src: url("../assets/fonts/Gotham-Black.woff2") format("woff2"), local("Gotham Black"), local("Gotham Pro Black"); font-weight: 900; font-display: swap; }
    :root { --green:#124A2E; --dark:#06271b; --ink:#151a18; --muted:#63706a; --line:#d9e0db; --bg:#f2f4ef; --soft:#e8f0eb; --paper:#fff; }
    * { box-sizing: border-box; }
    html { scroll-behavior: smooth; }
    body { margin:0; background:var(--bg); color:var(--ink); font-family:Gotham, "Montserrat", "Avenir Next", Arial, sans-serif; letter-spacing:0; }
    header { position:sticky; top:0; z-index:10; border-bottom:1px solid var(--line); background:rgba(255,255,255,.94); backdrop-filter:blur(12px); }
    .bar { width:min(1180px, calc(100% - 28px)); margin:0 auto; min-height:68px; display:flex; align-items:center; justify-content:space-between; gap:16px; }
    a { color:inherit; }
    .back { display:inline-flex; align-items:center; min-height:40px; padding:10px 13px; border-radius:4px; background:var(--green); color:#fff; font-weight:700; text-decoration:none; }
    .meta { color:var(--muted); font-size:13px; line-height:1.35; text-align:right; }
    .nav-toggle, .nav-close, .nav-backdrop { display:none; }
    .nav-toggle { align-items:center; min-height:40px; padding:10px 13px; border:1px solid var(--green); border-radius:4px; background:#fff; color:var(--green); font-weight:900; cursor:pointer; }
    .nav-close { width:38px; height:38px; margin:0 0 12px auto; place-items:center; border:1px solid var(--line); border-radius:999px; background:#fff; color:var(--green); font-size:24px; line-height:1; cursor:pointer; }
    main { width:min(1180px, calc(100% - 28px)); margin:0 auto; padding:44px 0 70px; }
    .hero { padding:34px; border-radius:8px; background:linear-gradient(135deg, var(--dark), var(--green)); color:#fff; }
    .kicker { display:inline-flex; margin-bottom:14px; padding:6px 9px; border:1px solid rgba(255,255,255,.22); border-radius:4px; color:rgba(255,255,255,.82); font-size:12px; font-weight:800; text-transform:uppercase; }
    h1 { max-width:880px; margin:0 0 12px; font-size:clamp(34px, 6vw, 64px); line-height:.98; text-transform:uppercase; letter-spacing:0; }
    .hero p { max-width:760px; margin:0; color:rgba(255,255,255,.78); font-size:18px; line-height:1.5; }
    .doc-shell { display:grid; grid-template-columns:280px minmax(0, 1fr); gap:22px; margin-top:22px; align-items:start; }
    .doc-nav { position:sticky; top:88px; max-height:calc(100vh - 110px); overflow:auto; padding:18px; border:1px solid var(--line); border-radius:8px; background:#fff; box-shadow:0 16px 42px rgba(15,22,18,.06); }
    .doc-nav strong { display:block; margin-bottom:12px; color:var(--dark); text-transform:uppercase; }
    .doc-nav a { display:block; padding:9px 0; border-top:1px solid var(--line); color:var(--muted); font-size:14px; line-height:1.35; text-decoration:none; }
    .doc-nav a:hover { color:var(--green); }
    .doc-tools { display:flex; flex-wrap:wrap; gap:8px; margin-top:16px; }
    .doc-tools button { min-height:36px; padding:8px 10px; border:1px solid var(--green); border-radius:4px; background:var(--green); color:#fff; font-weight:700; cursor:pointer; }
    .doc-tools button.secondary { background:#fff; color:var(--green); }
    .doc { min-width:0; }
    .doc-section { margin-bottom:14px; border:1px solid var(--line); border-radius:8px; background:#fff; box-shadow:0 12px 32px rgba(15,22,18,.045); overflow:hidden; }
    .doc-section summary { padding:18px 22px; color:var(--green); font-size:22px; line-height:1.18; font-weight:900; text-transform:uppercase; cursor:pointer; list-style:none; }
    .doc-section summary::-webkit-details-marker { display:none; }
    .doc-section summary::after { content:"+"; float:right; color:var(--muted); font-size:22px; }
    .doc-section[open] summary::after { content:"-"; }
    .doc-section-body { padding:0 22px 24px; border-top:1px solid var(--line); }
    .chapter-kicker { display:inline-flex; margin:18px 0 8px; padding:6px 9px; border-radius:4px; background:var(--soft); color:var(--green); font-size:12px; font-weight:900; text-transform:uppercase; }
    .doc h3 { margin:24px 0 10px; color:var(--dark); font-size:18px; line-height:1.22; letter-spacing:0; }
    .doc p, .doc li { color:#28302d; font-size:15.5px; line-height:1.68; }
    .doc p { margin:0 0 13px; }
    .doc ul { margin:0 0 18px; padding-left:23px; }
    .table-scroll { width:100%; overflow:auto; margin:18px 0 24px; border:1px solid var(--line); border-radius:7px; }
    table { width:100%; border-collapse:collapse; min-width:620px; background:#fff; }
    th, td { padding:11px 12px; border:1px solid var(--line); text-align:left; vertical-align:top; font-size:14px; line-height:1.45; }
    th { background:var(--soft); color:var(--dark); font-weight:900; }
    tr:nth-child(even) td { background:#fbfcfa; }
    .download-panel { display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:16px; margin-top:22px; padding:22px; border-radius:8px; background:var(--dark); color:#fff; }
    .download-panel strong { display:block; margin-bottom:6px; font-size:22px; text-transform:uppercase; }
    .download-panel p { margin:0; color:rgba(255,255,255,.74); }
    .download-actions { display:flex; flex-wrap:wrap; gap:10px; }
    .download-button { display:inline-flex; align-items:center; justify-content:center; min-height:42px; padding:11px 14px; border-radius:4px; border:1px solid #fff; background:#fff; color:var(--dark); font-weight:900; text-decoration:none; }
    .download-button.secondary { background:transparent; color:#fff; }
    footer { width:min(1180px, calc(100% - 28px)); margin:0 auto; padding:0 0 34px; color:var(--muted); font-size:13px; }
    @media (max-width: 900px) {
      body.nav-open { overflow:hidden; }
      .bar { flex-wrap:wrap; }
      .nav-toggle { display:inline-flex; }
      .nav-close { display:grid; }
      .nav-backdrop { position:fixed; inset:0; z-index:30; background:rgba(6,39,27,.42); opacity:0; pointer-events:none; transition:opacity .2s ease; }
      body.nav-open .nav-backdrop { display:block; opacity:1; pointer-events:auto; }
      .doc-shell { grid-template-columns:1fr; }
      .doc-nav { position:fixed; top:0; left:0; z-index:40; width:min(340px, 86vw); height:100vh; max-height:none; padding:18px; border-radius:0 8px 8px 0; transform:translateX(-104%); transition:transform .22s ease; }
      body.nav-open .doc-nav { transform:translateX(0); }
    }
    @media (max-width: 720px) { .bar { align-items:flex-start; flex-direction:column; padding:12px 0; } .meta { text-align:left; } .hero { padding:22px; } .doc-section summary { padding:16px; font-size:18px; } .doc-section-body { padding:0 16px 18px; } .download-panel { align-items:flex-start; flex-direction:column; } .download-actions, .download-button { width:100%; } }
    body.pdf-export { background:#fff; }
    body.pdf-export header, body.pdf-export .doc-nav, body.pdf-export .nav-toggle, body.pdf-export .nav-backdrop, body.pdf-export .download-panel, body.pdf-export footer { display:none !important; }
    body.pdf-export main { width:100%; padding:0; }
    body.pdf-export .hero { border-radius:0; margin:0 0 16px; padding:22px; }
    body.pdf-export .doc-shell { display:block; margin:0; }
    body.pdf-export .doc { width:100%; }
    body.pdf-export .doc-section { box-shadow:none; border:0; border-radius:0; margin:0 0 14px; }
    body.pdf-export .doc-section summary { display:block; padding:12px 0; border-bottom:1px solid var(--line); list-style:none; }
    body.pdf-export .doc-section summary::after { display:none; }
    body.pdf-export .doc-section-body { padding:0; border-top:0; }
    body.pdf-export .table-scroll { overflow:visible; }
    body.pdf-export table { min-width:0; }
    @media print {
      body { background:#fff; }
      header, .doc-nav, .nav-toggle, .nav-backdrop, .download-panel, footer { display:none !important; }
      main { width:100%; padding:0; }
      .hero { border-radius:0; margin:0 0 16px; padding:22px; print-color-adjust:exact; -webkit-print-color-adjust:exact; }
      .doc-shell { display:block; margin:0; }
      .doc-section { break-inside:auto; box-shadow:none; border:0; margin:0 0 14px; }
      .doc-section summary { display:block; padding:12px 0; border-bottom:1px solid var(--line); list-style:none; }
      .doc-section summary::after { display:none; }
      .doc-section-body { padding:0; border-top:0; }
      .table-scroll { overflow:visible; break-inside:auto; }
      table { min-width:0; page-break-inside:auto; }
      tr { page-break-inside:avoid; page-break-after:auto; }
    }
  </style>
</head>
<body>
  <header>
    <div class="bar">
      <a class="back" href="../FIXON_program_partnerski.html#dokumenty">Wr&oacute;&cacute; do dokument&oacute;w</a>
      <button class="nav-toggle" type="button" data-doc-action="toggle-nav" aria-controls="docNav" aria-expanded="false">Spis treści</button>
      <div class="meta">$safeGroup<br>Aktualizacja pliku: $date</div>
    </div>
  </header>
  <div class="nav-backdrop" data-doc-action="close-nav"></div>
  <main>
    <section class="hero">
      <span class="kicker">FIXON Tools &amp; Tech</span>
      <h1>$safeTitle</h1>
      <p>$safeSubtitle</p>
    </section>
    <div class="doc-shell">
      <aside class="doc-nav" id="docNav">
        <button class="nav-close" type="button" data-doc-action="close-nav" aria-label="Zamknij">×</button>
        <strong>Nawigacja dokumentu</strong>
        $($converted.Toc)
        <div class="doc-tools">
          <button type="button" data-doc-action="expand">Rozwiń wszystko</button>
          <button class="secondary" type="button" data-doc-action="collapse">Zwiń wszystko</button>
        </div>
      </aside>
      <article class="doc">
$($converted.Body)
$($converted.Downloads)
      </article>
    </div>
  </main>
  <footer>Podgl&#261;d statyczny dokumentu programowego FIXON.</footer>
  <script>
    if (new URLSearchParams(location.search).get('pdf') === '1') {
      document.body.classList.add('pdf-export');
      document.querySelectorAll('.doc-section').forEach(section => section.open = true);
    }
    document.querySelector('[data-doc-action="expand"]')?.addEventListener('click', () => {
      document.querySelectorAll('.doc-section').forEach(section => section.open = true);
    });
    document.querySelector('[data-doc-action="collapse"]')?.addEventListener('click', () => {
      document.querySelectorAll('.doc-section').forEach(section => section.open = false);
    });
    document.querySelectorAll('.doc-nav a').forEach(link => {
      link.addEventListener('click', () => {
        const target = document.querySelector(link.getAttribute('href'));
        if (target && target.tagName === 'DETAILS') target.open = true;
        setNav(false);
      });
    });
    const navToggle = document.querySelector('[data-doc-action="toggle-nav"]');
    const setNav = (isOpen) => {
      document.body.classList.toggle('nav-open', isOpen);
      navToggle?.setAttribute('aria-expanded', String(isOpen));
    };
    navToggle?.addEventListener('click', () => setNav(!document.body.classList.contains('nav-open')));
    document.querySelectorAll('[data-doc-action="close-nav"]').forEach(button => {
      button.addEventListener('click', () => setNav(false));
    });
    document.addEventListener('keydown', event => {
      if (event.key === 'Escape') setNav(false);
    });
  </script>
</body>
</html>
"@

  Set-Content -LiteralPath $target -Value $html -Encoding UTF8

  return [pscustomobject]@{
    Title = $Doc.Title
    Group = $Doc.Group
    Slug = "dokumenty/$($Doc.Slug)"
    Source = $Doc.Source
    Characters = (($blocks | ForEach-Object { $_.Plain }) -join "`n").Length
    Docx = "dokumenty/$docxHref"
    Pdf = "dokumenty/$pdfHref"
  }
}

$docs = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'pdf') -Force | Out-Null
$manifest = foreach ($doc in $docs.Documents) {
  Write-DocPage -Doc @{
    Title = $doc.Title
    Subtitle = $doc.Subtitle
    Source = $doc.Source
    Slug = $doc.Slug
    Group = $doc.Group
  } -OutputDir $OutputDir
}

$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $OutputDir 'manifest.json') -Encoding UTF8
$manifest
