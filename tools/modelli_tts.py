import trimesh, glob, io, numpy as np
from PIL import Image
M='tts/Mods/Models/'; I='tts/Mods/Images/'
def f(d,k): 
    r=glob.glob(d+'*'+k+'*'); return r[0] if r else None
spec={'flotta_barbara':('5DF2FF0FA346B2EF',None,(0.45,0.28,0.15)),
'cavalleria_barbara':('A2D59B7AE28DB317','AC1ACC6BB0',None),
'galea':('BFC0CA661AE816D8','12624E256C',None),
'catafratti':('D765C645FE4728DF','7A28E01874',None),
'flotta_elfica':('9032215A10431991',None,(0.19,0.56,0.17)),
'cavalleria_elfica':('239B06E94807950D','D1278A7328',None),
'cavalieri_warg':('0EB501CB8A02D45A','85BCEE5A73',None),
'rana_da_guerra':('1C6D92F52C591319','417CFC1134',None),
'popolo_balena':('31497D27618944B0',None,(0.25,0.3,0.6)),
'aeronave':('BE7C2899BEE114B8',None,(0.62,0.55,0.42)),
'flotta_pirata':('9032215A10431991',None,(0.15,0.12,0.1))}
for nome,(mk,tk,col) in spec.items():
    mf=f(M,mk)
    sc=trimesh.load(mf,force='mesh',process=False)
    if tk:
        im=Image.open(f(I,tk)).convert('RGB'); im.thumbnail((1024,1024))
        if sc.visual.kind=='texture' or hasattr(sc.visual,'uv'):
            uv=sc.visual.uv if hasattr(sc.visual,'uv') else None
        else: uv=None
        mat=trimesh.visual.material.PBRMaterial(baseColorTexture=im,metallicFactor=0.0,roughnessFactor=0.8)
        if uv is not None:
            sc.visual=trimesh.visual.TextureVisuals(uv=uv,material=mat)
    else:
        c=[int(x*255) for x in col]+[255]
        sc.visual=trimesh.visual.ColorVisuals(sc,face_colors=np.tile(c,(len(sc.faces),1)))
    b=sc.bounds; print(nome,len(sc.faces),np.round(b[1]-b[0],2), sc.visual.kind)
    sc.export('/home/claude/barbarian-kings/assets/modelli/%s.glb'%nome)
