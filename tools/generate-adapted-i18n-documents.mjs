import fs from "node:fs";
import path from "node:path";

const root = "C:/Users/Karolina/Documents/FIXON";
const manifest = JSON.parse(fs.readFileSync(path.join(root, "dokumenty", "manifest.json"), "utf8").replace(/^\uFEFF/, ""));

const contact = {
  name: "Karolina Tarasenko",
  phone: "+48 531 448 893",
  phoneHref: "tel:+48531448893",
  email: "heorhiibronnikov.commercial@gmail.com",
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
    "Magazyn i dostępność": "Lager und Verf&uuml;gbarkeit",
    "Sprzedaż": "Vertrieb",
    "Ekspozycja i marka": "Pr&auml;sentation und Marke",
    "Operacje": "Abl&auml;ufe",
    "Protokoły": "Protokolle",
    "Rozwój współpracy": "Ausbau der Zusammenarbeit",
  },
};

const ui = {
  en: {
    lang: "en",
    documents: "Documents",
    programme: "Programme",
    preview: "Adapted translated preview",
    downloadPdf: "Download adapted PDF",
    downloadDocx: "Download adapted DOCX",
    downloadHtml: "Download adapted HTML",
    sourcePolish: "Polish source",
    legalNotice: "Working legal/commercial draft. This translated version is prepared for reading, download and local counsel review before use in the selected country.",
    indexLead: "Downloadable adapted working drafts in English, prepared for partner onboarding and legal localisation.",
    countryTitle: "Country localisation matrix",
    clauseTitle: "Local clauses before signature",
    footer: "FIXON international adapted document draft.",
    read: "Read",
    download: "Download",
    role: "Partner Network Development Specialist",
  },
  de: {
    lang: "de",
    documents: "Dokumente",
    programme: "Programm",
    preview: "Adaptierte &uuml;bersetzte Vorschau",
    downloadPdf: "Adaptierte PDF herunterladen",
    downloadDocx: "Adaptierte DOCX herunterladen",
    downloadHtml: "Adaptierte HTML herunterladen",
    sourcePolish: "Polnische Quelle",
    legalNotice: "Juristischer und kommerzieller Arbeitsentwurf. Diese &uuml;bersetzte Fassung ist zum Lesen, Herunterladen und zur Pr&uuml;fung durch lokale Rechtsberatung vorbereitet.",
    indexLead: "Herunterladbare adaptierte Arbeitsfassungen auf Deutsch f&uuml;r Partner-Onboarding und rechtliche Lokalisierung.",
    countryTitle: "Lokalisierung nach Land",
    clauseTitle: "Lokale Klauseln vor Unterschrift",
    footer: "FIXON internationaler adaptierter Dokumentenentwurf.",
    read: "Lesen",
    download: "Download",
    role: "Spezialistin f&uuml;r den Ausbau des Partnernetzwerks",
  },
};

const countryRows = {
  en: [
    ["UK", "Use UK governing law and jurisdiction where applicable; review UK GDPR, PECR, product liability and B2B sale terms."],
    ["USA", "Use state-specific law and venue; review business opportunity/franchise triggers, earnings claims, warranty, sales tax and privacy rules."],
    ["Canada", "Use province-specific law; review CASL, privacy, bilingual requirements where applicable, warranty, tax and product safety."],
    ["Australia", "Review Australian Consumer Law, unfair contract terms, privacy, product safety, warranty, import and tax clauses."],
    ["South Africa", "Review POPIA, electronic communications, Consumer Protection Act exposure, product liability, import, tax and dispute wording."],
    ["Germany", "Use German-law drafting; review BGB/HGB, GDPR/BDSG, UWG marketing rules, warranty, retention of title and standard-term controls."],
    ["Austria", "Use Austrian-law drafting; review ABGB/UGB, GDPR/DSG, UWG marketing rules, warranty, retention of title and standard-term controls."],
    ["Switzerland", "Use Swiss-law drafting; review the Code of Obligations, revised FADP, competition rules, warranty and cross-border data transfers."],
  ],
  de: [
    ["UK", "UK-Rechtswahl und Zust&auml;ndigkeit einsetzen; UK GDPR, PECR, Produkthaftung und B2B-Verkaufsbedingungen pr&uuml;fen."],
    ["USA", "Bundesstaatliches Recht und Gerichtsstand einsetzen; Business-Opportunity-/Franchise-Risiken, Ertragsaussagen, Gew&auml;hrleistung, Sales Tax und Datenschutz pr&uuml;fen."],
    ["Kanada", "Provinzspezifisches Recht einsetzen; CASL, Datenschutz, m&ouml;gliche Zweisprachigkeit, Gew&auml;hrleistung, Steuern und Produktsicherheit pr&uuml;fen."],
    ["Australien", "Australian Consumer Law, unfair contract terms, Datenschutz, Produktsicherheit, Gew&auml;hrleistung, Import und Steuern pr&uuml;fen."],
    ["S&uuml;dafrika", "POPIA, elektronische Kommunikation, Consumer-Protection-Risiken, Produkthaftung, Import, Steuern und Streitbeilegung pr&uuml;fen."],
    ["Deutschland", "Deutsches Recht verwenden; BGB/HGB, DSGVO/BDSG, UWG, Gew&auml;hrleistung, Eigentumsvorbehalt und AGB-Kontrolle pr&uuml;fen."],
    ["&Ouml;sterreich", "&Ouml;sterreichisches Recht verwenden; ABGB/UGB, DSGVO/DSG, UWG, Gew&auml;hrleistung, Eigentumsvorbehalt und AGB-Kontrolle pr&uuml;fen."],
    ["Schweiz", "Schweizer Recht verwenden; Obligationenrecht, revidiertes DSG, Wettbewerbsrecht, Gew&auml;hrleistung und Daten&uuml;bermittlung pr&uuml;fen."],
  ],
};

