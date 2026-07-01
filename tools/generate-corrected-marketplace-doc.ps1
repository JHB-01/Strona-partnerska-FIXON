$ErrorActionPreference = 'Stop'

$Workspace = Split-Path -Parent $PSScriptRoot
$SourceHtml = Join-Path $Workspace 'FIXON_e-katalog.html'
$BaseOutput = Join-Path $Workspace 'FIXON_opisy_marketplace_skorygowane_2026-06-12.docx'

function Get-UniquePath {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $Path }
  $dir = Split-Path -Parent $Path
  $name = [IO.Path]::GetFileNameWithoutExtension($Path)
  $ext = [IO.Path]::GetExtension($Path)
  $i = 2
  do {
    $candidate = Join-Path $dir ("{0}_v{1}{2}" -f $name, $i, $ext)
    $i++
  } while (Test-Path -LiteralPath $candidate)
  return $candidate
}

function Split-TopLevel {
  param([string]$Text)
  $parts = New-Object System.Collections.Generic.List[string]
  $current = New-Object System.Text.StringBuilder
  $depth = 0
  $inString = $false
  $escape = $false
  foreach ($ch in $Text.ToCharArray()) {
    [void]$current.Append($ch)
    if ($inString) {
      if ($escape) { $escape = $false }
      elseif ($ch -eq '\') { $escape = $true }
      elseif ($ch -eq '"') { $inString = $false }
      continue
    }
    if ($ch -eq '"') { $inString = $true }
    elseif ($ch -eq '[') { $depth++ }
    elseif ($ch -eq ']') { $depth-- }
    elseif ($ch -eq ',' -and $depth -eq 0) {
      $s = $current.ToString()
      $parts.Add($s.Substring(0, $s.Length - 1).Trim())
      [void]$current.Clear()
    }
  }
  if ($current.ToString().Trim()) { $parts.Add($current.ToString().Trim()) }
  return $parts.ToArray()
}

function Parse-JsValue {
  param([string]$Token)
  $t = $Token.Trim()
  if ($t.StartsWith('[')) {
    $vals = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($t, '"((?:\\.|[^"\\])*)"')) {
      $vals.Add(($m.Groups[1].Value -replace '\\"','"'))
    }
    return ,$vals.ToArray()
  }
  if ($t.StartsWith('"')) { return ($t.Substring(1, $t.Length - 2) -replace '\\"','"') }
  return $t
}

function Beautify {
  param([string]$Text)
  if (-not $Text) { return '' }
  $r = $Text
  $pairs = @(
    @('\bzl\b','zł'), @('narzedzia','narzędzia'), @('narzedzie','narzędzie'),
    @('ktore','które'), @('ktory','który'), @('ktora','która'),
    @('prace','pracę'), @('czesc','część'), @('czesto','często'),
    @('ciezkich','ciężkich'), @('ciezszy','cięższy'),
    @('plytami','płytami'), @('plyt','płyt'), @('kostka','kostką'),
    @('kraweznikow','krawężników'), @('kraweznik','krawężnik'), @('obrzezy','obrzeży'),
    @('Sciagacz','Ściągacz'), @('sciagacz','ściągacz'),
    @('podwojne','podwójne'), @('podwojnym','podwójnym'),
    @('rolka','rolką'), @('plastikowa','plastikową'), @('podkladka','podkładką'), @('podstawa','podstawą'),
    @('lata','łata'), @('late','łatę'), @('profilujaca','profilująca'), @('reczna','ręczna'),
    @('zageszczania','zagęszczania'), @('Zageszczarka','Zagęszczarka'),
    @('podlozem','podłożem'), @('podloza','podłoża'), @('uzycia','użycia'),
    @('szybkosc','szybkość'), @('wysilek','wysiłek'), @('bezpieczenstwo','bezpieczeństwo'), @('uniwersalnosc','uniwersalność'),
    @('rowniej','równiej'), @('rozwiazanie','rozwiązanie'), @('rozwiazan','rozwiązań'),
    @('uzupelnienie','uzupełnienie'), @('dostep','dostęp')
  )
  foreach ($pair in $pairs) { $r = $r -replace $pair[0], $pair[1] }
  return $r
}

