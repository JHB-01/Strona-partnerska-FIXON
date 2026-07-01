$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$indexPath = Join-Path $root "index.html"
if (-not (Test-Path $indexPath)) {
  $indexPath = Join-Path $root "FIXON_e-katalog.html"
}
if (-not (Test-Path $indexPath)) {
  $indexPath = Join-Path $root "index.html.html"
}
$outDir = Join-Path $root "okladki_marketplace"
$imageDir = Join-Path $outDir "zdjecia_produktow"
$renderDir = Join-Path $outDir "_render"

New-Item -ItemType Directory -Path $outDir, $imageDir, $renderDir -Force | Out-Null

function Slugify([string]$text) {
  $s = $text.ToLowerInvariant()
  $map = @{
    "ą" = "a"; "ć" = "c"; "ę" = "e"; "ł" = "l"; "ń" = "n"; "ó" = "o"; "ś" = "s"; "ż" = "z"; "ź" = "z"
  }
  foreach ($k in $map.Keys) { $s = $s.Replace($k, $map[$k]) }
  $s = [regex]::Replace($s, "[^a-z0-9]+", "-").Trim("-")
  if ($s.Length -eq 0) { return "produkt" }
  return $s
}

function PolishText([string]$text) {
  if ([string]::IsNullOrWhiteSpace($text)) { return "" }
  $s = $text
  $replacements = [ordered]@{
    "narzedzi" = "narzędzi"; "narzedzie" = "narzędzie"; "narzedzia" = "narzędzia"; "narzedziem" = "narzędziem"
    "kraweznikow" = "krawężników"; "krawezniki" = "krawężniki"; "kraweznikach" = "krawężnikach"; "kraweznik" = "krawężnik"
    "obrzeza" = "obrzeża"; "obrzezy" = "obrzeży"; "plyt" = "płyt"; "plyty" = "płyty"; "plytowa" = "płytowa"
    "podloza" = "podłoża"; "podloze" = "podłoże"; "podbudowy" = "podbudowy"; "sciezka" = "ścieżka"
    "zageszczanie" = "zagęszczanie"; "zageszczarka" = "zagęszczarka"; "zageszczania" = "zagęszczania"
    "uzycia" = "użycia"; "uzytkowania" = "użytkowania"; "czestszego" = "częstszego"; "ciezszy" = "cięższy"
    "ciezkich" = "ciężkich"; "wiekszych" = "większych"; "mniejszych" = "mniejszych"; "szybszego" = "szybszego"
    "podwojnym" = "podwójnym"; "podwojne" = "podwójne"; "rolka" = "rolką"; "rolkami" = "rolkami"
    "poziomicy" = "poziomicy"; "reczna" = "ręczna"; "lata" = "łata"; "laty" = "łaty"
    "precyzyjnego" = "precyzyjnego"; "katow" = "kątów"; "dlugosci" = "długości"; "okregow" = "okręgów"
    "wozek" = "wózek"; "transportu" = "transportu"; "uchwyt poszerzajacy" = "uchwyt poszerzający"
    "stal nierdzewna" = "stal nierdzewna"; "rozszerzony" = "rozszerzony"; "mozliwosci" = "możliwości"
  }
  foreach ($k in $replacements.Keys) {
    $s = [regex]::Replace($s, [regex]::Escape($k), $replacements[$k], "IgnoreCase")
  }
  return $s
}

function ParseArray([string]$raw) {
  $items = @()
  foreach ($m in [regex]::Matches($raw, '"([^"]+)"')) { $items += $m.Groups[1].Value }
  return $items
}

function JobLabel([string]$job) {
  switch ($job) {
    "ukladanie" { "Układanie" }
    "profilowanie" { "Profilowanie" }
    "krawezniki" { "Krawężniki" }
    "podnoszenie" { "Podnoszenie" }
    "transport" { "Transport" }
    "zageszczanie" { "Zagęszczanie" }
    "specjalistyczne" { "Prace specjalistyczne" }
    default { PolishText $job }
  }
}

