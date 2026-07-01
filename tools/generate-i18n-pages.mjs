import fs from "node:fs";
import path from "node:path";

const root = "C:/Users/Karolina/Documents/FIXON";
const manifestPath = path.join(root, "dokumenty", "manifest.json");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8").replace(/^\uFEFF/, ""));

const contact = {
  phoneDisplay: "+48 531 448 893",
  phoneHref: "tel:+48531448893",
  name: "Karolina Tarasenko",
  rolePl: "Specjalista ds. Rozwoju Sieci Partnerskiej",
  roleEn: "Partner Network Development Specialist",
  roleDe: "Spezialistin f&uuml;r den Ausbau des Partnernetzwerks",
};

const titleBySlug = {
  "program-partnerski-fixon": { en: "FIXON Partner Programme", de: "FIXON Partnerprogramm" },
  "umowa-partnerska-fixon": { en: "FIXON Partner Agreement", de: "FIXON Partnervertrag" },
  "zalacznik-karta-partnera": { en: "Appendix: Partner Card", de: "Anlage: Partnerkarte" },
  "zalacznik-magazyn-startowy": { en: "Appendix: Starter Stock", de: "Anlage: Startlager" },
  "zalacznik-wsparcie-magazynowe": { en: "Appendix: Stock Support", de: "Anlage: Lagerunterst&uuml;tzung" },
  "zalacznik-cennik-katalogowy": { en: "Appendix: Catalogue Price List", de: "Anlage: Katalogpreisliste" },
  "zalacznik-statusy-produktow": { en: "Appendix: Product Statuses", de: "Anlage: Produktstatus" },
  "zalacznik-standardy-ekspozycji": { en: "Appendix: Display Standards", de: "Anlage: Pr&auml;sentationsstandards" },
  "zalacznik-polityka-marki": { en: "Appendix: FIXON Brand Policy", de: "Anlage: FIXON Markenrichtlinie" },
  "zalacznik-procedura-raportowania": { en: "Appendix: Reporting Procedure", de: "Anlage: Berichtsverfahren" },
  "zalacznik-wzor-raportu-miesiecznego": { en: "Appendix: Monthly Report Template", de: "Anlage: Vorlage Monatsbericht" },
  "zalacznik-wzor-zgloszenia-alarmowego": { en: "Appendix: Urgent Notice Template", de: "Anlage: Vorlage Eilmeldung" },
  "zalacznik-procedura-zwrotu": { en: "Appendix: Product Return Procedure", de: "Anlage: R&uuml;ckgabeverfahren" },
  "zalacznik-protokol-przekazania": { en: "Appendix: Handover Protocol", de: "Anlage: &Uuml;bergabeprotokoll" },
  "zalacznik-protokol-inwentaryzacji": { en: "Appendix: Inventory Protocol", de: "Anlage: Inventurprotokoll" },
  "zalacznik-rozbieznosci-magazynowe": { en: "Appendix: Stock Discrepancy Protocol", de: "Anlage: Protokoll zu Lagerabweichungen" },
  "zalacznik-uszkodzenie-utrata": { en: "Appendix: Damage or Loss Protocol", de: "Anlage: Protokoll bei Besch&auml;digung oder Verlust" },
  "zalacznik-produkty-testowe-premierowe": { en: "Appendix: Test and Launch Products", de: "Anlage: Test- und Einf&uuml;hrungsprodukte" },
  "zalacznik-karta-uprawnienia-strategicznego": { en: "Appendix: Strategic Entitlement Card", de: "Anlage: Karte f&uuml;r strategische Sonderrechte" },
  "zalacznik-karta-centrum-demonstracyjnego": { en: "Appendix: Demonstration Centre Card", de: "Anlage: Karte Demonstrationszentrum" },
};

