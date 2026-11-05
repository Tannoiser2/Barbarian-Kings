## Motore delle regole di Barbarian Kings (SPI, 1980, Ares n. 3).
## Deterministico: dato lo stesso seme e le stesse decisioni, ogni dispositivo arriva allo stesso stato.
## Le decisioni dei giocatori arrivano con invia(giocatore, decisione); quando tutti quelli attesi
## hanno deciso, la fase si risolve da sola e si passa alla successiva.
class_name Motore
extends RefCounted

const POOL := -2      # pedina disponibile (non in gioco)
const NEUTRALE := -1  # unità indigena neutrale

var n := 0
var g: Array = []          # giocatori: {nome, ia, tesoro, re, blocca}
var u: Dictionary = {}     # id -> {own, prov, illus, zombie, abil, magie, catt, invis}
var ctrl: Array = []       # 48 voci: proprietario della provincia (-1 nessuno)
var turno := 0
var fase := ""
var attese: Array = []     # giocatori da cui si aspetta una decisione
var dec: Dictionary = {}   # decisioni raccolte nella fase corrente
var seq: Array = []        # ordine di precedenza per le fasi a turno
var seq_i := 0
var seme := 1
var eventi: Array = []
var registro: Array = []
var finita := false
var vincitore := -1
var soglia := 120
var turni_max := 0
var gruppo: Array = []     # alleanza del turno: indice del gruppo, -1 nessuna
var usati: Dictionary = {}
var tornado: Array = []
var tempesta_mari: Array = []
var tempesta_monti: Array = []
var gelo: Array = []
var alluvione: Array = []
var lanciatori_eff: Dictionary = {}  # provincia/effetto -> giocatore che lo ha lanciato
var caduti: Dictionary = {}
var ritirati: Dictionary = {}
var combattuti: Dictionary = {}
var battaglie: Array = []
var batt_i := 0
var batt_ordine: Array = []
var batt_k := 0
var chiaro: Dictionary = {}
var piani: Dictionary = {}
var da_scegliere: Dictionary = {}   # fase province: quante ne restano per giocatore
var tasse_turno: Array = []
var mant_turno: Array = []

func _i(v) -> int:
	return int(v) if v != null else 0

# ---------------------------------------------------------------- dado

func dado() -> int:
	seme = (seme * 1103515245 + 12345) % 2147483648
	return int(seme / 65536) % 6 + 1

func _casuale(m: int) -> int:
	seme = (seme * 1103515245 + 12345) % 2147483648
	return int(seme / 65536) % m

func ordine_precedenza(gioc: Array) -> Array:
	var chiavi := {}
	for p in gioc:
		chiavi[p] = dado() * 1000 + _casuale(1000)
	var o := gioc.duplicate()
	o.sort_custom(func(a, b): return chiavi[a] > chiavi[b])
	return o

func ev(d: Dictionary) -> void:
	eventi.append(d)

func scrivi(t: String) -> void:
	registro.append(t)
	ev({"t": "log", "testo": t})

# ---------------------------------------------------------------- avvio

## cfg: {giocatori: [{nome, ia}], seme, turni_max}
func avvia(cfg: Dictionary) -> void:
	Dati.carica()
	seme = _i(cfg.get("seme", 12345)) % 2147483647 + 1
	turni_max = _i(cfg.get("turni_max", 0))
	g = []
	for gc in cfg["giocatori"]:
		g.append({"nome": str(gc["nome"]), "ia": bool(gc.get("ia", false)), "tesoro": 0, "re": 0, "blocca": true})
	n = g.size()
	soglia = 120 if n == 2 else (100 if n == 3 else 90)
	u = {}
	for id in Dati.unita:
		u[id] = {"own": POOL, "prov": 0, "illus": false, "zombie": false, "abil": [], "magie": [], "catt": -9, "invis": false}
	ctrl = []
	for i in 48:
		ctrl.append(-1)
	gruppo = []
	for i in n:
		gruppo.append(-1)
		g[i]["re"] = (i + 1) * 10
	var quante := 3 if n == 2 else (2 if n <= 4 else 1)
	seq = ordine_precedenza(range(n))
	seq_i = 0
	for i in n:
		da_scegliere[i] = quante
	scrivi("Barbarian Kings: %d giocatori, vittoria a %d di tasse." % [n, soglia])
	scrivi("Ordine di scelta delle province: " + ", ".join(seq.map(func(p): return g[p]["nome"])))
	fase = "province"
	attese = [seq[0]]
	dec = {}

# ---------------------------------------------------------------- interrogazioni

func unita_in(p: int, chi = null) -> Array:
	var out := []
	for id in u:
		var s: Dictionary = u[id]
		if s["prov"] == p and s["own"] != POOL and (chi == null or s["own"] == chi):
			out.append(id)
	out.sort()
	return out

func militari_in(p: int, chi) -> Array:
	return unita_in(p, chi).filter(func(id): return Dati.is_militare(id))

func alleati(a: int, b: int) -> bool:
	if a == b:
		return true
	if a < 0 or b < 0:
		return false
	return gruppo[a] >= 0 and gruppo[a] == gruppo[b]

func nemici(a: int, b: int) -> bool:
	return not alleati(a, b)

## Unità militari visibili di nemici (giocatori non alleati o neutrali) in una provincia.
func nemici_in(p: int, chi: int, anche_invisibili := false) -> Array:
	var out := []
	for id in unita_in(p):
		var s: Dictionary = u[id]
		if not Dati.is_militare(id) or s["own"] == POOL:
			continue
		if s["invis"] and not anche_invisibili:
			continue
		if nemici(s["own"], chi):
			out.append(id)
	return out

func controllate(p: int) -> Array:
	var out := []
	for q in range(1, 48):
		if ctrl[q] == p:
			out.append(q)
	return out

func tasse_di(p: int, con_tornado := false) -> int:
	var t := 0
	for q in controllate(p):
		if con_tornado and q in tornado:
			continue
		t += Dati.province[q]["tasse"]
	return t

func mantenimento(p: int) -> int:
	var t := 0
	for id in u:
		if u[id]["own"] == p:
			t += Dati.unita[id]["mant"]
	return t

func forza_nominale(ids: Array) -> int:
	var t := 0
	for id in ids:
		t += Dati.unita[id]["forza"]
	return t

func capi_di(p: int) -> Array:
	var out := []
	for id in u:
		if u[id]["own"] == p and Dati.classe(id) in ["capo", "mago"] and u[id]["catt"] == -9:
			out.append(id)
	out.sort()
	return out

func _capi_in(q: int, p: int) -> int:
	var c := 0
	for id in unita_in(q, p):
		if Dati.is_capo(id) and libero(id):
			c += 1
	return c

func conta_abil(id: int, a: String) -> int:
	return u[id]["abil"].count(a)

func libero(id: int) -> bool:
	return u[id]["catt"] == -9

## Gli "slot" di magia di un giocatore: ogni ramo conosciuto da ogni incantatore (un Re può averne fino a 3).
func slot_magia(p: int, ramo := "") -> Array:
	var out := []
	for id in capi_di(p):
		var m: Array = u[id]["magie"]
		for i in m.size():
			if ramo != "" and m[i]["r"] != ramo:
				continue
			var k := "%d:%d" % [id, i]
			if usati.has(k):
				continue
			out.append({"c": id, "i": i, "r": m[i]["r"], "v": m[i]["v"]})
	return out

func ha_ramo(p: int, rami: Array) -> bool:
	for r in rami:
		if not slot_magia(p, r).is_empty():
			return true
	return false

## Lancia un incantesimo dallo slot indicato: dado <= valore magico. 1 alza il valore, 6 lo abbassa.
func _lancia(c: int, i: int, s: String) -> bool:
	var k := "%d:%d" % [c, i]
	if usati.has(k) or not u.has(c) or u[c]["own"] < 0 or not libero(c):
		return false
	var m: Array = u[c]["magie"]
	if i < 0 or i >= m.size() or m[i]["r"] != Dati.INCANTESIMI[s]["ramo"]:
		return false
	usati[k] = true
	var v: int = m[i]["v"]
	var r := dado()
	var ok := r <= v
	if r == 1:
		m[i]["v"] = mini(5, v + 1)
	elif r == 6:
		m[i]["v"] = maxi(1, v - 1)
	var p: int = u[c]["own"]
	ev({"t": "incantesimo", "s": s, "c": c, "p": p, "ok": ok, "dado": r, "prov": u[c]["prov"]})
	scrivi("%s: %s lancia %s (dado %d su %d): %s." % [g[p]["nome"], Dati.nome_unita(c), Dati.INCANTESIMI[s]["nome"], r, v, "riuscito" if ok else "fallito"])
	return ok