function PriorityFeature([string]$priority) {
  switch ($priority) {
    "szybkosc" { @{ title = "SZYBSZA PRACA"; body = "Realna oszczędność czasu na budowie."; icon = "fast" } }
    "precyzja" { @{ title = "WIĘKSZA PRECYZJA"; body = "Lepsza kontrola ustawienia i prowadzenia."; icon = "target" } }
    "uniwersalnosc" { @{ title = "SZERSZE ZASTOSOWANIE"; body = "Jedno narzędzie do wielu zadań."; icon = "multi" } }
    "wysilek" { @{ title = "MNIEJ WYSIŁKU"; body = "Wygodniejsza praca przy ciężkich elementach."; icon = "lift" } }
    "bezpieczenstwo" { @{ title = "PEWNIEJSZA PRACA"; body = "Stabilniejsze prowadzenie i chwyt."; icon = "shield" } }
    "cena" { @{ title = "DOBRY WYBÓR"; body = "Praktyczna funkcja w rozsądnym budżecie."; icon = "value" } }
    default { @{ title = "PROFESJONALNE UŻYCIE"; body = "Narzędzie do codziennej pracy ekip."; icon = "tool" } }
  }
}

function DisplayTitle([string]$name) {
  $map = @{
    "FlatFix z rolka" = "FLATFIX Z ROLKĄ"
    "FlatFix z plastikowa podkladka" = "FLATFIX Z PLASTIKOWĄ PODKŁADKĄ"
    "FlatFix PLUS z plastikowa podstawa" = "FLATFIX PLUS Z PLASTIKOWĄ PODSTAWĄ"
    "FlatFix PLUS z rolka" = "FLATFIX PLUS Z ROLKĄ"
    "Adapter do podnoszenia - system GRIX" = "ADAPTER DO PODNOSZENIA"
    "Zageszczarka plytowa gruntu 120 kg 32 kN LONCIN" = "ZAGĘSZCZARKA PŁYTOWA"
    "ODBOJNIK GUMOWY 60x30x22mm" = "ODBOJNIK GUMOWY"
    "Odbojnik do GRIX PLUS" = "ODBOJNIK DO GRIX PLUS"
  }
  if ($map.ContainsKey($name)) { return $map[$name] }
  return (PolishText $name).ToUpperInvariant()
}

$preferredOrder = @(
  "Zestaw KRAWĘŻNIK PRO",
  "Zestaw LEVEL",
  "Zestaw MASTER",
  "Zestaw KRAWĘŻNIKI",
  "GRIX HOLD PRO",
  "GRIX HOLD",
  "GRIX",
  "GRIX PLUS",
  "GRIX HARD",
  "Adapter do podnoszenia - system GRIX",
  "FlatFix DUO",
  "FlatFix z rolka",
  "FlatFix z plastikowa podkladka",
  "FlatFix Standard",
  "FlatFix PLUS Standard",
  "FlatFix PLUS z plastikowa podstawa",
  "FlatFix PLUS z rolka",
  "LineFix",
  "KatFix",
  "KatFix PRO",
  "LevelFix",
  "FormFix DUAL",
  "FormFix MAX",
  "FormFix 1250-2200 mm",
  "FormFixMini",
  "KrawFix INOX",
  "KrawFix ROLLER",
  "KrawFix",
  "WallFix",
  "RolLift",
  "LiftX",
  "HandLift",
  "GRIPTOR",
  "GRIPTOR PRO",
  "BLOCKLIFT 300",
  "BLOCKLIFT 500",
  "HARDTAP MINI",
  "HARDTAP 5 kg",
  "HARDTAP 10 kg",
  "HARDTAP 15 kg",
  "HARDTAP 20 kg",
  "Zageszczarka plytowa gruntu 120 kg 32 kN LONCIN",
  "CyrkielFix",
  "BRUKFILL",
  "MONOX 6.0",
  "MONOX 8.0",
  "UrbanRoot STEEL",
  "UrbanRoot INOX",
  "UrbanRoot CUSTOM",
  "ODBOJNIK GUMOWY 60x30x22mm",
  "Odbojnik do GRIX PLUS"
)

$content = Get-Content -Raw -Encoding UTF8 $indexPath
$imageMap = @{}
foreach ($m in [regex]::Matches($content, '"([^"]+)"\s*:\s*"(https://[^"]+\.(?:webp|png|jpe?g)[^"]*)"')) {
  $imageMap[$m.Groups[1].Value] = $m.Groups[2].Value
}

$productsByName = @{}
$productPattern = 'product\("([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*\[([^\]]*)\],\s*\[([^\]]*)\],\s*\[([^\]]*)\]\)'
foreach ($m in [regex]::Matches($content, $productPattern)) {
  $name = $m.Groups[1].Value
  $productsByName[$name] = @{
    name = $name
    category = PolishText $m.Groups[2].Value
    status = $m.Groups[4].Value
    recommendation = PolishText $m.Groups[5].Value
    description = PolishText $m.Groups[6].Value
    technical = PolishText $m.Groups[8].Value
    jobs = @(ParseArray $m.Groups[9].Value)
    priorities = @(ParseArray $m.Groups[11].Value)
  }
}

