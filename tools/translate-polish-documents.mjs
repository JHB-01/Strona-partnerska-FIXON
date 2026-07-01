import fs from "node:fs";
import path from "node:path";
import https from "node:https";
import crypto from "node:crypto";
import { pathToFileURL } from "node:url";

const root = "C:/Users/Karolina/Documents/FIXON";
const sourceDir = path.join(root, "dokumenty");
const manifest = JSON.parse(fs.readFileSync(path.join(sourceDir, "manifest.json"), "utf8").replace(/^\uFEFF/, ""));
const targetLanguages = process.argv.includes("--de-only") ? ["de"] : process.argv.includes("--en-only") ? ["en"] : ["en", "de"];
const useNetwork = process.argv.includes("--use-network");
const useLocalModels = process.argv.includes("--local-models");
const localBatchSize = Number(process.argv.find((arg) => arg.startsWith("--batch-size="))?.split("=")[1] || 8);
const cacheDir = path.join(root, ".translation-cache");
const localRuntimeDir = path.join(root, ".translation-runtime");
const localModelCacheDir = path.join(localRuntimeDir, "models");

const languageMeta = {
  en: {
    htmlLang: "en",
    mainHref: "../../FIXON_partner_program_en.html#documents",
    backText: "Back to documents",
    navText: "Document navigation",
    tocText: "Table of contents",
    closeText: "Close",
    metaPrefix: "Translated 1:1 from Polish source",
    downloadTitle: "Download translated templates",
    downloadDescription: "The DOCX file is intended for operational editing, and the PDF file for sending or archiving.",
    docxButton: "Download translated DOCX",
    pdfButton: "Download translated PDF",
    htmlButton: "Download translated HTML",
    indexTitle: "Translated Programme Documents",
    indexLead: "Full structure-preserving translations of the Polish programme documents.",
    read: "Preview",
    programme: "Programme",
  },
  de: {
    htmlLang: "de",
    mainHref: "../../FIXON_partnerprogramm_de.html#documents",
    backText: "Zurück zu den Dokumenten",
    navText: "Dokumentnavigation",
    tocText: "Inhaltsverzeichnis",
    closeText: "Schließen",
    metaPrefix: "1:1 aus der polnischen Quelle übersetzt",
    downloadTitle: "Übersetzte Vorlagen herunterladen",
    downloadDescription: "Die DOCX-Datei dient der operativen Bearbeitung, die PDF-Datei dem Versand oder der Archivierung.",
    docxButton: "Übersetzte DOCX herunterladen",
    pdfButton: "Übersetzte PDF herunterladen",
    htmlButton: "Übersetzte HTML herunterladen",
    indexTitle: "Übersetzte Programmdokumente",
    indexLead: "Vollständige strukturgetreue Übersetzungen der polnischen Programmdokumente.",
    read: "Vorschau",
    programme: "Programm",
  },
};

const titleMap = {
  "program-partnerski-fixon": { en: "FIXON Partner Programme", de: "FIXON Partnerprogramm" },
  "umowa-partnerska-fixon": { en: "FIXON Partner Agreement", de: "FIXON Partnervertrag" },
  "zalacznik-karta-partnera": { en: "Appendix: Partner Card", de: "Anlage: Partnerkarte" },
  "zalacznik-magazyn-startowy": { en: "Appendix: Starter Stock", de: "Anlage: Startlager" },
  "zalacznik-wsparcie-magazynowe": { en: "Appendix: Stock Support", de: "Anlage: Lagerunterstützung" },
  "zalacznik-cennik-katalogowy": { en: "Appendix: Catalogue Price List", de: "Anlage: Katalogpreisliste" },
  "zalacznik-statusy-produktow": { en: "Appendix: Product Statuses", de: "Anlage: Produktstatus" },
  "zalacznik-standardy-ekspozycji": { en: "Appendix: Display Standards", de: "Anlage: Präsentationsstandards" },
  "zalacznik-polityka-marki": { en: "Appendix: FIXON Brand Policy", de: "Anlage: FIXON Markenrichtlinie" },
  "zalacznik-procedura-raportowania": { en: "Appendix: Reporting Procedure", de: "Anlage: Berichtsverfahren" },
  "zalacznik-wzor-raportu-miesiecznego": { en: "Appendix: Monthly Report Template", de: "Anlage: Vorlage Monatsbericht" },
  "zalacznik-wzor-zgloszenia-alarmowego": { en: "Appendix: Urgent Notice Template", de: "Anlage: Vorlage Eilmeldung" },
  "zalacznik-procedura-zwrotu": { en: "Appendix: Product Return Procedure", de: "Anlage: Rückgabeverfahren" },
  "zalacznik-protokol-przekazania": { en: "Appendix: Handover Protocol", de: "Anlage: Übergabeprotokoll" },
  "zalacznik-protokol-inwentaryzacji": { en: "Appendix: Inventory Protocol", de: "Anlage: Inventurprotokoll" },
  "zalacznik-rozbieznosci-magazynowe": { en: "Appendix: Stock Discrepancy Protocol", de: "Anlage: Protokoll zu Lagerabweichungen" },
  "zalacznik-uszkodzenie-utrata": { en: "Appendix: Damage or Loss Protocol", de: "Anlage: Protokoll bei Beschädigung oder Verlust" },
  "zalacznik-produkty-testowe-premierowe": { en: "Appendix: Test and Launch Products", de: "Anlage: Test- und Einführungsprodukte" },
  "zalacznik-karta-uprawnienia-strategicznego": { en: "Appendix: Strategic Entitlement Card", de: "Anlage: Karte für strategische Sonderrechte" },
  "zalacznik-karta-centrum-demonstracyjnego": { en: "Appendix: Demonstration Centre Card", de: "Anlage: Karte Demonstrationszentrum" },
};