const detail = {
  en: {
    "program-partnerski-fixon": {
      purpose: "Full commercial programme for partner onboarding, sales, display, stock support, reporting and monthly settlement.",
      sections: [
        ["1. Programme Objective", ["The FIXON Partner Programme enables material producers, distributors, building-material yards, points of sale and tool-rental channels to add professional paving and construction tools to their commercial offer without a mandatory full stock investment at launch.", "The Partner uses FIXON tools as a practical extension of the material sale. The programme is designed to make the contractor's work easier, reduce fatigue and increase the probability that the customer returns for further purchases."]],
        ["2. Start Model", ["The recommended launch model is a pilot based on demonstration, QR codes, the e-catalogue and a narrow selection of products matched to the Partner's customer profile.", "No upfront purchase of a full starter warehouse is required unless the parties agree otherwise in a local order, pilot card or stock-support appendix."]],
        ["3. Sales Method", ["The easiest moment to identify customer needs is during the purchase of materials. The salesperson asks about material type, load, crew size, job-site conditions and repeated pain points.", "The e-catalogue helps select the target tool quickly, so the sales team does not need to learn the full assortment before starting."]],
        ["4. Settlement", ["Sales are settled after a confirmed sales period. The standard rhythm is monthly, based on the report, confirmed sales data and agreed stock movements.", "Any country-specific tax, invoice, consumer, reseller or reporting requirements must be adapted locally before use."]],
      ],
      table: [["Programme level", "Commercial meaning"], ["Pilot Partner", "QR, e-catalogue, demonstration and selected test products"], ["Active Partner", "Monthly reporting, agreed stock logic and regular product availability"], ["Strategic Partner", "Individual entitlements, demonstration centre or extended network cooperation"]],
    },
    "umowa-partnerska-fixon": {
      purpose: "Partner agreement template defining commercial cooperation, responsibilities, reporting, stock support, confidentiality, brand use and termination.",
      sections: [
        ["1. Parties and Status", ["This agreement is concluded between FIXON and the Partner identified in the Partner Card. The Partner remains an independent business and is not authorised to act as agent, employee or legal representative of FIXON unless expressly agreed in writing.", "The agreement does not create a franchise, business opportunity, employment relationship or exclusive distribution right unless the local version expressly states otherwise."]],
        ["2. Commercial Cooperation", ["The Partner may promote, demonstrate and sell FIXON products through the agreed channel. The scope of products, stock, prices, discount rules and display materials is defined in the appendices.", "No guaranteed income, margin or sales volume is promised. Any forecast is indicative and must be reviewed under local law before use."]],
        ["3. Reporting and Settlement", ["The Partner provides monthly reports covering sales, stock, returns, urgent events and customer feedback. Settlement takes place after the relevant sales period has been confirmed.", "The parties adapt tax, invoice, withholding, resale and consumer disclosure wording to the selected jurisdiction."]],
        ["4. Brand, Data and Termination", ["The Partner uses the FIXON brand only according to the Brand Policy and approved materials. Personal data and marketing communication must follow the applicable privacy and electronic communication laws.", "Termination, notice periods, dispute resolution and post-termination duties must be localised before signature."]],
      ],
      table: [["Clause area", "Localisation before signature"], ["Governing law", "Insert country/state/province/canton-specific law and venue"], ["Data processing", "Define controller/processor roles and marketing consent"], ["Product liability", "Localise warranty, warnings, returns and liability limits"], ["Business opportunity risk", "Review especially for the USA and other regulated markets"]],
    },
    "zalacznik-karta-partnera": {
      purpose: "Partner data sheet and cooperation profile used to launch or update the relationship.",
      sections: [["1. Partner Identification", ["This card records the Partner's legal name, registration number, tax number, address, operating contacts and preferred language of cooperation."]], ["2. Cooperation Profile", ["The Partner selects the relevant channel: material producer, distribution network, yard, point of sale, tool rental or another B2B channel."]], ["3. Confirmation", ["The card confirms the starting model, pilot assumptions, documents received and persons authorised to exchange reports."]]],
      table: [["Field", "Value to complete"], ["Legal name", "[Partner legal name]"], ["Country / region", "[Market and jurisdiction]"], ["Channel type", "[Producer / distributor / yard / retail / rental]"], ["Contact person", "[Name, phone, email]"], ["Pilot scope", "[QR / e-catalogue / demo / starter products]"]],
    },
    "zalacznik-magazyn-startowy": {
      purpose: "Starter stock proposal for a pilot or launch phase, without forcing full warehouse investment.",
      sections: [["1. Principle", ["Starter stock is introduced only when justified by the Partner's channel, customer demand and agreed pilot scope. A full warehouse purchase is not a condition of joining the programme."]], ["2. Product Selection", ["Products are selected according to customer needs discovered during material purchases and supported by the e-catalogue."]], ["3. Review", ["Starter stock is reviewed after the first confirmed sales period and may be expanded, reduced or replaced."]]],
      table: [["Product group", "Starter logic"], ["Demonstration tools", "Used to explain value and build trust"], ["High-frequency tools", "Selected when customer demand is visible"], ["Test products", "Used for controlled market validation"], ["Replacement / service elements", "Held only if commercially justified"]],
    },
    "zalacznik-wsparcie-magazynowe": {
      purpose: "Stock-support rules for availability, replenishment and partner growth after the launch phase.",
      sections: [["1. Support Scope", ["Stock support helps maintain availability of products that show real demand. It is not an automatic obligation to finance unlimited inventory."]], ["2. Replenishment", ["Replenishment is based on monthly reports, stock status, lead time and agreed product priorities."]], ["3. Ownership and Risk", ["Ownership, risk, insurance and loss responsibility must be defined in the local version or order documents."]]],
      table: [["Status", "Meaning"], ["Pilot stock", "Limited quantity for validation"], ["Supported stock", "Products maintained due to recurring demand"], ["Special order", "Product ordered for a specific customer or project"], ["Paused", "Product temporarily removed from active availability"]],
    },
    "zalacznik-cennik-katalogowy": {
      purpose: "Catalogue price-list appendix for sales conversations, discount logic and price updates.",
      sections: [["1. Price Use", ["Catalogue prices support sales communication and partner planning. Final prices may depend on currency, tax, delivery, market, discounts and local law."]], ["2. Changes", ["FIXON may update catalogue prices according to the agreement. The Partner should use the latest approved price list in customer conversations."]], ["3. Local Requirements", ["Tax display, consumer pricing, resale price restrictions and currency disclosure must be adapted locally."]]],
      table: [["Price element", "Description"], ["Catalogue net price", "Reference price before tax unless local law requires otherwise"], ["Partner discount", "Commercial discount agreed with the Partner"], ["Recommended display", "May be used only where lawful"], ["Delivery / tax", "Shown separately where required"]],
    },
    "zalacznik-statusy-produktow": {
      purpose: "Definitions of product availability and sales statuses used in the catalogue and reports.",
      sections: [["1. Purpose", ["Product statuses prevent unclear promises and help the salesperson explain availability responsibly."]], ["2. Communication", ["The Partner may communicate only the current approved status from the e-catalogue or FIXON update."]], ["3. Updates", ["Status changes should be reflected in the monthly report and urgent notice process when they affect confirmed orders."]]],
      table: [["Status", "Sales meaning"], ["Available", "Product can be offered under current terms"], ["Order 7 / 14", "Product expected within the indicated ordering period"], ["On request", "Requires confirmation before customer commitment"], ["Paused", "Do not actively offer until updated"], ["Discontinued", "Do not sell unless replacement or remaining stock is approved"]],
    },
    "zalacznik-standardy-ekspozycji": {
      purpose: "Display, shelf, QR and demonstration standards for partner locations.",
      sections: [["1. Display Objective", ["The display should make the tool's practical use clear within seconds. It should not be decorative only."]], ["2. QR and E-catalogue", ["QR codes must lead to the current e-catalogue or approved product page. They should be placed close to the displayed tool or material context."]], ["3. Demonstration Readiness", ["If demonstration is promised, the tool must be clean, safe and ready to show."]]],
      table: [["Area", "Standard"], ["Shelf / display", "Clear product name, use case and QR"], ["Demo tool", "Safe, complete and presentable"], ["Printed materials", "Only approved brand and sales claims"], ["Updates", "Old claims and old prices removed promptly"]],
    },
    "zalacznik-polityka-marki": {
      purpose: "Brand-policy appendix controlling FIXON name, visuals, claims, sales language and safe communication.",
      sections: [["1. Brand Use", ["The Partner may use the FIXON name, logo and product materials only in the approved commercial context."]], ["2. Claims", ["Communication should focus on practical benefits: easier handling, faster work, better repeatability and reduced fatigue. Avoid guaranteed earnings, medical claims or unsupported performance promises."]], ["3. Local Marketing Law", ["Advertising, testimonials, influencer use, electronic marketing and comparative claims must be reviewed for the selected market."]]],
      table: [["Allowed", "Avoid"], ["Practical use-case language", "Guaranteed profit or sales promises"], ["Approved product images", "Unapproved AI or misleading images"], ["QR to e-catalogue", "Outdated files or wrong prices"], ["Clear partner status", "Implying agency or employment"]],
    },
    "zalacznik-procedura-raportowania": {
      purpose: "Monthly reporting procedure for sales, stock, settlement, customer feedback and product decisions.",
      sections: [["1. Reporting Rhythm", ["The standard reporting rhythm is monthly unless the parties agree a shorter pilot rhythm."]], ["2. Report Content", ["Reports include sales, stock, pending orders, returns, customer questions, demonstration activity and urgent events."]], ["3. Settlement Link", ["Settlement and stock decisions are based on confirmed reports and agreed supporting documents."]]],
      table: [["Report field", "Purpose"], ["Sales by product", "Settlement and demand analysis"], ["Stock status", "Replenishment decisions"], ["Customer feedback", "Product and sales improvement"], ["Exceptions", "Urgent response and risk control"]],
    },
    "zalacznik-wzor-raportu-miesiecznego": {
      purpose: "Monthly report template used by the Partner to confirm sales and operational status.",
      sections: [["1. Reporting Period", ["The Partner completes the month, location, responsible person and channel covered by the report."]], ["2. Sales and Stock", ["Sales, stock levels, orders and product statuses should be completed in the table below."]], ["3. Confirmation", ["The report is confirmed by the authorised person and used for monthly settlement."]]],
      table: [["Product", "Opening stock", "Sold", "Returned", "Closing stock", "Comments"], ["[Product]", "[Qty]", "[Qty]", "[Qty]", "[Qty]", "[Notes]"], ["[Product]", "[Qty]", "[Qty]", "[Qty]", "[Qty]", "[Notes]"]],
    },
    "zalacznik-wzor-zgloszenia-alarmowego": {
      purpose: "Urgent notice template for stock, quality, order or operational events requiring quick reaction.",
      sections: [["1. When to Use", ["Use this notice when a situation may affect customer delivery, safety, brand communication, stock accuracy or settlement."]], ["2. Required Data", ["The notice should include product, location, date, contact person, description, photos if relevant and requested action."]], ["3. Response", ["FIXON confirms the next action and records the case for the monthly report."]]],
      table: [["Field", "To complete"], ["Urgency level", "[High / Medium / Low]"], ["Product / order", "[Details]"], ["Issue", "[Description]"], ["Requested action", "[Replacement / confirmation / return / support]"]],
    },
    "zalacznik-procedura-zwrotu": {
      purpose: "Return procedure for products, including approval, condition check, documentation and settlement impact.",
      sections: [["1. Return Approval", ["Returns require prior confirmation unless local mandatory law gives the customer or Partner a non-excludable right."]], ["2. Condition", ["Returned products should be identified, counted and checked for use, damage, missing parts and packaging condition."]], ["3. Settlement", ["The settlement effect of a return depends on the approved reason, time, condition and local law."]]],
      table: [["Return reason", "Required action"], ["Wrong product", "Confirm order and replacement"], ["Damage", "Use damage/loss protocol"], ["Customer withdrawal", "Apply local law and agreed policy"], ["Stock correction", "Connect with inventory protocol"]],
    },
    "zalacznik-protokol-przekazania": {
      purpose: "Handover protocol for products, displays, demonstration tools or marketing materials.",
      sections: [["1. Handover Scope", ["The protocol confirms what was delivered, to whom, when and in what condition."]], ["2. Responsibility", ["The receiving party confirms responsibility for storage, demonstration use and return if applicable."]], ["3. Evidence", ["Photos, serial numbers or package lists may be attached when useful."]]],
      table: [["Item", "Quantity", "Condition", "Responsibility"], ["[Product/material]", "[Qty]", "[New / used / demo]", "[Partner / FIXON]"]],
    },
    "zalacznik-protokol-inwentaryzacji": {
      purpose: "Inventory protocol for periodic confirmation of stock, display and demonstration products.",
      sections: [["1. Inventory Date", ["The protocol records the date, location and persons responsible for the count."]], ["2. Count", ["Actual stock is compared with the report and previous handover documents."]], ["3. Differences", ["Differences are transferred to the stock-discrepancy protocol if not explained immediately."]]],
      table: [["Product", "Expected", "Actual", "Difference", "Comment"], ["[Product]", "[Qty]", "[Qty]", "[+/-]", "[Explanation]"]],
    },
    "zalacznik-rozbieznosci-magazynowe": {
      purpose: "Stock-discrepancy protocol for differences between expected and confirmed stock.",
      sections: [["1. Identification", ["The discrepancy is linked to the relevant inventory, report, handover or return document."]], ["2. Explanation", ["The Partner provides available explanation and supporting evidence."]], ["3. Decision", ["FIXON and the Partner agree correction, replacement, settlement adjustment or further investigation."]]],
      table: [["Product", "Expected", "Confirmed", "Difference", "Decision"], ["[Product]", "[Qty]", "[Qty]", "[+/-]", "[Correction / investigation]"]],
    },
    "zalacznik-uszkodzenie-utrata": {
      purpose: "Damage or loss protocol for products, tools, displays or demonstration elements.",
      sections: [["1. Event Description", ["The protocol records when and how the product was damaged or lost and who discovered the event."]], ["2. Evidence", ["Photos, customer information, courier records or internal notes should be attached when available."]], ["3. Responsibility", ["Responsibility and settlement effect must be decided according to the agreement and local mandatory law."]]],
      table: [["Field", "Value"], ["Product", "[Name / SKU]"], ["Event date", "[Date]"], ["Condition", "[Damaged / missing / incomplete]"], ["Proposed action", "[Repair / replacement / write-off / investigation]"]],
    },
    "zalacznik-produkty-testowe-premierowe": {
      purpose: "Rules for test, demonstration and launch products introduced before regular stock decisions.",
      sections: [["1. Test Purpose", ["Test products are used to validate customer demand, demonstrate use cases and collect feedback before wider launch."]], ["2. Communication", ["The Partner must clearly distinguish test, demo and launch products from standard permanent offer where relevant."]], ["3. Feedback", ["Feedback is collected through the monthly report or a dedicated launch form."]]],
      table: [["Product type", "Rules"], ["Test", "Limited use and feedback required"], ["Launch", "Promoted for a defined period"], ["Demo", "May not be sold unless approved"], ["Customer trial", "Requires clear return and responsibility terms"]],
    },
    "zalacznik-karta-uprawnienia-strategicznego": {
      purpose: "Strategic entitlement card for individually granted partner benefits or extended rights.",
      sections: [["1. Entitlement", ["The card identifies the special entitlement granted to the Partner and the reason for it."]], ["2. Conditions", ["Entitlements may depend on reporting, display quality, sales activity, geographic scope or demonstration readiness."]], ["3. Review", ["Entitlements are reviewed periodically and may be changed according to the agreement."]]],
      table: [["Entitlement", "Scope", "Validity", "Condition"], ["[Example]", "[Products / territory]", "[Date]", "[Reporting / display / sales]"]],
    },
    "zalacznik-karta-centrum-demonstracyjnego": {
      purpose: "Demonstration centre card defining requirements, tools, benefits and obligations of a demo location.",
      sections: [["1. Demonstration Centre Role", ["A demonstration centre allows customers to see, test or understand selected FIXON tools in a practical environment."]], ["2. Requirements", ["The centre must maintain safe, complete and current demonstration tools with QR access to product information."]], ["3. Benefits", ["Benefits may include launch priority, training materials, extended display support or strategic status when agreed."]]],
      table: [["Area", "Requirement"], ["Demo tools", "Complete, safe and presentable"], ["Staff", "Able to show basic use and open e-catalogue"], ["Materials", "Current QR, catalogue and approved claims"], ["Reporting", "Demo activity included in monthly report"]],
    },
  },
};