$covers = @()
$sourceRows = @("No,Product,ImageUrl,LocalImage")

for ($i = 0; $i -lt $preferredOrder.Count; $i++) {
  $name = $preferredOrder[$i]
  if (-not $productsByName.ContainsKey($name)) { throw "Brak produktu w katalogu: $name" }
  if (-not $imageMap.ContainsKey($name)) { throw "Brak zdjęcia w katalogu: $name" }

  $url = $imageMap[$name]
  if ($name -eq "MONOX 6.0") {
    $url = "https://storage.googleapis.com/nitro-media-local/projects/0qricweczxxpllt/gallery/vjdqlth.webp"
  }
  if ($name -eq "MONOX 8.0") {
    $url = "https://storage.googleapis.com/nitro-media-local/projects/0qricweczxxpllt/gallery/vohliso.webp"
  }
  $slug = Slugify $name
  $ext = [IO.Path]::GetExtension(([Uri]$url).AbsolutePath)
  if ([string]::IsNullOrWhiteSpace($ext)) { $ext = ".webp" }
  $localName = "{0:00}-{1}{2}" -f ($i + 1), $slug, $ext
  $localPath = Join-Path $imageDir $localName

  if (-not (Test-Path $localPath)) {
    Invoke-WebRequest -Uri $url -OutFile $localPath -Headers @{ "User-Agent" = "Mozilla/5.0" } -TimeoutSec 60
  }

  $p = $productsByName[$name]
  $jobs = @($p.jobs | ForEach-Object { JobLabel $_ })
  if ($jobs.Count -eq 0) { $jobs = @("Praca brukarska") }
  while ($jobs.Count -lt 5) { $jobs += @("Profesjonalne użycie") }
  $jobs = @($jobs | Select-Object -First 5)

  $features = @()
  foreach ($priority in $p.priorities) { $features += @(PriorityFeature $priority) }
  $features += @(
    @{ title = "PROFESJONALNA KONSTRUKCJA"; body = "Stworzone do pracy w terenie."; icon = "tool" },
    @{ title = "PRAKTYCZNE ZASTOSOWANIE"; body = "Ułatwia codzienne zadania ekipy."; icon = "check" }
  )
  $features = @($features | Select-Object -First 4)

  $title = DisplayTitle $name
  $subtitle = (PolishText $p.technical).ToUpperInvariant()
  if ([string]::IsNullOrWhiteSpace($subtitle)) { $subtitle = (PolishText $p.category).ToUpperInvariant() }

  $covers += [pscustomobject]@{
    no = $i + 1
    name = $name
    title = $title
    subtitle = $subtitle
    image = "../zdjecia_produktow/$localName"
    category = $p.category
    recommendation = $p.recommendation
    technical = $p.technical
    jobs = $jobs
    features = $features
    sourceUrl = $url
  }
  $sourceRows += ('"{0}","{1}","{2}","{3}"' -f ($i + 1), $name.Replace('"','""'), $url, $localName)
}

$sourceRows | Set-Content -Encoding UTF8 (Join-Path $outDir "mapa-zrodel-zdjec.csv")