const groupMap = {
  en: {
    "Dokument główny": "Main document",
    "Umowa": "Agreement",
    "Start współpracy": "Start of cooperation",
    "Magazyn i dostępność": "Stock and availability",
    "Sprzedaż": "Sales",
    "Ekspozycja i marka": "Display and brand",
    "Operacje": "Operations",
    "Protokoły": "Protocols",
    "Rozwój współpracy": "Growth of cooperation",
  },
  de: {
    "Dokument główny": "Hauptdokument",
    "Umowa": "Vertrag",
    "Start współpracy": "Start der Zusammenarbeit",
    "Magazyn i dostępność": "Lager und Verfügbarkeit",
    "Sprzedaż": "Vertrieb",
    "Ekspozycja i marka": "Präsentation und Marke",
    "Operacje": "Abläufe",
    "Protokoły": "Protokolle",
    "Rozwój współpracy": "Ausbau der Zusammenarbeit",
  },
};

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function slugBase(doc) {
  return path.basename(doc.Slug, ".html");
}

function translatedTitle(doc, lang) {
  return titleMap[slugBase(doc)]?.[lang] || doc.Title;
}

function loadCache(lang) {
  ensureDir(cacheDir);
  const file = path.join(cacheDir, `${lang}.json`);
  if (!fs.existsSync(file)) return {};
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function saveCache(lang, cache) {
  ensureDir(cacheDir);
  fs.writeFileSync(path.join(cacheDir, `${lang}.json`), JSON.stringify(cache, null, 2), "utf8");
}

function cacheKey(text) {
  return crypto.createHash("sha1").update(text).digest("hex");
}

function decodeEntities(input) {
  const named = {
    amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " ",
    oacute: "ó", Oacute: "Ó", aacute: "á", cacute: "ć", eacute: "é", nacute: "ń", sacute: "ś", zacute: "ź",
    rsquo: "'", lsquo: "'", rdquo: '"', ldquo: '"', ndash: "-", mdash: "-", hellip: "...",
  };
  return String(input)
    .replace(/&([a-zA-Z]+);/g, (_, name) => named[name] ?? `&${name};`)
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#([0-9]+);/g, (_, dec) => String.fromCodePoint(parseInt(dec, 10)));
}

function encodeEntities(input) {
  return String(input)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function preserveWhitespace(original, translated) {
  const prefix = original.match(/^\s*/)?.[0] || "";
  const suffix = original.match(/\s*$/)?.[0] || "";
  return `${prefix}${encodeEntities(translated.trim())}${suffix}`;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function requestJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { "User-Agent": "Mozilla/5.0 FIXON translation preparation" } }, (res) => {
      let data = "";
      res.setEncoding("utf8");
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0, 200)}`));
          return;
        }
        try {
          resolve(JSON.parse(data));
        } catch (error) {
          reject(error);
        }
      });
    }).on("error", reject);
  });
}

const localState = {
  module: null,
  plEn: null,
  enDe: null,
};

async function loadLocalTransformers() {
  if (!localState.module) {
    const moduleUrl = pathToFileURL(path.join(localRuntimeDir, "node_modules", "@xenova", "transformers", "src", "transformers.js")).href;
    localState.module = await import(moduleUrl);
    localState.module.env.cacheDir = localModelCacheDir;
    localState.module.env.allowRemoteModels = false;
  }
  return localState.module;
}

async function getLocalPipeline(name) {
  const { pipeline } = await loadLocalTransformers();
  if (name === "pl-en") {
    if (!localState.plEn) localState.plEn = await pipeline("translation", "Xenova/opus-mt-pl-en");
    return localState.plEn;
  }
  if (name === "en-de") {
    if (!localState.enDe) localState.enDe = await pipeline("translation", "Xenova/opus-mt-en-de");
    return localState.enDe;
  }
  throw new Error(`Unsupported local pipeline: ${name}`);
}

function splitForLocalTranslation(text, maxLen = 360) {
  const normalized = String(text).replace(/\s+/g, " ").trim();
  if (normalized.length <= maxLen) return [normalized];
  const sentences = normalized.split(/(?<=[.!?;:])\s+/);
  const chunks = [];
  let current = "";
  function pushCurrent() {
    if (current.trim()) chunks.push(current.trim());
    current = "";
  }
  for (const sentence of sentences) {
    if ((current + " " + sentence).trim().length <= maxLen) {
      current = (current + " " + sentence).trim();
      continue;
    }
    pushCurrent();
    if (sentence.length <= maxLen) {
      current = sentence;
      continue;
    }
    const words = sentence.split(/\s+/);
    for (const word of words) {
      if ((current + " " + word).trim().length > maxLen) pushCurrent();
      current = (current + " " + word).trim();
    }
  }
  pushCurrent();
  return chunks.length ? chunks : [normalized];
}

function extractTranslationText(item) {
  if (Array.isArray(item)) return extractTranslationText(item[0]);
  return item?.translation_text || item?.generated_text || "";
}

async function runLocalPipeline(modelName, texts) {
  const model = await getLocalPipeline(modelName);
  const out = [];
  for (let i = 0; i < texts.length; i += localBatchSize) {
    const batch = texts.slice(i, i + localBatchSize);
    const translated = await model(batch, { max_new_tokens: 256 });
    for (const item of translated) out.push(extractTranslationText(item));
  }
  return out;
}

async function translatePolishToEnglishTexts(texts) {
  const chunked = texts.map((text) => splitForLocalTranslation(text, 360));
  const flat = chunked.flat();
  const translatedFlat = await runLocalPipeline("pl-en", flat);
  const result = [];
  let index = 0;
  for (const chunks of chunked) {
    result.push(chunks.map(() => translatedFlat[index++] || "").join(" ").replace(/\s+/g, " ").trim());
  }
  return result;
}

async function translateEnglishToGermanTexts(texts) {
  const chunked = texts.map((text) => splitForLocalTranslation(text, 420));
  const flat = chunked.flat();
  const translatedFlat = await runLocalPipeline("en-de", flat);
  const result = [];
  let index = 0;
  for (const chunks of chunked) {
    result.push(chunks.map(() => translatedFlat[index++] || "").join(" ").replace(/\s+/g, " ").trim());
  }
  return result;
}

async function translateManyLocal(texts, lang, cache) {
  const normalizedTexts = [...new Set(texts.map((text) => decodeEntities(text).replace(/\s+/g, " ").trim()).filter(Boolean))];
  const missing = normalizedTexts.filter((text) => !cache[cacheKey(`${lang}\n${text}`)]);
  if (!missing.length) return;

  console.log(`${lang}: local translation ${missing.length} text blocks`);

  if (lang === "en") {
    for (let i = 0; i < missing.length; i += localBatchSize * 10) {
      const batch = missing.slice(i, i + localBatchSize * 10);
      const translated = await translatePolishToEnglishTexts(batch);
      batch.forEach((text, index) => {
        cache[cacheKey(`en\n${text}`)] = postProcess(translated[index], "en");
      });
      saveCache("en", cache);
      console.log(`en: cached ${Math.min(i + batch.length, missing.length)}/${missing.length}`);
    }
    return;
  }

  if (lang === "de") {
    const enCache = loadCache("en");
    const english = [];
    const needsEnglish = [];
    for (const text of missing) {
      const key = cacheKey(`en\n${text}`);
      if (enCache[key]) {
        english.push(enCache[key]);
      } else {
        english.push(null);
        needsEnglish.push(text);
      }
    }
    if (needsEnglish.length) {
      const translatedEnglish = await translatePolishToEnglishTexts(needsEnglish);
      let cursor = 0;
      missing.forEach((text, index) => {
        if (english[index]) return;
        const value = postProcess(translatedEnglish[cursor++], "en");
        enCache[cacheKey(`en\n${text}`)] = value;
        english[index] = value;
      });
      saveCache("en", enCache);
    }
    for (let i = 0; i < missing.length; i += localBatchSize * 10) {
      const textBatch = missing.slice(i, i + localBatchSize * 10);
      const englishBatch = english.slice(i, i + localBatchSize * 10);
      const translated = await translateEnglishToGermanTexts(englishBatch);
      textBatch.forEach((text, index) => {
        cache[cacheKey(`de\n${text}`)] = postProcess(translated[index], "de");
      });
      saveCache("de", cache);
      console.log(`de: cached ${Math.min(i + textBatch.length, missing.length)}/${missing.length}`);
    }
  }
}

async function translateOne(text, lang, cache) {
  const normalized = decodeEntities(text).replace(/\s+/g, " ").trim();
  if (!normalized) return normalized;
  const key = cacheKey(`${lang}\n${normalized}`);
  if (cache[key]) return cache[key];
  if (useLocalModels) {
    await translateManyLocal([normalized], lang, cache);
    return cache[key] || normalized;
  }
  if (!useNetwork) {
    throw new Error("Translation disabled. Run with --local-models for offline translation or --use-network after approval.");
  }
  const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=pl&tl=${encodeURIComponent(lang)}&dt=t&q=${encodeURIComponent(normalized)}`;
  const data = await requestJson(url);
  const translated = (data?.[0] || []).map((part) => part?.[0] || "").join("").trim();
  cache[key] = postProcess(translated, lang);
  await sleep(120);
  return cache[key];
}

