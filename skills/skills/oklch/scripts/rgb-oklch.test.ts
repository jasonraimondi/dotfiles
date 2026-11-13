import { assertAlmostEquals, assertEquals, assertThrows } from "jsr:@std/assert"
import { hexToRgb, oklchToRgb, rgbToHex, rgbToOklch } from "./rgb-oklch.ts"

Deno.test("rgbToOklch — pure white → L=1, C=0", () => {
  const out = rgbToOklch({ r: 255, g: 255, b: 255 })
  assertAlmostEquals(out.l, 1, 0.001)
  assertAlmostEquals(out.c, 0, 0.001)
  assertEquals(out.h, 0)
})

Deno.test("rgbToOklch — pure black → L=0, C=0", () => {
  const out = rgbToOklch({ r: 0, g: 0, b: 0 })
  assertAlmostEquals(out.l, 0, 0.001)
  assertAlmostEquals(out.c, 0, 0.001)
  assertEquals(out.h, 0)
})

Deno.test("rgbToOklch — Tailwind blue-500 (#3b82f6)", () => {
  const out = rgbToOklch({ r: 59, g: 130, b: 246 })
  assertAlmostEquals(out.l, 0.623, 0.001)
  assertAlmostEquals(out.c, 0.188, 0.001)
  assertAlmostEquals(out.h, 259.815, 0.05)
})

Deno.test("rgbToOklch — pure red (#ff0000)", () => {
  const out = rgbToOklch({ r: 255, g: 0, b: 0 })
  assertAlmostEquals(out.l, 0.628, 0.001)
  assertAlmostEquals(out.c, 0.258, 0.001)
  assertAlmostEquals(out.h, 29.234, 0.05)
})

Deno.test("rgbToOklch — Tailwind slate-800 (#1e293b)", () => {
  const out = rgbToOklch({ r: 30, g: 41, b: 59 })
  assertAlmostEquals(out.l, 0.279, 0.002)
  assertAlmostEquals(out.c, 0.037, 0.002)
  assertAlmostEquals(out.h, 260.031, 0.5)
})

Deno.test("rgbToOklch — alpha is preserved", () => {
  const out = rgbToOklch({ r: 0, g: 0, b: 0, a: 0.5 })
  assertEquals(out.a, 0.5)
})

Deno.test("rgbToOklch — no alpha key when alpha omitted", () => {
  const out = rgbToOklch({ r: 0, g: 0, b: 0 })
  assertEquals("a" in out, false)
})

Deno.test("oklchToRgb — Tailwind blue-500 round-trip", () => {
  const out = oklchToRgb({ l: 0.623, c: 0.188, h: 259.815 })
  assertEquals(out, { r: 59, g: 130, b: 246 })
})

Deno.test("oklchToRgb — pure red round-trip", () => {
  const out = oklchToRgb({ l: 0.628, c: 0.258, h: 29.234 })
  assertEquals(out, { r: 255, g: 0, b: 0 })
})

Deno.test("oklchToRgb — alpha is preserved", () => {
  const out = oklchToRgb({ l: 0.5, c: 0.1, h: 200, a: 0.25 })
  assertEquals(out.a, 0.25)
})

Deno.test("oklchToRgb — out-of-gamut chroma clamps to sRGB cube", () => {
  const out = oklchToRgb({ l: 0.7, c: 0.35, h: 150 })
  assertEquals(out.r >= 0 && out.r <= 255, true)
  assertEquals(out.g >= 0 && out.g <= 255, true)
  assertEquals(out.b >= 0 && out.b <= 255, true)
})

Deno.test("round-trip rgb → oklch → rgb preserves arbitrary colors", () => {
  const samples: Rgb[] = [
    { r: 100, g: 150, b: 200 },
    { r: 200, g: 50, b: 75 },
    { r: 17, g: 17, b: 17 },
    { r: 240, g: 240, b: 235 },
  ]
  for (const original of samples) {
    const back = oklchToRgb(rgbToOklch(original))
    // Allow ±1 drift from rounding through float pipeline
    assertAlmostEquals(back.r, original.r, 1)
    assertAlmostEquals(back.g, original.g, 1)
    assertAlmostEquals(back.b, original.b, 1)
  }
})

Deno.test("hexToRgb — 6-digit", () => {
  assertEquals(hexToRgb("#3b82f6"), { r: 59, g: 130, b: 246 })
})

Deno.test("hexToRgb — 3-digit shorthand expands", () => {
  assertEquals(hexToRgb("#fff"), { r: 255, g: 255, b: 255 })
  assertEquals(hexToRgb("#f00"), { r: 255, g: 0, b: 0 })
})

Deno.test("hexToRgb — 8-digit with alpha", () => {
  const out = hexToRgb("#3b82f680")
  assertEquals(out.r, 59)
  assertEquals(out.g, 130)
  assertEquals(out.b, 246)
  assertAlmostEquals(out.a!, 0.502, 0.001)
})

Deno.test("hexToRgb — 4-digit with alpha", () => {
  const out = hexToRgb("#f00a")
  assertEquals(out.r, 255)
  assertAlmostEquals(out.a!, 0.667, 0.001)
})

Deno.test("hexToRgb — leading # is optional, case insensitive", () => {
  assertEquals(hexToRgb("3B82F6"), { r: 59, g: 130, b: 246 })
})

Deno.test("hexToRgb — throws on garbage", () => {
  assertThrows(() => hexToRgb("#zzz"))
  assertThrows(() => hexToRgb("#12345"))
  assertThrows(() => hexToRgb(""))
})

Deno.test("rgbToHex — basic + alpha", () => {
  assertEquals(rgbToHex({ r: 59, g: 130, b: 246 }), "#3b82f6")
  assertEquals(rgbToHex({ r: 255, g: 0, b: 0, a: 0.5 }), "#ff000080")
  assertEquals(rgbToHex({ r: 255, g: 0, b: 0, a: 1 }), "#ff0000")
})

Deno.test("hex → oklch via composition matches Tailwind blue-500", () => {
  const out = rgbToOklch(hexToRgb("#3b82f6"))
  assertAlmostEquals(out.l, 0.623, 0.001)
  assertAlmostEquals(out.c, 0.188, 0.001)
  assertAlmostEquals(out.h, 259.815, 0.05)
})

Deno.test("oklch → hex round-trip via composition", () => {
  const hex = rgbToHex(oklchToRgb({ l: 0.623, c: 0.188, h: 259.815 }))
  assertEquals(hex, "#3b82f6")
})

type Rgb = { r: number; g: number; b: number; a?: number }