$json = $covers | ConvertTo-Json -Depth 8
$templatePath = Join-Path $renderDir "cover-template.html"
$template = @'
<!doctype html>
<html lang="pl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>FIXON Marketplace Cover</title>
<style>
  :root { --green:#003f2a; --line:#d7dedb; --soft:#f3f6f4; --black:#07110e; }
  * { box-sizing: border-box; }
  body { margin:0; background:#ddd; font-family: Arial, "Segoe UI", sans-serif; }
  .cover { width:1600px; height:1600px; background:#fff; color:var(--black); position:relative; overflow:hidden; padding:28px 38px 24px; }
  .top { display:flex; justify-content:space-between; align-items:flex-start; border-bottom:7px solid var(--green); padding-bottom:10px; }
  .brand { color:var(--green); font-weight:950; line-height:.84; letter-spacing:0; font-size:72px; }
  .brand small { display:block; font-size:31px; line-height:1.05; margin-top:9px; letter-spacing:.8px; }
  .badge { border:3px solid var(--green); border-radius:11px; padding:14px 22px; color:var(--green); font-weight:900; text-align:center; font-size:25px; line-height:1.05; margin-top:2px; }
  .title { color:var(--green); font-weight:950; font-size:89px; line-height:.95; margin:39px 0 12px; width:1450px; white-space:nowrap; letter-spacing:0; }
  .subtitle { font-weight:900; font-size:34px; line-height:1.12; text-transform:uppercase; max-width:930px; margin-bottom:29px; }
  .main { display:grid; grid-template-columns: 535px 1fr; gap:28px; }
  .slogan { color:var(--green); font-weight:900; font-size:42px; line-height:1.18; margin-bottom:28px; }
  .features { display:grid; gap:12px; }
  .feature { display:grid; grid-template-columns:86px 1fr; gap:16px; align-items:center; min-height:92px; }
  .iconbox { width:76px; height:76px; border:3px solid var(--green); border-radius:10px; display:flex; align-items:center; justify-content:center; color:var(--green); font-weight:900; font-size:31px; }
  .feature h3 { margin:0 0 5px; color:var(--green); font-size:24px; line-height:1.05; font-weight:950; }
  .feature p { margin:0; font-size:20px; line-height:1.22; font-weight:700; }
  .product-area { position:absolute; right:36px; top:315px; width:890px; height:660px; display:flex; align-items:center; justify-content:center; }
  .photo-frame { width:100%; height:100%; display:flex; align-items:center; justify-content:center; background:#fff; }
  .product-photo { max-width:100%; max-height:100%; object-fit:contain; display:block; }
  .applications { position:absolute; left:38px; bottom:244px; width:965px; height:145px; background:linear-gradient(90deg,#f5f7f6,#eef2f0); border-radius:12px; padding:18px 18px 14px; }
  .applications h3 { margin:0 0 10px; color:var(--green); font-size:25px; font-weight:950; }
  .apps { display:grid; grid-template-columns:repeat(5,1fr); height:82px; }
  .app { border-left:2px solid #bfc9c5; display:flex; flex-direction:column; justify-content:center; align-items:center; text-align:center; gap:7px; font-size:16px; font-weight:800; line-height:1.05; padding:0 10px; }
  .app:first-child { border-left:0; }
  .cube { width:45px; height:31px; border:3px solid var(--green); transform:skewY(-22deg); opacity:.9; }
  .spec { position:absolute; right:38px; bottom:247px; width:515px; border:1px solid #9fb0a9; border-radius:8px; overflow:hidden; background:#fff; }
  .spec h3 { margin:0; background:var(--green); color:#fff; text-align:center; padding:9px; font-size:22px; font-weight:950; }
  .row { display:grid; grid-template-columns:42% 58%; border-top:1px solid #bfc9c5; min-height:45px; }
  .row div { padding:10px 14px; font-size:17px; font-weight:800; line-height:1.16; display:flex; align-items:center; }
  .row div:first-child { border-right:1px solid #bfc9c5; color:#1a2b25; font-weight:900; }
  .bottom { position:absolute; left:36px; right:36px; bottom:82px; height:113px; background:linear-gradient(90deg,#003f2a,#00583c); color:#fff; border-radius:8px; display:grid; grid-template-columns:repeat(4,1fr); overflow:hidden; }
  .benefit { display:grid; grid-template-columns:76px 1fr; align-items:center; gap:12px; padding:0 24px; border-left:1px solid rgba(255,255,255,.45); }
  .benefit:first-child { border-left:0; }
  .benefit .bigicon { font-size:43px; font-weight:900; line-height:1; text-align:center; }
  .benefit strong { display:block; font-size:20px; line-height:1.12; font-weight:950; }
  .footer { position:absolute; left:56px; right:38px; bottom:24px; display:flex; justify-content:space-between; align-items:center; color:var(--green); font-weight:950; font-size:27px; }
  .source-note { font-size:13px; color:#6b7b74; font-weight:700; }
</style>
</head>
<body>
<div class="cover">
  <div class="top">
    <div class="brand">FIXON<small>TOOLS &amp; TECH</small></div>
    <div class="badge">PRODUKCJA<br>POLSKA</div>
  </div>
  <div id="title" class="title"></div>
  <div id="subtitle" class="subtitle"></div>
  <div class="main">
    <div>
      <div id="slogan" class="slogan"></div>
      <div id="features" class="features"></div>
    </div>
  </div>
  <div class="product-area"><div class="photo-frame"><img id="photo" class="product-photo" alt=""></div></div>
  <div class="applications"><h3>ZASTOSOWANIE</h3><div id="apps" class="apps"></div></div>
  <div class="spec"><h3>DANE TECHNICZNE</h3><div id="specRows"></div></div>
  <div id="bottom" class="bottom"></div>
  <div class="footer"><div>>> PRACUJ SZYBCIEJ. STABILNIEJ. PROFESJONALNIE.</div><div>MADE IN EUROPE</div></div>
</div>
<script>
const covers = __COVERS_JSON__;
const qs = new URLSearchParams(location.search);
const item = covers[Number(qs.get('i') || 0)] || covers[0];
const icon = { fast:'↻', target:'⌖', multi:'↔', lift:'⇧', shield:'✓', value:'◆', tool:'⚙', check:'✓' };
const el = id => document.getElementById(id);
el('title').textContent = item.title;
el('subtitle').textContent = item.subtitle;
el('photo').src = item.image;
el('photo').alt = item.name;
const sloganMap = {
  szybkosc:'Szybsza praca.',
  precyzja:'Większa precyzja.',
  uniwersalnosc:'Szersze zastosowanie.',
  wysilek:'Mniej wysiłku.',
  bezpieczenstwo:'Pewniejsza praca.',
  cena:'Dobry wybór.'
};
const slogan = item.features.slice(0,3).map(f => {
  if (f.title.includes('SZYBSZA')) return 'Szybsza praca.';
  if (f.title.includes('PRECYZJA')) return 'Większa precyzja.';
  if (f.title.includes('ZASTOSOWANIE')) return 'Szersze zastosowanie.';
  if (f.title.includes('WYSIŁKU')) return 'Mniej wysiłku.';
  if (f.title.includes('PEWNIEJSZA')) return 'Pewniejsza praca.';
  return 'Profesjonalny efekt.';
});
el('slogan').innerHTML = slogan.join('<br>');
el('features').innerHTML = item.features.map(f => `<div class="feature"><div class="iconbox">${icon[f.icon] || '✓'}</div><div><h3>${f.title}</h3><p>${f.body}</p></div></div>`).join('');
el('apps').innerHTML = item.jobs.map(j => `<div class="app"><div class="cube"></div><div>${j}</div></div>`).join('');
const spec = [
  ['Kategoria', item.category],
  ['Rekomendacja', item.recommendation],
  ['Opis', item.technical],
  ['Praca', item.jobs.slice(0,2).join(' / ')]
];
el('specRows').innerHTML = spec.map(r => `<div class="row"><div>${r[0]}</div><div>${r[1]}</div></div>`).join('');
const bottom = item.features.slice(0,4);
el('bottom').innerHTML = bottom.map(f => `<div class="benefit"><div class="bigicon">${icon[f.icon] || '✓'}</div><strong>${f.title}</strong></div>`).join('');
function fitText(node, min, max) {
  let size = max;
  node.style.fontSize = size + 'px';
  while (node.scrollWidth > node.clientWidth && size > min) {
    size -= 2;
    node.style.fontSize = size + 'px';
  }
}
fitText(el('title'), 42, 89);
</script>
</body>
</html>
'@

$template = $template.Replace("__COVERS_JSON__", $json)

$template | Set-Content -Encoding UTF8 $templatePath

$chromeCandidates = @(
  "C:\Program Files\Google\Chrome\Application\chrome.exe",
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
)
$browser = $chromeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { throw "Brak Chrome/Edge do eksportu PNG." }

for ($i = 0; $i -lt $covers.Count; $i++) {
  $slug = Slugify $covers[$i].name
  $out = Join-Path $outDir ("{0:00}-{1}.png" -f ($i + 1), $slug)
  $uri = (New-Object System.Uri($templatePath)).AbsoluteUri + "?i=$i"
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  & $browser --headless=new --disable-gpu --allow-file-access-from-files --window-size=1600,1600 --screenshot="$out" "$uri" *> $null
  $ErrorActionPreference = $oldPreference
  for ($attempt = 0; $attempt -lt 20 -and -not (Test-Path $out); $attempt++) {
    Start-Sleep -Milliseconds 250
  }
  if (-not (Test-Path $out)) { throw "Nie utworzono pliku: $out" }
}

Get-ChildItem -Path $outDir -Filter "*.png" | Sort-Object Name | Select-Object Name,Length,LastWriteTime