function postProcess(text, lang) {
  let out = String(text || "");
  out = out.replace(/\bFixon\b/g, "FIXON");
  out = out.replace(/\bTools\s*&\s*Tech\b/g, "Tools & Tech");
  if (lang === "en") {
    out = out.replace(/\bPartner Program\b/g, "Partner Programme");
    out = out.replace(/\bProgram Partner FIXON\b/g, "FIXON Partner Programme");
  }
  if (lang === "de") {
    out = out.replace(/\bPartnerprogramm FIXON\b/g, "FIXON Partnerprogramm");
  }
  return out;
}

function splitHtml(html) {
  return html.split(/(<[^>]+>)/g);
}

async function translateVisibleTextInHtml(html, lang, cache) {
  const parts = splitHtml(html);
  let skip = null;
  const output = [];
  for (const part of parts) {
    if (!part) continue;
    if (part.startsWith("<")) {
      const lower = part.toLowerCase();
      if (lower.startsWith("<style")) skip = "style";
      if (lower.startsWith("<script")) skip = "script";
      output.push(part);
      if (skip === "style" && lower.startsWith("</style")) skip = null;
      if (skip === "script" && lower.startsWith("</script")) skip = null;
      continue;
    }
    if (skip || !part.trim()) {
      output.push(part);
      continue;
    }
    const decoded = decodeEntities(part);
    if (!/\p{L}/u.test(decoded)) {
      output.push(part);
      continue;
    }
    const translated = await translateOne(decoded, lang, cache);
    output.push(preserveWhitespace(part, translated));
  }
  return output.join("");
}

