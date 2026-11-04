#!/usr/bin/env python3
"""Controlla che ogni carattere usato nei testi del gioco esista nei font (niente quadratini).

Uso: python3 tools/controlla_glifi.py
Legge le stringhe di scripts/*.gd e i nomi di assets/dati/gioco.json e le confronta con i glifi
di ogni font in assets/font/. Esce con errore se manca qualcosa.
"""
import glob, json, os, re, sys
from fontTools.ttLib import TTFont

R = os.path.join(os.path.dirname(__file__), '..')
testi = []
for f in glob.glob(R + '/scripts/*.gd'):
    src = open(f, encoding='utf-8').read()
    # solo il contenuto delle stringhe, non i commenti
    testi += re.findall(r'"((?:[^"\\\n]|\\.)*)"', src)
    testi += re.findall(r'"""(.*?)"""', src, re.S)
d = json.load(open(R + '/assets/dati/gioco.json', encoding='utf-8'))
for p in d['province']:
    testi += [p['nome'], p.get('nome_it', '')]
for t in d['tipi'].values():
    testi.append(t['nome'])
for u in d['unita']:
    testi.append(u.get('nome', ''))
caratteri = set(''.join(testi)) - set('\n\t\r')
errori = 0
for font in sorted(glob.glob(R + '/assets/font/*.ttf')):
    cmap = TTFont(font).getBestCmap()
    manca = sorted(ch for ch in caratteri if ord(ch) not in cmap and ord(ch) > 31)
    nome = os.path.basename(font)
    if manca:
        print(f'{nome}: mancano {"".join(manca)!r}')
        errori += 1
    else:
        print(f'{nome}: tutti i {len(caratteri)} caratteri presenti')
sys.exit(1 if errori else 0)