const groupNames = {
  en: {
    "Dokument g\u0142\u00f3wny": "Main document",
    Umowa: "Agreement",
    "Start wsp\u00f3\u0142pracy": "Start of cooperation",
    "Magazyn i dost\u0119pno\u015b\u0107": "Stock and availability",
    "Sprzeda\u017c": "Sales",
    "Ekspozycja i marka": "Display and brand",
    Operacje: "Operations",
    "Protoko\u0142y": "Protocols",
    "Rozw\u00f3j wsp\u00f3\u0142pracy": "Growth of cooperation",
  },
  de: {
    "Dokument g\u0142\u00f3wny": "Hauptdokument",
    Umowa: "Vertrag",
    "Start wsp\u00f3\u0142pracy": "Start der Zusammenarbeit",
    "Magazyn i dost\u0119pno\u015b\u0107": "Lager und Verf&uuml;gbarkeit",
    "Sprzeda\u017c": "Vertrieb",
    "Ekspozycja i marka": "Pr&auml;sentation und Marke",
    Operacje: "Abl&auml;ufe",
    "Protoko\u0142y": "Protokolle",
    "Rozw\u00f3j wsp\u00f3\u0142pracy": "Ausbau der Zusammenarbeit",
  },
};

const legalReferences = [
  ["UK ICO guidance", "https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/"],
  ["US eCFR 16 CFR Part 437", "https://www.ecfr.gov/current/title-16/chapter-I/subchapter-D/part-437"],
  ["European Commission GDPR framework", "https://commission.europa.eu/law/law-topic/data-protection/legal-framework-eu-data-protection_en"],
  ["Canada anti-spam legislation", "https://fightspam-combattrelepourriel.ised-isde.canada.ca/site/canada-anti-spam-legislation/en"],
  ["Australian Consumer Law", "https://consumer.gov.au/"],
  ["OAIC Australian Privacy Principles", "https://www.oaic.gov.au/privacy/australian-privacy-principles"],
  ["South Africa POPIA", "https://inforegulator.org.za/popia/"],
  ["Swiss Federal Act on Data Protection", "https://www.fedlex.admin.ch/eli/cc/2022/491/en"],
];

const jurisdictions = {
  en: [
    ["UK", "Localise governing law, venue, UK GDPR, PECR direct marketing, product-liability and business-to-business sale terms."],
    ["USA", "Use state-specific law and venue. Check business opportunity or franchise triggers, earnings claims, warranties, sales tax, privacy and marketing consent."],
    ["Canada", "Use province-specific law. Check CASL, privacy, bilingual requirements where applicable, product safety, tax and warranty wording."],
    ["Australia", "Use Australian law and venue. Check Australian Consumer Law, privacy, unfair contract terms, warranties, product safety, import and tax logic."],
    ["South Africa", "Use South African law. Check POPIA, electronic communications, Consumer Protection Act exposure, product liability, import, tax and dispute clauses."],
    ["Germany", "Use German-law drafting. Check BGB/HGB, GDPR/BDSG, competition and marketing rules, warranty, retention of title and standard-term controls."],
    ["Austria", "Use Austrian-law drafting. Check ABGB/UGB, GDPR/DSG, competition and marketing rules, warranty, retention of title and standard-term controls."],
    ["Switzerland", "Use Swiss-law drafting. Check the Code of Obligations, revised FADP, competition and marketing rules, warranty, retention of title and data-transfer wording."],
  ],
  de: [
    ["UK", "Rechtswahl, Gerichtsstand, UK GDPR, PECR-Direktmarketing, Produkthaftung und B2B-Verkaufsbedingungen lokalisieren."],
    ["USA", "Bundesstaatliches Recht und Gerichtsstand einsetzen. Business-Opportunity-/Franchise-Ausl&ouml;ser, Ertragsaussagen, Gew&auml;hrleistung, Sales Tax, Datenschutz und Marketingeinwilligungen pr&uuml;fen."],
    ["Kanada", "Provinzspezifisches Recht einsetzen. CASL, Datenschutz, m&ouml;gliche Zweisprachigkeit, Produktsicherheit, Steuern und Gew&auml;hrleistung pr&uuml;fen."],
    ["Australien", "Australisches Recht und Gerichtsstand einsetzen. Australian Consumer Law, Datenschutz, unfair contract terms, Gew&auml;hrleistung, Produktsicherheit, Import und Steuern pr&uuml;fen."],
    ["S&uuml;dafrika", "S&uuml;dafrikanisches Recht einsetzen. POPIA, elektronische Kommunikation, Consumer-Protection-Risiken, Produkthaftung, Import, Steuern und Streitbeilegung pr&uuml;fen."],
    ["Deutschland", "Deutsches Recht verwenden. BGB/HGB, DSGVO/BDSG, Wettbewerbs- und Marketingrecht, Gew&auml;hrleistung, Eigentumsvorbehalt und AGB-Kontrolle pr&uuml;fen."],
    ["&Ouml;sterreich", "&Ouml;sterreichisches Recht verwenden. ABGB/UGB, DSGVO/DSG, Wettbewerbs- und Marketingrecht, Gew&auml;hrleistung, Eigentumsvorbehalt und AGB-Kontrolle pr&uuml;fen."],
    ["Schweiz", "Schweizer Recht verwenden. Obligationenrecht, revidiertes DSG, Wettbewerbs- und Marketingrecht, Gew&auml;hrleistung, Eigentumsvorbehalt und Daten&uuml;bermittlung pr&uuml;fen."],
  ],
};