function rewriteTranslatedHtml(html, doc, lang) {
  const meta = languageMeta[lang];
  const base = slugBase(doc);
  let out = html;
  out = out.replace('<html lang="pl">', `<html lang="${meta.htmlLang}">`);
  out = out.replace(/url\("\.\.\/assets\//g, 'url("../../assets/');
  out = out.replace(/href="\.\.\/FIXON_program_partnerski\.html#dokumenty"/g, `href="${meta.mainHref}"`);
  out = out.replace(/href="docx\/([^"]+\.docx)"/g, `href="docx/$1"`);
  out = out.replace(/href="pdf\/([^"]+\.pdf)"/g, `href="pdf/$1"`);
  out = out.replace(/<title>[\s\S]*?<\/title>/, `<title>${encodeEntities(translatedTitle(doc, lang))} | FIXON</title>`);
  out = out.replace(/<h1>[\s\S]*?<\/h1>/, `<h1>${encodeEntities(translatedTitle(doc, lang))}</h1>`);
  out = out.replace(/<strong>[^<]*<\/strong>\s*<a href="#section-/g, `<strong>${encodeEntities(meta.navText)}</strong>\n        <a href="#section-`);
  out = out.replace(/aria-label="[^"]*"/g, `aria-label="${encodeEntities(meta.closeText)}"`);
  out = out.replace(/data-doc-action="toggle-nav"[^>]*>[\s\S]*?<\/button>/, (match) => match.replace(/>[^<]*<\/button>$/, `>${encodeEntities(meta.tocText)}</button>`));
  out = out.replace(/<div class="download-panel">[\s\S]*?<\/div>\s*<\/section>/, `<div class="download-panel">
  <div>
    <strong>${encodeEntities(meta.downloadTitle)}</strong>
    <p>${encodeEntities(meta.downloadDescription)}</p>
  </div>
  <div class="download-actions">
    <a class="download-button" href="docx/${base}.docx" download>${encodeEntities(meta.docxButton)}</a>
    <a class="download-button secondary" href="pdf/${base}.pdf" download>${encodeEntities(meta.pdfButton)}</a>
    <a class="download-button secondary" href="download/${base}.html" download>${encodeEntities(meta.htmlButton)}</a>
  </div>
</div>
      </section>`);
  const langSwitch = `<div class="doc-tools"><a class="download-button secondary" href="../${base}.html">PL</a><a class="download-button secondary" href="../en/${base}.html">EN</a><a class="download-button secondary" href="../de/${base}.html">DE</a></div>`;
  out = out.replace(/<div class="meta">([\s\S]*?)<\/div>/, `<div class="meta">${encodeEntities(groupMap[lang][doc.Group] || doc.Group)}<br>${encodeEntities(meta.metaPrefix)}</div>`);
  out = out.replace(/(<div class="doc-tools">[\s\S]*?<\/div>)/, `$1\n        ${langSwitch}`);
  return out;
}

function stripTags(input) {
  return decodeEntities(String(input).replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]+>/g, " ")).replace(/\s+/g, " ").trim();
}

