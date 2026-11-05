#!/usr/bin/env python3
"""Disegna le illustrazioni provvisorie delle carte (stemmi luminosi su fondo scuro), usate finché
in assets/img/carte/ non ci sono le immagini create con ChatGPT (vedi docs/immagini_chatgpt.md).
Uso: python3 tools/carte_provvisorie.py
"""
import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

R = os.path.join(os.path.dirname(__file__), '..', 'assets', 'ui')
W, H = 240, 360

COL = {
    'mente': (150, 160, 255), 'elementi': (110, 215, 255), 'illusione': (240, 150, 255),
    'necromanzia': (130, 255, 100), 'marcia': (255, 200, 90), 'ritirata': (200, 220, 255),
    'tattica': (255, 120, 80), 'azione': (240, 200, 120),
}


def fondo(c):
    y, x = np.mgrid[0:H, 0:W]
    d = np.sqrt(((x - W / 2) / W) ** 2 + ((y - H * 0.45) / H) ** 2)
    g = np.clip(1 - d * 2.1, 0, 1) ** 1.6
    base = np.array([28, 18, 12], float)
    img = base[None, None, :] * (1 - g[..., None] * 0.3) + np.array(c)[None, None, :] * g[..., None] * 0.55
    rng = np.random.RandomState(3)
    img += (rng.rand(H, W, 1) - 0.5) * 10
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).convert('RGBA')


def stemma(nome, c):
    lay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    cx, cy = W // 2, int(H * 0.45)
    lw = 9
    if nome == 'mente':          # occhio
        d.ellipse((cx - 80, cy - 42, cx + 80, cy + 42), outline=c, width=lw)
        d.ellipse((cx - 28, cy - 28, cx + 28, cy + 28), fill=c)
        d.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(20, 12, 8))
    elif nome == 'elementi':     # fulmine
        pts = [(cx + 20, cy - 95), (cx - 40, cy + 5), (cx + 2, cy + 5), (cx - 22, cy + 95), (cx + 45, cy - 15), (cx + 4, cy - 15)]
        d.polygon(pts, fill=c)
    elif nome == 'illusione':    # luna e stelle
        d.ellipse((cx - 70, cy - 70, cx + 70, cy + 70), fill=c)
        d.ellipse((cx - 40, cy - 85, cx + 95, cy + 50), fill=(0, 0, 0, 0))
        for sx, sy, r in [(cx + 45, cy - 55, 9), (cx + 70, cy + 20, 6), (cx + 25, cy + 60, 7)]:
            d.ellipse((sx - r, sy - r, sx + r, sy + r), fill=c)
    elif nome == 'necromanzia':  # teschio
        d.ellipse((cx - 62, cy - 75, cx + 62, cy + 40), fill=c)
        d.rectangle((cx - 36, cy + 20, cx + 36, cy + 70), fill=c)
        for ex in (-26, 26):
            d.ellipse((cx + ex - 18, cy - 30, cx + ex + 18, cy + 8), fill=(20, 12, 8))
        d.polygon([(cx, cy + 12), (cx - 9, cy + 30), (cx + 9, cy + 30)], fill=(20, 12, 8))
        for tx in (-18, 0, 18):
            d.line((cx + tx, cy + 48, cx + tx, cy + 70), fill=(20, 12, 8), width=5)
    elif nome == 'marcia':       # stivale e frecce
        for k in range(3):
            x0 = cx - 75 + k * 45
            d.polygon([(x0, cy - 50), (x0 + 40, cy), (x0, cy + 50), (x0 + 14, cy)], fill=c)
    elif nome == 'ritirata':     # scudo
        d.polygon([(cx - 65, cy - 70), (cx + 65, cy - 70), (cx + 65, cy), (cx, cy + 85), (cx - 65, cy)], outline=c, width=lw)
        d.line((cx, cy - 60, cx, cy + 70), fill=c, width=lw)
    elif nome == 'tattica':      # spade incrociate
        for s in (-1, 1):
            d.line((cx - 70 * s, cy - 80, cx + 70 * s, cy + 80), fill=c, width=12)
            d.line((cx + 40 * s - 22, cy + 50 - 22 * s * s, cx + 40 * s + 22, cy + 50 + 22 * 0), fill=c, width=8)
    else:                        # stella a otto punte
        pts = []
        for i in range(16):
            r = 85 if i % 2 == 0 else 32
            a = i * math.pi / 8 - math.pi / 2
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
        d.polygon(pts, fill=c)
    alone = lay.filter(ImageFilter.GaussianBlur(14))
    return alone, lay


for nome, c in COL.items():
    img = fondo(c)
    alone, lay = stemma(nome, c)
    img = Image.alpha_composite(img, alone)
    img = Image.alpha_composite(img, alone)
    img = Image.alpha_composite(img, lay)
    d = ImageDraw.Draw(img)
    d.rectangle((3, 3, W - 4, H - 4), outline=(200, 160, 80), width=3)
    d.rectangle((10, 10, W - 11, H - 11), outline=(120, 84, 30), width=1)
    img.convert('RGB').save(os.path.join(R, 'carta_%s.png' % nome))
print('fatto')
