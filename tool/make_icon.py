"""Draws the Cunning Cat logo (a winking cat) as PNGs for the app icon and splash.

Usage: python3 tool/make_icon.py   (needs Pillow)
Outputs assets/brand/icon.png (full icon), icon_fg.png (adaptive foreground),
splash.png (logo on transparent background).
"""
import os
from PIL import Image, ImageDraw

INDIGO = (30, 27, 75)
INDIGO_2 = (67, 56, 202)
AMBER = (245, 158, 11)
AMBER_DARK = (217, 119, 6)
WHITE = (255, 255, 255)
S = 4  # supersampling


def cat(draw, cx, cy, r):
    """Winking cat head centred at (cx, cy), head radius r."""
    # ears
    draw.polygon([(cx - r * 0.95, cy - r * 0.15), (cx - r * 0.80, cy - r * 1.25), (cx - r * 0.20, cy - r * 0.80)], fill=AMBER)
    draw.polygon([(cx + r * 0.95, cy - r * 0.15), (cx + r * 0.80, cy - r * 1.25), (cx + r * 0.20, cy - r * 0.80)], fill=AMBER)
    # inner ears
    draw.polygon([(cx - r * 0.78, cy - r * 0.35), (cx - r * 0.72, cy - r * 0.98), (cx - r * 0.38, cy - r * 0.72)], fill=AMBER_DARK)
    draw.polygon([(cx + r * 0.78, cy - r * 0.35), (cx + r * 0.72, cy - r * 0.98), (cx + r * 0.38, cy - r * 0.72)], fill=AMBER_DARK)
    # head
    draw.ellipse([cx - r, cy - r * 0.9, cx + r, cy + r * 0.9], fill=AMBER)
    # open eye (left): almond with slit pupil
    ex, ey, ew, eh = cx - r * 0.40, cy - r * 0.08, r * 0.30, r * 0.20
    draw.ellipse([ex - ew, ey - eh, ex + ew, ey + eh], fill=INDIGO)
    draw.ellipse([ex - ew * 0.22, ey - eh * 0.85, ex + ew * 0.22, ey + eh * 0.85], fill=AMBER)
    draw.ellipse([ex + ew * 0.35, ey - eh * 0.6, ex + ew * 0.62, ey - eh * 0.2], fill=WHITE)
    # winking eye (right): a confident curve
    wx, wy = cx + r * 0.40, cy - r * 0.06
    draw.arc([wx - r * 0.30, wy - r * 0.22, wx + r * 0.30, wy + r * 0.18], start=200, end=340, fill=INDIGO, width=int(r * 0.09))
    # nose
    draw.polygon([(cx - r * 0.10, cy + r * 0.20), (cx + r * 0.10, cy + r * 0.20), (cx, cy + r * 0.32)], fill=INDIGO)
    # smirk
    draw.arc([cx - r * 0.05, cy + r * 0.18, cx + r * 0.35, cy + r * 0.52], start=20, end=160, fill=INDIGO, width=int(r * 0.06))
    # whiskers
    w = int(r * 0.035)
    for dy in (0.30, 0.42):
        draw.line([(cx - r * 0.35, cy + r * dy), (cx - r * 1.05, cy + r * (dy - 0.08))], fill=INDIGO, width=w)
        draw.line([(cx + r * 0.35, cy + r * dy), (cx + r * 1.05, cy + r * (dy - 0.08))], fill=INDIGO, width=w)


def gradient(size):
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            px[x, y] = tuple(int(INDIGO[i] * (1 - t) + INDIGO_2[i] * t) for i in range(3))
    return img


def render(size, background, scale):
    big = size * S
    if background:
        img = gradient(big // 8).resize((big, big)).convert('RGBA')
    else:
        img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cat(d, big / 2, big * 0.56, big * 0.30 * scale)
    return img.resize((size, size), Image.LANCZOS)


def main(out='assets/brand'):
    os.makedirs(out, exist_ok=True)
    render(1024, True, 1.0).save(os.path.join(out, 'icon.png'))
    render(1024, False, 0.62).save(os.path.join(out, 'icon_fg.png'))
    render(768, False, 1.0).save(os.path.join(out, 'splash.png'))


if __name__ == '__main__':
    main()
