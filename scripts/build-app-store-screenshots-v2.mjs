// Hevy-style App Store screenshot set for Unit 2.1 (2026-10-23).
// Bold two-line uppercase headlines with blue keywords, light background with
// a blue band, a real phone frame, UI pieces popping out of the phone, a
// two-frame panorama opener and an optional before/after pair.
// Sources: docs/app-store-assets/2.1/source (real build captures).
// Output:  docs/app-store-assets/2.1/exports/6.9-inch-v2 (1290 x 2796, no alpha).
// Optional: docs/app-store-assets/2.1/before-after/before.(jpg|png) and after.(jpg|png).
import fs from "node:fs"
import path from "node:path"
import { createRequire } from "node:module"
import { fileURLToPath } from "node:url"

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..")
const requireFromRoot = createRequire(path.join(root, "package.json"))
const sharp = createRequire(requireFromRoot.resolve("next/package.json"))("sharp")

const assets = path.join(root, "docs/app-store-assets/2.1")
const source = (name) => path.join(assets, "source", name)
const outDir = path.join(assets, "exports/6.9-inch-v2")

const W = 1290
const H = 2796
const BG = "#F2F3F5"
const BLUE = "#0068E0"
const INK = "#0A0A0A"
const BAND_Y = 2060
const FONT = "SF Pro Display, -apple-system, Helvetica Neue, Arial, sans-serif"

const esc = (value) => value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")

/** lines: [[["LOG ", INK], ["SETS", BLUE]], ...] */
function headline(lines, { align = "middle", size = 124, top = 250, gap = 136, x = W / 2, width = W } = {}) {
  const rows = lines.map((segments, index) => {
    const spans = segments.map(([text, color]) => `<tspan fill="${color}">${esc(text)}</tspan>`).join("")
    return `<text x="${x}" y="${top + index * gap}" text-anchor="${align}" font-family="${FONT}" font-size="${size}" font-weight="900" letter-spacing="-1">${spans}</text>`
  })
  return Buffer.from(`<svg width="${width}" height="${top + lines.length * gap + 40}" xmlns="http://www.w3.org/2000/svg">${rows.join("")}</svg>`)
}

function textSVG(text, { size, color, weight = 800, width, height, y }) {
  return Buffer.from(`<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg"><text x="${width / 2}" y="${y}" text-anchor="middle" font-family="${FONT}" font-size="${size}" font-weight="${weight}" fill="${color}" letter-spacing="1">${esc(text)}</text></svg>`)
}

function roundedMask(width, height, radius) {
  return Buffer.from(`<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg"><rect width="${width}" height="${height}" rx="${radius}" ry="${radius}" fill="#fff"/></svg>`)
}

async function shadow(width, height, radius, { blur = 40, opacity = 0.22 } = {}) {
  const pad = blur * 2
  const svg = Buffer.from(`<svg width="${width + pad * 2}" height="${height + pad * 2}" xmlns="http://www.w3.org/2000/svg"><rect x="${pad}" y="${pad}" width="${width}" height="${height}" rx="${radius}" fill="#000" fill-opacity="${opacity}"/></svg>`)
  return { input: await sharp(svg).blur(blur / 2).png().toBuffer(), pad }
}

/** Real-looking phone: black bezel, rounded screen, Dynamic Island. */
async function phone(screenFile, width = 1000) {
  const meta = await sharp(screenFile).metadata()
  const screenHeight = Math.round(width * meta.height / meta.width)
  const radius = Math.round(width * 0.118)
  const screen = await sharp(screenFile)
    .resize(width, screenHeight)
    .composite([{ input: roundedMask(width, screenHeight, radius), blend: "dest-in" }])
    .png().toBuffer()
  const bezel = 26
  const frameW = width + bezel * 2
  const frameH = screenHeight + bezel * 2
  const islandW = Math.round(width * 0.3)
  const islandH = Math.round(width * 0.085)
  const frame = Buffer.from(`<svg width="${frameW}" height="${frameH}" xmlns="http://www.w3.org/2000/svg"><rect width="${frameW}" height="${frameH}" rx="${radius + bezel}" fill="${INK}"/></svg>`)
  const island = Buffer.from(`<svg width="${islandW}" height="${islandH}" xmlns="http://www.w3.org/2000/svg"><rect width="${islandW}" height="${islandH}" rx="${islandH / 2}" fill="${INK}"/></svg>`)
  const buffer = await sharp(frame)
    .composite([
      { input: screen, left: bezel, top: bezel },
      { input: island, left: Math.round((frameW - islandW) / 2), top: bezel + Math.round(width * 0.03) },
    ])
    .png().toBuffer()
  return { buffer, width: frameW, height: frameH, screenScale: width / meta.width, bezel }
}