detail.de = Object.fromEntries(Object.entries(detail.en).map(([slug, spec]) => {
  const deCommon = {
    purpose: {
      "program-partnerski-fixon": "Vollst&auml;ndiges kommerzielles Programm f&uuml;r Partner-Onboarding, Verkauf, Pr&auml;sentation, Lagerunterst&uuml;tzung, Reporting und monatliche Abrechnung.",
      "umowa-partnerska-fixon": "Partnervertragsvorlage f&uuml;r kommerzielle Zusammenarbeit, Verantwortlichkeiten, Reporting, Lagerunterst&uuml;tzung, Vertraulichkeit, Markennutzung und Beendigung.",
    }[slug] || spec.purpose.replace("Working", "Arbeits").replace("Partner", "Partner"),
  };
  const genericSections = [
    ["1. Zweck des Dokuments", ["Diese adaptierte Fassung beschreibt die praktische Nutzung des Dokuments im FIXON Partnerprogramm. Sie ersetzt nicht die lokale rechtliche Pr&uuml;fung.", "Das Dokument ist f&uuml;r Lesen, Download, interne Abstimmung und Vorbereitung einer lokalen Landesfassung vorgesehen."]],
    ["2. Operativer Anwendungsbereich", ["Die Regelung gilt f&uuml;r den vereinbarten Partnerkanal, die im Programm best&auml;tigten Produkte und die im jeweiligen Markt zul&auml;ssige Kommunikation.", "Der Start kann ohne Pflicht zum Aufbau eines vollen Lagers erfolgen; QR, E-Katalog, Demonstration und ein Pilotumfang reichen f&uuml;r den Beginn."]],
    ["3. Pflichten und Nachweise", ["Der Partner dokumentiert Verkaufs-, Lager-, R&uuml;ckgabe- und Ausnahmeereignisse nachvollziehbar. FIXON stellt freigegebene Produkt-, Marken- und Kataloginformationen bereit.", "Monatliche Daten bilden die Grundlage f&uuml;r Abrechnung, Nachversorgung und Weiterentwicklung der Zusammenarbeit."]],
    ["4. Lokale Anpassung", ["Vor Unterschrift oder Versand an einen Partner m&uuml;ssen Rechtswahl, Gerichtsstand, Datenschutz, Marketing, Gew&auml;hrleistung, Produkthaftung, Steuer- und Importregeln an das konkrete Land angepasst werden."]],
  ];
  const programSections = [
    ["1. Ziel des Programms", ["Das FIXON Partnerprogramm erm&ouml;glicht Herstellern, H&auml;ndlern, Baustofflagern, Verkaufsstellen und Werkzeugverleihkan&auml;len, professionelle Werkzeuge ohne Pflichtinvestition in ein volles Startlager in den Verkauf aufzunehmen.", "Der Partner nutzt FIXON Werkzeuge als praktische Erweiterung des Materialverkaufs. Das Programm soll Arbeit erleichtern, Erm&uuml;dung senken und die R&uuml;ckkehr des Kunden f&ouml;rdern."]],
    ["2. Startmodell", ["Empfohlen ist ein Pilot mit Demonstration, QR-Codes, E-Katalog und einer schmalen Produktauswahl passend zum Kundenprofil des Partners.", "Ein voller Lageraufbau ist keine Teilnahmebedingung, sofern die Parteien nichts anderes in einer lokalen Bestellung, Pilotkarte oder Lageranlage vereinbaren."]],
    ["3. Verkaufsmethode", ["Der beste Moment zur Bedarfserkennung ist der Materialkauf. Der Verk&auml;ufer fragt nach Material, Last, Teamgr&ouml;&szlig;e, Baustellensituation und wiederkehrenden Problemen.", "Der E-Katalog f&uuml;hrt schnell zum Zielwerkzeug, ohne dass das Team das gesamte Sortiment vor dem Start auswendig lernen muss."]],
    ["4. Abrechnung", ["Verk&auml;ufe werden nach einem best&auml;tigten Verkaufszeitraum abgerechnet. Der Standardrhythmus ist monatlich und basiert auf Bericht, best&auml;tigten Verkaufsdaten und vereinbarten Lagerbewegungen."]],
  ];
  const agreementSections = [
    ["1. Parteien und Status", ["Der Vertrag wird zwischen FIXON und dem in der Partnerkarte benannten Partner geschlossen. Der Partner bleibt selbst&auml;ndiges Unternehmen und ist ohne ausdr&uuml;ckliche schriftliche Zustimmung kein Vertreter, Arbeitnehmer oder Rechtsagent von FIXON.", "Der Vertrag begr&uuml;ndet kein Franchise, keine Business Opportunity, kein Arbeitsverh&auml;ltnis und kein exklusives Vertriebsrecht, sofern die lokale Fassung dies nicht ausdr&uuml;cklich vorsieht."]],
    ["2. Kommerzielle Zusammenarbeit", ["Der Partner darf FIXON Produkte &uuml;ber den vereinbarten Kanal bewerben, demonstrieren und verkaufen. Produkte, Lager, Preise, Rabatte und Displaymaterial werden in Anlagen geregelt.", "Es werden keine garantierten Ertr&auml;ge, Margen oder Verkaufsvolumina zugesagt. Prognosen sind nur indikativ und lokal rechtlich zu pr&uuml;fen."]],
    ["3. Reporting und Abrechnung", ["Der Partner liefert monatliche Berichte zu Verkauf, Lager, R&uuml;ckgaben, Ausnahmeereignissen und Kundenfeedback. Die Abrechnung erfolgt nach Best&auml;tigung des relevanten Zeitraums."]],
    ["4. Marke, Daten und Beendigung", ["Die Marke FIXON wird nur gem&auml;&szlig; Markenrichtlinie und freigegebenen Materialien genutzt. Datenschutz und elektronische Kommunikation m&uuml;ssen dem jeweiligen Markt entsprechen."]],
  ];
  return [slug, {
    purpose: deCommon.purpose,
    sections: slug === "program-partnerski-fixon" ? programSections : slug === "umowa-partnerska-fixon" ? agreementSections : genericSections,
    table: spec.table.map((row, rowIndex) => row.map((cell) => {
      if (rowIndex === 0) return cell.replace("Field", "Feld").replace("Value", "Wert").replace("Purpose", "Zweck").replace("Rules", "Regeln").replace("Status", "Status");
      return cell.replace("Product", "Produkt").replace("Partner", "Partner").replace("Available", "Verf&uuml;gbar").replace("Monthly", "Monatlich").replace("Stock", "Lager").replace("Report", "Bericht");
    })),
  }];
}));

