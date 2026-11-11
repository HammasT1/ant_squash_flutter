#!/usr/bin/env python3
"""Generates the animated README banners and section headers (docs/*.svg)
using the same palette as the game, and the tinted ant sprites."""
import base64, io, os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "docs")

BG, NAVY, PURPLE = "#08111F", "#1C2D4D", "#291633"
ACCENT, DEEP, GOLD, LIGHT, CYAN = "#FF8A2A", "#FF5A3D", "#FFD36A", "#FFB347", "#59D8FF"
FONT = "'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif"


def b64_png(path, height):
    img = Image.open(path).convert("RGBA")
    w = round(img.width * height / img.height)
    img = img.resize((w, height), Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, "PNG", optimize=True)
    return base64.b64encode(buf.getvalue()).decode(), w, height


ANT, ANT_W, ANT_H = b64_png(os.path.join(ROOT, "assets/images/ant.png"), 96)
CAKE, CAKE_W, CAKE_H = b64_png(os.path.join(ROOT, "assets/images/cake.png"), 260)


def banner():
    W, H = 1280, 380
    cx, cy = 1000, 190  # cake centre
    # (start x, start y, begin delay) for the marching ants
    ants = [(-60, 60, 0.0), (-60, 320, 1.7), (560, -60, 3.1), (700, 440, 0.9),
            (1340, 40, 2.4), (1340, 340, 4.0)]
    ant_xml = []
    for i, (sx, sy, delay) in enumerate(ants):
        ex, ey = cx + (sx - cx) * 0.16, cy + (sy - cy) * 0.16
        dur = 6.0
        ant_xml.append(f"""
    <g>
      <animateMotion dur="{dur}s" begin="{delay}s" repeatCount="indefinite" rotate="auto"
        keyPoints="0;1" keyTimes="0;1" calcMode="linear" path="M{sx},{sy} L{ex:.0f},{ey:.0f}"/>
      <animate attributeName="opacity" dur="{dur}s" begin="{delay}s" repeatCount="indefinite"
        values="0;1;1;0;0" keyTimes="0;0.06;0.9;0.93;1"/>
      <g transform="rotate(90)"><image href="data:image/png;base64,{ANT}"
        x="{-ANT_W*0.28:.1f}" y="{-ANT_H*0.28:.1f}" width="{ANT_W*0.56:.1f}" height="{ANT_H*0.56:.1f}"/></g>
    </g>
    <circle cx="{ex:.0f}" cy="{ey:.0f}" r="6" fill="none" stroke="{GOLD}" stroke-width="3" opacity="0">
      <animate attributeName="r" dur="{dur}s" begin="{delay}s" repeatCount="indefinite"
        values="6;6;46;46" keyTimes="0;0.9;0.99;1"/>
      <animate attributeName="opacity" dur="{dur}s" begin="{delay}s" repeatCount="indefinite"
        values="0;0;0.9;0" keyTimes="0;0.9;0.93;1"/>
    </circle>""")
    stars = "".join(
        f'<circle cx="{x}" cy="{y}" r="{r}" fill="#fff"><animate attributeName="opacity" '
        f'values="0.05;0.55;0.05" dur="{d}s" begin="{b}s" repeatCount="indefinite"/></circle>'
        for x, y, r, d, b in [(140, 40, 1.6, 3.2, 0), (330, 300, 1.3, 4.1, .6), (560, 70, 1.8, 3.7, 1.1),
                              (760, 330, 1.4, 5, .3), (880, 60, 1.5, 4.4, 2), (1180, 330, 1.6, 3.5, .9),
                              (60, 250, 1.2, 4.8, 1.5), (640, 210, 1.1, 3.9, 2.6), (1230, 130, 1.7, 4.2, .2)])
    return f"""<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{BG}"/><stop offset="0.55" stop-color="{NAVY}"/><stop offset="1" stop-color="{PURPLE}"/>
      <animate attributeName="x2" values="1;0.8;1" dur="12s" repeatCount="indefinite"/>
    </linearGradient>
    <linearGradient id="title" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="{LIGHT}"/><stop offset="0.5" stop-color="{ACCENT}"/><stop offset="1" stop-color="{DEEP}"/>
    </linearGradient>
    <linearGradient id="shine" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="0.5" stop-color="#fff" stop-opacity="0.55"/><stop offset="1" stop-color="#fff" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="{GOLD}" stop-opacity="0.5"/><stop offset="0.6" stop-color="{ACCENT}" stop-opacity="0.12"/><stop offset="1" stop-color="{ACCENT}" stop-opacity="0"/>
    </radialGradient>
    <filter id="blur"><feGaussianBlur stdDeviation="34"/></filter>
    <clipPath id="card"><rect width="{W}" height="{H}" rx="28"/></clipPath>
    <clipPath id="titleClip"><text x="70" y="206" font-family="{FONT}" font-size="104" font-weight="900" letter-spacing="4">ANT SQUASH</text></clipPath>
  </defs>
  <g clip-path="url(#card)">
    <rect width="{W}" height="{H}" fill="url(#bg)"/>
    <g filter="url(#blur)">
      <circle cx="120" cy="90" r="110" fill="{ACCENT}" opacity="0.22"><animate attributeName="cy" values="90;130;90" dur="8s" repeatCount="indefinite"/></circle>
      <circle cx="660" cy="320" r="90" fill="{CYAN}" opacity="0.14"><animate attributeName="cx" values="660;720;660" dur="10s" repeatCount="indefinite"/></circle>
      <circle cx="1180" cy="70" r="120" fill="{GOLD}" opacity="0.16"><animate attributeName="cy" values="70;30;70" dur="9s" repeatCount="indefinite"/></circle>
    </g>
    {stars}
    <circle cx="{cx}" cy="{cy}" r="210" fill="url(#glow)"><animate attributeName="r" values="190;225;190" dur="4s" repeatCount="indefinite"/></circle>
    <g>
      <animateTransform attributeName="transform" type="translate" values="0,-6;0,8;0,-6" dur="4s" repeatCount="indefinite"/>
      <image href="data:image/png;base64,{CAKE}" x="{cx-CAKE_W/2:.0f}" y="{cy-CAKE_H/2:.0f}" width="{CAKE_W}" height="{CAKE_H}"/>
    </g>
    {''.join(ant_xml)}
    <text x="70" y="206" font-family="{FONT}" font-size="104" font-weight="900" letter-spacing="4" fill="url(#title)">ANT SQUASH</text>
    <g clip-path="url(#titleClip)">
      <rect x="-300" y="100" width="260" height="130" fill="url(#shine)" transform="skewX(-20)">
        <animate attributeName="x" values="-300;900" dur="5s" repeatCount="indefinite"/>
      </rect>
    </g>
    <text x="74" y="256" font-family="{FONT}" font-size="26" font-weight="500" fill="#C9D6EE" letter-spacing="1">
      Defend the cake. Tap fast. Chain combos.<animate attributeName="opacity" values="0;1" dur="1.6s" fill="freeze"/>
    </text>
    <g font-family="{FONT}" font-size="15" font-weight="700" letter-spacing="1.5">
      <g><rect x="74" y="288" width="126" height="32" rx="16" fill="{ACCENT}" fill-opacity="0.16" stroke="{ACCENT}" stroke-opacity="0.6"/><text x="137" y="309" text-anchor="middle" fill="{LIGHT}">FLUTTER</text></g>
      <g><rect x="212" y="288" width="150" height="32" rx="16" fill="{CYAN}" fill-opacity="0.12" stroke="{CYAN}" stroke-opacity="0.5"/><text x="287" y="309" text-anchor="middle" fill="{CYAN}">ARCADE GAME</text></g>
      <g><rect x="374" y="288" width="176" height="32" rx="16" fill="{GOLD}" fill-opacity="0.12" stroke="{GOLD}" stroke-opacity="0.5"/><text x="462" y="309" text-anchor="middle" fill="{GOLD}">14 ACHIEVEMENTS</text></g>
    </g>
  </g>
  <rect x="1" y="1" width="{W-2}" height="{H-2}" rx="27" fill="none" stroke="{ACCENT}" stroke-opacity="0.35" stroke-width="2"/>
</svg>
"""