const purposeBySlug = {
  en: {
    "program-partnerski-fixon": "Explains the partner model, entry conditions, pilot start, no required upfront investment, monthly sales settlement and operating rhythm.",
    "umowa-partnerska-fixon": "Defines commercial responsibilities, reporting, stock support, display rules, settlement, confidentiality and termination mechanics.",
    "zalacznik-karta-partnera": "Collects partner identification data, operating contact points and selected cooperation profile.",
    "zalacznik-magazyn-startowy": "Lists the starter stock proposal and protects the principle that stock is introduced only after an agreed pilot decision.",
    "zalacznik-wsparcie-magazynowe": "Describes how stock support and replenishment are organised when cooperation is already active.",
    "zalacznik-cennik-katalogowy": "Controls catalogue pricing, discount logic and communication of price updates.",
    "zalacznik-statusy-produktow": "Explains product availability statuses and the sales meaning of catalogue labels.",
    "zalacznik-standardy-ekspozycji": "Sets rules for physical display, QR points, demonstration readiness and shelf clarity.",
    "zalacznik-polityka-marki": "Controls brand language, claims, visual hierarchy and communication safety.",
    "zalacznik-procedura-raportowania": "Sets the monthly reporting rhythm needed for settlement and stock decisions.",
    "zalacznik-wzor-raportu-miesiecznego": "Provides the monthly report format used to confirm sales and needs.",
    "zalacznik-wzor-zgloszenia-alarmowego": "Provides an urgent notice format for stock, quality or operational exceptions.",
    "zalacznik-procedura-zwrotu": "Describes product return steps and responsibilities.",
    "zalacznik-protokol-przekazania": "Confirms transfer of products, display materials or demonstration tools.",
    "zalacznik-protokol-inwentaryzacji": "Confirms stock count and condition at agreed checkpoints.",
    "zalacznik-rozbieznosci-magazynowe": "Documents differences between expected and confirmed stock.",
    "zalacznik-uszkodzenie-utrata": "Documents damage or loss and allocates follow-up responsibility.",
    "zalacznik-produkty-testowe-premierowe": "Structures cooperation around test products and new launches.",
    "zalacznik-karta-uprawnienia-strategicznego": "Defines strategic entitlements granted to selected partners.",
    "zalacznik-karta-centrum-demonstracyjnego": "Defines requirements and benefits of a demonstration centre profile.",
  },
  de: {
    "program-partnerski-fixon": "Erl&auml;utert Partnermodell, Einstieg, Pilotstart, fehlende Pflichtinvestition, monatliche Abrechnung und operative Taktung.",
    "umowa-partnerska-fixon": "Regelt kommerzielle Pflichten, Reporting, Lagerunterst&uuml;tzung, Pr&auml;sentation, Abrechnung, Vertraulichkeit und Beendigung.",
    "zalacznik-karta-partnera": "Erfasst Partnerdaten, operative Ansprechpartner und das gew&auml;hlte Kooperationsprofil.",
    "zalacznik-magazyn-startowy": "Listet den Startlager-Vorschlag und sch&uuml;tzt den Grundsatz, dass Lager erst nach Pilotentscheidung aufgebaut wird.",
    "zalacznik-wsparcie-magazynowe": "Beschreibt Lagerunterst&uuml;tzung und Nachversorgung in der laufenden Zusammenarbeit.",
    "zalacznik-cennik-katalogowy": "Regelt Katalogpreise, Rabattlogik und Kommunikation von Preis&auml;nderungen.",
    "zalacznik-statusy-produktow": "Erl&auml;utert Verf&uuml;gbarkeitsstatus und die Verkaufsbedeutung der Kataloglabels.",
    "zalacznik-standardy-ekspozycji": "Setzt Regeln f&uuml;r Ausstellung, QR-Punkte, Demo-Bereitschaft und Regalklarheit.",
    "zalacznik-polityka-marki": "Regelt Markensprache, Aussagen, visuelle Hierarchie und sichere Kommunikation.",
    "zalacznik-procedura-raportowania": "Legt den monatlichen Reporting-Rhythmus f&uuml;r Abrechnung und Lagerentscheidungen fest.",
    "zalacznik-wzor-raportu-miesiecznego": "Stellt das Monatsreport-Format zur Best&auml;tigung von Verk&auml;ufen und Bedarf bereit.",
    "zalacznik-wzor-zgloszenia-alarmowego": "Stellt eine Eilmeldung f&uuml;r Lager-, Qualit&auml;ts- oder Betriebsabweichungen bereit.",
    "zalacznik-procedura-zwrotu": "Beschreibt R&uuml;ckgabeablauf und Verantwortlichkeiten.",
    "zalacznik-protokol-przekazania": "Best&auml;tigt die &Uuml;bergabe von Produkten, Displaymaterial oder Demonstrationswerkzeugen.",
    "zalacznik-protokol-inwentaryzacji": "Best&auml;tigt Bestand und Zustand zu vereinbarten Pr&uuml;fpunkten.",
    "zalacznik-rozbieznosci-magazynowe": "Dokumentiert Abweichungen zwischen erwartetem und best&auml;tigtem Bestand.",
    "zalacznik-uszkodzenie-utrata": "Dokumentiert Besch&auml;digung oder Verlust und weist Folgeverantwortung zu.",
    "zalacznik-produkty-testowe-premierowe": "Strukturiert Testprodukte und Produkteinf&uuml;hrungen.",
    "zalacznik-karta-uprawnienia-strategicznego": "Definiert strategische Sonderrechte ausgew&auml;hlter Partner.",
    "zalacznik-karta-centrum-demonstracyjnego": "Definiert Anforderungen und Vorteile eines Demonstrationszentrums.",
  },
};