func _slot_ok(p: int, x: Dictionary, s: String) -> bool:
	var c := _i(x.get("c", 0))
	return u.has(c) and u[c]["own"] == p and libero(c) and u[c]["prov"] > 0

# ---------------------------------------------------------------- invio decisioni

## Restituisce "" se la decisione è accettata, altrimenti il motivo del rifiuto.
func invia(p: int, d: Dictionary) -> String:
	if finita:
		return "partita finita"
	if not (p in attese):
		return "non è il tuo momento"
	var err := _valida(p, d)
	if err != "":
		return err
	dec[p] = d
	attese.erase(p)
	_dopo_decisione(p, d)
	return ""

func _valida(p: int, d: Dictionary) -> String:
	match fase:
		"province":
			var q := _i(d.get("prov", 0))
			if q < 18 or q > 47 or ctrl[q] != -1:
				return "provincia non disponibile"
		"re":
			var q := _i(d.get("prov", 0))
			if ctrl[q] != p:
				return "il Re va in una tua provincia"
			var ab: Array = d.get("abil", [])
			if ab.size() > 3:
				return "al massimo tre abilità"
			for a in ab:
				if not (a in Dati.ABILITA_EROE or a in Dati.RAMI):
					return "abilità sconosciuta"
		"acquisti":
			var spesa := 0
			for c in d.get("compra", []):
				var id := _i(c["id"])
				if not u.has(id) or Dati.unita[id]["tipo"] == "re":
					return "pedina non acquistabile"
				if not (u[id]["own"] == POOL or (u[id]["illus"] and u[id]["own"] >= 0)):
					return "pedina già in gioco: " + Dati.nome_unita(id)
				var q := _i(c["p"])
				if q <= 0 or ctrl[q] != p or not militari_in(q, NEUTRALE).is_empty():
					return "devi controllare la provincia"
				if Dati.is_militare(id) and Dati.unita[id]["origine"] != Dati.province[q]["nativi"]:
					return "%s non si recluta in %s" % [Dati.nome_tipo(id), Dati.nome_prov(q)]
				spesa += 1 if c.get("illus", false) else Dati.unita[id]["costo"]
			if spesa > g[p]["tesoro"]:
				return "non hai abbastanza sequin"
	return ""

func _dopo_decisione(p: int, d: Dictionary) -> void:
	match fase:
		"province":
			var q := _i(d["prov"])
			ctrl[q] = p
			da_scegliere[p] -= 1
			scrivi("%s sceglie %s." % [g[p]["nome"], Dati.nome_prov(q)])
			ev({"t": "controllo", "prov": q, "p": p})
			_prossimo_sceglitore()
			return
		"acquisti":
			_esegui_acquisti(p, d)
			seq_i += 1
			if seq_i < seq.size():
				attese = [seq[seq_i]]
				return
			_avanza()
			return
		"battaglia":
			_esegui_attacchi(p, d)
			_prossima_scelta_battaglia()
			return
	if attese.is_empty():
		_risolvi()

func _prossimo_sceglitore() -> void:
	for k in seq.size() * 3:
		seq_i = (seq_i + 1) % seq.size()
		var p: int = seq[seq_i]
		if da_scegliere[p] > 0:
			attese = [p]
			return
	# tutte scelte: si piazzano i Re
	fase = "re"
	attese = range(n)
	dec = {}

# ---------------------------------------------------------------- sequenza di gioco

const FASI := ["alleanze", "tornado", "finanze", "acquisti", "magia1", "chiaro", "piano", "rivela", "battaglia", "magia3"]

func _risolvi() -> void:
	match fase:
		"re":
			for p in n:
				var d: Dictionary = dec[p]
				var re: int = g[p]["re"]
				u[re]["own"] = p
				u[re]["prov"] = _i(d["prov"])
				for a in d.get("abil", []):
					if a in Dati.RAMI:
						u[re]["magie"].append({"r": a, "v": 2})
					else:
						u[re]["abil"].append(a)
				g[p]["tesoro"] = 50
				ev({"t": "arrivo", "id": re, "prov": u[re]["prov"]})
				scrivi("%s pone %s in %s." % [g[p]["nome"], Dati.nome_unita(re), Dati.nome_prov(u[re]["prov"])])
			# unità neutrali nelle province libere con tasse 6 o più
			for q in range(18, 48):
				if ctrl[q] == -1 and Dati.province[q]["tasse"] >= 6:
					var tipo: String = Dati.fanteria_nativa.get(Dati.province[q]["nativi"], "")
					var id := _dal_pool(tipo)
					if id > 0:
						u[id]["own"] = NEUTRALE
						u[id]["prov"] = q
						ev({"t": "arrivo", "id": id, "prov": q})
			scrivi("Unità indigene neutrali piazzate nelle province ricche non scelte.")
			_inizio_turno()
		"alleanze":
			_risolvi_alleanze()
			_avanza()
		"tornado":
			for p in dec:
				for x in dec[p].get("incanti", []):
					if x.get("s", "") == "tornado" and _slot_ok(p, x, "tornado"):
						if _lancia(_i(x["c"]), _i(x["i"]), "tornado"):
							var q := _i(x["prov"])
							tornado.append(q)
							ev({"t": "effetto", "s": "tornado", "prov": q})
							scrivi("Un tornado devasta %s: niente tasse." % Dati.nome_prov(q))
			_avanza()
		"finanze":
			for p in dec:
				_esegui_manutenzione(p, dec[p])
			for p in n:
				if not dec.has(p):
					_esegui_manutenzione(p, {})
			_avanza()
		"magia1":
			_risolvi_magia1()
			_avanza()
		"chiaro":
			chiaro = {}
			var bersagli := {}
			for p in dec:
				for x in dec[p].get("incanti", []):
					if x.get("s", "") == "chiaroveggenza" and _slot_ok(p, x, "chiaroveggenza"):
						if _lancia(_i(x["c"]), _i(x["i"]), "chiaroveggenza"):
							bersagli[p] = _i(x["p"])
			for p in bersagli:
				var t: int = bersagli[p]
				if bersagli.get(t, -1) == p:
					scrivi("Chiaroveggenze incrociate: nessuno vede i piani dell'altro.")
					continue
				chiaro[p] = t
			_avanza()
		"piano":
			piani = dec.duplicate(true)
			for p in n:
				if dec.has(p):
					g[p]["blocca"] = bool(dec[p].get("blocca", true))
			_risolvi_magia2()
			_esegui_movimento()
			_avanza()
		"rivela":
			for p in dec:
				for x in dec[p].get("incanti", []):
					if x.get("s", "") == "rivela" and _slot_ok(p, x, "rivela"):
						if _lancia(_i(x["c"]), _i(x["i"]), "rivela"):
							_rivela(p, _i(x["prov"]))
			_avanza()
		"magia3":
			_risolvi_resurrezioni()
			_avanza()

## Passa alla fase successiva saltando quelle in cui nessuno ha qualcosa da decidere.
func _avanza() -> void:
	var i := FASI.find(fase)
	while true:
		i += 1
		if i >= FASI.size():
			_fine_turno()
			return
		fase = FASI[i]
		dec = {}
		if _entra():
			return

## Prepara la fase: true se qualcuno deve decidere, false se va saltata (dopo averla risolta).
func _entra() -> bool:
	attese = []
	match fase:
		"alleanze":
			if n < 3:
				return false
			attese = range(n)
		"tornado":
			for p in n:
				if ha_ramo(p, ["elementi"]):
					attese.append(p)
		"finanze":
			tasse_turno = []
			for p in n:
				var t := tasse_di(p, true)
				tasse_turno.append(t)
				g[p]["tesoro"] += t
				if t > 0:
					scrivi("%s riscuote %d sequin di tasse." % [g[p]["nome"], t])
				ev({"t": "tasse", "p": p, "q": t})
				if mantenimento(p) > 0 or _re_prigionieri(p).size() > 0:
					attese.append(p)
		"acquisti":
			seq = ordine_precedenza(range(n))
			seq_i = 0
			attese = [seq[0]]
			scrivi("Ordine di reclutamento: " + ", ".join(seq.map(func(p): return g[p]["nome"])))
			return true
		"magia1":
			for p in n:
				if ha_ramo(p, ["necromanzia", "mente"]):
					attese.append(p)
		"chiaro":
			if n < 2:
				return false
			for p in n:
				if ha_ramo(p, ["mente"]):
					attese.append(p)
		"piano":
			attese = range(n)
		"rivela":
			for p in n:
				if ha_ramo(p, ["illusione"]):
					attese.append(p)
		"battaglia":
			_prepara_battaglie()
			return _prossima_scelta_battaglia(true)
		"magia3":
			for p in n:
				if not _resurrezioni_possibili(p).is_empty():
					attese.append(p)
	if attese.is_empty():
		_risolvi_vuota()
		return false
	return true

