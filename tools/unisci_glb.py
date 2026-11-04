"""Unisce in un solo GLB il personaggio riggato di Meshy e le animazioni scaricate a parte,
riduce la texture a JPEG 1024 e toglie le mappe non necessarie (normal, ecc.) per il web.
Uso: unisci_glb.py uscita.glb rig.glb nome1=anim1.glb nome2=anim2.glb ..."""
import sys, io, struct
from pygltflib import GLTF2, BufferView, Accessor, Animation, AnimationChannel, AnimationChannelTarget, AnimationSampler
from PIL import Image

def blob_slice(g, blob, bv_index):
    bv = g.bufferViews[bv_index]
    o = bv.byteOffset or 0
    return blob[o:o + bv.byteLength]

out, rigf = sys.argv[1], sys.argv[2]
anims = [a.split('=', 1) for a in sys.argv[3:]]
g = GLTF2().load(rigf)
blob = g.binary_blob()
# nuovi dati per ogni bufferView
dati = [blob_slice(g, blob, i) for i in range(len(g.bufferViews))]
# texture: solo il colore di base, ridotto
mat = g.materials[0]
pbr = mat.pbrMetallicRoughness
base_tex = pbr.baseColorTexture.index if pbr and pbr.baseColorTexture else None
keep_img = g.textures[base_tex].source if base_tex is not None else None
for i, im in enumerate(g.images):
    if i == keep_img:
        pil = Image.open(io.BytesIO(dati[im.bufferView])).convert('RGB')
        pil.thumbnail((1024, 1024), Image.LANCZOS)
        b = io.BytesIO(); pil.save(b, 'JPEG', quality=86)
        dati[im.bufferView] = b.getvalue(); im.mimeType = 'image/jpeg'
    else:
        dati[im.bufferView] = b'\0\0\0\0'
mat.normalTexture = None; mat.occlusionTexture = None; mat.emissiveTexture = None
if pbr:
    pbr.metallicRoughnessTexture = None
    pbr.metallicFactor = 0.0; pbr.roughnessFactor = 0.85
# animazioni già presenti nel rig: si scartano (sono pose di riferimento)
g.animations = []
nomi = {n.name: i for i, n in enumerate(g.nodes)}
for nome, f in anims:
    a = GLTF2().load(f)
    ab = a.binary_blob()
    for an in a.animations[:1]:
        new = Animation(name=nome, channels=[], samplers=[])
        cache = {}
        def copia(acc_i):
            if acc_i in cache: return cache[acc_i]
            acc = a.accessors[acc_i]
            d = blob_slice(a, ab, acc.bufferView)[acc.byteOffset or 0:]
            bvn = len(g.bufferViews)
            g.bufferViews.append(BufferView(buffer=0, byteOffset=0, byteLength=len(d)))
            dati.append(d)
            na = Accessor(bufferView=bvn, byteOffset=0, componentType=acc.componentType, count=acc.count,
                          type=acc.type, max=acc.max, min=acc.min, normalized=acc.normalized)
            g.accessors.append(na)
            cache[acc_i] = len(g.accessors) - 1
            return cache[acc_i]
        for s in an.samplers:
            new.samplers.append(AnimationSampler(input=copia(s.input), output=copia(s.output), interpolation=s.interpolation))
        for c in an.channels:
            nn = a.nodes[c.target.node].name
            if nn not in nomi: continue
            new.channels.append(AnimationChannel(sampler=c.sampler, target=AnimationChannelTarget(node=nomi[nn], path=c.target.path)))
        g.animations.append(new)
# ricostruisce il buffer
nb = bytearray()
for i, bv in enumerate(g.bufferViews):
    while len(nb) % 4: nb += b'\0'
    bv.byteOffset = len(nb); bv.byteLength = len(dati[i]); nb += dati[i]
while len(nb) % 4: nb += b'\0'
g.buffers[0].byteLength = len(nb)
g.set_binary_blob(bytes(nb))
g.save_binary(out)
print(out, len(nb) // 1024, 'KB', [an.name for an in g.animations])
