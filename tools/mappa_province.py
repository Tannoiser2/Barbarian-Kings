import numpy as np, json, cv2
from PIL import Image
from skimage.segmentation import watershed
from scipy import ndimage as ndi
Image.MAX_IMAGE_PIXELS=None
W,H=2895,1917
c=np.array(Image.open('tts/Mods/Images/httpssteamusercontentaakamaihdnetugc97227892810719637E4B29E06B7EA3BF63DE94E8A9281498A97BB8404.png').convert('RGB').resize((W,H),Image.LANCZOS)).astype(int)
ID0=np.array(Image.open('/home/claude/barbarian-kings/assets/img/province_id.png').resize((W,H),Image.NEAREST))
land=ID0>=18
r,g,b=c[...,0],c[...,1],c[...,2]
mx=np.maximum(np.maximum(r,g),b)
nero=((mx<150)&~((g>r+20)&(g>b+10)))|(mx<62)
el=cv2.GaussianBlur(nero.astype(np.float32),(0,0),4)
d=json.load(open('/home/claude/barbarian-kings/assets/dati/gioco.json'))
basso=(el<0.02)&land
lb,nb=ndi.label(basso); sz=ndi.sum(basso,lb,range(1,nb+1))
basso=np.isin(lb,np.where(sz>3000)[0]+1)
mk=np.zeros((H,W),np.int32)
for p in d['province']:
    if p['id']<18: continue
    x=int(p['x']*W); y=int(p['y']*H)
    best=None
    for rr in range(0,36,3):
        ys,xs=np.nonzero(basso[max(0,y-rr):y+rr+1,max(0,x-rr):x+rr+1])
        if len(xs):
            k=np.argmin((xs-min(rr,x))**2+(ys-min(rr,y))**2)
            best=(max(0,x-rr)+xs[k],max(0,y-rr)+ys[k]); break
    if best is None:
        best=(x,y); print('nessun punto basso',p['id'])
        cv2.circle(mk,(x,y),14,p['id'],-1)
    cv2.circle(mk,(int(best[0]),int(best[1])),4,p['id'],-1)
lab=watershed(np.round(el*40).astype(np.int32),mk,mask=land)
ID=ID0.copy(); ID[land]=lab[land]
# righe non assegnate: lascia ID0
ID[land&(lab==0)]=ID0[land&(lab==0)]
Image.fromarray(ID.astype(np.uint8)).resize((1448,959),Image.NEAREST).save('/tmp/idnew.png')
cc=c.astype(np.uint8).copy()
e=cv2.morphologyEx(ID.astype(np.uint8),cv2.MORPH_GRADIENT,np.ones((3,3),np.uint8))>0
cc[e]=(255,0,0)
Image.fromarray(cc).resize((1448,959)).crop((380,0,1300,800)).save('view/bordi2.png')
u,cn=np.unique(lab[land],return_counts=True)
print(dict(zip(u.tolist(),cn.tolist())))
print('nero frac', nero[land].mean(), 'el>0.05', (el[land]>0.05).mean())