func _risolvi_vuota() -> void:
	# alcune fasi hanno comunque effetti automatici anche senza decisioni
	match fase:
		"finanze":
			for p in n:
				_esegui_manutenzione(p, {})
		"chiaro":
			chiaro = {}
		"piano":
			_esegui_movimento()

func _inizio_turno() -> void:
	turno += 1
	gruppo = []
	for i in n:
		gruppo.append(-1)
	usati = {}
	tornado = []
	tempesta_mari = []
	tempesta_monti = []
	gelo = []
	alluvione = []
	lanciatori_eff = {}
	caduti = {}
	ritirati = {}
	combattuti = {}
	chiaro = {}
	piani = {}
	if turno > 1:
		var migliore := -1
		var mt := -1
		for p in n:
			var t := tasse_di(p)
			if t >= soglia and t > mt:
				mt = t
				migliore = p
		if migliore < 0 and turni_max > 0 and turno > turni_max:
			for p in n:
				var t := tasse_di(p)
				if t > mt:
					mt = t
					migliore = p
		if migliore >= 0:
			finita = true
			vincitore = migliore
			fase = "fine"
			attese = []
			scrivi("%s controlla province per %d di tasse e vince la partita!" % [g[migliore]["nome"], mt])
			ev({"t": "vittoria", "p": migliore})
			return
	scrivi("--- Anno %d ---" % turno)
	ev({"t": "turno", "n": turno})
	fase = FASI[0]
	dec = {}
	if not _entra():
		_avanza()

func _fine_turno() -> void:
	_inizio_turno()

# ---------------------------------------------------------------- alleanze

func _risolvi_alleanze() -> void:
	var vieta := {}
	var forza := {}
	for p in dec:
		var d: Dictionary = dec[p]
		for x in d.get("doni", []):
			var a := _i(x["a"])
			var q := mini(_i(x["q"]), g[p]["tesoro"])
			if q > 0 and a >= 0 and a < n and a != p:
				g[p]["tesoro"] -= q
				g[a]["tesoro"] += q
				scrivi("%s versa %d sequin a %s." % [g[p]["nome"], q, g[a]["nome"]])
				ev({"t": "dono", "da": p, "a": a, "q": q})
		for x in d.get("incanti", []):
			var s: String = x.get("s", "")
			if (s == "discordia" or s == "armonia") and _slot_ok(p, x, s):
				var a := _i(x["a"])
				var b := _i(x["b"])
				if a == b or a < 0 or b < 0 or a >= n or b >= n:
					continue
				if _lancia(_i(x["c"]), _i(x["i"]), s):
					var k := "%d-%d" % [mini(a, b), maxi(a, b)]
					if s == "discordia":
						vieta[k] = true
					else:
						forza[k] = true
	var coppie := {}
	for a in n:
		for b in range(a + 1, n):
			var k := "%d-%d" % [a, b]
			var fa: Array = dec.get(a, {}).get("firme", [])
			var fb: Array = dec.get(b, {}).get("firme", [])
			var firm := (fa.has(b) or fa.has(float(b))) and (fb.has(a) or fb.has(float(a)))
			if forza.has(k):
				firm = true
			elif vieta.has(k):
				firm = false
			if firm:
				coppie[k] = true
	# componenti connesse; se una componente non è completa qualcuno è in due alleanze: tutte nulle
	var comp := []
	for i in n:
		comp.append(i)
	for k in coppie:
		var ab: PackedStringArray = k.split("-")
		var x := _radice(comp, int(ab[0]))
		var y := _radice(comp, int(ab[1]))
		comp[x] = y
	var gr := {}
	for i in n:
		var r := _radice(comp, i)
		if not gr.has(r):
			gr[r] = []
		gr[r].append(i)
	var id_g := 0
	for r in gr:
		var m: Array = gr[r]
		if m.size() < 2:
			continue
		var completa := true
		for a in m:
			for b in m:
				if a < b and not coppie.has("%d-%d" % [a, b]):
					completa = false
		if not completa:
			scrivi("Firme incrociate: un giocatore era in due alleanze, tutte annullate.")
			continue
		for a in m:
			gruppo[a] = id_g
		scrivi("Alleanza per l'anno %d: %s." % [turno, ", ".join(m.map(func(p): return g[p]["nome"]))])
		ev({"t": "alleanza", "membri": m})
		id_g += 1

func _radice(c: Array, i: int) -> int:
	while c[i] != i:
		i = c[i]
	return i

# ---------------------------------------------------------------- finanze

func _re_prigionieri(p: int) -> Array:
	var out := []
	for id in u:
		if Dati.unita[id]["tipo"] == "re" and u[id]["catt"] == p:
			out.append(id)
	return out

func _esegui_manutenzione(p: int, d: Dictionary) -> void:
	for x in d.get("libera", []):
		var id := _i(x)
		if u.has(id) and u[id]["catt"] == p:
			u[id]["catt"] = -9
			scrivi("%s libera %s." % [g[p]["nome"], Dati.nome_unita(id)])
			ev({"t": "liberato", "id": id})
	for x in d.get("congeda", []):
		var id := _i(x)
		if u.has(id) and u[id]["own"] == p and Dati.unita[id]["tipo"] != "re":
			_elimina(id, "congedata")
	var m := mantenimento(p)
	if m > g[p]["tesoro"]:
		# il tesoro non basta: si congedano per prime le unità più costose da mantenere
		var lista := []
		for id in u:
			if u[id]["own"] == p and Dati.unita[id]["mant"] > 0:
				lista.append(id)
		lista.sort_custom(func(a, b): return Dati.unita[a]["mant"] * 10 - Dati.unita[a]["forza"] > Dati.unita[b]["mant"] * 10 - Dati.unita[b]["forza"])
		for id in lista:
			if mantenimento(p) <= g[p]["tesoro"]:
				break
			_elimina(id, "congedata per mancanza di fondi")
		m = mantenimento(p)
	g[p]["tesoro"] -= m
	if m > 0:
		scrivi("%s paga %d sequin di mantenimento (restano %d)." % [g[p]["nome"], m, g[p]["tesoro"]])

func _dal_pool(tipo: String) -> int:
	var ids := Dati.unita.keys()
	ids.sort()
	for id in ids:
		if Dati.unita[id]["tipo"] == tipo and u[id]["own"] == POOL:
			return id
	return 0

## Pedine disponibili di un tipo (comprese le illusioni altrui, che si possono «reclamare»).
func disponibili(tipo: String) -> Array:
	var out := []
	var ids := Dati.unita.keys()
	ids.sort()
	for id in ids:
		if Dati.unita[id]["tipo"] == tipo and u[id]["own"] == POOL:
			out.append(id)
	if out.is_empty():
		for id in ids:
			if Dati.unita[id]["tipo"] == tipo and u[id]["illus"] and u[id]["own"] >= 0:
				out.append(id)
	return out