function slugBase(doc) {
  return path.basename(doc.Slug, ".html");
}

function titleOf(doc, lang) {
  return titleBySlug[slugBase(doc)]?.[lang] || doc.Title;
}

function groupOf(doc, lang) {
  return groupNames[lang][doc.Group] || doc.Group;
}

function specOf(doc, lang) {
  const slug = slugBase(doc);
  return detail[lang][slug] || detail[lang]["zalacznik-karta-partnera"];
}

function decodeEntities(input) {
  const named = {
    amp: "&", lt: "<", gt: ">", quot: '"', apos: "'",
    nbsp: " ", uuml: "ü", Uuml: "Ü", auml: "ä", Auml: "Ä", ouml: "ö", Ouml: "Ö",
    szlig: "ß", eacute: "é", ndash: "-", mdash: "-", hellip: "...",
  };
  return String(input)
    .replace(/&([a-zA-Z]+);/g, (_, name) => named[name] ?? `&${name};`)
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#([0-9]+);/g, (_, dec) => String.fromCodePoint(parseInt(dec, 10)));
}

function stripHtml(input) {
  return decodeEntities(String(input).replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]+>/g, "")).replace(/\s+\n/g, "\n").trim();
}

function xmlEscape(input) {
  return stripHtml(input).replace(/[<>&"']/g, (c) => ({ "<": "&lt;", ">": "&gt;", "&": "&amp;", '"': "&quot;", "'": "&apos;" }[c]));
}

function pdfText(input) {
  return stripHtml(input)
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/[–—]/g, "-")
    .replace(/[^\x09\x0a\x0d\x20-\xff]/g, "?");
}

function htmlCss() {
  return `
    @import url("https://fonts.googleapis.com/css2?family=League+Spartan:wght@400;500;600;700;800;900&display=swap");
    :root{--green:#124A2E;--dark:#06271b;--ink:#141917;--muted:#5b6762;--line:#d7ded8;--bg:#eef1ec;--soft:#e8f0eb;--paper:#fff;--yellow:#d4b15a;--shadow:0 18px 44px rgba(15,22,18,.10)}
    *{box-sizing:border-box}body{margin:0;background:linear-gradient(180deg,#fafaf5 0%,var(--bg) 62%,#fff 100%);color:var(--ink);font-family:"League Spartan",Arial,sans-serif}a{color:inherit}.wrap{width:min(1120px,calc(100% - 32px));margin:0 auto}.top{position:sticky;top:0;z-index:20;background:rgba(255,255,255,.94);border-bottom:1px solid var(--line);backdrop-filter:blur(12px)}.nav{min-height:68px;display:flex;align-items:center;justify-content:space-between;gap:16px}.brand{font-weight:900;text-transform:uppercase;text-decoration:none;color:var(--green);font-size:26px}.langs{display:flex;gap:6px;flex-wrap:wrap}.langs a{padding:8px 10px;border:1px solid var(--line);border-radius:4px;text-decoration:none;font-weight:800;color:var(--green);background:#fff}.hero{padding:58px 0 34px;background:linear-gradient(135deg,var(--dark),var(--green));color:#fff}.hero h1{max-width:940px;margin:0 0 12px;font-size:clamp(38px,6vw,70px);line-height:.96;text-transform:uppercase}.lead{max-width:820px;color:rgba(255,255,255,.84);font-size:21px;line-height:1.42}.btn{display:inline-flex;align-items:center;justify-content:center;min-height:46px;padding:12px 15px;border-radius:4px;background:var(--green);border:1px solid var(--green);color:#fff;font-weight:900;text-decoration:none}.hero .btn{background:#fff;color:var(--dark);border-color:#fff}.btn.alt{background:transparent;color:#fff;border-color:rgba(255,255,255,.62)}.actions{display:flex;flex-wrap:wrap;gap:10px;margin-top:22px}.notice{padding:16px;border-left:5px solid var(--yellow);background:#fff7df;font-weight:800}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px}.card,.document{padding:20px;border:1px solid var(--line);border-radius:8px;background:#fff;box-shadow:var(--shadow)}section{padding:36px 0}h2{margin:0 0 12px;font-size:clamp(28px,4vw,46px);line-height:1;text-transform:uppercase}h3{margin:22px 0 8px;font-size:24px;color:var(--dark)}p,li{line-height:1.56}.muted{color:var(--muted)}.table-scroll{overflow:auto;border:1px solid var(--line);border-radius:8px;background:#fff;margin:14px 0}table{width:100%;border-collapse:collapse;min-width:720px}th,td{padding:11px;border:1px solid var(--line);text-align:left;vertical-align:top;line-height:1.45}th{background:var(--soft);color:var(--dark)}.document-title{border-bottom:2px solid var(--green);padding-bottom:14px;margin-bottom:18px}.document-title strong{display:block;color:var(--green);text-transform:uppercase}.download-list{display:flex;flex-wrap:wrap;gap:10px}.download-list .btn{background:#fff;color:var(--green);border-color:var(--line)}footer{padding:28px 0;border-top:1px solid var(--line);background:#fff;color:var(--muted)}@media(max-width:780px){.nav{align-items:flex-start;flex-direction:column;padding:12px 0}.grid{grid-template-columns:1fr}.btn{width:100%}}
    @media print{.top,.hero .actions,.download-list{display:none}.hero{background:#fff;color:#000;padding:20px 0}.lead{color:#333}.document{box-shadow:none;border:0}.wrap{width:100%}body{background:#fff}}
  `;
}

function renderTable(rows) {
  return `<div class="table-scroll"><table>${rows.map((row, index) => `<tr>${row.map((cell) => `<${index === 0 ? "th" : "td"}>${cell}</${index === 0 ? "th" : "td"}>`).join("")}</tr>`).join("")}</table></div>`;
}

function renderDocumentBody(doc, lang) {
  const spec = specOf(doc, lang);
  const t = ui[lang];
  const sections = spec.sections.map(([heading, paragraphs]) => `<h3>${heading}</h3>${paragraphs.map((p) => `<p>${p}</p>`).join("")}`).join("");
  const matrix = renderTable([[lang === "de" ? "Land" : "Market", lang === "de" ? "Anpassung" : "Adaptation"], ...countryRows[lang]]);
  const clauseRows = lang === "de"
    ? [["Bereich", "Vor Nutzung zu pr&uuml;fen"], ["Rechtswahl", "Land, Gerichtsstand, Sprache und Streitbeilegung"], ["Datenschutz", "Rollen, Hinweise, Einwilligungen und Daten&uuml;bermittlung"], ["Produkt & Verkauf", "Gew&auml;hrleistung, Haftung, Sicherheit, Steuern und Import"], ["Marketing", "Elektronische Kommunikation, Aussagen, Testimonials und Preisangaben"]]
    : [["Area", "To review before use"], ["Governing law", "Country, venue, language and dispute resolution"], ["Privacy", "Roles, notices, consent and data transfers"], ["Product & sales", "Warranty, liability, safety, tax and import"], ["Marketing", "Electronic communication, claims, testimonials and pricing displays"]];
  return `
    <article class="document">
      <div class="document-title"><strong>FIXON Tools & Tech</strong><h2>${titleOf(doc, lang)}</h2><p class="muted">${spec.purpose}</p></div>
      <p class="notice">${t.legalNotice}</p>
      ${sections}
      <h3>${t.countryTitle}</h3>
      ${matrix}
      <h3>${t.clauseTitle}</h3>
      ${renderTable(clauseRows)}
      <h3>${lang === "de" ? "Kontakt und Version" : "Contact and version"}</h3>
      <p>${contact.name}, ${t.role}, ${contact.phone}, ${contact.email}</p>
      <p>${lang === "de" ? "Status: adaptierte Arbeitsfassung zur lokalen Pr&uuml;fung." : "Status: adapted working draft for local review."}</p>
    </article>`;
}

function buildPlainBlocks(doc, lang) {
  const spec = specOf(doc, lang);
  const blocks = [
    { type: "h1", text: stripHtml(titleOf(doc, lang)) },
    { type: "p", text: stripHtml(spec.purpose) },
    { type: "p", text: stripHtml(ui[lang].legalNotice) },
  ];
  for (const [heading, paragraphs] of spec.sections) {
    blocks.push({ type: "h2", text: stripHtml(heading) });
    for (const p of paragraphs) blocks.push({ type: "p", text: stripHtml(p) });
  }
  blocks.push({ type: "h2", text: stripHtml(ui[lang].countryTitle) });
  blocks.push({ type: "table", rows: [[lang === "de" ? "Land" : "Market", lang === "de" ? "Anpassung" : "Adaptation"], ...countryRows[lang]].map((row) => row.map(stripHtml)) });
  blocks.push({ type: "h2", text: stripHtml(ui[lang].clauseTitle) });
  const clauseRows = lang === "de"
    ? [["Bereich", "Vor Nutzung zu pruefen"], ["Rechtswahl", "Land, Gerichtsstand, Sprache und Streitbeilegung"], ["Datenschutz", "Rollen, Hinweise, Einwilligungen und Datenuebermittlung"], ["Produkt & Verkauf", "Gewaehrleistung, Haftung, Sicherheit, Steuern und Import"], ["Marketing", "Elektronische Kommunikation, Aussagen, Testimonials und Preisangaben"]]
    : [["Area", "To review before use"], ["Governing law", "Country, venue, language and dispute resolution"], ["Privacy", "Roles, notices, consent and data transfers"], ["Product & sales", "Warranty, liability, safety, tax and import"], ["Marketing", "Electronic communication, claims, testimonials and pricing displays"]];
  blocks.push({ type: "table", rows: clauseRows.map((row) => row.map(stripHtml)) });
  if (spec.table) {
    blocks.push({ type: "h2", text: lang === "de" ? "Dokumenttabelle" : "Document table" });
    blocks.push({ type: "table", rows: spec.table.map((row) => row.map(stripHtml)) });
  }
  blocks.push({ type: "p", text: `${stripHtml(contact.name)}, ${stripHtml(ui[lang].role)}, ${contact.phone}, ${contact.email}` });
  return blocks;
}

function pageHtml({ lang, title, body }) {
  return `<!doctype html>
<html lang="${lang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <style>${htmlCss()}</style>
</head>
<body>${body}</body>
</html>`;
}

function writeHtmlDownload(doc, lang, outPath) {
  const body = `<main><section><div class="wrap">${renderDocumentBody(doc, lang)}</div></section></main>`;
  fs.writeFileSync(outPath, pageHtml({ lang, title: `${titleOf(doc, lang)} | FIXON`, body }), "utf8");
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
    cent.writeUInt32LE(0, 38);
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

function writeDocx(doc, lang, outPath) {
  const blocks = buildPlainBlocks(doc, lang);
  const body = blocks.map((block) => {
    if (block.type === "h1") return paragraphXml(block.text, "Heading1");
    if (block.type === "h2") return paragraphXml(block.text, "Heading2");
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

function wrapPdfLine(text, max = 88) {
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

function pdfEscape(s) {
  return pdfText(s).replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)");
}

function writePdf(doc, lang, outPath) {
  const blocks = buildPlainBlocks(doc, lang);
  const pages = [];
  let lines = [];
  let y = 790;
  function newPage() {
    if (lines.length) pages.push(lines.join("\n"));
    lines = [];
    y = 790;
  }
  function addLine(text, size = 11, leading = 15) {
    if (y < 60) newPage();
    lines.push(`BT /F1 ${size} Tf 50 ${y} Td (${pdfEscape(text)}) Tj ET`);
    y -= leading;
  }
  for (const block of blocks) {
    if (block.type === "table") {
      y -= 6;
      for (const row of block.rows) {
        for (const line of wrapPdfLine(row.join(" | "), 100)) addLine(line, 9, 12);
      }
      y -= 8;
      continue;
    }
    const size = block.type === "h1" ? 21 : block.type === "h2" ? 15 : 10.5;
    const lead = block.type === "p" ? 14 : 19;
    if (block.type !== "p") y -= 6;
    for (const line of wrapPdfLine(block.text, block.type === "h1" ? 58 : 88)) addLine(line, size, lead);
    if (block.type !== "p") y -= 4;
  }
  newPage();
  const objects = [];
  objects.push("<< /Type /Catalog /Pages 2 0 R >>");
  objects.push(`<< /Type /Pages /Kids [${pages.map((_, i) => `${3 + i * 2} 0 R`).join(" ")}] /Count ${pages.length} >>`);
  pages.forEach((content, i) => {
    const pageId = 3 + i * 2;
    const contentId = pageId + 1;
    const stream = Buffer.from(content, "latin1");
    objects.push(`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 ${3 + pages.length * 2} 0 R >> >> /Contents ${contentId} 0 R >>`);
    objects.push(Buffer.concat([Buffer.from(`<< /Length ${stream.length} >>\nstream\n`, "latin1"), stream, Buffer.from("\nendstream", "latin1")]));
  });
  objects.push("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>");
  const buffers = [Buffer.from("%PDF-1.4\n%FIXON\n", "latin1")];
  const offsets = [0];
  objects.forEach((obj, i) => {
    offsets.push(Buffer.concat(buffers).length);
    buffers.push(Buffer.from(`${i + 1} 0 obj\n`, "latin1"));
    buffers.push(Buffer.isBuffer(obj) ? obj : Buffer.from(obj, "latin1"));
    buffers.push(Buffer.from("\nendobj\n", "latin1"));
  });
  const body = Buffer.concat(buffers);
  let xref = `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  offsets.slice(1).forEach((off) => { xref += `${String(off).padStart(10, "0")} 00000 n \n`; });
  const trailer = `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${body.length}\n%%EOF`;
  fs.writeFileSync(outPath, Buffer.concat([body, Buffer.from(xref + trailer, "latin1")]));
}

function writeDocPage(doc, lang) {
  const t = ui[lang];
  const base = slugBase(doc);
  const dir = path.join(root, "dokumenty", lang);
  const downloadDir = path.join(dir, "download");
  const pdfDir = path.join(dir, "pdf");
  const docxDir = path.join(dir, "docx");
  for (const d of [downloadDir, pdfDir, docxDir]) fs.mkdirSync(d, { recursive: true });
  const htmlDownload = `download/${base}.html`;
  const pdfDownload = `pdf/${base}.pdf`;
  const docxDownload = `docx/${base}.docx`;
  writeHtmlDownload(doc, lang, path.join(dir, htmlDownload));
  writeDocx(doc, lang, path.join(dir, docxDownload));
  writePdf(doc, lang, path.join(dir, pdfDownload));
  const body = `
  <header class="top"><div class="wrap nav"><a class="brand" href="../../FIXON_program_partnerski.html">FIXON</a><div class="langs"><a href="../${base}.html">PL</a><a href="../en/${base}.html">EN</a><a href="../de/${base}.html">DE</a></div></div></header>
  <main>
    <section class="hero"><div class="wrap"><h1>${titleOf(doc, lang)}</h1><p class="lead">${specOf(doc, lang).purpose}</p><div class="actions"><a class="btn" href="${pdfDownload}" download>${t.downloadPdf}</a><a class="btn alt" href="${docxDownload}" download>${t.downloadDocx}</a><a class="btn alt" href="${htmlDownload}" download>${t.downloadHtml}</a></div></div></section>
    <section><div class="wrap">
      <div class="grid">
        <article class="card"><h3>${t.documents}</h3><p class="muted">${groupOf(doc, lang)}</p></article>
        <article class="card"><h3>${lang === "de" ? "Status" : "Status"}</h3><p class="muted">${t.legalNotice}</p></article>
        <article class="card"><h3>FIXON</h3><p class="muted">${contact.name}<br>${t.role}<br><a href="${contact.phoneHref}">${contact.phone}</a></p></article>
      </div>
      <div class="download-list" style="margin-top:16px"><a class="btn" href="${pdfDownload}" download>${t.downloadPdf}</a><a class="btn" href="${docxDownload}" download>${t.downloadDocx}</a><a class="btn" href="${htmlDownload}" download>${t.downloadHtml}</a><a class="btn" href="../${base}.html">${t.sourcePolish}</a></div>
    </div></section>
    <section><div class="wrap"><h2>${t.preview}</h2>${renderDocumentBody(doc, lang)}</div></section>
  </main><footer><div class="wrap">${t.footer}</div></footer>`;
  fs.writeFileSync(path.join(dir, `${base}.html`), pageHtml({ lang, title: `${titleOf(doc, lang)} | FIXON`, body }), "utf8");
}

function writeIndex(lang) {
  const t = ui[lang];
  const dir = path.join(root, "dokumenty", lang);
  const rows = manifest.map((doc) => {
    const base = slugBase(doc);
    return `<div class="doc-row"><div><strong>${titleOf(doc, lang)}</strong><p>${groupOf(doc, lang)} - ${specOf(doc, lang).purpose}</p></div><div class="actions"><a class="btn" href="${base}.html">${t.read}</a><a class="btn" href="pdf/${base}.pdf" download>PDF</a><a class="btn" href="docx/${base}.docx" download>DOCX</a><a class="btn" href="download/${base}.html" download>HTML</a></div></div>`;
  }).join("\n");
  const body = `
  <header class="top"><div class="wrap nav"><a class="brand" href="../../FIXON_program_partnerski.html">FIXON</a><div class="langs"><a href="../../FIXON_program_partnerski.html">PL</a><a href="../en/index.html">EN</a><a href="../de/index.html">DE</a></div></div></header>
  <main>
    <section class="hero"><div class="wrap"><h1>${lang === "de" ? "Adaptierte Dokumente" : "Adapted Documents"}</h1><p class="lead">${t.indexLead}</p><div class="actions"><a class="btn" href="../../${lang === "de" ? "FIXON_partnerprogramm_de.html" : "FIXON_partner_program_en.html"}">${t.programme}</a></div></div></section>
    <section><div class="wrap"><p class="notice">${t.legalNotice}</p><div class="doc-list">${rows}</div></div></section>
  </main><footer><div class="wrap">${t.footer}</div></footer>`;
  fs.writeFileSync(path.join(dir, "index.html"), pageHtml({ lang, title: `${t.documents} | FIXON`, body }), "utf8");
}

for (const lang of ["en", "de"]) {
  for (const doc of manifest) writeDocPage(doc, lang);
  writeIndex(lang);
}