function slugBase(doc) {
  return path.basename(doc.Slug, ".html");
}

function translatedTitle(doc, lang) {
  return titleBySlug[slugBase(doc)]?.[lang] || doc.Title;
}

function groupName(doc, lang) {
  return groupNames[lang][doc.Group] || doc.Group;
}

function css() {
  return `
    @import url("https://fonts.googleapis.com/css2?family=League+Spartan:wght@400;500;600;700;800;900&display=swap");
    :root{--green:#124A2E;--green2:#0a3624;--ink:#141917;--muted:#5d6863;--line:#d7ded8;--bg:#eef1ec;--soft:#e7f0ea;--paper:#fff;--yellow:#d4b15a;--shadow:0 18px 44px rgba(15,22,18,.10)}
    *{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:linear-gradient(180deg,#fafaf5 0%,var(--bg) 62%,#fff 100%);color:var(--ink);font-family:"League Spartan","Montserrat","Avenir Next",Arial,sans-serif;letter-spacing:0}
    a{color:inherit}.wrap{width:min(1120px,calc(100% - 32px));margin:0 auto}.top{position:sticky;top:0;z-index:20;background:rgba(255,255,255,.94);border-bottom:1px solid var(--line);backdrop-filter:blur(12px)}.nav{min-height:68px;display:flex;align-items:center;justify-content:space-between;gap:16px}.brand{font-weight:900;text-transform:uppercase;text-decoration:none;color:var(--green);font-size:26px}.langs{display:flex;gap:6px;flex-wrap:wrap}.langs a{padding:8px 10px;border:1px solid var(--line);border-radius:4px;text-decoration:none;font-weight:800;color:var(--green);background:#fff}.hero{padding:66px 0 42px;background:linear-gradient(135deg,#061f17 0%,var(--green) 68%,#1c5c3f 100%);color:#fff}.hero h1{max-width:900px;margin:0 0 16px;font-size:clamp(40px,7vw,76px);line-height:.95;text-transform:uppercase}.lead{max-width:760px;color:rgba(255,255,255,.83);font-size:21px;line-height:1.42}.cta-row{display:flex;flex-wrap:wrap;gap:12px;margin-top:26px}.btn{display:inline-flex;align-items:center;justify-content:center;min-height:48px;padding:13px 17px;border-radius:4px;background:var(--green);border:1px solid var(--green);color:#fff;font-weight:900;text-decoration:none}.hero .btn{background:#fff;color:#06271b;border-color:#fff}.btn.alt{background:transparent;color:#fff;border-color:rgba(255,255,255,.62)}section{padding:44px 0}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px}.grid.two{grid-template-columns:repeat(2,minmax(0,1fr))}.card{padding:20px;border:1px solid var(--line);border-radius:8px;background:#fff;box-shadow:var(--shadow)}h2{margin:0 0 12px;font-size:clamp(30px,4vw,48px);line-height:1;text-transform:uppercase}h3{margin:0 0 8px;font-size:22px}.muted{color:var(--muted);line-height:1.55}.notice{padding:18px;border-left:5px solid var(--yellow);background:#fff7df;font-weight:800}.doc-list{display:grid;gap:10px}.doc-row{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:12px;align-items:center;padding:14px;border:1px solid var(--line);border-radius:8px;background:#fff}.doc-row strong{display:block;color:#06271b;font-size:18px}.table-scroll{overflow:auto;border:1px solid var(--line);border-radius:8px;background:#fff}table{width:100%;border-collapse:collapse;min-width:780px}th,td{padding:12px;border:1px solid var(--line);text-align:left;vertical-align:top;line-height:1.45}th{background:var(--soft);color:#06271b}.source-actions{display:flex;flex-wrap:wrap;gap:10px;margin-top:16px}.source-actions .btn{background:#fff;color:var(--green);border-color:var(--line)}footer{padding:28px 0;border-top:1px solid var(--line);background:#fff;color:var(--muted)}@media(max-width:760px){.nav{align-items:flex-start;flex-direction:column;padding:12px 0}.grid,.grid.two{grid-template-columns:1fr}.doc-row{grid-template-columns:1fr}.hero{padding:42px 0 30px}.cta-row,.btn{width:100%}}
  `;
}