func _esegui_acquisti(p: int, d: Dictionary) -> void:
	var compra: Array = d.get("compra", [])
	var illus_ok := false
	var vuole_illus := false
	for c in compra:
		if c.get("illus", false):
			vuole_illus = true
	if vuole_illus:
		var sl := slot_magia(p, "illusione")
		var x: Dictionary = d.get("incanto", {})
		if x.is_empty() and not sl.is_empty():
			x = sl[0]
		if not x.is_empty() and _slot_ok(p, x, "illusioni"):
			illus_ok = _lancia(_i(x["c"]), _i(x["i"]), "illusioni")
	for c in compra:
		var id := _i(c["id"])
		var q := _i(c["p"])
		var il: bool = c.get("illus", false)
		if il and not illus_ok:
			continue
		var costo: int = 1 if il else Dati.unita[id]["costo"]
		if costo > g[p]["tesoro"]:
			continue
		if u[id]["own"] != POOL:
			if u[id]["illus"]:
				scrivi("%s era un'illusione di %s: svanisce." % [Dati.nome_unita(id), g[u[id]["own"]]["nome"]])
				_elimina(id, "")
			else:
				continue
		g[p]["tesoro"] -= costo
		u[id]["own"] = p
		u[id]["prov"] = q
		u[id]["illus"] = il
		u[id]["zombie"] = false
		u[id]["abil"] = []
		u[id]["magie"] = []
		u[id]["catt"] = -9
		u[id]["invis"] = false
		var tipo: String = Dati.unita[id]["tipo"]
		var ab: Array = c.get("abil", [])
		if tipo == "eroe":
			var a: String = ab[0] if ab.size() > 0 and ab[0] in Dati.ABILITA_EROE else "tattica"
			u[id]["abil"] = [a]
		elif tipo == "mago":
			var r: String = ab[0] if ab.size() > 0 and ab[0] in Dati.RAMI else "elementi"
			u[id]["magie"] = [{"r": r, "v": 2}]
		ev({"t": "arrivo", "id": id, "prov": q, "p": p})
		scrivi("%s recluta %s in %s." % [g[p]["nome"], Dati.nome_tipo(id), Dati.nome_prov(q)])

# ---------------------------------------------------------------- prima fase magica

func _risolvi_magia1() -> void:
	# 1. uccidi maghi ed eroi: simultaneo
	var morti := []
	for p in dec:
		for x in dec[p].get("incanti", []):
			if x.get("s", "") != "uccidi_capo" or not _slot_ok(p, x, "uccidi_capo"):
				continue
			var t := _i(x["t"])
			if not u.has(t) or u[t]["own"] < 0 or alleati(u[t]["own"], p) or not (Dati.unita[t]["tipo"] in ["eroe", "mago"]):
				continue
			if g[p]["tesoro"] < 8:
				continue
			if _lancia(_i(x["c"]), _i(x["i"]), "uccidi_capo"):
				g[p]["tesoro"] -= 8
				morti.append(t)
	for t in morti:
		if u[t]["own"] != POOL:
			ev({"t": "maledizione", "id": t, "prov": u[t]["prov"]})
			_elimina(t, "fulminato dalla necromanzia")
	# 2. uccidi unità
	for p in dec:
		for x in dec[p].get("incanti", []):
			if x.get("s", "") != "uccidi_unita" or not _slot_ok(p, x, "uccidi_unita"):
				continue
			var bersagli := []
			for t in x.get("t", []):
				var id := _i(t)
				if u.has(id) and u[id]["own"] != POOL and Dati.is_militare(id) and u[id]["own"] != p and not alleati(u[id]["own"], p):
					bersagli.append(id)
			if bersagli.is_empty() or g[p]["tesoro"] < 5:
				continue
			if _lancia(_i(x["c"]), _i(x["i"]), "uccidi_unita"):
				for id in bersagli:
					if g[p]["tesoro"] < 5:
						break
					g[p]["tesoro"] -= 5
					ev({"t": "maledizione", "id": id, "prov": u[id]["prov"]})
					_elimina(id, "distrutta dalla necromanzia")
	# 3. fedeltà sulle unità neutrali, per precedenza
	var chi := []
	for p in dec:
		for x in dec[p].get("incanti", []):
			if x.get("s", "") == "fedelta":
				chi.append(p)
	for p in ordine_precedenza(chi):
		for x in dec[p].get("incanti", []):
			if x.get("s", "") != "fedelta" or not _slot_ok(p, x, "fedelta"):
				continue
			var bersagli := []
			for t in x.get("t", []):
				var id := _i(t)
				if u.has(id) and u[id]["own"] == NEUTRALE:
					bersagli.append(id)
			if bersagli.is_empty() or g[p]["tesoro"] < 5:
				continue
			if _lancia(_i(x["c"]), _i(x["i"]), "fedelta"):
				for id in bersagli:
					if g[p]["tesoro"] < 5:
						break
					g[p]["tesoro"] -= 5
					u[id]["own"] = p
					ev({"t": "fedelta", "id": id, "p": p, "prov": u[id]["prov"]})
					scrivi("%s giura fedeltà a %s." % [Dati.nome_unita(id), g[p]["nome"]])
	_aggiorna_controllo()

# ---------------------------------------------------------------- seconda fase magica (dopo i piani)

func _risolvi_magia2() -> void:
	var ordine := ["controllo", "tempesta_mari", "tempesta_monti", "gelo", "alluvione", "invisibilita"]
	for s in ordine:
		for p in range(n):
			if not dec.has(p):
				continue
			for x in dec[p].get("incanti", []):
				if x.get("s", "") != s or not _slot_ok(p, x, s):
					continue
				match s:
					"controllo":
						var e := _i(x["eroe"])
						if not u.has(e) or Dati.unita[e]["tipo"] != "eroe" or u[e]["own"] < 0 or alleati(u[e]["own"], p) or not libero(e):
							continue
						if _lancia(_i(x["c"]), _i(x["i"]), s):
							x["_ok"] = true
							ev({"t": "effetto", "s": "controllo", "prov": u[e]["prov"], "id": e})
					"tempesta_mari", "tempesta_monti":
						var a := _i(x["a"])
						var b := _i(x["b"])
						var serve := "mare" if s == "tempesta_mari" else "montagna"
						if a <= 0 or b <= 0 or Dati.province[a]["terreno"] != serve or Dati.province[b]["terreno"] != serve:
							continue
						if a != b and not Dati.adiacenti(a, b):
							continue
						if _lancia(_i(x["c"]), _i(x["i"]), s):
							var lista: Array = tempesta_mari if s == "tempesta_mari" else tempesta_monti
							for q in [a, b]:
								if not (q in lista):
									lista.append(q)
								lanciatori_eff["%s:%d" % [s, q]] = p
								ev({"t": "effetto", "s": s, "prov": q})
					"gelo":
						var q := _i(x["prov"])
						if q <= 0 or not (Dati.is_mare(q) or Dati.province[q]["terreno"] == "palude"):
							continue
						if _lancia(_i(x["c"]), _i(x["i"]), s):
							gelo.append(q)
							lanciatori_eff["gelo:%d" % q] = p
							ev({"t": "effetto", "s": "gelo", "prov": q})
					"alluvione":
						var q := _i(x["prov"])
						if q <= 0 or Dati.is_mare(q):
							continue
						if _lancia(_i(x["c"]), _i(x["i"]), s):
							alluvione.append(q)
							lanciatori_eff["alluvione:%d" % q] = p
							ev({"t": "effetto", "s": "alluvione", "prov": q})
					"invisibilita":
						var c := _i(x["capo"])
						if not u.has(c) or u[c]["own"] != p or not Dati.is_capo(c) or not libero(c):
							continue
						if _lancia(_i(x["c"]), _i(x["i"]), s):
							x["_ok"] = true

func _immune(s: String, q: int, p: int) -> bool:
	var k := "%s:%d" % [s, q]
	return lanciatori_eff.has(k) and alleati(lanciatori_eff[k], p)

# ---------------------------------------------------------------- movimento

func costo_terreno(id: int, q: int) -> int:
	var t: String = Dati.province[q]["terreno"]
	var o: String = Dati.unita[id]["origine"]
	var c := Dati.classe(id)
	if q in gelo and t == "palude":
		return 1
	match t:
		"montagna":
			return 1 if o == "nani" else 2
		"foresta":
			return 1 if o == "elfi" else 2
		"palude":
			return 1 if c == "rana" else 2
	return 1

## Capacità di movimento di un gruppo (capo + unità): la più bassa delle unità, più la Marcia del capo.
func mov_gruppo(capo: int, unita: Array) -> int:
	var marcia := conta_abil(capo, "marcia") if Dati.is_capo(capo) else 0
	if unita.is_empty():
		return mini(7, Dati.unita[capo]["mov"] + marcia)
	var m := 99
	for id in unita:
		m = mini(m, Dati.unita[id]["mov"] + marcia)
	return m

