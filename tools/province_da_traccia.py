"""Ricostruisce le mappe delle province (province_id.png e province_id_moderna.png) dalla traccia dei
confini (tools/dati/traccia_confini.png, nero = confine, orientata come la mappa moderna).

Ogni area chiusa della traccia diventa la provincia il cui punto (x, y per la mappa originale) vi cade
dentro; le linee si riempiono con la provincia più vicina. La cornice tiene i valori precedenti.
Uso: python3 tools/province_da_traccia.py
"""
import json
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

Image.MAX_IMAGE_PIXELS = None
R = __file__.rsplit('/tools/', 1)[0]
d = json.load(open(R + '/assets/dati/gioco.json'))
lin0 = np.array(Image.open(R + '/tools/dati/traccia_confini.png').convert('L')) < 128


def regioni(lin_full, W, H):
    lin = np.array(Image.fromarray((lin_full * 255).astype(np.uint8)).resize((W, H), Image.BOX)) > 60
    lin = ndi.binary_dilation(lin, iterations=3)
    lab, n = ndi.label(~lin)
    sz = ndi.sum(np.ones_like(lab), lab, range(n + 1))
    grandi = [i for i in range(1, n + 1) if sz[i] >= 300]
    idx = ndi.distance_transform_edt(~np.isin(lab, grandi), return_distances=False, return_indices=True)
    return lab[idx[0], idx[1]]


# mappa originale: la traccia ruotata di 90 gradi in senso orario
W, H = 2172, 1438
lab = regioni(np.rot90(lin0, 3), W, H)
vecchia = np.array(Image.open(R + '/assets/img/province_id.png').resize((W, H), Image.NEAREST))
lut = np.zeros(lab.max() + 1, np.uint8)
for p in d['province']:
    r = lab[int(float(p['y']) * H), int(float(p['x']) * W)]
    assert lut[r] == 0, 'due province nella stessa area: %d' % p['id']
    lut[r] = p['id']
orig = lut[lab]
orig[orig == 0] = vecchia[orig == 0]
Image.fromarray(orig).save(R + '/assets/img/province_id.png')

# mappa moderna: la stessa suddivisione, riportata nell'orientamento della traccia
Wm, Hm = 1532, 2313
mod = np.array(Image.fromarray(np.rot90(orig, 1)).resize((Wm, Hm), Image.NEAREST))
vecchia_m = np.array(Image.open(R + '/assets/img/province_id_moderna.png').resize((Wm, Hm), Image.NEAREST))
mod[mod == 0] = vecchia_m[mod == 0]
Image.fromarray(mod).save(R + '/assets/img/province_id_moderna.png')
print('fatto')
