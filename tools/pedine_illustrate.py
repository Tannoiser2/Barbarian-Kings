#!/usr/bin/env python3
"""Crea le pedine illustrate (assets/img/pedine_ill/NNN.png) dalle illustrazioni "reborn" delle unità
(tools/dati/illustrazioni_pedine/*.png, figure su fondo trasparente).

Ogni pedina tiene il colore di fondo della pedina SPI originale (assets/img/pedine_colore), così casate e
popoli restano riconoscibili, e porta forza e movimento in basso come le pedine originali.
Uso: python3 tools/pedine_illustrate.py
"""
import json, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
ILL = os.path.join(R, 'tools', 'dati', 'illustrazioni_pedine')
OUT = os.path.join(R, 'assets', 'img', 'pedine_ill')
os.makedirs(OUT, exist_ok=True)
L = 256

FIGURA = {
    're': 're', 'eroe': 'eroe', 'mago': 'mago',
    'fanteria_barbara': 'fanteria_barbarica', 'cavalleria_barbara': 'cavalleria_barbarica', 'flotta_barbara': 'flotta_da_guerra',
    'legione': 'fanteria_civilizzata', 'catafratti': 'cavalleria_civilizzata', 'galea': 'flotta_da_guerra',
    'arcieri_elfici': 'arciere_elfico', 'cavalleria_elfica': 'cavalleria_elfica', 'flotta_elfica': 'flotta_da_guerra',
    'fanteria_orchesca': 'fanteria_orchesca', 'cavalieri_warg': 'cavalcalupo_orchesco',
    'fanteria_nanica': 'guerriero_nanico', 'fanteria_feudale': 'cavaliere_feudale',
    'rana_da_guerra': 'rana_da_guerra', 'popolo_balena': 'balena', 'aeronave': 'aeronave', 'flotta_pirata': 'nave_pirata',
}

font = ImageFont.truetype(os.path.join(R, 'assets', 'font', 'PirataOne.ttf'), 58)
font_p = ImageFont.truetype(os.path.join(R, 'assets', 'font', 'AlmendraGrassetto.ttf'), 30)
d = json.load(open(os.path.join(R, 'assets', 'dati', 'gioco.json')))
cache = {}


def figura(nome):
    if nome not in cache:
        im = Image.open(os.path.join(ILL, nome + '.png')).convert('RGBA')
        im = im.crop(im.getchannel('A').point(lambda a: 255 if a > 20 else 0).getbbox())
        cache[nome] = im
    return cache[nome]


def colore_fondo(id_):
    p = os.path.join(R, 'assets', 'img', 'pedine_colore', '%03d.png' % id_)
    a = np.array(Image.open(p).convert('RGB')).astype(float)
    h, w, _ = a.shape
    bordo = np.concatenate([a[3:10].reshape(-1, 3), a[h - 10:h - 3].reshape(-1, 3), a[:, 3:10].reshape(-1, 3), a[:, w - 10:w - 3].reshape(-1, 3)])
    return tuple(int(v) for v in np.median(bordo, axis=0))


def testo(dr, xy, t, f, col=(255, 248, 225)):
    dr.text(xy, t, font=f, fill=col, anchor='ms', stroke_width=4, stroke_fill=(25, 12, 4))


for u in d['unita']:
    id_ = int(u['id'])
    c = np.array(colore_fondo(id_), float)
    y, x = np.mgrid[0:L, 0:L]
    g = 1 - np.clip(np.sqrt(((x - L / 2) / L) ** 2 + ((y - L * 0.42) / L) ** 2) * 1.5, 0, 1)
    fondo = c[None, None, :] * (0.62 + 0.5 * g[..., None])
    img = Image.fromarray(np.clip(fondo, 0, 255).astype(np.uint8)).convert('RGBA')
    fig = figura(FIGURA[u['tipo']])
    s = min(232 / fig.width, 186 / fig.height)
    f2 = fig.resize((int(fig.width * s), int(fig.height * s)), Image.LANCZOS)
    px = (L - f2.width) // 2
    py = 8 + (186 - f2.height) // 2
    ombra = Image.new('RGBA', img.size, (0, 0, 0, 0))
    sag = Image.new('RGBA', f2.size, (0, 0, 0, 170))
    ombra.paste(sag, (px + 4, py + 5), f2)
    img = Image.alpha_composite(img, ombra.filter(ImageFilter.GaussianBlur(5)))
    img.alpha_composite(f2, (px, py))
    dr = ImageDraw.Draw(img)
    # fascia in basso con i valori, come sulle pedine SPI
    band = Image.new('RGBA', (L, 58), (0, 0, 0, 0))
    bd = ImageDraw.Draw(band)
    bd.rectangle((0, 0, L, 58), fill=(20, 12, 6, 150))
    img.alpha_composite(band, (0, L - 58))
    if u['tipo'] in ('re', 'eroe', 'mago'):
        nome = u.get('nome') or {'eroe': 'Eroe', 'mago': 'Mago'}[u['tipo']]
        testo(dr, (L // 2 - 14, L - 16), nome, font_p)
        testo(dr, (L - 22, L - 14), str(u['mov']), font_p, (255, 225, 140))
    else:
        testo(dr, (L // 2, L - 12), '%d-%d' % (u['forza'], u['mov']), font)
    dr.rectangle((1, 1, L - 2, L - 2), outline=(235, 210, 150), width=3)
    dr.rectangle((7, 7, L - 8, L - 8), outline=tuple(int(v * 0.5) for v in c), width=2)
    img.convert('RGB').save(os.path.join(OUT, '%03d.webp' % id_), 'WEBP', quality=88, method=6)
print('pedine illustrate:', len(d['unita']))
