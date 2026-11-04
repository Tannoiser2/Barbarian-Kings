#!/usr/bin/env python3
"""Disegna la grafica dell'interfaccia (pergamene, cuoio, oro, stemmi, monete, icone) in assets/ui/.

Tutto è generato qui, senza immagini esterne: rilanciare lo script rigenera i file.
Uso: python3 tools/grafica_ui.py
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

R = os.path.join(os.path.dirname(__file__), '..', 'assets', 'ui')
os.makedirs(R, exist_ok=True)
rng = np.random.RandomState(7)

ORO = (212, 170, 82)
ORO_SCURO = (120, 84, 30)
INCHIOSTRO = (52, 30, 14)


def rumore(w, h, scale, ottave=4, seme=0):
    r = np.random.RandomState(seme)
    out = np.zeros((h, w))
    amp = 1.0
    tot = 0
    for o in range(ottave):
        s = max(2, int(scale / (2 ** o)))
        small = r.rand(h // s + 2, w // s + 2)
        img = Image.fromarray((small * 255).astype(np.uint8)).resize((w + s * 2, h + s * 2), Image.BICUBIC)
        out += np.array(img)[s:s + h, s:s + w] / 255.0 * amp
        tot += amp
        amp *= 0.5
    return out / tot


def pergamena(w, h, seme=1, bordo=True, scura=False):
    n = rumore(w, h, 120, 5, seme)
    n2 = rumore(w, h, 30, 3, seme + 1)
    base = np.array([238, 223, 186]) if not scura else np.array([205, 182, 138])
    col = base[None, None, :] * (0.86 + 0.16 * n[..., None]) - (n2[..., None] - 0.5) * 18
    # macchie
    for k in range(6):
        cx, cy = rng.randint(0, w), rng.randint(0, h)
        rr = rng.randint(min(w, h) // 10, min(w, h) // 4)
        yy, xx = np.mgrid[0:h, 0:w]
        d = np.clip(1 - np.hypot(xx - cx, yy - cy) / rr, 0, 1) ** 2
        col -= d[..., None] * np.array([18, 22, 30]) * rng.uniform(0.3, 1.0)
    # bordi bruciacchiati
    yy, xx = np.mgrid[0:h, 0:w]
    dist = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy)).astype(float)
    v = np.clip(1 - dist / 38.0, 0, 1) ** 1.6
    col = col * (1 - v[..., None] * 0.45) + np.array([90, 55, 25]) * v[..., None] * 0.45
    img = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8)).convert('RGBA')
    if bordo:
        d = ImageDraw.Draw(img)
        d.rectangle([6, 6, w - 7, h - 7], outline=INCHIOSTRO + (255,), width=3)
        d.rectangle([12, 12, w - 13, h - 13], outline=ORO_SCURO + (220,), width=1)
        for (x, y) in [(12, 12), (w - 13, 12), (12, h - 13), (w - 13, h - 13)]:
            angolo(d, x, y, 1 if x < w / 2 else -1, 1 if y < h / 2 else -1)
    return img


def angolo(d, x, y, sx, sy):
    """Fregio d'angolo: un rombo dorato e due volute."""
    c = (x + sx * 10, y + sy * 10)
    d.polygon([(c[0], c[1] - 7), (c[0] + 7, c[1]), (c[0], c[1] + 7), (c[0] - 7, c[1])], fill=ORO + (255,), outline=INCHIOSTRO + (255,))
    for k in range(2):
        r = 9 + k * 6
        bb = [x + sx * 4 - r, y + sy * 4 - r, x + sx * 4 + r, y + sy * 4 + r]
        a0 = {(1, 1): 0, (-1, 1): 90, (-1, -1): 180, (1, -1): 270}[(sx, sy)]
        d.arc(bb, a0, a0 + 90, fill=ORO_SCURO + (255,), width=2)