function X { param([string]$Text) [System.Security.SecurityElement]::Escape([string]$Text) }
function P {
  param([string]$Text, [string]$Style = '')
  $styleXml = if ($Style) { "<w:pPr><w:pStyle w:val=`"$Style`"/></w:pPr>" } else { '' }
  $runs = (($Text -split "`n") | ForEach-Object { '<w:r><w:t xml:space="preserve">' + (X $_) + '</w:t></w:r>' }) -join '<w:r><w:br/></w:r>'
  return "<w:p>$styleXml$runs</w:p>"
}
function PB { '<w:p><w:r><w:br w:type="page"/></w:r></w:p>' }
function Cell {
  param($Value, [int]$Width = 2400)
  $inner = ''
  if ($Value -is [array]) {
    foreach ($v in $Value) { $inner += P ([string]$v) }
  } else {
    $inner = P ([string]$Value)
  }
  return "<w:tc><w:tcPr><w:tcW w:w=`"$Width`" w:type=`"dxa`"/><w:tcMar><w:top w:w=`"80`" w:type=`"dxa`"/><w:left w:w=`"80`" w:type=`"dxa`"/><w:bottom w:w=`"80`" w:type=`"dxa`"/><w:right w:w=`"80`" w:type=`"dxa`"/></w:tcMar></w:tcPr>$inner</w:tc>"
}
function Tbl {
  param($Rows, $Widths)
  $border = '<w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="A8B8AE"/><w:left w:val="single" w:sz="4" w:space="0" w:color="A8B8AE"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="A8B8AE"/><w:right w:val="single" w:sz="4" w:space="0" w:color="A8B8AE"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="A8B8AE"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="A8B8AE"/></w:tblBorders>'
  $xml = "<w:tbl><w:tblPr><w:tblStyle w:val=`"TableGrid`"/><w:tblW w:w=`"0`" w:type=`"auto`"/>$border</w:tblPr>"
  foreach ($row in $Rows) {
    $xml += '<w:tr>'
    for ($i = 0; $i -lt $row.Count; $i++) { $xml += Cell $row[$i] $Widths[$i] }
    $xml += '</w:tr>'
  }
  return $xml + '</w:tbl>'
}
function ListXml { param($Items) (($Items | ForEach-Object { P "- $_" }) -join '') }
function LimitText { param([string]$Text, [int]$Length) $c = ($Text -replace '\s+',' ').Trim(); if ($c.Length -le $Length) { $c } else { $c.Substring(0, $Length - 1).Trim() } }

$displayNames = @{
  'FlatFix z rolka' = 'FlatFix z rolką'
  'FlatFix z plastikowa podkladka' = 'FlatFix z plastikową podkładką'
  'FlatFix PLUS z plastikowa podstawa' = 'FlatFix PLUS z plastikową podstawą'
  'FlatFix PLUS z rolka' = 'FlatFix PLUS z rolką'
  'Zageszczarka plytowa gruntu 120 kg 32 kN LONCIN' = 'Zagęszczarka płytowa gruntu 120 kg 32 kN LONCIN'
}
$categories = @{
  'Obrzeza i krawezniki' = 'Obrzeża i krawężniki'
  'Zageszczanie i przygotowanie podloza' = 'Zagęszczanie i przygotowanie podłoża'
  'Chwytanie i podnoszenie' = 'Chwytanie i podnoszenie'
  'Prowadzenie i profilowanie' = 'Prowadzenie i profilowanie'
  'Transport i przenoszenie' = 'Transport i przenoszenie'
  'Systemy i zestawy' = 'Systemy i zestawy'
  'Akcesoria i dodatki' = 'Akcesoria i dodatki'
}
$statusLabels = @{
  maker = 'Dostępny z dostawą'
  order7 = 'Dostępny na zamówienie, przewidywany termin do 7 dni'
  order14 = 'Dostępny na zamówienie, przewidywany termin do 14 dni'
}
$sitePrices = @{
  'Zestaw LEVEL' = '2 460,00 PLN brutto'; 'Zestaw MASTER' = '1 550,00 PLN brutto'; 'Zestaw KRAWĘŻNIKI' = '550,01 PLN brutto'; 'GRIX HOLD PRO' = '295,20 PLN brutto'; 'GRIX HOLD' = '240,00 PLN brutto'; 'GRIX' = '197,00 PLN brutto'; 'GRIX PLUS' = '270,00 PLN brutto'; 'Adapter do podnoszenia - system GRIX' = '80,00 PLN brutto'; 'GRIX HARD' = '650,01 PLN brutto'; 'FlatFix DUO' = '280,00 PLN brutto'; 'FlatFix z rolka' = '195,00 PLN brutto'; 'FlatFix z plastikowa podkladka' = '150,00 PLN brutto'; 'FlatFix Standard' = '120,00 PLN brutto'; 'KatFix PRO' = '270,60 PLN brutto'; 'KatFix' = '195,00 PLN brutto'; 'LineFix' = '140,00 PLN brutto'; 'FlatFix PLUS Standard' = '145,00 PLN brutto'; 'FlatFix PLUS z plastikowa podstawa' = '180,00 PLN brutto'; 'FlatFix PLUS z rolka' = '220,00 PLN brutto'; 'BLOCKLIFT 500' = '2 400,00 PLN brutto'; 'BLOCKLIFT 300' = '1 250,00 PLN brutto'; 'CyrkielFix' = '145,00 PLN brutto'; 'BRUKFILL' = '11 000,00 PLN brutto'; 'KrawFix INOX' = '320,50 PLN brutto'; 'KrawFix ROLLER' = '470,00 PLN brutto'; 'KrawFix' = '240,00 PLN brutto'; 'MONOX 6.0' = '9 864,60 PLN brutto'; 'MONOX 8.0' = '13 800,00 PLN brutto'; 'FormFix DUAL' = '2 460,00 PLN brutto'; 'FormFix MAX' = '1 470,00 PLN brutto'; 'FormFix 1250-2200 mm' = '980,00 PLN brutto'; 'FormFixMini' = '660,01 PLN brutto'; 'HandLift' = '280,00 PLN brutto'; 'GRIPTOR' = '340,00 PLN brutto'; 'HARDTAP 5 kg' = '220,00 PLN brutto'; 'HARDTAP 10 kg' = '282,90 PLN brutto'; 'HARDTAP 15 kg' = '332,10 PLN brutto'; 'HARDTAP 20 kg' = '369,00 PLN brutto'; 'RolLift' = '740,00 PLN brutto'; 'LiftX' = '340,00 PLN brutto'; 'Zageszczarka plytowa gruntu 120 kg 32 kN LONCIN' = '4 700,00 PLN brutto'; 'WallFix' = '1 650,00 PLN brutto'; 'LevelFix' = '1 799,66 PLN brutto'; 'ODBOJNIK GUMOWY 60x30x22mm' = '10,00 PLN brutto'; 'Odbojnik do GRIX PLUS' = '95,01 PLN brutto'; 'UrbanRoot STEEL' = '1 970,00 PLN brutto'; 'UrbanRoot INOX' = '3 383,00 PLN brutto'; 'UrbanRoot CUSTOM' = '2 999,99 PLN brutto'
}

function DName($p) { if ($displayNames.ContainsKey($p.Name)) { $displayNames[$p.Name] } else { $p.Name } }
function DCategory($p) { if ($categories.ContainsKey($p.Category)) { $categories[$p.Category] } else { $p.Category } }
function PrimaryPrice($p) { if ($sitePrices.ContainsKey($p.Name)) { $sitePrices[$p.Name] } else { Beautify $p.Price } }
function NPrice([string]$s) { ($s -replace '\s','' -replace 'PLNbrutto','' -replace 'zl','' -replace 'zł','').Trim() }
function PriceNote($p) {
  if (-not $sitePrices.ContainsKey($p.Name)) { return 'Brak na odczytanej stronie producenta; użyto lokalnego e-katalogu. Przed publikacją potwierdź cenę.' }
  if ((NPrice $sitePrices[$p.Name]) -ne (NPrice $p.Price)) { return "Różnica ceny: strona producenta $($sitePrices[$p.Name]), lokalny katalog $(Beautify $p.Price). Do publikacji przyjmij aktualny cennik." }
  return 'Cena zgodna w lokalnym katalogu i odczycie strony producenta.'
}
function Purpose($p) {
  switch ($p.Category) {
    'Chwytanie i podnoszenie' { 'chwytania, podnoszenia i ustawiania elementów brukarskich' }
    'Prowadzenie i profilowanie' { 'prowadzenia, profilowania i kontroli ustawienia podczas prac brukarskich' }
    'Obrzeza i krawezniki' { 'prac przy obrzeżach, krawężnikach i podbudowie' }
    'Transport i przenoszenie' { 'transportu i przenoszenia płyt, krawężników lub cięższych elementów' }
    'Zageszczanie i przygotowanie podloza' { 'przygotowania i zagęszczania podłoża' }
    'Systemy i zestawy' { 'szerszej organizacji pracy ekipy brukarskiej' }
    default { 'uzupełnienia zestawu narzędzi albo realizacji specjalistycznych' }
  }
}
function Problem($p) {
  switch ($p.Category) {
    'Chwytanie i podnoszenie' { 'powtarzalne chwytanie, podnoszenie i poprawianie elementów' }
    'Prowadzenie i profilowanie' { 'utrzymanie równego prowadzenia, kąta, linii i profilu' }
    'Obrzeza i krawezniki' { 'dokładne ustawianie krawężników i obrzeży bez improwizacji na budowie' }
    'Transport i przenoszenie' { 'przenoszenie materiału między miejscem składowania a frontem pracy' }
    'Zageszczanie i przygotowanie podloza' { 'ręczne lub mechaniczne przygotowanie podłoża w miejscach, gdzie liczy się kontrola' }
    'Systemy i zestawy' { 'łączenie kilku etapów pracy w jeden uporządkowany system' }
    default { 'uzupełnienie pracy narzędzi i dopasowanie rozwiązania do konkretnego zadania' }
  }
}
function TypeLine($p) {
  $n = DName $p
  if ($n -match 'Zestaw') { 'profesjonalny zestaw narzędzi brukarskich' }
  elseif ($n -match 'GRIX|GRIPTOR|HandLift|BLOCKLIFT') { 'profesjonalny chwytak brukarski' }
  elseif ($n -match 'FlatFix') { 'profesjonalna nasadka do prowadzenia poziomicy' }
  elseif ($n -match 'KatFix|LineFix|LevelFix') { 'profesjonalne narzędzie do wyznaczania i prowadzenia pracy' }
  elseif ($n -match 'FormFix') { 'profesjonalna łata profilująca' }
  elseif ($n -match 'KrawFix') { 'profesjonalny ściągacz podbudowy przy krawężnikach' }
  elseif ($n -match 'WallFix') { 'specjalistyczny zestaw szalunku ślizgowego' }
  elseif ($n -match 'RolLift|LiftX') { 'narzędzie do transportu i przenoszenia elementów brukarskich' }
  elseif ($n -match 'HARDTAP') { 'profesjonalny ubijak ręczny' }
  elseif ($n -match 'Zagęszczarka|Zageszczarka') { 'profesjonalna zagęszczarka płytowa' }
  elseif ($n -match 'BRUKFILL') { 'profesjonalne urządzenie do fugowania kostki brukowej' }
  elseif ($n -match 'MONOX') { 'profesjonalny grader drogowy' }
  elseif ($n -match 'UrbanRoot') { 'kratownica przydrzewna do realizacji miejskich' }
  elseif ($n -match 'Odbojnik|ODBOJNIK') { 'element ochronny i serwisowy do narzędzi FIXON' }
  else { "profesjonalne narzędzie z kategorii $((DCategory $p).ToLower())" }
}
function Positioning($p) {
  $n = DName $p
  $rec = (Beautify $p.Recommendation).ToLower()
  if ($n -match 'PRO|PLUS|MAX|HARD|DUAL|INOX|ROLLER|500|CUSTOM' -or $rec -match 'mocniejsza|specjalistycz') { 'Wersja wzmocniona do wymagających zadań' }
  elseif ($n -match 'Zestaw') { 'Kompletny pakiet do uporządkowanej pracy ekipy' }
  elseif ($rec -match 'ekonomiczna|tańsza|tansza|podstawowa') { 'Praktyczna wersja do wejścia w system FIXON' }
  elseif ($rec -match 'najlepszy') { 'Mocna rekomendacja do regularnej pracy wykonawczej' }
  elseif ($rec -match 'dodatek|uzupełnienie|uzupelnienie') { 'Uzupełnienie zestawu, które porządkuje pracę w detalu' }
  else { 'Profesjonalne narzędzie do codziennej pracy na budowie' }
}
function BenefitLines($p) {
  $map = @{ szybkosc='Sprawniejsze tempo pracy.'; precyzja='Większa precyzja.'; wysilek='Mniej obciążających ruchów.'; bezpieczenstwo='Pewniejsza kontrola narzędzia.'; uniwersalnosc='Szersze zastosowanie w pracy ekipy.'; cena='Rozsądny koszt wejścia.' }
  $a = @()
  foreach ($x in $p.Priorities) { if ($map.ContainsKey($x)) { $a += $map[$x] } }
  while ($a.Count -lt 3) { $a += 'Większa kontrola.' }
  return $a[0..2]
}
function Apps($p) {
  $a = @()
  foreach ($job in $p.Jobs) {
    if ($job -eq 'ukladanie') { $a += 'kostka brukowa i płyty chodnikowe','podjazdy, ścieżki, tarasy i place' }
    elseif ($job -eq 'podnoszenie') { $a += 'chwytanie i podnoszenie elementów betonowych','płyty chodnikowe, gazony, bloczki i palisady' }
    elseif ($job -eq 'krawezniki') { $a += 'krawężniki i obrzeża betonowe','palisady i elementy ogrodzeniowe' }
    elseif ($job -eq 'profilowanie') { $a += 'profilowanie i wyrównywanie podbudowy','prowadzenie łat, poziomic i linii roboczych' }
    elseif ($job -eq 'transport') { $a += 'transport płyt i krawężników','organizacja materiału na budowie' }
    elseif ($job -eq 'zageszczanie') { $a += 'zagęszczanie podłoża','poprawki w miejscach o ograniczonym dostępie' }
    elseif ($job -eq 'specjalistyczne') { $a += 'realizacje specjalistyczne','większe fronty pracy' }
  }
  if (-not $a) { $a = @((Purpose $p),(Problem $p),'codzienna praca wykonawcza') }
  return $a | Select-Object -Unique -First 6
}
function Keywords($p) { (($p.Jobs + $p.Priorities | ForEach-Object { Beautify $_ }) + @((DName $p),'FIXON','narzędzie brukarskie',(DCategory $p))) -join ', ' }
function TitleRows($p) {
  $n = DName $p
  $purpose = Beautify $p.Technical
  if (-not $purpose) { $purpose = Purpose $p }
  return @(
    @('Allegro', (LimitText "$n FIXON - $purpose" 75)),
    @('Amazon PL', (LimitText "FIXON $n - $purpose, narzędzie brukarskie dla wykonawców" 180)),
    @('Facebook / Meta', (LimitText "$n FIXON do pracy brukarskiej" 80)),
    @('OLX', (LimitText "$n FIXON - narzędzie brukarskie, nowe" 70)),
    @('eBay PL', (LimitText "FIXON $n narzędzie brukarskie $purpose" 80)),
    @('eBay EN', (LimitText "FIXON $n professional paving tool" 80)),
    @('SEO title', (LimitText "$n FIXON - $(DCategory $p)" 60))
  )
}

$html = Get-Content -LiteralPath $SourceHtml -Raw -Encoding UTF8
$imageBlock = [regex]::Match($html, '(?s)const productImages = \{(.*?)\n\s*\};').Groups[1].Value
$productImages = @{}
foreach ($m in [regex]::Matches($imageBlock, '"([^"]+)"\s*:\s*"([^"]+)"')) { $productImages[$m.Groups[1].Value] = $m.Groups[2].Value }
$productBlock = [regex]::Match($html, '(?s)const products = \[(.*?)\n\s*\];').Groups[1].Value
$products = New-Object System.Collections.Generic.List[object]
foreach ($m in [regex]::Matches($productBlock, '(?s)product\((.*?)\)\s*,?')) {
  $args = @(Split-TopLevel $m.Groups[1].Value | ForEach-Object { Parse-JsValue $_ })
  if ($args.Count -lt 11) { continue }
  $products.Add([pscustomobject]@{
    Name = $args[0]; Category = $args[1]; Price = $args[2]; Status = $args[3]
    Recommendation = $args[4]; Description = $args[5]; Sales = $args[6]; Technical = $args[7]
    Jobs = @($args[8]); Scales = @($args[9]); Priorities = @($args[10]); Image = ($productImages[$args[0]])
  })
}

$doc = New-Object System.Collections.Generic.List[string]
$doc.Add((P 'FIXON - opisy marketplace po korekcie stylu' 'Title'))
$doc.Add((P 'Wersja skorygowana według wzorca opisu GRIX PLUS: mocny nagłówek, pozycjonowanie wersji, specyfikacja, zastosowanie, wyróżniki i krótkie warianty na platformy.'))
$doc.Add((P "Data: 12.06.2026. Zakres: $($products.Count) produktów. Odbiorca: klient końcowy, głównie wykonawca brukarski lub budowlany."))
$doc.Add((PB))
$doc.Add((P '1. Nowy wzorzec opisu' 'Heading1'))
$doc.Add((P 'Nowy opis ma brzmieć jak oferta marketplace, a nie neutralna karta katalogowa. Zachowuje bezpieczeństwo polityki marki, ale jest bardziej zdecydowany: najpierw produkt i jego wersja, potem krótka obietnica praktycznej wartości, specyfikacja, zastosowania i wyróżniki.'))
$doc.Add((Tbl @(
  @('Element','Jak pisać po korekcie'),
  @('Nagłówek','Nazwa produktu + profesjonalny typ narzędzia + najważniejszy zakres lub zastosowanie.'),
  @('Linia pozycjonująca','Wersja wzmocniona, ekonomiczna, kompletna, specjalistyczna albo startowa - zależnie od produktu.'),
  @('Ton','Konkretny, dynamiczny, skierowany do wykonawcy. Bez przesadnych gwarancji i bez ataku na konkurencję.'),
  @('Specyfikacja','Tylko dane potwierdzone: zakres, masa, liczba elementów, materiał, wariant, status.'),
  @('Zastosowanie','Realne prace: krawężniki, płyty, palisady, profilowanie, transport, zagęszczanie, fugowanie itd.')
) @(2800,7400)))
$doc.Add((P '2. Tabela pól marketplace' 'Heading1'))
$doc.Add((Tbl @(
  @('Platforma','Najważniejsze pola','Jak używać opisów'),
  @('Allegro','Tytuł, opis, parametry, GPSR, zdjęcia, cena, dostawa','Użyj pełnego opisu głównego, specyfikacji i listy zastosowań.'),
  @('Amazon','Title, Bullet Points, Product Description, Product Details, Search Terms','Użyj bulletów i opisu długiego, bez języka promocyjnego w tytule.'),
  @('Facebook / Meta','Tytuł, cena, kategoria, opis, zdjęcia, lokalizacja','Użyj krótkiego wariantu social i prostego CTA do kontaktu.'),
  @('OLX','Tytuł, cena, opis, lokalizacja, wysyłka, zdjęcia','Użyj wariantu uproszczonego z ceną, dostępnością i zastosowaniem.'),
  @('eBay','Title do 80 znaków, Item specifics, Description, Shipping, Returns','Użyj tytułu EN/PL, item specifics i krótkiego opisu angielskiego.'),
  @('Inne marketplace','Slug, meta title, meta description, atrybuty, media','Użyj krótkiego opisu, meta description i słów kluczowych.')
) @(2400,3800,4000)))
$doc.Add((PB))
$doc.Add((P '3. Zbiorcza tabela produktów' 'Heading1'))
$rows = New-Object System.Collections.Generic.List[object]
$rows.Add(@('Produkt','Pozycjonowanie','Cena do publikacji','Status','Uwagi'))
foreach ($p in $products) { $rows.Add(@((DName $p),(Positioning $p),(PrimaryPrice $p),$statusLabels[$p.Status],(PriceNote $p))) }
$doc.Add((Tbl $rows @(2600,3100,2100,2600,3300)))
$doc.Add((PB))
$doc.Add((P '4. Gotowe opisy produktów' 'Heading1'))

$idx = 0
foreach ($p in $products) {
  $idx++
  $n = DName $p
  $type = TypeLine $p
  $pos = Positioning $p
  $purpose = Purpose $p
  $problem = Problem $p
  $tech = Beautify $p.Technical

  $doc.Add((PB))
  $doc.Add((P "$idx. $n" 'Heading1'))
  $doc.Add((Tbl @(
    @('Pole','Wartość'),
    @('Nazwa robocza',$n),
    @('Pozycjonowanie',$pos),
    @('Typ',$type),
    @('Kategoria',(DCategory $p)),
    @('Cena do publikacji',(PrimaryPrice $p)),
    @('Status',$statusLabels[$p.Status]),
    @('Uwaga cenowa',(PriceNote $p))
  ) @(2600,7600)))
  $doc.Add((P 'Opis produktu - wersja główna marketplace' 'Heading2'))
  $doc.Add((P "$n - $type"))
  $doc.Add((P $pos))
  $doc.Add((P "$n to $type marki FIXON, zaprojektowane do $purpose. To propozycja dla wykonawców, którzy chcą mieć pod ręką narzędzie do konkretnego zadania, zamiast improwizować rozwiązanie na budowie."))
  foreach ($line in (BenefitLines $p)) { $doc.Add((P $line)) }
  $doc.Add((P "Narzędzie sprawdzi się szczególnie tam, gdzie pojawia się $problem. W opisie oferty warto pokazać je jako praktyczne wsparcie codziennej pracy, bez obiecywania gwarantowanych wyników czy sztywnych procentów oszczędności."))
  $doc.Add((P 'Pracuj sprawniej. Stabilniej. Profesjonalnie.'))

  $doc.Add((P 'Specyfikacja techniczna' 'Heading2'))
  $spec = @("Typ produktu: $type.")
  if ($tech) { $spec += "Informacja techniczna: $($tech.TrimEnd('.'))." }
  if ("$n $tech" -match 'INOX|stal nierdzewna|Stal nierdzewna') { $spec += 'Materiał komunikowany: stal nierdzewna, jeśli potwierdzają to aktualne materiały produktu.' }
  $spec += "Zakres zastosowania: $purpose."
  $spec += "Dostępność: $($statusLabels[$p.Status])."
  $doc.Add((ListXml $spec))

  $doc.Add((P 'Zastosowanie' 'Heading2'))
  $doc.Add((ListXml (Apps $p)))

  $doc.Add((P "Co wyróżnia $n?" 'Heading2'))
  $wyr = @("$n porządkuje etap pracy: $problem.")
  foreach ($line in (BenefitLines $p)) { $wyr += $line }
  if ($tech) { $wyr += "Parametr do pokazania klientowi: $($tech.TrimEnd('.'))." }
  $wyr += 'Komunikacja zgodna z polityką marki: praktyczna, konkretna i bez obietnic gwarantowanego wyniku.'
  $doc.Add((ListXml $wyr))

  $doc.Add((P 'Tytuły na platformy' 'Heading2'))
  $trows = New-Object System.Collections.Generic.List[object]
  $trows.Add(@('Platforma','Wariant tytułu'))
  foreach ($tr in (TitleRows $p)) { $trows.Add($tr) }
  $doc.Add((Tbl $trows @(2600,7600)))

  $doc.Add((P 'Warianty krótkie i kanałowe' 'Heading2'))
  $short = "$n FIXON to $type do $purpose. Sprawdza się przy $problem i pomaga ekipie pracować stabilniej, dokładniej oraz z mniejszą improwizacją."
  $fb = "$n FIXON to narzędzie dla ekip, które chcą usprawnić $problem. Konkretne zastosowanie, jasna funkcja i profesjonalny charakter pracy bez prowizorycznych rozwiązań."
  $olx = "$n FIXON - nowe narzędzie dla ekip brukarskich i budowlanych. Zastosowanie: $purpose. Cena: $(PrimaryPrice $p). Dostępność i termin wysyłki do potwierdzenia przed zakupem."
  $amazon = @("$n FIXON: $type do $purpose.", "Praktyczne zastosowanie: $problem.")
  foreach ($line in (BenefitLines $p | Select-Object -First 2)) { $amazon += $line }
  if ($tech) { $amazon += "Dane techniczne: $($tech.TrimEnd('.'))." }
  $doc.Add((Tbl @(
    @('Kanał','Treść'),
    @('Krótki opis marketplace',$short),
    @('Facebook / post',$fb),
    @('OLX',$olx),
    @('Amazon bullets',$amazon),
    @('Meta description',(LimitText "$n FIXON: $short Cena: $(PrimaryPrice $p)." 155)),
    @('Słowa kluczowe',(Keywords $p)),
    @('CTA',"Zapytaj o dostępność $n i dobierz narzędzie do pracy swojej ekipy.")
  ) @(2600,7600)))
}

$doc.Add((PB))
$doc.Add((P '5. Kontrola przed publikacją' 'Heading1'))
$doc.Add((Tbl @(
  @('Pytanie kontrolne','Tak/Nie/Uwagi'),
  @('Czy opis jest mocny sprzedażowo, ale bez gwarantowania efektów?',''),
  @('Czy materiał, zakres, masa i parametry są potwierdzone w karcie produktu?',''),
  @('Czy cena i dostępność są aktualne?',''),
  @('Czy zdjęcia pokazują właściwy wariant produktu?',''),
  @('Czy uzupełniono GPSR, producenta, dostawę, zwroty i warunki sprzedaży?','')
) @(6200,4000)))
$doc.Add((P '6. Źródła i uwagi' 'Heading1'))
$doc.Add((ListXml @(
  'Wzorzec stylu: opis GRIX PLUS przekazany przez użytkownika w rozmowie.',
  'Dane produktowe: lokalny e-katalog FIXON oraz strona producenta STARK-FIXON: https://stark-house.pl/pl',
  'Dla produktów bez potwierdzonych parametrów materiałowych nie dopisano twardych deklaracji typu stal nierdzewna poza miejscami, gdzie wynika to z nazwy lub danych produktu.'
)))

$documentXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><w:body>' + (($doc.ToArray()) -join "`n") + '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1000" w:right="900" w:bottom="1000" w:left="900" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr></w:body></w:document>'
$stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Aptos" w:hAnsi="Aptos" w:eastAsia="Aptos" w:cs="Aptos"/><w:sz w:val="22"/><w:color w:val="1F2A24"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="140" w:line="276" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style><w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:qFormat/><w:rPr><w:b/><w:sz w:val="44"/><w:color w:val="124A2E"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:before="360" w:after="180"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:sz w:val="30"/><w:color w:val="124A2E"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:before="240" w:after="120"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:sz w:val="25"/><w:color w:val="06271B"/></w:rPr></w:style><w:style w:type="table" w:styleId="TableGrid"><w:name w:val="Table Grid"/></w:style></w:styles>'
$contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>'
$rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>'
$docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>'
$core = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>FIXON opisy marketplace po korekcie stylu</dc:title><dc:creator>Codex dla FIXON</dc:creator><cp:lastModifiedBy>Codex</cp:lastModifiedBy><dcterms:created xsi:type="dcterms:W3CDTF">2026-06-12T00:00:00Z</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">2026-06-12T00:00:00Z</dcterms:modified></cp:coreProperties>'
$app = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Codex</Application></Properties>'

$OutputPath = Get-UniquePath $BaseOutput
$PackageDir = Join-Path $env:TEMP ("fixon-docx-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $PackageDir, (Join-Path $PackageDir '_rels'), (Join-Path $PackageDir 'word'), (Join-Path $PackageDir 'word\_rels'), (Join-Path $PackageDir 'docProps') | Out-Null
Set-Content -LiteralPath (Join-Path $PackageDir '[Content_Types].xml') -Value $contentTypes -Encoding UTF8
Set-Content -LiteralPath (Join-Path $PackageDir '_rels\.rels') -Value $rels -Encoding UTF8
Set-Content -LiteralPath (Join-Path $PackageDir 'docProps\core.xml') -Value $core -Encoding UTF8
Set-Content -LiteralPath (Join-Path $PackageDir 'docProps\app.xml') -Value $app -Encoding UTF8
Set-Content -LiteralPath (Join-Path $PackageDir 'word\document.xml') -Value $documentXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $PackageDir 'word\styles.xml') -Value $stylesXml -Encoding UTF8
Set-Content -LiteralPath (Join-Path $PackageDir 'word\_rels\document.xml.rels') -Value $docRels -Encoding UTF8

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($PackageDir, $OutputPath)

Get-Item -LiteralPath $OutputPath | Select-Object FullName,Length,LastWriteTime
Write-Output "products=$($products.Count)"