/** A piece of the real screen, enlarged on a white card that pops out of the phone. */
async function callout(screenFile, crop, scale = 1.12, radius = 34) {
  // Keep the card and its shadow inside the 1290px canvas.
  const width = Math.min(Math.round(crop.width * scale), W - 200)
  const piece = await sharp(screenFile).extract(crop).resize(width).png().toBuffer()
  const meta = await sharp(piece).metadata()
  const card = await sharp({ create: { width: meta.width, height: meta.height, channels: 4, background: "#FFFFFF" } })
    .composite([{ input: piece }, { input: roundedMask(meta.width, meta.height, radius), blend: "dest-in" }])
    .png().toBuffer()
  return { buffer: card, width: meta.width, height: meta.height, radius }
}

async function base(width = W) {
  const band = Buffer.from(`<svg width="${width}" height="${H - BAND_Y}" xmlns="http://www.w3.org/2000/svg"><rect width="${width}" height="${H - BAND_Y}" fill="${BLUE}"/></svg>`)
  return sharp({ create: { width, height: H, channels: 3, background: BG } })
    .composite([{ input: band, left: 0, top: BAND_Y }])
    .png().toBuffer()
}

async function place(layers, item, left, top) {
  const s = await shadow(item.width, item.height, item.radius ?? 120, item.shadowOptions)
  layers.push({ input: s.input, left: Math.round(left - s.pad), top: Math.round(top - s.pad + 18) })
  layers.push({ input: item.buffer, left: Math.round(left), top: Math.round(top) })
}

async function standard({ file, lines, screen, pops = [], extras = [] }) {
  const layers = [{ input: headline(lines), left: 0, top: 0 }]
  const device = await phone(source(screen), 980)
  const phoneLeft = Math.round((W - device.width) / 2)
  const phoneTop = 610
  await place(layers, { ...device, radius: 140 }, phoneLeft, phoneTop)
  for (const pop of pops) {
    const item = await callout(source(screen), pop.crop, pop.scale ?? 1.12)
    const left = pop.left ?? Math.round((W - item.width) / 2)
    await place(layers, { ...item, shadowOptions: { blur: 36, opacity: 0.25 } }, left, pop.top)
  }
  for (const extra of extras) layers.push(...await extra())
  const png = await sharp(await base()).composite(layers).flatten({ background: BG }).png().toBuffer()
  await sharp(png).removeAlpha().toFile(path.join(outDir, file))
}