function extractBlocks(html) {
  const body = html
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<aside[\s\S]*?<\/aside>/gi, "")
    .replace(/<header[\s\S]*?<\/header>/gi, "")
    .replace(/<footer[\s\S]*?<\/footer>/gi, "");
  const blocks = [];
  const re = /<(h1|h2|h3|p|li|div class="chapter-kicker"|table)\b[^>]*>([\s\S]*?)<\/(?:h1|h2|h3|p|li|div|table)>/gi;
  for (const m of body.matchAll(re)) {
    const tag = m[1].toLowerCase();
    const inner = m[2];
    if (tag === "table") {
      const rows = [];
      for (const row of inner.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)) {
        const cells = [];
        for (const cell of row[1].matchAll(/<t[hd][^>]*>([\s\S]*?)<\/t[hd]>/gi)) cells.push(stripTags(cell[1]));
        if (cells.length) rows.push(cells);
      }
      if (rows.length) blocks.push({ type: "table", rows });
    } else {
      const text = stripTags(inner);
      if (text) blocks.push({ type: tag.includes("chapter") ? "h2" : tag, text });
    }
  }
  return blocks;
}

function xmlEscape(input) {
  return String(input).replace(/[<>&"']/g, (c) => ({ "<": "&lt;", ">": "&gt;", "&": "&amp;", '"': "&quot;", "'": "&apos;" }[c]));
}

function crc32(buf) {
  let table = crc32.table;
  if (!table) {
    table = crc32.table = new Uint32Array(256);
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
      table[n] = c >>> 0;
    }
  }
  let c = 0xffffffff;
  for (const b of buf) c = table[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function dosDateTime(date = new Date()) {
  const time = (date.getHours() << 11) | (date.getMinutes() << 5) | Math.floor(date.getSeconds() / 2);
  const dosDate = ((date.getFullYear() - 1980) << 9) | ((date.getMonth() + 1) << 5) | date.getDate();
  return { time, date: dosDate };
}

function writeZip(entries, outPath) {
  const chunks = [];
  const central = [];
  let offset = 0;
  const { time, date } = dosDateTime();
  for (const entry of entries) {
    const name = Buffer.from(entry.name, "utf8");
    const data = Buffer.isBuffer(entry.data) ? entry.data : Buffer.from(entry.data, "utf8");
    const crc = crc32(data);
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4);
    local.writeUInt16LE(0, 6);
    local.writeUInt16LE(0, 8);
    local.writeUInt16LE(time, 10);
    local.writeUInt16LE(date, 12);
    local.writeUInt32LE(crc, 14);
    local.writeUInt32LE(data.length, 18);
    local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(name.length, 26);
    chunks.push(local, name, data);
    const cent = Buffer.alloc(46);
    cent.writeUInt32LE(0x02014b50, 0);
    cent.writeUInt16LE(20, 4);
    cent.writeUInt16LE(20, 6);
    cent.writeUInt16LE(0, 8);
    cent.writeUInt16LE(0, 10);
    cent.writeUInt16LE(time, 12);
    cent.writeUInt16LE(date, 14);
    cent.writeUInt32LE(crc, 16);
    cent.writeUInt32LE(data.length, 20);
    cent.writeUInt32LE(data.length, 24);
    cent.writeUInt16LE(name.length, 28);
    cent.writeUInt32LE(offset, 42);
    central.push(cent, name);
    offset += local.length + name.length + data.length;
  }
  const centralStart = offset;
  const centralBuf = Buffer.concat(central);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(entries.length, 8);
  end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(centralBuf.length, 12);
  end.writeUInt32LE(centralStart, 16);
  fs.writeFileSync(outPath, Buffer.concat([...chunks, centralBuf, end]));
}

function paragraphXml(text, style = "") {
  const styleXml = style ? `<w:pPr><w:pStyle w:val="${style}"/></w:pPr>` : "";
  return `<w:p>${styleXml}<w:r><w:t xml:space="preserve">${xmlEscape(text)}</w:t></w:r></w:p>`;
}

function tableXml(rows) {
  return `<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/><w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/><w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/></w:tblBorders></w:tblPr>${rows.map((row) => `<w:tr>${row.map((cell) => `<w:tc><w:tcPr><w:tcW w:w="2400" w:type="dxa"/></w:tcPr>${paragraphXml(cell)}</w:tc>`).join("")}</w:tr>`).join("")}</w:tbl>`;
}

function writeDocxFromHtml(html, outPath) {
  const blocks = extractBlocks(html);
  const body = blocks.map((block) => {
    if (block.type === "h1") return paragraphXml(block.text, "Heading1");
    if (block.type === "h2" || block.type === "h3") return paragraphXml(block.text, "Heading2");
    if (block.type === "table") return tableXml(block.rows);
    return paragraphXml(block.text);
  }).join("");
  const documentXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>${body}<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/></w:sectPr></w:body></w:document>`;
  const stylesXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:sz w:val="22"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:color w:val="124A2E"/><w:sz w:val="38"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:color w:val="06271B"/><w:sz w:val="28"/></w:rPr></w:style></w:styles>`;
  writeZip([
    { name: "[Content_Types].xml", data: `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>` },
    { name: "_rels/.rels", data: `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>` },
    { name: "word/_rels/document.xml.rels", data: `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>` },
    { name: "word/document.xml", data: documentXml },
    { name: "word/styles.xml", data: stylesXml },
  ], outPath);
}

function pdfText(input) {
  return String(input)
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/[–—]/g, "-")
    .replace(/[^\x09\x0a\x0d\x20-\xff]/g, "?");
}

function pdfEscape(input) {
  return pdfText(input).replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)");
}