def section(slug, icon, title, subtitle):
    W, H = 900, 84
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="{NAVY}"/><stop offset="1" stop-color="{BG}"/>
    </linearGradient>
    <linearGradient id="bar" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{GOLD}"/><stop offset="1" stop-color="{DEEP}"/>
    </linearGradient>
    <linearGradient id="sweep" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="{ACCENT}" stop-opacity="0"/><stop offset="0.5" stop-color="{GOLD}" stop-opacity="0.9"/><stop offset="1" stop-color="{ACCENT}" stop-opacity="0"/>
    </linearGradient>
    <clipPath id="c"><rect width="{W}" height="{H}" rx="18"/></clipPath>
  </defs>
  <g clip-path="url(#c)">
    <rect width="{W}" height="{H}" fill="url(#bg)"/>
    <circle cx="{W-40}" cy="20" r="80" fill="{ACCENT}" opacity="0.13"><animate attributeName="cx" values="{W-40};{W-120};{W-40}" dur="9s" repeatCount="indefinite"/></circle>
    <rect width="7" height="{H}" fill="url(#bar)"/>
    <rect x="-300" y="{H-3}" width="300" height="3" fill="url(#sweep)"><animate attributeName="x" values="-300;{W}" dur="4.5s" repeatCount="indefinite"/></rect>
    <circle cx="52" cy="{H/2}" r="24" fill="{GOLD}" fill-opacity="0.92" stroke="{ACCENT}" stroke-opacity="0.9" stroke-width="2"/>
    <g transform="translate(52 {H/2})"><animateTransform attributeName="transform" type="translate" values="52 {H/2-2};52 {H/2+2};52 {H/2-2}" dur="2.4s" repeatCount="indefinite"/>
      <image href="data:image/png;base64,{ANT}" x="-8" y="-12" width="17" height="24"/></g>
    <text x="96" y="38" font-family="{FONT}" font-size="26" font-weight="900" fill="#fff" letter-spacing="1">{title}</text>
    <text x="96" y="62" font-family="{FONT}" font-size="14" fill="#9FB3D1" letter-spacing="0.5">{subtitle}</text>
  </g>
  <rect x="0.5" y="0.5" width="{W-1}" height="{H-1}" rx="17.5" fill="none" stroke="#fff" stroke-opacity="0.1"/>
