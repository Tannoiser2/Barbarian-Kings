import json
names={1:"Sea of Whales",2:"Sea of Ice",3:"Northern Arm",4:"Dragon's Claw",5:"Sea of Winds",6:"Thorian Abyss",7:"Sta Fira Ocean",8:"South Starsea",9:"East Starsea",10:"North Starsea",11:"West Starsea",12:"Mel Fira Ocean",13:"Nila's Sea",14:"Strait of Tuli",15:"Bay of Jedren",16:"Sea of Kizann",17:"Gulf of Bornn",18:"Korsland",19:"Kann",20:"Arkann",21:"Andesite",22:"Sira",23:"B'nor",24:"Sukann",25:"Stel",26:"Yakash",27:"Mela",28:"Yaro",29:"E'kor",30:"Shevane",31:"Zann",32:"Grandarite",33:"M'yakash",34:"Tharady",35:"Sashok",36:"Chevois",37:"Wys",38:"Drormt",39:"Munampt",40:"Hadren",41:"Penna",42:"Romark",43:"Lilla",44:"Starhome",45:"Thoria",46:"Ela",47:"Chesa"}
it={1:"Mare delle Balene",2:"Mare dei Ghiacci",3:"Braccio Settentrionale",4:"Artiglio del Drago",5:"Mare dei Venti",6:"Abisso Toriano",7:"Oceano Sta Fira",8:"Mare Stellato Sud",9:"Mare Stellato Est",10:"Mare Stellato Nord",11:"Mare Stellato Ovest",12:"Oceano Mel Fira",13:"Mare di Nila",14:"Stretto di Tuli",15:"Baia di Jedren",16:"Mare di Kizann",17:"Golfo di Bornn"}
tax={1:1,2:0,3:2,4:1,5:1,6:1,7:1,8:2,9:1,10:2,11:2,12:1,13:1,14:4,15:2,16:2,17:2,18:6,19:6,20:4,21:8,22:6,23:2,24:6,25:4,26:10,27:3,28:8,29:6,30:6,31:3,32:6,33:4,34:8,35:3,36:4,37:3,38:4,39:3,40:4,41:6,42:2,43:2,44:8,45:4,46:4,47:10}
nat={1:"balene",18:"barbari",19:"barbari",20:"barbari",21:"nani",22:"elfi",23:"feudali",24:"barbari",25:"nani",26:"orchi",27:"elfi",28:"elfi",29:"barbari",30:"civili",31:"barbari",32:"nani",33:"orchi",34:"civili",35:"orchi",36:"feudali",37:"aeronauti",38:"palustri",39:"palustri",40:"civili",41:"civili",42:"feudali",43:"elfi",44:"pirati",45:"civili",46:"elfi",47:"civili"}
terr={}
for k in range(1,48):
    terr[k]='mare' if k<=17 else 'pianura'
for k in (21,25,32): terr[k]='montagna'
for k in (22,23,27,28,43,46,44): terr[k]='foresta'
for k in (38,39): terr[k]='palude'
adj_txt="""1-2 1-17 1-18 1-19 1-20 1-21 2-3 2-5 2-18 2-22 2-23 2-29 3-4 3-23 3-28 3-29 3-30 4-5 4-6 4-28 4-30 4-35 4-36 4-37 4-42
5-6 5-29 5-30 5-37 6-7 6-37 6-42 6-45 7-8 7-11 7-12 7-45 7-47 8-9 8-11 8-44 8-45 8-47 9-10 9-38 9-39 9-44 9-45
10-11 10-14 10-38 10-41 10-44 11-12 11-14 11-43 11-44 11-46 12-13 12-43 12-46 13-14 13-15 13-16 13-43
14-15 14-40 14-41 14-43 15-16 15-31 15-34 15-38 15-40 16-17 16-31 17-19 17-24 17-31
18-21 19-20 19-24 20-21 20-24 20-25 21-22 21-25 21-26 22-23 22-26 22-27 23-27 23-28 24-25 24-31 24-32
25-26 25-32 26-27 26-32 26-33 27-28 28-33 28-35 29-30 31-32 31-34 32-33 32-34 33-34 33-35 34-35 34-36 34-38
35-36 36-38 36-39 36-42 38-39 38-40 38-41 39-42 39-45 40-41 42-45 43-46 45-47"""
adj={k:set() for k in range(1,48)}
for t in adj_txt.split():
    a,b=map(int,t.split('-')); adj[a].add(b); adj[b].add(a)
C=json.load(open('centers_color.json'))
W,H=5790,3834
prov=[]
for k in range(1,48):
    prov.append({"id":k,"nome":names[k],"nome_it":it.get(k,names[k]),"tasse":tax[k],"nativi":nat.get(k,""),"terreno":terr[k],
      "adiacenti":sorted(adj[k]),"x":round(C[str(k)][0]/W,4),"y":round(C[str(k)][1]/H,4)})