function htmlPage({ lang, title, body }) {
  return `<!doctype html>
<html lang="${lang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <style>${css()}</style>
</head>
<body>${body}</body>
</html>`;
}

function languageLinks(current, base = "") {
  if (current === "docs") {
    return `<div class="langs"><a href="../../FIXON_program_partnerski.html">PL</a><a href="../en/index.html">EN</a><a href="../de/index.html">DE</a></div>`;
  }
  if (current === "doc") {
    return `<div class="langs"><a href="../${base}.html">PL</a><a href="../en/${base}.html">EN</a><a href="../de/${base}.html">DE</a></div>`;
  }
  if (current === "landing") {
    return `<div class="langs"><a href="landing-pl.html">PL</a><a href="landing-en.html">EN</a><a href="landing-de.html">DE</a></div>`;
  }
  return `<div class="langs"><a href="FIXON_program_partnerski.html">PL</a><a href="FIXON_partner_program_en.html">EN</a><a href="FIXON_partnerprogramm_de.html">DE</a></div>`;
}

function legalReferenceList() {
  return legalReferences.map(([label, href]) => `<li><a href="${href}">${label}</a></li>`).join("\n");
}

function writeDocPages(lang) {
  const dir = path.join(root, "dokumenty", lang);
  fs.mkdirSync(dir, { recursive: true });
  const isDe = lang === "de";

  for (const doc of manifest) {
    const base = slugBase(doc);
    const title = translatedTitle(doc, lang);
    const tableRows = jurisdictions[lang].map(([market, note]) => `<tr><td><strong>${market}</strong></td><td>${note}</td></tr>`).join("\n");
    const polishPreview = `../${base}.html`;
    const sourcePdf = doc.Pdf.replace("dokumenty/", "../");
    const sourceDocx = doc.Docx.replace("dokumenty/", "../");
    const body = `
  <header class="top"><div class="wrap nav"><a class="brand" href="../../FIXON_program_partnerski.html">FIXON</a>${languageLinks("doc", base)}</div></header>
  <main>
    <section class="hero"><div class="wrap"><h1>${title}</h1><p class="lead">${isDe ? "Deutschsprachige Arbeitsfassung mit internationaler Lokalisierungsmatrix f&uuml;r Partner in mehreren Rechtsr&auml;umen." : "English working version with an international localisation matrix for partners across multiple jurisdictions."}</p><div class="cta-row"><a class="btn" href="${contact.phoneHref}">${isDe ? "Kontakt aufnehmen" : "Talk to FIXON"} ${contact.phoneDisplay}</a><a class="btn alt" href="../../${isDe ? "FIXON_partnerprogramm_de.html" : "FIXON_partner_program_en.html"}">${isDe ? "Programm lesen" : "Read programme"}</a></div></div></section>
    <section><div class="wrap">
      <p class="notice">${isDe ? "Juristischer Arbeitsentwurf: Diese Fassung erleichtert Lesen, &Uuml;bersetzung und Lokalisierung. Vor Versand oder Unterzeichnung muss die jeweilige Landesversion durch lokale Rechtsberatung finalisiert werden." : "Legal working draft: this version supports reading, translation and localisation. Before sending or signing, the selected country version must be finalised by local counsel."}</p>
      <div class="grid">
        <article class="card"><h3>${isDe ? "Dokumentgruppe" : "Document group"}</h3><p class="muted">${groupName(doc, lang)}</p></article>
        <article class="card"><h3>${isDe ? "Zweck" : "Purpose"}</h3><p class="muted">${purposeBySlug[lang][base] || (isDe ? "Arbeitsfassung f&uuml;r Partner-Onboarding und operative Abstimmung." : "Working version for partner onboarding and operational alignment.")}</p></article>
        <article class="card"><h3>${isDe ? "Kontakt" : "Contact"}</h3><p class="muted">${contact.name}<br>${isDe ? contact.roleDe : contact.roleEn}<br><a href="${contact.phoneHref}">${contact.phoneDisplay}</a></p></article>
      </div>
      <div class="source-actions">
        <a class="btn" href="${polishPreview}">${isDe ? "Polnische Vorschau" : "Polish preview"}</a>
        <a class="btn" href="${sourcePdf}">${isDe ? "PDF-Quelle" : "Source PDF"}</a>
        <a class="btn" href="${sourceDocx}">${isDe ? "DOCX-Quelle" : "Source DOCX"}</a>
      </div>
    </div></section>
    <section><div class="wrap"><h2>${isDe ? "Lokalisierung nach Markt" : "Market Localisation"}</h2><div class="table-scroll"><table><thead><tr><th>${isDe ? "Markt" : "Market"}</th><th>${isDe ? "Anpassung vor Nutzung" : "Adaptation before use"}</th></tr></thead><tbody>${tableRows}</tbody></table></div></div></section>
    <section><div class="wrap"><h2>${isDe ? "Klauseln zur Pr&uuml;fung" : "Clauses to Review"}</h2><div class="grid">
      <article class="card"><h3>${isDe ? "Rechtswahl" : "Governing law"}</h3><p class="muted">${isDe ? "Landesspezifische Rechtswahl, Gerichtsstand, Sprache der Fassung und Streitbeilegung einsetzen." : "Insert country-specific governing law, venue, document language and dispute-resolution wording."}</p></article>
      <article class="card"><h3>${isDe ? "Daten & Marketing" : "Data & marketing"}</h3><p class="muted">${isDe ? "Datenschutzrollen, Datenschutzhinweise, Auftragsverarbeitung, Marketingeinwilligung und Opt-out-Prozesse pr&uuml;fen." : "Review privacy roles, notices, processing arrangements, marketing consent and opt-out processes."}</p></article>
      <article class="card"><h3>${isDe ? "Produkt & Verkauf" : "Product & sales"}</h3><p class="muted">${isDe ? "Gew&auml;hrleistung, Produkthaftung, Sicherheitsinformationen, Steuern, Import und verbotene Ertragsversprechen lokalisieren." : "Localise warranty, product liability, safety notices, tax, import and prohibited earnings-claim language."}</p></article>
    </div></div></section>
    <section><div class="wrap"><h2>${isDe ? "Rechtsquellen" : "Legal References"}</h2><ul class="muted">${legalReferenceList()}</ul></div></section>
  </main>
  <footer><div class="wrap">${isDe ? "FIXON internationaler Dokumentenentwurf." : "FIXON international document draft."}</div></footer>`;
    fs.writeFileSync(path.join(dir, `${base}.html`), htmlPage({ lang, title: `${title} | FIXON`, body }), "utf8");
  }

  const rows = manifest.map((doc) => {
    const base = slugBase(doc);
    return `<div class="doc-row"><div><strong>${translatedTitle(doc, lang)}</strong><p class="muted">${groupName(doc, lang)}</p></div><a class="btn" href="${base}.html">${isDe ? "Lesen" : "Read"}</a></div>`;
  }).join("\n");
  const body = `
  <header class="top"><div class="wrap nav"><a class="brand" href="../../FIXON_program_partnerski.html">FIXON</a>${languageLinks("docs")}</div></header>
  <main>
    <section class="hero"><div class="wrap"><h1>${isDe ? "Internationale Dokumente" : "International Documents"}</h1><p class="lead">${isDe ? "Deutschsprachige Arbeitsfassungen mit Lokalisierungshinweisen f&uuml;r UK, USA, Kanada, Australien, S&uuml;dafrika, Deutschland, &Ouml;sterreich und die Schweiz." : "English working versions with localisation notes for the UK, USA, Canada, Australia, South Africa, Germany, Austria and Switzerland."}</p><div class="cta-row"><a class="btn" href="${contact.phoneHref}">${isDe ? "Anrufen" : "Call"} ${contact.phoneDisplay}</a><a class="btn alt" href="../../${isDe ? "FIXON_partnerprogramm_de.html" : "FIXON_partner_program_en.html"}">${isDe ? "Programm" : "Programme"}</a></div></div></section>
    <section><div class="wrap"><p class="notice">${isDe ? "Keine finale Rechtsberatung. Diese Fassungen sind f&uuml;r &Uuml;bersetzung, Strukturierung und lokale Pr&uuml;fung vorbereitet." : "Not final legal advice. These versions are prepared for translation, structure and local review."}</p><div class="doc-list">${rows}</div></div></section>
  </main><footer><div class="wrap">FIXON</div></footer>`;
  fs.writeFileSync(path.join(dir, "index.html"), htmlPage({ lang, title: `${isDe ? "Internationale Dokumente" : "International Documents"} | FIXON`, body }), "utf8");
}