function wrapLine(text, max = 94) {
  const words = pdfText(text).split(/\s+/).filter(Boolean);
  const lines = [];
  let line = "";
  for (const word of words) {
    if ((line + " " + word).trim().length > max) {
      if (line) lines.push(line);
      line = word;
    } else {
      line = (line + " " + word).trim();
    }
  }
  if (line) lines.push(line);
  return lines;
}

function writePdfFromHtml(html, outPath) {
  const blocks = extractBlocks(html);
  const pages = [];
  let lines = [];
  let y = 790;
  function newPage() {
    if (lines.length) pages.push(lines.join("\n"));
    lines = [];
    y = 790;
  }
  function addLine(text, size = 10.5, leading = 14) {
    if (y < 60) newPage();
    lines.push(`BT /F1 ${size} Tf 50 ${y} Td (${pdfEscape(text)}) Tj ET`);
    y -= leading;
  }
  for (const block of blocks) {
    if (block.type === "table") {
      y -= 5;
      for (const row of block.rows) for (const line of wrapLine(row.join(" | "), 105)) addLine(line, 8.5, 11);
      y -= 8;
      continue;
    }
    const size = block.type === "h1" ? 20 : block.type === "h2" || block.type === "h3" ? 14 : 10;
    if (block.type !== "p" && block.type !== "li") y -= 6;
    for (const line of wrapLine(block.text, block.type === "h1" ? 58 : 94)) addLine(line, size, block.type === "p" ? 13 : 17);
    if (block.type !== "p" && block.type !== "li") y -= 3;
  }
  newPage();
  const objects = ["<< /Type /Catalog /Pages 2 0 R >>"];
  objects.push(`<< /Type /Pages /Kids [${pages.map((_, i) => `${3 + i * 2} 0 R`).join(" ")}] /Count ${pages.length} >>`);
  pages.forEach((content, i) => {
    const pageId = 3 + i * 2;
    const contentId = pageId + 1;
    const stream = Buffer.from(content, "latin1");
    objects.push(`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 ${3 + pages.length * 2} 0 R >> >> /Contents ${contentId} 0 R >>`);
    objects.push(Buffer.concat([Buffer.from(`<< /Length ${stream.length} >>\nstream\n`, "latin1"), stream, Buffer.from("\nendstream", "latin1")]));
  });
  objects.push("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>");
  const chunks = [Buffer.from("%PDF-1.4\n%FIXON\n", "latin1")];
  const offsets = [0];
  for (let i = 0; i < objects.length; i++) {
    offsets.push(Buffer.concat(chunks).length);
    chunks.push(Buffer.from(`${i + 1} 0 obj\n`, "latin1"));
    chunks.push(Buffer.isBuffer(objects[i]) ? objects[i] : Buffer.from(objects[i], "latin1"));
    chunks.push(Buffer.from("\nendobj\n", "latin1"));
  }
  const body = Buffer.concat(chunks);
  let xref = `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (const offset of offsets.slice(1)) xref += `${String(offset).padStart(10, "0")} 00000 n \n`;
  fs.writeFileSync(outPath, Buffer.concat([body, Buffer.from(`trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${body.length}\n%%EOF`, "latin1")]));
}

async function translateDocument(doc, lang, cache) {
  const base = slugBase(doc);
  const source = fs.readFileSync(path.join(sourceDir, `${base}.html`), "utf8");
  const translated = rewriteTranslatedHtml(await translateVisibleTextInHtml(source, lang, cache), doc, lang);
  const targetDir = path.join(sourceDir, lang);
  const htmlPath = path.join(targetDir, `${base}.html`);
  const downloadDir = path.join(targetDir, "download");
  const docxDir = path.join(targetDir, "docx");
  const pdfDir = path.join(targetDir, "pdf");
  ensureDir(downloadDir);
  ensureDir(docxDir);
  ensureDir(pdfDir);
  fs.writeFileSync(htmlPath, translated, "utf8");
  fs.writeFileSync(path.join(downloadDir, `${base}.html`), translated, "utf8");
  writeDocxFromHtml(translated, path.join(docxDir, `${base}.docx`));
  writePdfFromHtml(translated, path.join(pdfDir, `${base}.pdf`));
  return { slug: base, chars: translated.length };
}

function collectTranslatableTextsInHtml(html) {
  const parts = splitHtml(html);
  let skip = null;
  const texts = [];
  for (const part of parts) {
    if (!part) continue;
    if (part.startsWith("<")) {
      const lower = part.toLowerCase();
      if (lower.startsWith("<style")) skip = "style";
      if (lower.startsWith("<script")) skip = "script";
      if (skip === "style" && lower.startsWith("</style")) skip = null;
      if (skip === "script" && lower.startsWith("</script")) skip = null;
      continue;
    }
    if (skip || !part.trim()) continue;
    const decoded = decodeEntities(part).replace(/\s+/g, " ").trim();
    if (!decoded || !/\p{L}/u.test(decoded)) continue;
    texts.push(decoded);
  }
  return texts;
}

function collectAllTranslatableTexts() {
  const texts = new Set();
  for (const doc of manifest) {
    const base = slugBase(doc);
    const source = fs.readFileSync(path.join(sourceDir, `${base}.html`), "utf8");
    for (const text of collectTranslatableTextsInHtml(source)) texts.add(text);
  }
  return [...texts];
}

function writeIndex(lang) {
  const meta = languageMeta[lang];
  const rows = manifest.map((doc) => {
    const base = slugBase(doc);
    return `<div class="doc-row"><div><strong>${encodeEntities(translatedTitle(doc, lang))}</strong><p>${encodeEntities(groupMap[lang][doc.Group] || doc.Group)}</p></div><div class="download-actions"><a class="download-button" href="${base}.html">${encodeEntities(meta.read)}</a><a class="download-button secondary" href="pdf/${base}.pdf" download>PDF</a><a class="download-button secondary" href="docx/${base}.docx" download>DOCX</a><a class="download-button secondary" href="download/${base}.html" download>HTML</a></div></div>`;
  }).join("\n");
  const html = `<!doctype html>
<html lang="${meta.htmlLang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${encodeEntities(meta.indexTitle)} | FIXON</title>
  <style>
    @import url("https://fonts.googleapis.com/css2?family=League+Spartan:wght@400;500;600;700;800;900&display=swap");
    :root{--green:#124A2E;--dark:#06271b;--ink:#151a18;--muted:#63706a;--line:#d9e0db;--bg:#f2f4ef;--soft:#e8f0eb;--paper:#fff}
    *{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:"League Spartan",Arial,sans-serif}a{color:inherit}.wrap{width:min(1180px,calc(100% - 28px));margin:0 auto}header{position:sticky;top:0;z-index:10;border-bottom:1px solid var(--line);background:rgba(255,255,255,.94);backdrop-filter:blur(12px)}.bar{min-height:68px;display:flex;align-items:center;justify-content:space-between;gap:12px}.back,.download-button{display:inline-flex;align-items:center;justify-content:center;min-height:40px;padding:10px 13px;border-radius:4px;border:1px solid var(--green);background:var(--green);color:#fff;font-weight:900;text-decoration:none}.download-button.secondary{background:#fff;color:var(--green)}main{padding:42px 0 70px}.hero{padding:34px;border-radius:8px;background:linear-gradient(135deg,var(--dark),var(--green));color:#fff}.hero h1{margin:0 0 12px;font-size:clamp(34px,6vw,64px);line-height:.98;text-transform:uppercase}.hero p{max-width:760px;margin:0;color:rgba(255,255,255,.78);font-size:18px;line-height:1.5}.doc-list{display:grid;gap:12px;margin-top:22px}.doc-row{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:14px;align-items:center;padding:18px;border:1px solid var(--line);border-radius:8px;background:#fff}.doc-row strong{font-size:19px;color:var(--dark)}.doc-row p{margin:5px 0 0;color:var(--muted)}.download-actions{display:flex;flex-wrap:wrap;gap:8px}@media(max-width:760px){.bar,.doc-row{align-items:flex-start;flex-direction:column;display:flex}.download-actions,.download-button{width:100%}}
  </style>
</head>
<body>
  <header><div class="wrap bar"><a class="back" href="${meta.mainHref}">${encodeEntities(meta.programme)}</a><div>${meta.htmlLang.toUpperCase()}</div></div></header>
  <main class="wrap"><section class="hero"><h1>${encodeEntities(meta.indexTitle)}</h1><p>${encodeEntities(meta.indexLead)}</p></section><section class="doc-list">${rows}</section></main>
</body>
</html>`;
  fs.writeFileSync(path.join(sourceDir, lang, "index.html"), html, "utf8");
}

async function main() {
  const allTexts = useLocalModels ? collectAllTranslatableTexts() : [];
  for (const lang of targetLanguages) {
    const cache = loadCache(lang);
    if (useLocalModels) await translateManyLocal(allTexts, lang, cache);
    const results = [];
    for (const doc of manifest) {
      results.push(await translateDocument(doc, lang, cache));
      if (results.length % 3 === 0) saveCache(lang, cache);
      console.log(`${lang}: ${results[results.length - 1].slug}`);
    }
    writeIndex(lang);
    saveCache(lang, cache);
    console.log(`${lang}: completed ${results.length} documents`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