# sanity: symmetric, connected
import collections
seen={1};q=[1]
while q:
    a=q.pop()
    for b in adj[a]:
        if b not in seen: seen.add(b);q.append(b)
print('connected',len(seen))
for p in prov:
    if p['terreno']!='mare': p['costiera']=any(b<=17 for b in p['adiacenti'])
print([p['nome'] for p in prov if p['terreno']!='mare' and not p['costiera']])
T=[ # id range, tipo
]
unita=[]
def add(ids,tipo,orig,cost,mant,forza,mov,nome):
    for i in ids: unita.append({"id":i,"tipo":tipo,"origine":orig,"costo":cost,"mant":mant,"forza":forza,"mov":mov})
tipi={
 "re":{"nome":"Re","classe":"capo"},"eroe":{"nome":"Eroe","classe":"capo"},"mago":{"nome":"Mago","classe":"mago"},
 "flotta_barbara":{"nome":"Flotta barbara","classe":"flotta"},"fanteria_barbara":{"nome":"Fanteria barbara","classe":"fanteria"},"cavalleria_barbara":{"nome":"Cavalleria barbara","classe":"cavalleria"},
 "galea":{"nome":"Flotta di galee","classe":"flotta"},"legione":{"nome":"Legione","classe":"fanteria","legione":True},"catafratti":{"nome":"Catafratti","classe":"cavalleria"},
 "flotta_elfica":{"nome":"Flotta elfica","classe":"flotta"},"arcieri_elfici":{"nome":"Arcieri elfici","classe":"fanteria"},"cavalleria_elfica":{"nome":"Cavalleria elfica","classe":"cavalleria"},
 "fanteria_orchesca":{"nome":"Fanteria orchesca","classe":"fanteria"},"cavalieri_warg":{"nome":"Cavalieri dei warg","classe":"cavalleria"},
 "fanteria_nanica":{"nome":"Fanteria nanica","classe":"fanteria"},"fanteria_feudale":{"nome":"Fanteria feudale","classe":"fanteria"},
 "rana_da_guerra":{"nome":"Rana da guerra","classe":"rana"},"popolo_balena":{"nome":"Popolo delle balene","classe":"balena"},
 "aeronave":{"nome":"Aeronave","classe":"aeronave"},"flotta_pirata":{"nome":"Flotta pirata","classe":"flotta"}}
case={10:"Evrin",20:"Nol",30:"Melmil",40:"LiMoren",50:"Greensword"}
re_nomi={10:"Re Coth",20:"Re Aradren II",30:"Re Fina",40:"Re Wil",50:"Re Baxx"}
for h in (10,20,30,40,50):
    unita.append({"id":h,"tipo":"re","origine":"","costo":0,"mant":0,"forza":0,"mov":4,"casa":case[h],"nome":re_nomi[h]})
    for e in (h+1,h+2): unita.append({"id":e,"tipo":"eroe","origine":"","costo":10,"mant":4,"forza":0,"mov":4,"casa":case[h]})
    for m in (h+3,h+4): unita.append({"id":m,"tipo":"mago","origine":"","costo":10,"mant":4,"forza":0,"mov":4,"casa":case[h]})
add(range(111,116),"flotta_barbara","barbari",2,1,1,2,"")
add(range(121,127),"fanteria_barbara","barbari",4,2,2,2,"")
add(range(131,137),"cavalleria_barbara","barbari",6,3,2,3,"")
add(range(211,216),"galea","civili",6,2,2,2,"")
add(range(221,227),"legione","civili",7,3,3,2,"")
add(range(231,234),"catafratti","civili",10,5,3,3,"")
add(range(311,316),"flotta_elfica","elfi",7,3,3,2,"")
add(range(321,327),"arcieri_elfici","elfi",5,2,2,2,"")
add(range(331,336),"cavalleria_elfica","elfi",7,4,2,4,"")
add(range(411,417),"fanteria_orchesca","orchi",1,1,1,2,"")
add(range(421,425),"cavalieri_warg","orchi",3,2,1,3,"")
add(range(511,517),"fanteria_nanica","nani",8,3,3,2,"")
add(range(611,615),"fanteria_feudale","feudali",2,1,1,2,"")
add((711,712),"rana_da_guerra","palustri",5,2,2,2,"")
add((811,812),"popolo_balena","balene",5,2,2,2,"")
add((911,912),"aeronave","aeronauti",14,5,3,3,"")
add((951,),"flotta_pirata","pirati",8,3,4,2,"")
print(len(unita))
fanteria_nativa={"barbari":"fanteria_barbara","civili":"legione","elfi":"arcieri_elfici","orchi":"fanteria_orchesca","nani":"fanteria_nanica","feudali":"fanteria_feudale","palustri":"rana_da_guerra","balene":"popolo_balena","aeronauti":"aeronave","pirati":"flotta_pirata"}
json.dump({"province":prov,"unita":unita,"tipi":tipi,"fanteria_nativa":fanteria_nativa},open('/home/claude/barbarian-kings/assets/dati/gioco.json','w'),ensure_ascii=False,indent=1)