## Costo di un passo da "da" ad "a" per il gruppo, -1 se vietato. st descrive il percorso fatto finora.
func costo_passo(membri: Array, da: int, a: int, st: Dictionary) -> int:
	if not Dati.adiacenti(da, a):
		return -1
	var mare_a := Dati.is_mare(a)
	var mare_da := Dati.is_mare(da)
	var mil := membri.filter(func(id): return Dati.is_militare(id))
	if mil.is_empty():
		return -1 if mare_a else 1
	var vettori := 0
	var portati := 0
	for id in mil:
		var c := Dati.classe(id)
		if c in ["flotta", "aeronave"]:
			vettori += 1
		elif c in ["fanteria", "cavalleria"]:
			portati += 1
	var costo := 1
	for id in mil:
		var c := Dati.classe(id)
		var cc := 1
		match c:
			"flotta":
				if mare_a:
					if not mare_da and st.get("mare_prec", 0) > 0 and a != st["mare_prec"] and not Dati.adiacenti(a, st["mare_prec"]):
						cc = -1
				elif not (mare_da and Dati.province[a].get("costiera", false)):
					cc = -1
			"balena":
				cc = 1 if mare_a else -1
			"aeronave":
				cc = 1
			"rana":
				if mare_a:
					cc = -1 if st.get("mari_rana", 0) >= 1 else 1
				elif mare_da:
					cc = 1
				else:
					cc = costo_terreno(id, a)
			_:
				if mare_a:
					if a in gelo:
						cc = 1
					elif portati > vettori or st.get("terra", false):
						cc = -1
				elif mare_da:
					cc = costo_terreno(id, a)
				else:
					cc = -1 if st.get("mare", false) else costo_terreno(id, a)
		if cc < 0:
			return -1
		costo = maxi(costo, cc)
	return costo

func avanza_stato(membri: Array, da: int, a: int, st: Dictionary) -> Dictionary:
	var s := st.duplicate()
	if Dati.is_mare(a):
		s["mare"] = true
		s["mare_prec"] = a
		s["mari_rana"] = s.get("mari_rana", 0) + 1
	elif not Dati.is_mare(da):
		s["terra"] = true
	return s

## Controlla un ordine: {capo, unita:[...], via:[...]}. Restituisce "" se valido.
func valida_ordine(p: int, o: Dictionary, impegnati := {}) -> String:
	var capo := _i(o.get("capo", 0))
	if not u.has(capo) or u[capo]["own"] != p or not libero(capo) or not (Dati.classe(capo) in ["capo", "mago"]):
		return "capo non valido"
	var partenza: int = u[capo]["prov"]
	var unita := []
	for x in o.get("unita", []):
		var id := _i(x)
		if not u.has(id) or u[id]["own"] != p or u[id]["prov"] != partenza or not Dati.is_militare(id) or impegnati.has(id):
			return "unità non valida"
		unita.append(id)
	if not unita.is_empty() and not Dati.is_capo(capo):
		return "i maghi non guidano unità"
	var membri := [capo] + unita
	var ma := mov_gruppo(capo, unita)
	var st := {}
	var da := partenza
	var spesi := 0
	for x in o.get("via", []):
		var q := _i(x)
		var c := costo_passo(membri, da, q, st)
		if c < 0:
			return "passo vietato verso " + Dati.nome_prov(q)
		spesi += c
		if spesi > ma:
			return "movimento insufficiente"
		st = avanza_stato(membri, da, q, st)
		da = q
	return ""

## Passi possibili dal termine del percorso: provincia -> costo totale.
func passi_possibili(p: int, capo: int, unita: Array, via: Array) -> Dictionary:
	var membri := [capo] + unita
	var ma := mov_gruppo(capo, unita)
	var st := {}
	var da: int = u[capo]["prov"]
	var spesi := 0
	for q in via:
		spesi += costo_passo(membri, da, q, st)
		st = avanza_stato(membri, da, q, st)
		da = q
	var out := {}
	for q in Dati.province[da]["adiacenti"]:
		var c := costo_passo(membri, da, q, st)
		if c > 0 and spesi + c <= ma:
			out[q] = spesi + c
	return out

func _esegui_movimento() -> void:
	ev({"t": "movimento_inizio"})
	var gruppi := []
	var impegnati := {}
	var controllati := {}
	# eroi sotto controllo mentale: si muovono per conto di chi li controlla
	for p in dec:
		for x in dec[p].get("incanti", []):
			if x.get("s", "") == "controllo" and x.get("_ok", false):
				controllati[_i(x["eroe"])] = {"p": p, "via": x.get("via", [])}
	for p in n:
		if not dec.has(p):
			continue
		for o in dec[p].get("ordini", []):
			var capo := _i(o.get("capo", 0))
			if controllati.has(capo):
				continue
			if valida_ordine(p, o, impegnati) != "":
				continue
			var unita := []
			for x in o.get("unita", []):
				unita.append(_i(x))
			var via := []
			for x in o.get("via", []):
				via.append(_i(x))
			if via.is_empty():
				continue
			for id in unita:
				impegnati[id] = true
			impegnati[capo] = true
			gruppi.append({"p": p, "capo": capo, "unita": unita, "via": via})
	for e in controllati:
		var via := []
		for x in controllati[e]["via"]:
			via.append(_i(x))
		if not via.is_empty() and valida_ordine(u[e]["own"], {"capo": e, "unita": [], "via": via}) == "":
			gruppi.append({"p": u[e]["own"], "capo": e, "unita": [], "via": via, "controllato": controllati[e]["p"]})
			scrivi("%s si muove sotto controllo mentale di %s." % [Dati.nome_unita(e), g[controllati[e]["p"]]["nome"]])
	# invisibilità
	for p in dec:
		for x in dec[p].get("incanti", []):
			if x.get("s", "") == "invisibilita" and x.get("_ok", false):
				var c := _i(x["capo"])
				var membri := [c]
				for gr in gruppi:
					if gr["capo"] == c:
						membri += gr["unita"]
				if not gruppi.any(func(gr): return gr["capo"] == c):
					membri += militari_in(u[c]["prov"], p)
				for id in membri:
					u[id]["invis"] = true
				ev({"t": "invisibile", "ids": membri, "p": p})
	# tempi di arrivo di ogni passo
	for gr in gruppi:
		var membri: Array = [gr["capo"]] + gr["unita"]
		var st := {}
		var da: int = u[gr["capo"]]["prov"]
		var t := 0
		var tempi := []
		for q in gr["via"]:
			t += costo_passo(membri, da, q, st)
			st = avanza_stato(membri, da, q, st)
			tempi.append(t)
			da = q
		gr["tempi"] = tempi
		gr["k"] = 0
		gr["fermo"] = false
		gr["mosso"] = false
		gr["membri"] = membri
		gr["partenza"] = u[gr["capo"]]["prov"]
		# immobilizzati da tempeste, gelo o alluvione
		var q0: int = gr["partenza"]
		for id in membri:
			if _immobile(id, q0, gr["p"]):
				gr["fermo"] = true
				scrivi("%s resta bloccato dagli elementi in %s." % [Dati.nome_unita(gr["capo"]), Dati.nome_prov(q0)])
				break
	var tmax := 0
	for gr in gruppi:
		if not gr["tempi"].is_empty():
			tmax = maxi(tmax, gr["tempi"][-1])
	for T in range(1, tmax + 1):
		var mossi := []
		for gr in gruppi:
			if gr["fermo"] or gr["k"] >= gr["via"].size() or gr["tempi"][gr["k"]] != T:
				continue
			var da: int = u[gr["capo"]]["prov"]
			var a: int = gr["via"][gr["k"]]
			var motivo := _ingresso_vietato(gr, da, a)
			if motivo != "":
				gr["fermo"] = true
				scrivi("%s si ferma in %s: %s." % [Dati.nome_unita(gr["capo"]), Dati.nome_prov(da), motivo])
				continue
			for id in gr["membri"]:
				if u[id]["own"] != POOL and u[id]["prov"] == da:
					u[id]["prov"] = a
			ev({"t": "muovi", "ids": gr["membri"].filter(func(id): return u[id]["prov"] == a), "da": da, "a": a, "p": gr["p"], "T": T})
			gr["k"] += 1
			gr["mosso"] = true
			mossi.append(gr)
			if a in alluvione and not _immune("alluvione", a, gr["p"]):
				gr["fermo"] = true
				scrivi("%s è travolto dall'alluvione in %s." % [Dati.nome_unita(gr["capo"]), Dati.nome_prov(a)])
		# blocchi
		for gr in mossi:
			if gr["fermo"] or gr["k"] >= gr["via"].size():
				continue
			var q: int = u[gr["capo"]]["prov"]
			if u[gr["capo"]]["invis"]:
				continue
			var bloccanti := []
			for id in nemici_in(q, gr["p"], true):
				var o: int = u[id]["own"]
				if o == NEUTRALE or g[o]["blocca"]:
					bloccanti.append(id)
			if not bloccanti.is_empty():
				gr["fermo"] = true
				for id in bloccanti:
					if u[id]["invis"]:
						_svela(id)
				var chi: int = u[bloccanti[0]]["own"]
				scrivi("%s viene bloccato in %s da %s." % [Dati.nome_unita(gr["capo"]), Dati.nome_prov(q), "unità neutrali" if chi == NEUTRALE else g[chi]["nome"]])
				ev({"t": "blocco", "prov": q, "id": gr["capo"]})
		_controlla_capi_soli()
		_controllo_al_passaggio(mossi)
	# fine del movimento: effetti residui
	for q in gelo:
		for id in unita_in(q):
			if Dati.is_militare(id) and not (Dati.classe(id) in ["flotta", "balena", "aeronave"]):
				scrivi("Il ghiaccio si scioglie in %s: %s affoga." % [Dati.nome_prov(q), Dati.nome_unita(id)])
				_elimina(id, "")
	for id in u.keys():
		var s: Dictionary = u[id]
		if s["own"] == POOL or s["prov"] <= 0:
			continue
		var c := Dati.classe(id)
		var q: int = s["prov"]
		if c == "aeronave" and (Dati.is_mare(q) or Dati.province[q]["terreno"] == "montagna"):
			scrivi("%s precipita in %s." % [Dati.nome_unita(id), Dati.nome_prov(q)])
			_elimina(id, "")
		elif c == "rana" and Dati.is_mare(q):
			_elimina(id, "")
	_controlla_capi_soli()
	_aggiorna_controllo()
	ev({"t": "movimento_fine"})

