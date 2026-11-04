import numpy as np, cv2, json
from PIL import Image
from skimage.segmentation import watershed
from scipy import ndimage as ndi
from collections import Counter
c=np.array(Image.open('/mnt/user-data/uploads/d04a6539-image.png').convert('RGB')).astype(int)
H,W=c.shape[:2]
M={1:(320,130),2:(850,170),3:(805,455),4:(805,800),5:(965,625),6:(930,1105),7:(760,1410),8:(600,1270),9:(600,1085),10:(430,1075),11:(415,1255),12:(210,1410),13:(85,1125),14:(225,1075),15:(160,905),16:(75,775),17:(75,375),
18:(540,125),19:(190,255),20:(310,360),21:(480,300),22:(560,330),23:(770,350),24:(205,455),25:(350,470),26:(460,545),27:(690,470),28:(640,600),29:(895,465),30:(790,685),31:(200,665),32:(310,650),33:(470,675),34:(405,805),35:(590,733),36:(670,855),37:(900,848),38:(445,912),39:(655,1005),40:(255,945),41:(345,1022),42:(790,1000),43:(235,1185),44:(507,1175),45:(760,1205),46:(300,1335),47:(660,1355)}
r,g,b=c[...,0],c[...,1],c[...,2]
mx=np.maximum(np.maximum(r,g),b)
mn=np.minimum(np.minimum(r,g),b)
nero=((mx<62)&(mx-mn<22)).astype(np.uint8)
# tagli nella catena montuosa (Andesite / Stel / Grandarite)
TAGLI=[((365,355),(470,418)),((275,527),(390,595))]
for a,bb in TAGLI: cv2.line(nero,a,bb,1,3)
el=cv2.GaussianBlur(nero.astype(np.float32),(0,0),2.0)
q=np.round(el*30).astype(np.int32)
mk=np.zeros((H,W),np.int32)
for k,(x,y) in M.items(): cv2.circle(mk,(x,y),5,k,-1)
fr=np.zeros((H,W),bool); fr[14:H-14,14:W-14]=True
lab=watershed(q,mk,mask=fr)
np.save('gptid.npy',lab.astype(np.uint8))
cnt=Counter()
for A,B in [(lab[:,:-1],lab[:,1:]),(lab[:-1,:],lab[1:,:])]:
    m=(A!=B)&(A>0)&(B>0)
    for x,y in zip(A[m],B[m]): cnt[(min(x,y),max(x,y))]+=1
auto={k for k,v in cnt.items() if v>6}
d=json.load(open('/home/claude/barbarian-kings/assets/dati/gioco.json'))
mano=set()
for p in d['province']:
    for qq in p['adiacenti']: mano.add((min(p['id'],qq),max(p['id'],qq)))
print('solo nella mappa nuova',sorted((int(a),int(b),cnt[(a,b)]) for a,b in auto-mano))
print('solo nelle regole',sorted(mano-auto))
out=(c*0.55).astype(np.uint8)
e=cv2.morphologyEx(lab.astype(np.uint8),cv2.MORPH_GRADIENT,np.ones((3,3),np.uint8))>0
rng=np.random.RandomState(7); cols=rng.randint(60,255,(48,3))
out=(c*0.5+cols[lab]*0.5).astype(np.uint8); out[e]=(255,0,0)
for k,(x,y) in M.items(): cv2.putText(out,str(k),(x-8,y+5),cv2.FONT_HERSHEY_SIMPLEX,0.5,(0,0,0),2)
Image.fromarray(out).save('view/gptws.png')