function writeProgrammePage(lang) {
  const isDe = lang === "de";
  const file = isDe ? "FIXON_partnerprogramm_de.html" : "FIXON_partner_program_en.html";
  const body = `
  <header class="top"><div class="wrap nav"><a class="brand" href="FIXON_program_partnerski.html">FIXON</a>${languageLinks("programme")}</div></header>
  <main>
    <section class="hero"><div class="wrap"><h1>${isDe ? "Partnerprogramm f&uuml;r H&auml;ndler und Baustoffkan&auml;le" : "Partner Programme for distributors and building-material channels"}</h1><p class="lead">${isDe ? "Professionelle Werkzeuge in den Verkauf aufnehmen, ohne schweren Startbestand und ohne lange Schulungsphase." : "Add professional tools to the sales conversation without heavy starter stock and without a long training phase."}</p><div class="cta-row"><a class="btn" href="${contact.phoneHref}">${isDe ? "Anrufen" : "Call"} ${contact.phoneDisplay}</a><a class="btn alt" href="${isDe ? "dokumenty/de/index.html" : "dokumenty/en/index.html"}">${isDe ? "Dokumente lesen" : "Read documents"}</a></div></div></section>
    <section><div class="wrap"><div class="grid">
      <article class="card"><h3>${isDe ? "Kein schwerer Start" : "No heavy start"}</h3><p class="muted">${isDe ? "Pilot, QR, E-Katalog und Demonstration statt vollem Lageraufbau. Abrechnung erst nach best&auml;tigtem Verkaufszeitraum." : "Pilot, QR, e-catalogue and demonstration instead of building a full stock position. Settlement follows a confirmed sales period."}</p></article>
      <article class="card"><h3>${isDe ? "Einfacher Verkauf" : "Easy sales path"}</h3><p class="muted">${isDe ? "Beim Materialkauf wird der Bedarf nat&uuml;rlich sichtbar; das Zielwerkzeug wird &uuml;ber den E-Katalog gew&auml;hlt." : "Needs appear naturally during the material purchase; the target tool is selected through the e-catalogue."}</p></article>
      <article class="card"><h3>${isDe ? "Wiederkehrender Kunde" : "Returning customer"}</h3><p class="muted">${isDe ? "Ein zufriedener und weniger m&uuml;der Pflasterer kommt schneller f&uuml;r den n&auml;chsten Einkauf zur&uuml;ck." : "A less tired and more satisfied paving contractor returns sooner for the next purchase."}</p></article>
    </div></div></section>
    <section><div class="wrap"><h2>${isDe ? "Kontakt" : "Contact"}</h2><div class="card"><h3>${contact.name}</h3><p class="muted">${isDe ? contact.roleDe : contact.roleEn}<br><a href="${contact.phoneHref}">${contact.phoneDisplay}</a></p></div></div></section>
  </main><footer><div class="wrap">FIXON Tools & Tech</div></footer>`;
  fs.writeFileSync(path.join(root, file), htmlPage({ lang, title: `${isDe ? "FIXON Partnerprogramm" : "FIXON Partner Programme"}`, body }), "utf8");
}

