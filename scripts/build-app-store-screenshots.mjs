import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"
import { createRequire } from "node:module"

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..")
// sharp ships with Next.js (pnpm keeps it nested), so resolve it from next.
const requireFromRoot = createRequire(path.join(root, "package.json"))
const sharp = createRequire(requireFromRoot.resolve("next/package.json"))("sharp")
const sourceDir = path.join(root, "docs/app-store-assets/2.1/source")
const outputDir = path.join(root, "docs/app-store-assets/2.1/exports/6.9-inch")
const width = 1290
const height = 2796

const screens = [
  ["01-next-target.png", "01-one-clear-target.png", "Know what to\nlift next"],
  ["02-one-tap.png", "02-log-in-3-seconds.png", "Log a set\nin 3 seconds"],
  ["03-double-progression.png", "03-reps-then-weight.png", "Hit 10 reps.\nAdd 5 lb."],
  ["04-program-setup.png", "04-program-setup.png", "Paste your plan\nor choose one"],
  ["05-progress-history.png", "05-see-progress.png", "See your strength\ngo up"],
  ["06-lock-screen-timer.png", "06-lock-screen-timer.png", "Rest timer on your\nLock Screen"],
]

function escapeXML(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
}

function titleSVG(title) {
  const lines = title.split("\n")
  const tspans = lines
    .map((line, index) => `<tspan x="645" dy="${index === 0 ? 0 : 108}">${escapeXML(line)}</tspan>`)
    .join("")
  return Buffer.from(`
    <svg width="${width}" height="430" xmlns="http://www.w3.org/2000/svg">
      <text x="645" y="150" text-anchor="middle"
        font-family="-apple-system, BlinkMacSystemFont, Helvetica Neue, Arial, sans-serif"
        font-size="92" font-weight="760" letter-spacing="-3" fill="#0A0A0A">${tspans}</text>
    </svg>
  `)
}

async function render([sourceName, outputName, title]) {
  const sourcePath = path.join(sourceDir, sourceName)
  if (!fs.existsSync(sourcePath)) {
    throw new Error(`Missing source screenshot: ${sourcePath}`)
  }

  const phoneWidth = 1030
  const phoneHeight = 2290
  const top = 440
  const phone = await sharp(sourcePath)
    .flatten({ background: "#F5F5F5" })
    .resize(phoneWidth, phoneHeight, { fit: "cover", position: "top" })
    .composite([
      {
        input: Buffer.from(`<svg width="${phoneWidth}" height="${phoneHeight}" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" rx="76" ry="76" fill="white"/></svg>`),
        blend: "dest-in",
      },
    ])
    .png()
    .toBuffer()

  const shadow = Buffer.from(`
    <svg width="1150" height="2390" xmlns="http://www.w3.org/2000/svg">
      <defs><filter id="s" x="-30%" y="-30%" width="160%" height="160%"><feDropShadow dx="0" dy="28" stdDeviation="32" flood-color="#000" flood-opacity="0.16"/></filter></defs>
      <rect x="60" y="30" width="1030" height="2290" rx="76" fill="#fff" filter="url(#s)"/>
    </svg>
  `)

  await sharp({ create: { width, height, channels: 3, background: "#F5F5F5" } })
    .composite([
      { input: titleSVG(title), left: 0, top: 0 },
      { input: shadow, left: 70, top: top - 30 },
      { input: phone, left: 130, top },
    ])
    .removeAlpha()
    .png({ compressionLevel: 9 })
    .toFile(path.join(outputDir, outputName))
}

async function main() {
  fs.mkdirSync(outputDir, { recursive: true })
  for (const screen of screens) await render(screen)
}

main().catch((error) => {
  console.error(error.message)
  process.exitCode = 1
})