## Chi entra con unità militari in una provincia senza altre forze ne diventa l'ultimo occupante (7.1).
func _controllo_al_passaggio(mossi: Array) -> void:
	for gr in mossi:
		var q: int = u[gr["capo"]]["prov"]
		var p: int = gr["p"]
		if not gr["membri"].any(func(id): return Dati.is_militare(id) and u[id]["prov"] == q):
			continue
		var altri := false
		for id in unita_in(q):
			if Dati.is_militare(id) and u[id]["own"] != p and not (u[id]["own"] >= 0 and alleati(u[id]["own"], p)):
				altri = true
				break
		if altri or ctrl[q] == p or (ctrl[q] >= 0 and alleati(ctrl[q], p) and not militari_in(q, ctrl[q]).is_empty()):
			continue
		ctrl[q] = p
		ev({"t": "controllo", "prov": q, "p": p})

func _immobile(id: int, q: int, p: int) -> bool:
	var c := Dati.classe(id)
	var navale := c in ["flotta", "balena", "rana", "aeronave"]
	if q in tempesta_mari and navale and not _immune("tempesta_mari", q, p):
		return true
	if q in tempesta_monti and not _immune("tempesta_monti", q, p) and Dati.unita[id]["origine"] != "nani" and Dati.is_militare(id):
		return true
	if q in gelo and c in ["flotta", "balena"] and not _immune("gelo", q, p):
		return true
	if q in alluvione and not _immune("alluvione", q, p) and c != "rana":
		return true
	return false

func _ingresso_vietato(gr: Dictionary, da: int, a: int) -> String:
	var p: int = gr["p"]
	var navale: bool = gr["membri"].any(func(id): return Dati.classe(id) in ["flotta", "balena", "rana", "aeronave"])
	var terra: bool = gr["membri"].any(func(id): return Dati.is_militare(id) and Dati.unita[id]["origine"] != "nani")
	if a in tempesta_mari and navale and not _immune("tempesta_mari", a, p):
		return "mari in tempesta"
	if a in tempesta_monti and terra and not _immune("tempesta_monti", a, p):
		return "tempesta sui monti"
	if a in gelo and gr["membri"].any(func(id): return Dati.classe(id) in ["flotta", "balena"]) and not _immune("gelo", a, p):
		return "mare gelato"
	if Dati.is_mare(a) and not (a in gelo):
		# unità di terra senza navi sufficienti (dopo perdite o immobilizzazioni)
		var vet := 0
		var port := 0
		for id in gr["membri"]:
			if u[id]["prov"] != da:
				continue
			var c := Dati.classe(id)
			if c in ["flotta", "aeronave"]:
				vet += 1
			elif c in ["fanteria", "cavalleria"]:
				port += 1
		if port > vet:
			return "navi insufficienti"
	# 8.4: da una provincia occupata da nemici non si entra in una provincia nemica
	if not u[gr["capo"]]["invis"] and not nemici_in(da, p).is_empty():
		if not nemici_in(a, p).is_empty():
			return "non si passa da una provincia nemica all'altra"
		if da != gr["partenza"] and ctrl[a] >= 0 and nemici(ctrl[a], p):
			return "non si passa da una provincia nemica all'altra"
	return ""

## 8.2: capi e maghi senza unità amiche in una provincia con militari nemici: Re catturati, gli altri eliminati.
func _controlla_capi_soli() -> void:
	for id in u.keys():
		var s: Dictionary = u[id]
		if s["own"] < 0 or s["prov"] <= 0 or Dati.is_militare(id) or not libero(id):
			continue
		var q: int = s["prov"]
		var p: int = s["own"]
		var amici := false
		for x in unita_in(q):
			if Dati.is_militare(x) and alleati(u[x]["own"], p) and u[x]["own"] >= 0:
				amici = true
				break
		if amici:
			continue
		var nem := nemici_in(q, p, true)
		if nem.is_empty():
			continue
		var captor: int = u[nem[0]]["own"]
		if Dati.unita[id]["tipo"] == "re":
			s["catt"] = captor
			scrivi("%s viene catturato in %s da %s!" % [Dati.nome_unita(id), Dati.nome_prov(q), "unità neutrali" if captor == NEUTRALE else g[captor]["nome"]])
			ev({"t": "cattura", "id": id, "prov": q, "da": captor})
		else:
			ev({"t": "morte", "id": id, "prov": q})
			_elimina(id, "sorpreso senza scorta e ucciso")

func _libera_prigionieri() -> void:
	for id in u.keys():
		var s: Dictionary = u[id]
		if Dati.unita[id]["tipo"] != "re" or s["catt"] == -9 or s["own"] < 0:
			continue
		var custodi := militari_in(s["prov"], s["catt"])
		if custodi.is_empty():
			s["catt"] = -9
			scrivi("%s è di nuovo libero: nessuno lo sorveglia più." % Dati.nome_unita(id))
			ev({"t": "liberato", "id": id})

func _svela(id: int) -> void:
	var p: int = u[id]["own"]
	var q: int = u[id]["prov"]
	var ids := []
	for x in unita_in(q, p):
		if u[x]["invis"]:
			u[x]["invis"] = false
			ids.append(x)
	if not ids.is_empty():
		scrivi("La forza invisibile di %s appare in %s!" % [g[p]["nome"], Dati.nome_prov(q)])
		ev({"t": "svelato", "ids": ids, "prov": q})

func _rivela(p: int, q: int) -> void:
	var trovati := []
	for id in unita_in(q):
		var s: Dictionary = u[id]
		if s["own"] >= 0 and s["own"] != p and (s["illus"] or s["invis"]):
			trovati.append(id)
	ev({"t": "rivela", "p": p, "prov": q, "ids": trovati})
	if trovati.is_empty():
		scrivi("In %s non c'è nulla di nascosto." % Dati.nome_prov(q))
		return
	for id in trovati:
		if u[id]["illus"]:
			scrivi("In %s %s si rivela un'illusione e svanisce." % [Dati.nome_prov(q), Dati.nome_unita(id)])
			_elimina(id, "")
	for id in trovati:
		if u.has(id) and u[id]["own"] >= 0 and u[id]["invis"]:
			_svela(id)

