#!/usr/bin/env python3
"""Turns the frames written by tool/capture_frames_test.dart into phone-framed
GIFs and screenshots under docs/media.

Usage: python3 tool/make_media.py [frames_dir]   (needs Pillow and ffmpeg)
"""
import glob, os, shutil, subprocess, sys, tempfile
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAMES = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build/frames")
OUT = os.path.join(ROOT, "docs/media")
os.makedirs(OUT, exist_ok=True)

BEZEL = {"gif": 8, "shot": 10}
ACCENT = (255, 138, 42)


def phone(screen: Image.Image, width: int, bezel: int) -> Image.Image:
    """Wraps a screenshot in a rounded phone frame with a transparent surround."""
    scale = 4  # supersample the mask for smooth corners
    sw = width
    sh = round(screen.height * sw / screen.width)
    screen = screen.convert("RGBA").resize((sw, sh), Image.LANCZOS)
    W, H = sw + bezel * 2, sh + bezel * 2
    r_out, r_in = round(sw * 0.15), round(sw * 0.15) - bezel // 2

    body = Image.new("RGBA", (W * scale, H * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((0, 0, W * scale - 1, H * scale - 1), r_out * scale, fill=(11, 18, 32, 255))
    d.rounded_rectangle((0, 0, W * scale - 1, H * scale - 1), r_out * scale, outline=ACCENT + (150,), width=scale * 2)
    body = body.resize((W, H), Image.LANCZOS)

    mask = Image.new("L", (sw * scale, sh * scale), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw * scale - 1, sh * scale - 1), r_in * scale, fill=255)
    mask = mask.resize((sw, sh), Image.LANCZOS)
    body.paste(screen, (bezel, bezel), mask)

    # camera punch-hole
    over = Image.new("RGBA", (W * scale, H * scale), (0, 0, 0, 0))
    od = ImageDraw.Draw(over)
    cx, cy, cr = W * scale // 2, (bezel + round(sw * 0.045)) * scale, round(sw * 0.017) * scale
    od.ellipse((cx - cr, cy - cr, cx + cr, cy + cr), fill=(6, 9, 16, 255))
    over = over.resize((W, H), Image.LANCZOS)
    body.alpha_composite(over)
    return body


def frames_of(scene):
    return sorted(glob.glob(os.path.join(FRAMES, scene, "[0-9]*.png")))


def make_gif(scene, name, width=280, fps=15, colors=112, skip=0, tail=None):
    files = frames_of(scene)[skip:]
    if tail:
        files = files[:tail]
    if not files:
        print("no frames for", scene)
        return
    tmp = tempfile.mkdtemp()
    try:
        for i, f in enumerate(files):
            phone(Image.open(f), width, BEZEL["gif"]).save(os.path.join(tmp, f"{i:05d}.png"))
        pal = os.path.join(tmp, "pal.png")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(fps), "-i", os.path.join(tmp, "%05d.png"),
                        "-vf", f"palettegen=max_colors={colors}:reserve_transparent=1:stats_mode=diff", pal], check=True)
        dest = os.path.join(OUT, name)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(fps), "-i", os.path.join(tmp, "%05d.png"), "-i", pal,
                        "-lavfi", "paletteuse=dither=bayer:bayer_scale=4:alpha_threshold=128:diff_mode=rectangle",
                        "-loop", "0", dest], check=True)
        print(f"{name}: {len(files)} frames, {os.path.getsize(dest)/1024/1024:.2f} MB")
    finally:
        shutil.rmtree(tmp)


def make_shot(scene, name, width=360):
    files = frames_of(scene)
    if not files:
        print("no shot", scene)
        return
    img = phone(Image.open(files[0]), width, BEZEL["shot"])
    dest = os.path.join(OUT, name)
    img.save(dest, optimize=True)
    print(f"{name}: {os.path.getsize(dest)/1024:.0f} KB")


if __name__ == "__main__":
    make_gif("menu", "menu.gif", width=250, colors=80)
    make_gif("play", "gameplay.gif", width=250, colors=72, skip=20, tail=140)
    make_gif("hall", "hall-of-fame.gif", width=250, colors=80)
    for scene, name in [("shot_start", "start.png"), ("shot_play", "play.png"), ("shot_pause", "pause.png"),
                        ("shot_gameover", "gameover.png"), ("shot_stats", "stats.png"),
                        ("shot_achievements", "achievements.png"), ("shot_top10", "top10.png")]:
        make_shot(scene, name)