</svg>
"""


def divider():
    W, H = 900, 28
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <defs>
    <linearGradient id="l" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="{ACCENT}" stop-opacity="0"/><stop offset="0.5" stop-color="{ACCENT}"/><stop offset="1" stop-color="{ACCENT}" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <rect x="0" y="13" width="{W}" height="2" rx="1" fill="url(#l)" opacity="0.7"/>
  <g>
    <animateMotion dur="9s" repeatCount="indefinite" rotate="auto" path="M-30,14 L{W+30},14"/>
    <g transform="rotate(90)"><image href="data:image/png;base64,{ANT}" x="-9" y="-13" width="18" height="26"/></g>
  </g>
</svg>
"""


def write(rel, text):
    path = os.path.join(DOCS, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)
    print("wrote", rel, f"{len(text)//1024} KB")


def tinted_ants():
    base = Image.open(os.path.join(ROOT, "assets/images/ant.png")).convert("RGBA")
    types = {"normal": (None, 1.0), "fast": ((0x4D, 0xB8, 0xFF), 0.72),
             "tank": ((0xB0, 0x4D, 0xFF), 1.3), "queen": ((0xFF, 0xD0, 0x2E), 1.6)}
    for name, (tint, scale) in types.items():
        img = base.copy()
        if tint:  # mirrors ColorFilter.mode(tint@0.45, srcATop) used in the game
            px = img.load()
            for y in range(img.height):
                for x in range(img.width):
                    r, g, b, a = px[x, y]
                    if a:
                        k = 0.45
                        px[x, y] = (round(r * (1 - k) + tint[0] * k),
                                    round(g * (1 - k) + tint[1] * k),
                                    round(b * (1 - k) + tint[2] * k), a)
        h = round(110 * scale)
        img = img.resize((round(img.width * h / img.height), h), Image.LANCZOS)
        canvas = Image.new("RGBA", (200, 190), (0, 0, 0, 0))
        canvas.paste(img, ((200 - img.width) // 2, (190 - img.height) // 2), img)
        canvas.save(os.path.join(DOCS, "ants", f"{name}.png"), optimize=True)
        print("wrote ants/%s.png" % name)


if __name__ == "__main__":
    write("banner.svg", banner())
    write("divider.svg", divider())
    for slug, icon, title, sub in [
        ("gameplay", "🎬", "SEE IT IN ACTION", "Real frames rendered from the game itself"),
        ("features", "✨", "FEATURES", "Everything packed into the game"),
        ("how-to-play", "🕹️", "HOW TO PLAY", "Tap, combo, survive"),
        ("ants", "🐜", "MEET THE ANTS", "Four enemy types, each with its own trick"),
        ("getting-started", "🚀", "GETTING STARTED", "Run it on any platform in minutes"),
        ("structure", "🗂️", "PROJECT STRUCTURE", "Where everything lives"),
        ("built-with", "🛠️", "BUILT WITH", "The tools behind the game"),
        ("roadmap", "🗺️", "ROADMAP", "What is done and what is next"),
    ]:
        write(f"sections/{slug}.svg", section(slug, icon, title, sub))
    tinted_ants()
