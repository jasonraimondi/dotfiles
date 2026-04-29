/**
 * Convert between sRGB and OKLCH.
 *
 * sRGB → linear sRGB → LMS → OKLab → OKLCH (and the inverse).
 * Reference: Björn Ottosson, https://bottosson.github.io/posts/oklab/
 */

export type Rgb = { r: number; g: number; b: number; a?: number }
export type Oklch = { l: number; c: number; h: number; a?: number }

const srgbToLinear = (c: number): number =>
  c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)

const linearToSrgb = (c: number): number =>
  c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055

const clamp = (x: number, lo: number, hi: number): number =>
  Math.max(lo, Math.min(hi, x))

/**
 * sRGB (channels 0–255, alpha 0–1) → OKLCH.
 * Returns L in [0,1], C ≥ 0, H in [0,360). Hue is 0 for grays.
 */
export function rgbToOklch({ r, g, b, a }: Rgb): Oklch {
  const rl = srgbToLinear(r / 255)
  const gl = srgbToLinear(g / 255)
  const bl = srgbToLinear(b / 255)

  const l_ = 0.4122214708 * rl + 0.5363325363 * gl + 0.0514459929 * bl
  const m_ = 0.2119034982 * rl + 0.6806995451 * gl + 0.1073969566 * bl
  const s_ = 0.0883024619 * rl + 0.2817188376 * gl + 0.6299787005 * bl

  const lc = Math.cbrt(l_)
  const mc = Math.cbrt(m_)
  const sc = Math.cbrt(s_)

  const L = 0.2104542553 * lc + 0.7936177850 * mc - 0.0040720468 * sc
  const A = 1.9779984951 * lc - 2.4285922050 * mc + 0.4505937099 * sc
  const B = 0.0259040371 * lc + 0.7827717662 * mc - 0.8086757660 * sc

  const C = Math.sqrt(A * A + B * B)
  let H = C < 1e-4 ? 0 : (Math.atan2(B, A) * 180) / Math.PI
  if (H < 0) H += 360

  return a === undefined ? { l: L, c: C, h: H } : { l: L, c: C, h: H, a }
}

/**
 * OKLCH → sRGB (channels 0–255, alpha passed through).
 * Out-of-gamut colors are clamped to the sRGB cube without reducing chroma —
 * use a gamut mapper if you need perceptual fidelity for wide-gamut input.
 */
export function oklchToRgb({ l: L, c: C, h: H, a }: Oklch): Rgb {
  const hr = (H * Math.PI) / 180
  const A = C * Math.cos(hr)
  const B = C * Math.sin(hr)

  const lc = L + 0.3963377774 * A + 0.2158037573 * B
  const mc = L - 0.1055613458 * A - 0.0638541728 * B
  const sc = L - 0.0894841775 * A - 1.2914855480 * B

  const ll = lc * lc * lc
  const mm = mc * mc * mc
  const ss = sc * sc * sc

  const rl = 4.0767416621 * ll - 3.3077115913 * mm + 0.2309699292 * ss
  const gl = -1.2684380046 * ll + 2.6097574011 * mm - 0.3413193965 * ss
  const bl = -0.0041960863 * ll - 0.7034186147 * mm + 1.7076147010 * ss

  const r = Math.round(clamp(linearToSrgb(rl), 0, 1) * 255)
  const g = Math.round(clamp(linearToSrgb(gl), 0, 1) * 255)
  const b = Math.round(clamp(linearToSrgb(bl), 0, 1) * 255)

  return a === undefined ? { r, g, b } : { r, g, b, a }
}

/**
 * Parse `#rgb`, `#rgba`, `#rrggbb`, or `#rrggbbaa` to Rgb.
 * Leading `#` optional. Throws on malformed input.
 */
export function hexToRgb(hex: string): Rgb {
  const h = hex.replace(/^#/, "")
  if (!/^[0-9a-fA-F]+$/.test(h) || ![3, 4, 6, 8].includes(h.length)) {
    throw new Error(`Invalid hex color: ${hex}`)
  }
  const short = h.length === 3 || h.length === 4
  const expand = (i: number) =>
    short ? parseInt(h[i] + h[i], 16) : parseInt(h.slice(i * 2, i * 2 + 2), 16)
  const r = expand(0)
  const g = expand(1)
  const b = expand(2)
  const hasAlpha = h.length === 4 || h.length === 8
  return hasAlpha ? { r, g, b, a: expand(3) / 255 } : { r, g, b }
}

/**
 * Format Rgb as `#rrggbb`, or `#rrggbbaa` when alpha is present and < 1.
 */
export function rgbToHex({ r, g, b, a }: Rgb): string {
  const byte = (n: number) =>
    clamp(Math.round(n), 0, 255).toString(16).padStart(2, "0")
  const base = `#${byte(r)}${byte(g)}${byte(b)}`
  return a === undefined || a >= 1 ? base : base + byte(a * 255)
}
