import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const localeDir = path.resolve("docs/app-store-localization");
const locales = [
  {
    file: "de-DE.md",
    uiDisclosure: "Die App-Oberfläche ist derzeit auf Englisch.",
    retiredPositioning: "Du kennst dein Programm",
  },
  {
    file: "es-MX.md",
    uiDisclosure: "la interfaz de la app está en inglés por ahora.",
    retiredPositioning: "Ya conoces tu programa",
  },
  {
    file: "pt-BR.md",
    uiDisclosure: "a interface do app está em inglês por enquanto.",
    retiredPositioning: "Você já conhece seu treino",
  },
  {
    file: "fr-FR.md",
    uiDisclosure: "l’interface de l’app est en anglais pour le moment.",
    retiredPositioning: "Vous connaissez votre programme",
  },
  {
    file: "tr.md",
    uiDisclosure: "Uygulama arayüzü şimdilik İngilizce.",
    retiredPositioning: "Programını zaten biliyorsun",
  },
];

const limits = {
  "App name": 30,
  Subtitle: 30,
  "Promotional text": 170,
  Description: 4000,
  Keywords: 100,
  "What’s New": 4000,
};

const failures = [];
const rows = [];

function count(value) {
  return [...value.normalize("NFC")].length;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function fencedValue(markdown, heading) {
  const expression = new RegExp(
    `^## ${escapeRegExp(heading)}[^\\n]*\\n[\\s\\S]*?^\`\`\`\\n([\\s\\S]*?)\\n\`\`\``,
    "m",
  );
  return markdown.match(expression)?.[1];
}

function fail(file, message) {
  failures.push(`${file}: ${message}`);
}

for (const locale of locales) {
  const markdown = fs.readFileSync(path.join(localeDir, locale.file), "utf8");
  const fields = Object.fromEntries(
    Object.keys(limits).map((heading) => [heading, fencedValue(markdown, heading)]),
  );

  for (const [field, limit] of Object.entries(limits)) {
    const value = fields[field];
    if (!value) {
      fail(locale.file, `missing fenced ${field} value`);
      continue;
    }
    const length = count(value);
    if (length > limit) {
      fail(locale.file, `${field} is ${length}/${limit} characters`);
    }
  }

  const keywords = fields.Keywords ?? "";
  if (/\s/.test(keywords)) {
    fail(locale.file, "keywords contain whitespace");
  }

  const indexedWords = new Set(
    `${fields["App name"] ?? ""} ${fields.Subtitle ?? ""}`
      .toLocaleLowerCase()
      .match(/[\p{L}\p{N}]+/gu) ?? [],
  );
  for (const keyword of keywords.toLocaleLowerCase().split(",")) {
    if (indexedWords.has(keyword)) {
      fail(locale.file, `keyword duplicates app name/subtitle: ${keyword}`);
    }
  }

  const description = fields.Description ?? "";
  const whatsNew = fields["What’s New"] ?? "";
  if (!description.includes(locale.uiDisclosure)) {
    fail(locale.file, "English-only UI disclosure is missing or changed");
  }
  if (!description.includes("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")) {
    fail(locale.file, "EULA URL is missing");
  }
  if (!description.includes("https://unitlift.app/privacy")) {
    fail(locale.file, "privacy URL is missing");
  }
  if ((description.match(/^• /gm) ?? []).length !== 5) {
    fail(locale.file, "description must contain exactly five feature bullets");
  }
  if ((whatsNew.match(/^• /gm) ?? []).length !== 3) {
    fail(locale.file, "What’s New must contain exactly three bullets");
  }
  if (markdown.includes(locale.retiredPositioning)) {
    fail(locale.file, "retired experienced-user positioning is still present");
  }
  if (markdown.includes("STALE FOR 2.1")) {
    fail(locale.file, "file is still marked stale after regeneration");
  }

  const subscriptionRows = [
    ...markdown.matchAll(
      /^\| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \|$/gm,
    ),
  ];
  if (subscriptionRows.length !== 4) {
    fail(locale.file, `expected 4 subscription rows, found ${subscriptionRows.length}`);
  }
  for (const [, productID, displayName, productDescription] of subscriptionRows) {
    if (count(displayName) > 30) {
      fail(locale.file, `${productID} display name exceeds 30 characters`);
    }
    if (count(productDescription) > 45) {
      fail(locale.file, `${productID} description exceeds 45 characters`);
    }
  }

  rows.push({
    locale: locale.file.replace(".md", ""),
    name: `${count(fields["App name"] ?? "")}/30`,
    subtitle: `${count(fields.Subtitle ?? "")}/30`,
    promo: `${count(fields["Promotional text"] ?? "")}/170`,
    keywords: `${count(keywords)}/100`,
  });
}

console.table(rows);

if (failures.length > 0) {
  for (const failure of failures) {
    console.error(`ERROR ${failure}`);
  }
  process.exit(1);
}

console.log("All five locale files passed structural, character-limit, disclosure, and keyword-duplication checks.");
