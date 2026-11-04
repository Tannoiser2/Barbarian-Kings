import numpy as np, cv2, json
from PIL import Image, ImageFilter
from scipy import ndimage as ndi
R='/home/claude/barbarian-kings/assets/'
src=Image.open('/mnt/user-data/uploads/d04a6539-image.png').convert('RGB')
W,H=src.size
ID=np.load('gptid.npy').astype(np.uint8)
# 1. texture ingrandita 2x con i due tagli tratteggiati nella catena montuosa
big=src.resize((W*2,H*2),Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=2,percent=60,threshold=2))
a=np.array(big)
TAGLI=[((365,355),(470,418)),((275,527),(390,595))]
for (x0,y0),(x1,y1) in TAGLI:
    L=np.hypot(x1-x0,y1-y0); n=int(L/7)
    for k in range(n):
        if k%2: continue
        t0=k/n; t1=min(1,(k+1)/n)
        p0=(int(2*(x0+(x1-x0)*t0)),int(2*(y0+(y1-y0)*t0))); p1=(int(2*(x0+(x1-x0)*t1)),int(2*(y0+(y1-y0)*t1)))
        cv2.line(a,p0,p1,(28,22,16),5,cv2.LINE_AA)
Image.fromarray(a).save(R+'img/mappa_moderna.webp',quality=88)
Image.fromarray(ID).save(R+'img/province_id_moderna.png')
# 2. punti di riferimento: miniature e scritte
d=json.load(open(R+'dati/gioco.json'))
for p in d['province']:
    m=(ID==p['id'])
    dt=ndi.distance_transform_edt(np.pad(m,1))[1:-1,1:-1]
    y,x=np.unravel_index(np.argmax(dt),dt.shape)
    r=dt[y,x]
    # scritta: il punto più interno lontano almeno 55 px dalle miniature
    yy,xx=np.mgrid[0:H,0:W]
    lontano=np.hypot(xx-x,yy-y)>min(55,r*1.6)
    dt2=np.where(lontano,dt,0)
    ly,lx=np.unravel_index(np.argmax(dt2),dt2.shape)
    if dt2[ly,lx]<9:
        lx,ly=x,int(y+r*0.9)
    p['mx']=round(x/W,4); p['my']=round(y/H,4); p['lx']=round(lx/W,4); p['ly']=round(ly/H,4)
json.dump(d,open(R+'dati/gioco.json','w'),ensure_ascii=False,indent=1)
# 3. rilievo
c=np.array(src).astype(float)/255
lum=c.mean(-1)
terra=(ID>=18).astype(float)
base=cv2.GaussianBlur(terra,(0,0),3)*0.10
monti=np.isin(ID,[21,25,32]).astype(float)
ms=cv2.GaussianBlur(monti,(0,0),4)
cresta=np.clip((cv2.GaussianBlur(lum,(0,0),1.2)-0.30)/0.45,0,1)
largo=cv2.GaussianBlur(cresta,(0,0),6)
h=base+ms*(0.14+0.42*cresta*0.6+0.42*largo*0.6)
# isola di Starhome: un cono boscoso
sh=(ID==44).astype(float); dts=ndi.distance_transform_edt(sh); h+=np.clip(dts/dts.max(),0,1)**1.5*0.35
# colline sparse dipinte sulla terra (marroni) fuori dai monti
coll=((c[...,0]>c[...,2]+0.12)&(lum<0.45)&(terra>0)&(monti==0)).astype(float)
h+=cv2.GaussianBlur(coll,(0,0),3)*0.08
foreste=np.isin(ID,[22,23,27,28,43,46]).astype(float)
h+=cv2.GaussianBlur(foreste,(0,0),4)*0.03
h=cv2.GaussianBlur(h,(0,0),0.8)
print('altezza max',h.max())
HMAX=1.0
Image.fromarray(np.clip(h/HMAX*255,0,255).astype(np.uint8)).save(R+'img/rilievo.png')
# 4. alberi e canne
rng=np.random.RandomState(11)
verde=(c[...,1]>c[...,0]+0.03)&(c[...,1]>c[...,2]+0.02)&(lum<0.42)
foresta_px=(verde&(foreste>0))|(verde&(ID==44))
ys,xs=np.nonzero(foresta_px)
sel=rng.choice(len(xs),size=min(6500,len(xs)),replace=False)
alberi=[]
for i in sel:
    x,y=xs[i],ys[i]
    alberi.append([round(x/W,4),round(y/H,4),round(float(rng.uniform(0.7,1.3)),2),int(rng.randint(0,4))])
canne=[]
palude=np.isin(ID,[38,39])
ys,xs=np.nonzero(palude&(c[...,1]>c[...,2]-0.05))
sel=rng.choice(len(xs),size=min(1600,len(xs)),replace=False)
for i in sel:
    canne.append([round(xs[i]/W,4),round(ys[i]/H,4),round(float(rng.uniform(0.6,1.4)),2)])
json.dump({"alberi":alberi,"canne":canne,"hmax":HMAX},open(R+'dati/vegetazione.json','w'))
print(len(alberi),len(canne))