func _aggiorna_controllo() -> void:
	_libera_prigionieri()
	for q in range(1, 48):
		var presenti := {}
		var neutrali := false
		for id in unita_in(q):
			if not Dati.is_militare(id):
				continue
			var o: int = u[id]["own"]
			if o == NEUTRALE:
				neutrali = true
			elif o >= 0:
				presenti[o] = presenti.get(o, 0) + Dati.unita[id]["forza"]
		var prima: int = ctrl[q]
		if neutrali:
			ctrl[q] = -1
		elif presenti.is_empty():
			pass
		elif presenti.has(ctrl[q]):
			pass
		else:
			var best := -1
			var bf := -1
			for o in presenti:
				if presenti[o] > bf:
					bf = presenti[o]
					best = o
			ctrl[q] = best
		if ctrl[q] != prima:
			ev({"t": "controllo", "prov": q, "p": ctrl[q]})
			if ctrl[q] >= 0:
				scrivi("%s prende il controllo di %s." % [g[ctrl[q]]["nome"], Dati.nome_prov(q)])

func _elimina(id: int, motivo: String) -> void:
	var s: Dictionary = u[id]
	if motivo != "":
		scrivi("%s: %s." % [Dati.nome_unita(id), motivo])
	ev({"t": "eliminata", "id": id, "prov": s["prov"]})
	s["own"] = POOL
	s["prov"] = 0
	s["illus"] = false
	s["zombie"] = false
	s["abil"] = []
	s["magie"] = []
	s["catt"] = -9
	s["invis"] = false

# ---------------------------------------------------------------- combattimento

## Lato di un giocatore in battaglia: il capo dell'alleanza (il primo dei membri), -1 per i neutrali.
func lato(p: int) -> int:
	if p < 0:
		return NEUTRALE
	if gruppo[p] < 0:
		return p
	for i in n:
		if gruppo[i] == gruppo[p]:
			return i
	return p

func lati_in(q: int) -> Array:
	var out := []
	for id in unita_in(q):
		if not Dati.is_militare(id) or u[id]["invis"]:
			continue
		var l := lato(u[id]["own"])
		if not (l in out):
			out.append(l)
	out.sort()
	return out

func forza_di_lato(q: int, l: int) -> Array:
	var out := []
	for id in unita_in(q):
		if Dati.is_militare(id) and not u[id]["invis"] and lato(u[id]["own"]) == l:
			out.append(id)
	return out

func _prepara_battaglie() -> void:
	battaglie = []
	for q in range(1, 48):
		if q in alluvione:
			continue
		var l := lati_in(q)
		if l.size() >= 2 and l.any(func(x): return x >= 0):
			battaglie.append(q)
	batt_i = -1
	batt_ordine = []
	batt_k = 0

## Passa al prossimo giocatore che deve decidere se attaccare. Con inizio=true restituisce se c'è qualcosa da fare.
func _prossima_scelta_battaglia(inizio := false) -> bool:
	while true:
		if batt_i >= 0 and batt_k < batt_ordine.size():
			var q: int = battaglie[batt_i]
			var p: int = batt_ordine[batt_k]
			batt_k += 1
			if not bersagli_attacco(q, p).is_empty():
				attese = [p]
				dec = {}
				ev({"t": "battaglia_scelta", "prov": q, "p": p})
				return true
			continue
		if batt_i >= 0:
			_attacco_neutrali(battaglie[batt_i])
		batt_i += 1
		if batt_i >= battaglie.size():
			if inizio:
				_dopo_battaglie()
				return false
			_dopo_battaglie()
			_avanza()
			return false
		var q2: int = battaglie[batt_i]
		var giocatori := []
		for l in lati_in(q2):
			if l >= 0:
				giocatori.append(l)
		batt_ordine = ordine_precedenza(giocatori)
		batt_k = 0
	return false

func _dopo_battaglie() -> void:
	_controlla_capi_soli()
	_aggiorna_controllo()

func provincia_battaglia() -> int:
	if fase == "battaglia" and batt_i >= 0 and batt_i < battaglie.size():
		return battaglie[batt_i]
	return 0

## Lati che il giocatore (capofila della sua alleanza) può ancora attaccare in q.
func bersagli_attacco(q: int, p: int) -> Array:
	var l := lato(p)
	if l != p or forza_di_lato(q, l).is_empty():
		return []
	var out := []
	for x in lati_in(q):
		if x == l:
			continue
		if combattuti.has(_chiave_batt(q, l, x)):
			continue
		out.append(x)
	return out

func _chiave_batt(q: int, a: int, b: int) -> String:
	return "%d:%d:%d" % [q, mini(a, b), maxi(a, b)]

func _esegui_attacchi(p: int, d: Dictionary) -> void:
	var q := provincia_battaglia()
	for x in d.get("attacca", []):
		var b := _i(x)
		if b in bersagli_attacco(q, p):
			combatti(q, lato(p), b)

func _attacco_neutrali(q: int) -> void:
	if forza_di_lato(q, NEUTRALE).is_empty():
		return
	for l in lati_in(q):
		if l < 0 or combattuti.has(_chiave_batt(q, l, NEUTRALE)):
			continue
		if forza_di_lato(q, NEUTRALE).is_empty():
			return
		scrivi("Le unità indigene di %s attaccano %s." % [Dati.nome_prov(q), g[l]["nome"]])
		combatti(q, NEUTRALE, l)

## Forza effettiva con i modificatori del terreno: prima si somma, poi si dimezza arrotondando per difetto.
func forza_effettiva(ids: Array, q: int) -> int:
	var t: String = Dati.province[q]["terreno"]
	if q in gelo:
		t = "pianura"
	var normale := 0
	var doppia := 0
	var mezza := 0
	for id in ids:
		var f: int = Dati.unita[id]["forza"]
		var o: String = Dati.unita[id]["origine"]
		var c := Dati.classe(id)
		var tipo: String = Dati.unita[id]["tipo"]
		match t:
			"montagna":
				if o == "nani":
					doppia += f
				elif c == "cavalleria":
					mezza += f
				else:
					normale += f
			"foresta":
				if o == "elfi":
					doppia += f
				elif c == "cavalleria" or tipo == "legione":
					mezza += f
				else:
					normale += f
			"palude":
				if c == "rana":
					doppia += f
				else:
					mezza += f
			_:
				normale += f
	return normale + doppia * 2 + int(mezza / 2)

func _capi_lato(q: int, l: int) -> Array:
	var out := []
	for id in unita_in(q):
		if Dati.is_capo(id) and u[id]["own"] >= 0 and libero(id) and lato(u[id]["own"]) == l:
			out.append(id)
	return out

func _max_abil(capi: Array, a: String) -> int:
	var m := 0
	for id in capi:
		m = maxi(m, conta_abil(id, a))
	return m

func combatti(q: int, a: int, b: int) -> void:
	combattuti[_chiave_batt(q, a, b)] = true
	# le illusioni costrette a combattere svaniscono prima del risultato
	for l in [a, b]:
		for id in forza_di_lato(q, l):
			if u[id]["illus"]:
				scrivi("%s era un'illusione e svanisce." % Dati.nome_unita(id))
				_elimina(id, "")
	var fa := forza_di_lato(q, a)
	var fb := forza_di_lato(q, b)
	if fa.is_empty() or fb.is_empty():
		_controlla_capi_soli()
		return
	var sa := forza_effettiva(fa, q)
	var sb := forza_effettiva(fb, q)
	var ca := _capi_lato(q, a)
	var cb := _capi_lato(q, b)
	var a_grande := sa > sb or (sa == sb and dado() >= 4)
	var grande := maxi(sa, sb)
	var piccolo := mini(sa, sb)
	var r := 6 if piccolo <= 0 else clampi(int(grande / piccolo), 1, 6)
	var base := (r - 1) if a_grande else -(r - 1)
	var spost := _max_abil(ca, "tattica") - _max_abil(cb, "tattica")
	var pos := clampi(base + spost, -5, 5)
	var grande_a: bool
	if pos > 0:
		grande_a = true
	elif pos < 0:
		grande_a = false
	else:
		grande_a = spost > 0 or (spost == 0 and a_grande)
	var col := absi(pos)
	var d := dado()
	var ris: String = Dati.CRT[d - 1][col]
	var nome_a: String = "indigeni" if a < 0 else g[a]["nome"]
	var nome_b: String = "indigeni" if b < 0 else g[b]["nome"]
	var colonna := "%d-1" % (col + 1)
	scrivi("Battaglia in %s: %s (%d) contro %s (%d), colonna %s, dado %d: %s." % [Dati.nome_prov(q), nome_a, sa, nome_b, sb, colonna, d, _testo_ris(ris, grande_a, nome_a, nome_b)])
	ev({"t": "battaglia", "prov": q, "a": a, "b": b, "fa": sa, "fb": sb, "col": colonna, "dado": d, "ris": ris, "grande_a": grande_a, "ids_a": fa.duplicate(), "ids_b": fb.duplicate()})
	var colpito := a if (ris[0] == "L") == grande_a else b
	var vincente := b if colpito == a else a
	var effetto := ris.substr(1)
	var forze := fa if colpito == a else fb
	match effetto:
		"e":
			for id in forze:
				_cade(id, q)
		"me":
			for id in _meta_perdite(forze):
				_cade(id, q)
		"r":
			_ritirata(q, colpito, vincente)
	_controlla_capi_soli()