function writeAdLanding(lang) {
  const isPl = lang === "pl";
  const isDe = lang === "de";
  const file = isPl ? "landing-pl.html" : isDe ? "landing-de.html" : "landing-en.html";
  const readHref = isPl ? "FIXON_program_partnerski.html" : isDe ? "FIXON_partnerprogramm_de.html" : "FIXON_partner_program_en.html";
  const title = isPl ? "FIXON Partnerstwo w 60 sekund" : isDe ? "FIXON Partnerschaft in 60 Sekunden" : "FIXON Partnership in 60 Seconds";
  const h1 = isPl ? "Dodaj narz&#x119;dzia do sprzeda&#x17C;y bez ci&#x119;&#x17C;kiego wdro&#x17C;enia" : isDe ? "Werkzeuge verkaufen ohne schweren Start" : "Sell tools without a heavy rollout";
  const lead = isPl ? "Kr&oacute;tka &#x15B;cie&#x17C;ka: telefon, decyzja o pilota&#x17C;u albo przej&#x15B;cie do pe&#x142;nego programu." : isDe ? "Kurzer Weg: Anruf, Pilotentscheidung oder vollst&auml;ndiges Programm lesen." : "One short path: call, choose a pilot or read the full programme.";
  const body = `
  <header class="top"><div class="wrap nav"><a class="brand" href="${readHref}">FIXON</a>${languageLinks("landing")}</div></header>
  <main>
    <section class="hero"><div class="wrap"><h1>${h1}</h1><p class="lead">${lead}</p><div class="cta-row"><a class="btn" href="${contact.phoneHref}">${isPl ? "Zadzwo&#x144;" : isDe ? "Anrufen" : "Call"} ${contact.phoneDisplay}</a><a class="btn alt" href="${readHref}">${isPl ? "Czytaj pe&#x142;ny program" : isDe ? "Vollst&auml;ndiges Programm" : "Read full programme"}</a></div></div></section>
    <section><div class="wrap"><div class="grid">
      <article class="card"><h3>${isPl ? "Bez inwestycji na start" : isDe ? "Kein Startinvestment" : "No upfront stock investment"}</h3><p class="muted">${isPl ? "Start od pilota&#x17C;u, bez kupowania pe&#x142;nego magazynu." : isDe ? "Start mit Pilot, ohne volles Lager zu kaufen." : "Start with a pilot, without buying a full stock position."}</p></article>
      <article class="card"><h3>${isPl ? "E-katalog pomaga sprzedawa&#x107;" : isDe ? "E-Katalog hilft beim Verkauf" : "E-catalogue supports sales"}</h3><p class="muted">${isPl ? "Nie trzeba zna&#x107; ca&#x142;ego asortymentu od pierwszego dnia." : isDe ? "Das Sortiment muss nicht vom ersten Tag an vollst&auml;ndig gelernt werden." : "The sales team does not need to learn the whole assortment on day one."}</p></article>
      <article class="card"><h3>${isPl ? "Kontakt do osoby" : isDe ? "Direkter Kontakt" : "Direct contact"}</h3><p class="muted">${contact.name}<br>${isPl ? contact.rolePl : isDe ? contact.roleDe : contact.roleEn}<br><a href="${contact.phoneHref}">${contact.phoneDisplay}</a></p></article>
    </div></div></section>
  </main><footer><div class="wrap">FIXON Tools & Tech</div></footer>`;
  fs.writeFileSync(path.join(root, file), htmlPage({ lang, title, body }), "utf8");
}

writeDocPages("en");
writeDocPages("de");
writeProgrammePage("en");
writeProgrammePage("de");
writeAdLanding("pl");
writeAdLanding("en");
writeAdLanding("de");