async function panorama() {
  const width = W * 2
  const layers = []
  layers.push({
    input: headline([
      [["LOG ", INK]], [["SETS", BLUE]],
      [["GET ", INK]], [["STRONGER", BLUE]],
      [["KNOW ", INK]], [["WHAT'S NEXT", BLUE]],
    ], { align: "start", x: 96, size: 140, gap: 150, top: 380, width: W }),
    left: 0, top: 0,
  })
  layers.push({
    input: textSVG("NO ADS · NO ACCOUNT · WORKS OFFLINE", { size: 46, color: "#FFFFFF", width: W, height: 200, y: 120 }),
    left: 0, top: BAND_Y + 230,
  })
  layers.push({
    input: Buffer.from(`<svg width="420" height="160" xmlns="http://www.w3.org/2000/svg"><text x="400" y="110" text-anchor="end" font-family="${FONT}" font-size="104" font-weight="900" letter-spacing="2" fill="${INK}">UNIT</text></svg>`),
    left: width - 470, top: 120,
  })
  const device = await phone(source("07-exercise-done.png"), 900)
  const tilted = await sharp(device.buffer).rotate(-9, { background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer()
  const tiltedMeta = await sharp(tilted).metadata()
  const phoneLeft = W + 20
  const phoneTop = 360
  const s = await shadow(device.width, device.height, 140, { blur: 50, opacity: 0.2 })
  layers.push({ input: await sharp(s.input).rotate(-9, { background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer(), left: phoneLeft - s.pad, top: phoneTop - s.pad + 30 })
  layers.push({ input: tilted, left: phoneLeft, top: phoneTop })
  // The finished-exercise cards sit under the headline and cross the seam. Card text
  // ends at x 797 and the check starts at x 979 (card px), so a left of 400 puts the
  // seam in the empty gap: no text is cut when the frames show apart.
  const cards = [
    { crop: { left: 63, top: 350, width: 1194, height: 276 }, left: 400, top: 1240 },
    { crop: { left: 63, top: 650, width: 1194, height: 276 }, left: 400, top: 1530 },
    { crop: { left: 63, top: 950, width: 1194, height: 276 }, left: 400, top: 1820 },
  ]
  for (const card of cards) {
    const item = await callout(source("07-exercise-done.png"), card.crop, 0.92, 38)
    await place(layers, { ...item, shadowOptions: { blur: 34, opacity: 0.24 } }, card.left, card.top)
  }
  void tiltedMeta
  const png = await sharp(await base(width)).composite(layers).png().toBuffer()
  await sharp(png).extract({ left: 0, top: 0, width: W, height: H }).removeAlpha().toFile(path.join(outDir, "01-log-get-stronger.png"))
  await sharp(png).extract({ left: W, top: 0, width: W, height: H }).removeAlpha().toFile(path.join(outDir, "02-exercise-done.png"))
}

function findBeforeAfter() {
  const dir = path.join(assets, "before-after")
  const pick = (name) => ["jpg", "jpeg", "png"].map((ext) => path.join(dir, `${name}.${ext}`)).find((file) => fs.existsSync(file))
  const before = pick("before")
  const after = pick("after")
  return before && after ? { before, after } : null
}

async function photoCard(file, label) {
  const width = 470
  const height = 600
  const photo = await sharp(file).resize(width, height, { fit: "cover", position: "attention" })
    .composite([{ input: roundedMask(width, height, 36), blend: "dest-in" }]).png().toBuffer()
  const chip = Buffer.from(`<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg"><rect x="24" y="${height - 96}" width="${label.length * 26 + 56}" height="72" rx="36" fill="${INK}" fill-opacity="0.82"/><text x="${24 + 28}" y="${height - 48}" font-family="${FONT}" font-size="38" font-weight="800" fill="#FFFFFF" letter-spacing="2">${label}</text></svg>`)
  const buffer = await sharp(photo).composite([{ input: chip }]).png().toBuffer()
  return { buffer, width, height, radius: 36 }
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true })
  await panorama()
  await standard({
    file: "03-hit-reps-add-weight.png",
    lines: [[["HIT 10 REPS.", INK]], [["ADD 5 LB.", BLUE]]],
    screen: "03-double-progression.png",
    pops: [{ crop: { left: 60, top: 640, width: 1200, height: 680 }, scale: 1.0, top: 1180 }],
  })
  await standard({
    file: "04-one-tap.png",
    lines: [[["LOG A SET", INK]], [["IN ONE TAP", BLUE]]],
    screen: "02-one-tap.png",
    pops: [{ crop: { left: 86, top: 509, width: 1146, height: 508 }, scale: 1.0, top: 1080 }],
  })
  const beforeAfter = findBeforeAfter()
  await standard({
    file: "05-see-progress.png",
    lines: [[["SEE YOUR", INK]], [["PROGRESS", BLUE]]],
    screen: "05-progress-history.png",
    pops: beforeAfter ? [] : [{ crop: { left: 60, top: 900, width: 1200, height: 940 }, scale: 0.95, top: 1250 }],
    extras: beforeAfter ? [async () => {
      const layers = []
      const before = await photoCard(beforeAfter.before, "BEFORE")
      const after = await photoCard(beforeAfter.after, "AFTER")
      await place(layers, { ...before, shadowOptions: { blur: 34, opacity: 0.25 } }, 120, 1240)
      await place(layers, { ...after, shadowOptions: { blur: 34, opacity: 0.25 } }, W - 120 - after.width, 1240)
      return layers
    }] : [],
  })
  await standard({
    file: "06-paste-or-pick.png",
    lines: [[["PASTE YOUR PLAN", INK]], [["OR PICK ONE", BLUE]]],
    screen: "04-program-setup.png",
    pops: [{ crop: { left: 60, top: 640, width: 1200, height: 560 }, scale: 1.0, top: 1220 }],
  })
  await standard({
    file: "07-lock-screen-timer.png",
    lines: [[["REST TIMER ON", INK]], [["YOUR LOCK SCREEN", BLUE]]],
    screen: "06-lock-screen-timer.png",
  })
  console.log(`Wrote ${fs.readdirSync(outDir).length} screenshots to ${path.relative(root, outDir)}${beforeAfter ? " (with before/after)" : " (before/after not provided yet)"}`)
}

await main()