func _testo_ris(ris: String, grande_a: bool, na: String, nb: String) -> String:
	var chi := (na if grande_a else nb) if ris[0] == "L" else (nb if grande_a else na)
	var plur := chi.ends_with("indigeni")
	match ris.substr(1):
		"e":
			return ("%s vengono annientati" if plur else "%s viene annientato") % chi
		"me":
			return ("%s perdono metà delle forze" if plur else "%s perde metà delle forze") % chi
		"r":
			return ("%s devono ritirarsi" if plur else "%s deve ritirarsi") % chi
	return ris

func _cade(id: int, q: int) -> void:
	if not caduti.has(q):
		caduti[q] = []
	caduti[q].append(id)
	ev({"t": "morte", "id": id, "prov": q})
	_elimina(id, "cade in battaglia")

## Metà forza: si eliminano unità che sommano almeno metà della forza, perdendo il meno possibile.
func _meta_perdite(ids: Array) -> Array:
	var tot := forza_nominale(ids)
	var serve := int(ceil(tot / 2.0))
	var ord := ids.duplicate()
	ord.sort_custom(func(a, b): return Dati.unita[a]["costo"] * 10 / maxi(1, Dati.unita[a]["forza"]) < Dati.unita[b]["costo"] * 10 / maxi(1, Dati.unita[b]["forza"]))
	# ricerca esaustiva se poche unità, altrimenti golosa
	if ids.size() <= 12:
		var best := []
		var best_c := 1 << 30
		for mask in range(1, 1 << ids.size()):
			var f := 0
			var c := 0
			var sel := []
			for i in ids.size():
				if mask & (1 << i):
					f += Dati.unita[ids[i]]["forza"]
					c += Dati.unita[ids[i]]["costo"] * 100 + Dati.unita[ids[i]]["forza"]
					sel.append(ids[i])
			if f >= serve and c < best_c:
				best_c = c
				best = sel
		return best
	var out := []
	var f2 := 0
	for id in ord:
		if f2 >= serve:
			break
		out.append(id)
		f2 += Dati.unita[id]["forza"]
	return out

func _ritirata(q: int, l: int, vincente: int) -> void:
	var capi_l := _capi_lato(q, l)
	var capi_v := _capi_lato(q, vincente)
	var netto := _max_abil(capi_l, "ritirata") - _max_abil(capi_v, "ritirata")
	if netto >= 2:
		scrivi("Grazie all'abilità di Ritirata, %s resta sul campo." % ("indigeni" if l < 0 else g[l]["nome"]))
		return
	var sceglie_vincitore := netto <= -1
	var membri := forza_di_lato(q, l)
	for id in unita_in(q):
		if not Dati.is_militare(id) and u[id]["own"] >= 0 and lato(u[id]["own"]) == l and libero(id):
			membri.append(id)
	var proprietario := l
	var migliore := 0
	var punti_best := -9999
	for a in Dati.province[q]["adiacenti"]:
		if costo_passo(membri, q, a, {}) < 0:
			continue
		var occupata := false
		for id in unita_in(a):
			if Dati.is_militare(id) and nemici(u[id]["own"] if u[id]["own"] >= 0 else NEUTRALE, proprietario if proprietario >= 0 else NEUTRALE):
				occupata = true
		if l >= 0 and occupata:
			continue
		if l < 0 and not unita_in(a).filter(func(id): return Dati.is_militare(id) and u[id]["own"] >= 0).is_empty():
			continue
		var punti := 0
		if l >= 0 and ctrl[a] >= 0 and alleati(ctrl[a], l):
			punti += 20
		punti += Dati.province[a]["tasse"]
		if Dati.is_mare(a):
			punti -= 5
		if sceglie_vincitore:
			punti = -punti
		if punti > punti_best:
			punti_best = punti
			migliore = a
	if l >= 0:
		if not ritirati.has(q):
			ritirati[q] = {}
		for id in membri:
			ritirati[q][u[id]["own"]] = true
	if migliore == 0:
		scrivi("%s non ha dove ritirarsi ed è distrutto." % ("indigeni" if l < 0 else g[l]["nome"]))
		for id in membri:
			if Dati.is_militare(id):
				_cade(id, q)
		return
	for id in membri:
		u[id]["prov"] = migliore
	ev({"t": "ritirata", "ids": membri, "da": q, "a": migliore})
	scrivi("%s si ritira in %s." % ["indigeni" if l < 0 else g[l]["nome"], Dati.nome_prov(migliore)])

# ---------------------------------------------------------------- terza fase magica

func _resurrezioni_possibili(p: int) -> Array:
	var out := []
	for sl in slot_magia(p, "necromanzia"):
		var q: int = u[sl["c"]]["prov"]
		if caduti.has(q) and not caduti[q].filter(func(id): return u[id]["own"] == POOL).is_empty() and not (ritirati.has(q) and ritirati[q].has(p)):
			out.append(sl)
	return out

func _risolvi_resurrezioni() -> void:
	var per_prov := {}
	for p in dec:
		for x in dec[p].get("incanti", []):
			if x.get("s", "") != "resurrezione" or not _slot_ok(p, x, "resurrezione"):
				continue
			var q: int = u[_i(x["c"])]["prov"]
			if not per_prov.has(q):
				per_prov[q] = []
			per_prov[q].append({"p": p, "x": x})
	for q in per_prov:
		var chi := []
		for e in per_prov[q]:
			chi.append(e["p"])
		var ord := ordine_precedenza(chi)
		for p in ord:
			var e: Dictionary = per_prov[q].filter(func(z): return z["p"] == p)[0]
			var morti: Array = caduti.get(q, []).filter(func(id): return u[id]["own"] == POOL)
			if morti.is_empty():
				break
			var c := _i(e["x"]["c"])
			var k := "%d:%d" % [c, _i(e["x"]["i"])]
			var prima := dado_prossimo()
			var ok := _lancia(c, _i(e["x"]["i"]), "resurrezione")
			if ok:
				for id in morti:
					u[id]["own"] = p
					u[id]["prov"] = q
					u[id]["zombie"] = true
				ev({"t": "resurrezione", "prov": q, "ids": morti, "p": p})
				scrivi("In %s %d caduti si rialzano come zombi al servizio di %s!" % [Dati.nome_prov(q), morti.size(), g[p]["nome"]])
				break
			elif prima == 6:
				var proprie := militari_in(q, p).filter(func(id): return not u[id]["zombie"])
				var perse := 0
				for id in proprie:
					if perse >= morti.size():
						break
					_cade(id, q)
					perse += 1
				scrivi("Il rito fallisce in modo orribile: %s perde %d unità." % [g[p]["nome"], perse])
	_aggiorna_controllo()

## Valore che uscirà al prossimo tiro, senza consumarlo (per il caso speciale del 6 nel risveglio).
func dado_prossimo() -> int:
	var s := (seme * 1103515245 + 12345) % 2147483648
	return int(s / 65536) % 6 + 1

# ---------------------------------------------------------------- informazioni per l'interfaccia

func visibile_a(id: int, p: int) -> bool:
	var s: Dictionary = u[id]
	if s["own"] == POOL or s["prov"] <= 0:
		return false
	if s["invis"] and s["own"] != p and p >= 0:
		return false
	if s["invis"] and p < 0:
		return false
	return true

func descr_fase() -> String:
	match fase:
		"province": return "Scelta delle province"
		"re": return "Il Re e le sue abilità"
		"alleanze": return "Fase delle alleanze"
		"tornado": return "Fase dei tornado"
		"finanze": return "Finanze: tasse e mantenimento"
		"acquisti": return "Reclutamento"
		"magia1": return "Prima fase magica"
		"chiaro": return "Chiaroveggenza"
		"piano": return "Piano di movimento"
		"rivela": return "Rivelazione delle illusioni"
		"battaglia": return "Combattimento"
		"magia3": return "Terza fase magica"
		"fine": return "Partita finita"
	return fase
