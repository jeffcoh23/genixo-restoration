const statusColors = {
  emergency: "hsl(0 72% 51%)",
  warning: "hsl(38 92% 50%)",
  success: "hsl(152 60% 30%)",
  info: "hsl(199 89% 36%)",
  quote: "hsl(262 52% 57%)",
  completed: "hsl(152 46% 30%)",
  neutral: "hsl(220 6% 55%)",
};

const textColors = {
  black: "hsl(0 0% 0%)",
  white: "hsl(0 0% 100%)",
};

const mapping = {
  new: { bg: "info", text: "white" },
  acknowledged: { bg: "info", text: "white" },
  proposal_requested: { bg: "quote", text: "white" },
  proposal_submitted: { bg: "quote", text: "white" },
  proposal_signed: { bg: "quote", text: "white" },
  active: { bg: "success", text: "white" },
  job_started: { bg: "success", text: "white" },
  on_hold: { bg: "warning", text: "black" },
  completed: { bg: "completed", text: "white" },
  emergency: { bg: "emergency", text: "white" },
  default: { bg: "neutral", text: "black" },
};

function parseHsl(input) {
  const match = input.match(/^hsl\(([-\d.]+)\s+([-\d.]+)%\s+([-\d.]+)%\)$/);
  if (!match) throw new Error(`Invalid HSL value: ${input}`);
  return [Number(match[1]), Number(match[2]) / 100, Number(match[3]) / 100];
}

function hslToRgb(h, s, l) {
  const hue = ((h % 360) + 360) % 360 / 360;
  if (s === 0) return [l, l, l];

  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;

  const hueToRgb = (t) => {
    let temp = t;
    if (temp < 0) temp += 1;
    if (temp > 1) temp -= 1;
    if (temp < 1 / 6) return p + (q - p) * 6 * temp;
    if (temp < 1 / 2) return q;
    if (temp < 2 / 3) return p + (q - p) * (2 / 3 - temp) * 6;
    return p;
  };

  return [hueToRgb(hue + 1 / 3), hueToRgb(hue), hueToRgb(hue - 1 / 3)];
}

function linearize(value) {
  return value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
}

function luminance(rgb) {
  const [r, g, b] = rgb.map(linearize);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrastRatio(colorA, colorB) {
  const lumA = luminance(colorA);
  const lumB = luminance(colorB);
  const [lighter, darker] = lumA > lumB ? [lumA, lumB] : [lumB, lumA];
  return (lighter + 0.05) / (darker + 0.05);
}

let hasFailures = false;

Object.entries(mapping).forEach(([status, cfg]) => {
  const bgRgb = hslToRgb(...parseHsl(statusColors[cfg.bg]));
  const textRgb = hslToRgb(...parseHsl(textColors[cfg.text]));
  const ratio = contrastRatio(bgRgb, textRgb);

  if (ratio < 4.5) {
    hasFailures = true;
    console.error(`FAIL ${status}: ${ratio.toFixed(2)}:1`);
    return;
  }

  console.log(`PASS ${status}: ${ratio.toFixed(2)}:1`);
});

if (hasFailures) {
  process.exitCode = 1;
} else {
  console.log("All status contrasts meet WCAG AA (4.5:1).");
}