def cuoio(w, h, colore, bordo_oro=True, luce=0.0, seme=3):
    n = rumore(w, h, 18, 3, seme)
    c = np.array(colore, float)
    yy = np.linspace(0, 1, h)[:, None]
    grad = 1.12 - 0.3 * yy
    col = c[None, None, :] * (grad[..., None] * (0.85 + 0.25 * n[..., None])) * (1 + luce)
    img = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8)).convert('RGBA')
    # angoli arrotondati
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], radius=9, fill=255)
    img.putalpha(mask)
    d = ImageDraw.Draw(img)
    if bordo_oro:
        d.rounded_rectangle([1, 1, w - 2, h - 2], radius=9, outline=(40, 22, 10, 255), width=2)
        d.rounded_rectangle([3, 3, w - 4, h - 4], radius=7, outline=ORO + (255,), width=2)
        d.rounded_rectangle([6, 6, w - 7, h - 7], radius=5, outline=(255, 230, 160, 70), width=1)
    # cuciture
    for x in range(14, w - 14, 9):
        d.line([(x, 9), (x + 4, 9)], fill=(255, 220, 160, 60), width=1)
        d.line([(x, h - 10), (x + 4, h - 10)], fill=(0, 0, 0, 60), width=1)
    return img


def scudo(colore, w=64, h=76):
    img = Image.new('RGBA', (w * 4, h * 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    W, H = w * 4, h * 4
    pts = [(8, 8), (W - 8, 8), (W - 8, H * 0.45)]
    for k in range(21):
        t = k / 20
        x = W - 8 - (W / 2 - 8) * t
        y = H * 0.45 + (H - 10 - H * 0.45) * math.sin(t * math.pi / 2)
        pts.append((x, y))
    for k in range(21):
        t = 1 - k / 20
        x = 8 + (W / 2 - 8) * t
        y = H * 0.45 + (H - 10 - H * 0.45) * math.sin(t * math.pi / 2)
        pts.append((x, y))
    pts.append((8, H * 0.45))
    d.polygon(pts, fill=(40, 22, 10, 255))
    interno = [(x * 0.86 + W * 0.07, y * 0.86 + H * 0.06) for x, y in pts]
    d.polygon(interno, fill=ORO + (255,))
    interno2 = [(x * 0.76 + W * 0.12, y * 0.76 + H * 0.105) for x, y in pts]
    d.polygon(interno2, fill=tuple(colore) + (255,))
    # banda diagonale e riflesso
    d.line([(W * 0.2, H * 0.18), (W * 0.82, H * 0.7)], fill=tuple(int(c * 0.8) for c in colore) + (255,), width=int(W * 0.08))

    return img.resize((w, h), Image.LANCZOS)


def moneta(s=40):
    img = Image.new('RGBA', (s * 4, s * 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    S = s * 4
    d.ellipse([4, 4, S - 4, S - 4], fill=(110, 75, 20, 255))
    d.ellipse([12, 12, S - 12, S - 12], fill=(232, 190, 80, 255))
    d.ellipse([30, 30, S - 30, S - 30], outline=(150, 105, 30, 255), width=8)
    # una piccola corona incisa
    cx, cy = S / 2, S / 2
    d.polygon([(cx - 34, cy + 18), (cx - 34, cy - 14), (cx - 17, cy + 2), (cx, cy - 24), (cx + 17, cy + 2), (cx + 34, cy - 14), (cx + 34, cy + 18)], fill=(150, 105, 30, 255))
    d.ellipse([22, 18, S * 0.45, S * 0.36], fill=(255, 245, 200, 90))
    return img.resize((s, s), Image.LANCZOS)


def divisore(w=420, h=26):
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = h // 2
    d.line([(10, c), (w / 2 - 22, c)], fill=ORO_SCURO + (255,), width=2)
    d.line([(w / 2 + 22, c), (w - 10, c)], fill=ORO_SCURO + (255,), width=2)
    d.polygon([(w / 2, c - 9), (w / 2 + 14, c), (w / 2, c + 9), (w / 2 - 14, c)], fill=ORO + (255,), outline=INCHIOSTRO + (255,))
    for x in (w / 2 - 30, w / 2 + 30):
        d.ellipse([x - 4, c - 4, x + 4, c + 4], fill=ORO + (255,))
    for x in (10, w - 10):
        d.ellipse([x - 3, c - 3, x + 3, c + 3], fill=ORO_SCURO + (255,))
    return img


def casella(spuntata, s=26):
    img = Image.new('RGBA', (s * 4, s * 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    S = s * 4
    d.rounded_rectangle([6, 6, S - 6, S - 6], radius=14, fill=(246, 234, 204, 255), outline=(60, 36, 16, 255), width=8)
    d.rounded_rectangle([16, 16, S - 16, S - 16], radius=8, outline=ORO + (255,), width=4)
    if spuntata:
        d.line([(26, 52), (44, 74), (80, 26)], fill=(150, 30, 20, 255), width=14, joint='curve')
    return img.resize((s, s), Image.LANCZOS)


def freccia_giu(s=20):
    img = Image.new('RGBA', (s * 4, s * 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    S = s * 4
    d.polygon([(12, 24), (S - 12, 24), (S / 2, S - 20)], fill=(243, 223, 168, 255), outline=(40, 22, 10, 255))
    return img.resize((s, s), Image.LANCZOS)


def barra(w=600, h=64):
    """Fascia di legno scuro con filo d'oro (barra in alto)."""
    n = rumore(w, h, 40, 4, 9)
    venature = (np.sin(np.linspace(0, 60, w)[None, :] + n * 8) * 0.5 + 0.5)
    base = np.array([62, 38, 20], float)
    col = base[None, None, :] * (0.75 + 0.35 * venature[..., None] * (0.7 + 0.3 * n[..., None]))
    img = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8)).convert('RGBA')
    d = ImageDraw.Draw(img)
    d.line([(0, h - 6), (w, h - 6)], fill=ORO + (255,), width=2)
    d.line([(0, h - 2), (w, h - 2)], fill=(20, 10, 4, 255), width=3)
    d.line([(0, 2), (w, 2)], fill=(120, 84, 40, 255), width=1)
    return img


def cornice_tonda(img_path, out, s=200):
    """Ritratto del Saggio (dal modello del mago creato con Meshy) in un medaglione dorato."""
    src = Image.open(img_path).convert('RGBA')
    w, h = src.size
    crop = src.crop((int(w * 0.28), int(h * 0.04), int(w * 0.72), int(h * 0.48))).resize((s, s), Image.LANCZOS)
    fondo = pergamena(s, s, seme=5, bordo=False, scura=True)
    fondo.alpha_composite(crop)
    mask = Image.new('L', (s, s), 0)
    ImageDraw.Draw(mask).ellipse([8, 8, s - 8, s - 8], fill=255)
    res = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    res.paste(fondo, (0, 0), mask)
    d = ImageDraw.Draw(res)
    d.ellipse([3, 3, s - 3, s - 3], outline=(40, 22, 10, 255), width=4)
    d.ellipse([7, 7, s - 7, s - 7], outline=ORO + (255,), width=5)
    d.ellipse([13, 13, s - 13, s - 13], outline=ORO_SCURO + (255,), width=1)
    res.save(out)


if __name__ == '__main__':
    pergamena(512, 512, 1).save(os.path.join(R, 'pergamena.png'))
    pergamena(512, 512, 2, scura=True).save(os.path.join(R, 'pergamena_scura.png'))
    pergamena(1024, 768, 4).save(os.path.join(R, 'pagina.png'))
    cuoio(220, 56, (128, 28, 22)).save(os.path.join(R, 'bottone.png'))
    cuoio(220, 56, (128, 28, 22), luce=0.22).save(os.path.join(R, 'bottone_su.png'))
    cuoio(220, 56, (90, 18, 14), luce=-0.1).save(os.path.join(R, 'bottone_giu.png'))
    cuoio(220, 56, (98, 86, 72)).save(os.path.join(R, 'bottone_spento.png'))
    cuoio(220, 56, (96, 64, 30)).save(os.path.join(R, 'bottone2.png'))
    cuoio(220, 56, (96, 64, 30), luce=0.22).save(os.path.join(R, 'bottone2_su.png'))
    cuoio(220, 56, (40, 70, 34)).save(os.path.join(R, 'bottone_verde.png'))
    cuoio(220, 56, (40, 70, 34), luce=0.22).save(os.path.join(R, 'bottone_verde_su.png'))
    barra().save(os.path.join(R, 'barra.png'))
    divisore().save(os.path.join(R, 'divisore.png'))
    moneta().save(os.path.join(R, 'moneta.png'))
    casella(False).save(os.path.join(R, 'casella.png'))
    casella(True).save(os.path.join(R, 'casella_si.png'))
    freccia_giu().save(os.path.join(R, 'freccia_giu.png'))
    colori = [(236, 230, 214), (190, 36, 30), (226, 178, 40), (48, 130, 52), (44, 84, 180)]
    for i, c in enumerate(colori):
        scudo(c).save(os.path.join(R, 'scudo_%d.png' % i))
    scudo((110, 104, 96)).save(os.path.join(R, 'scudo_neutrale.png'))
    mago = '/home/claude/meshy/glb/mago_anteprima.png'
    if os.path.exists(mago):
        cornice_tonda(mago, os.path.join(R, 'saggio.png'))
    print('fatto')
