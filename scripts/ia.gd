## Giocatori artificiali di Barbarian Kings: decidono ogni fase guardando solo ciò che è visibile.
class_name IA
extends RefCounted

## Numeri casuali propri dell'IA: non toccano il dado del motore, così ogni dispositivo resta allineato.
static var _gen := RandomNumberGenerator.new()

static func _rnd(m: Motore, k: int) -> int:
	return _gen.randi() % k

static func decidi(m: Motore, p: int) -> Dictionary:
	_gen.seed = hash([m.seme, m.turno, m.fase, p, m.eventi.size()])
	match m.fase:
		"province": return _province(m, p)
		"re": return _re(m, p)
		"alleanze": return _alleanze(m, p)
		"tornado": return _tornado(m, p)
		"finanze": return {}
		"acquisti": return _acquisti(m, p)
		"magia1": return _magia1(m, p)
		"chiaro": return _chiaro(m, p)
		"piano": return _piano(m, p)
		"rivela": return _rivela(m, p)
		"battaglia": return _battaglia(m, p)
		"magia3": return _magia3(m, p)
	return {}

const VALORE_NATIVI := {"civili": 4, "nani": 3, "elfi": 3, "barbari": 2, "orchi": 2, "feudali": 1, "palustri": 1, "aeronauti": 2, "pirati": 1, "balene": 0}

static func _province(m: Motore, p: int) -> Dictionary:
	var mie := m.controllate(p)
	var best := 0
	var bv := -999.0
	for q in range(18, 48):
		if m.ctrl[q] != -1:
			continue
		var pr: Dictionary = Dati.province[q]
		var v: float = pr["tasse"] * 1.5 + VALORE_NATIVI.get(pr["nativi"], 0) * 1.5
		for a in pr["adiacenti"]:
			if m.ctrl[a] == -1:
				v += Dati.province[a]["tasse"] * 0.25
			elif m.ctrl[a] != p:
				v -= 3.0
			if a in mie:
				v += 4.0
		v += _rnd(m, 100) / 100.0
		if v > bv:
			bv = v
			best = q
	return {"prov": best}

static func _re(m: Motore, p: int) -> Dictionary:
	var mie := m.controllate(p)
	var best: int = mie[0]
	for q in mie:
		if Dati.province[q]["tasse"] > Dati.province[best]["tasse"]:
			best = q
	var scelte := [["tattica", "tattica", "necromanzia"], ["tattica", "marcia", "elementi"], ["tattica", "ritirata", "mente"], ["tattica", "tattica", "illusione"], ["tattica", "marcia", "necromanzia"]]
	return {"prov": best, "abil": scelte[p % scelte.size()]}

static func _capofila(m: Motore) -> int:
	var best := -1
	var bt := -1
	for q in m.n:
		var t := m.tasse_di(q)
		if t > bt:
			bt = t
			best = q
	return best

static func _alleanze(m: Motore, p: int) -> Dictionary:
	var leader := _capofila(m)
	var firme := []
	if leader != p:
		for q in m.n:
			if q != p and q != leader:
				firme.append(q)
	var inc := []
	for sl in m.slot_magia(p, "mente"):
		if leader != p and m.n >= 3:
			var altro := -1
			for q in m.n:
				if q != p and q != leader:
					altro = q
					break
			if altro >= 0:
				inc.append({"c": sl["c"], "i": sl["i"], "s": "discordia", "a": leader, "b": altro})
		break
	return {"firme": firme, "incanti": inc}

static func _tornado(m: Motore, p: int) -> Dictionary:
	var sl := m.slot_magia(p, "elementi")
	if sl.is_empty():
		return {}
	var leader := _capofila(m)
	var bersaglio := leader if leader != p else -1
	if bersaglio < 0:
		for q in m.n:
			if q != p and not m.alleati(q, p):
				bersaglio = q
				break
	if bersaglio < 0:
		return {}
	var best := 0
	for q in m.controllate(bersaglio):
		if best == 0 or Dati.province[q]["tasse"] > Dati.province[best]["tasse"]:
			best = q
	if best == 0:
		return {}
	return {"incanti": [{"c": sl[0]["c"], "i": sl[0]["i"], "s": "tornado", "prov": best}]}

static func _acquisti(m: Motore, p: int) -> Dictionary:
	var tesoro: int = m.g[p]["tesoro"]
	var entrate := m.tasse_di(p)
	var mant := m.mantenimento(p)
	var compra := []
	var presi := {}
	var mie := m.controllate(p).filter(func(q): return m.militari_in(q, Motore.NEUTRALE).is_empty())
	if mie.is_empty():
		return {"compra": []}
	var militari := 0
	var capi := 0
	for id in m.u:
		if m.u[id]["own"] == p:
			if Dati.is_capo(id):
				capi += 1
			elif Dati.is_militare(id):
				militari += 1
	# provincia "base": quella dove sta il Re, altrimenti la più ricca
	var re: int = m.g[p]["re"]
	var base: int = m.u[re]["prov"] if m.u[re]["prov"] in mie else mie[0]
	# eroi: almeno un capo ogni tre o quattro unità, e almeno due capi dal primo anno
	var serve_eroi := 0
	if capi < 2:
		serve_eroi = 1
	if militari + 3 > capi * 4:
		serve_eroi = maxi(serve_eroi, 1)
	for k in serve_eroi:
		if tesoro < 16 or entrate - mant < 5:
			break
		var eroi := m.disponibili("eroe").filter(func(id): return m.u[id]["own"] == Motore.POOL and not presi.has(id))
		if eroi.is_empty():
			break
		var dove := _provincia_senza_capo(m, p, mie)
		compra.append({"id": eroi[0], "p": dove, "abil": ["tattica" if _rnd(m, 3) > 0 else "marcia"]})
		presi[eroi[0]] = true
		tesoro -= 10
		mant += 4
	# un mago necromante quando si è ricchi
	if tesoro >= 45 and entrate - mant >= 10 and _rnd(m, 3) == 0:
		var maghi := m.disponibili("mago").filter(func(id): return m.u[id]["own"] == Motore.POOL)
		if not maghi.is_empty():
			compra.append({"id": maghi[0], "p": base, "abil": [["necromanzia", "elementi", "mente"][_rnd(m, 3)]]})
			presi[maghi[0]] = true
			tesoro -= 10
			mant += 4
	# unità militari: le più forti per sequin, finché il mantenimento resta sostenibile
	for giro in 12:
		var best_id := 0
		var best_q := 0
		var bv := -1.0
		for q in mie:
			var nat: String = Dati.province[q]["nativi"]
			if nat == "":
				continue
			for tipo in Dati.tipi:
				var ids := m.disponibili(tipo).filter(func(id): return not presi.has(id) and m.u[id]["own"] == Motore.POOL)
				if ids.is_empty():
					continue
				var id0: int = ids[0]
				var dd: Dictionary = Dati.unita[id0]
				if dd["origine"] != nat or dd["costo"] > tesoro:
					continue
				if mant + dd["mant"] > entrate + 2:
					continue
				var c := Dati.classe(id0)
				if c in ["flotta", "balena"] and not _serve_flotta(m, p, q):
					continue
				var v: float = float(dd["forza"]) / float(dd["costo"]) + dd["forza"] * 0.15
				if m._capi_in(q, p) > 0:
					v += 0.2
				if v > bv:
					bv = v
					best_id = id0
					best_q = q
		if best_id == 0:
			break
		compra.append({"id": best_id, "p": best_q})
		presi[best_id] = true
		tesoro -= Dati.unita[best_id]["costo"]
		mant += Dati.unita[best_id]["mant"]
	return {"compra": compra}

static func _serve_flotta(m: Motore, p: int, q: int) -> bool:
	# una flotta serve se ci sono isole o coste da raggiungere: la si compra solo ogni tanto
	var flotte := 0
	for id in m.u:
		if m.u[id]["own"] == p and Dati.classe(id) == "flotta":
			flotte += 1
	return flotte < 1 and Dati.province[q].get("costiera", false) and m.turno >= 3

static func _provincia_senza_capo(m: Motore, p: int, mie: Array) -> int:
	var best: int = mie[0]
	var bv := -1
	for q in mie:
		var mil := m.militari_in(q, p).size()
		var v: int = mil * 2 - m._capi_in(q, p) * 5 + Dati.province[q]["tasse"]
		if v > bv:
			bv = v
			best = q
	return best

static func _magia1(m: Motore, p: int) -> Dictionary:
	var inc := []
	var tesoro: int = m.g[p]["tesoro"]
	for sl in m.slot_magia(p, "necromanzia"):
		if tesoro < 16:
			break
		# un eroe nemico, altrimenti l'unità nemica più forte vicino a noi
		var bersaglio := 0
		for id in m.u:
			var s: Dictionary = m.u[id]
			if s["own"] >= 0 and s["own"] != p and not m.alleati(s["own"], p) and Dati.unita[id]["tipo"] in ["eroe", "mago"] and m.visibile_a(id, p):
				bersaglio = id
				break
		if bersaglio > 0:
			inc.append({"c": sl["c"], "i": sl["i"], "s": "uccidi_capo", "t": bersaglio})
			tesoro -= 8
		else:
			var forte := 0
			for id in m.u:
				var s2: Dictionary = m.u[id]
				if s2["own"] >= 0 and s2["own"] != p and not m.alleati(s2["own"], p) and Dati.is_militare(id) and m.visibile_a(id, p):
					if forte == 0 or Dati.unita[id]["forza"] > Dati.unita[forte]["forza"]:
						forte = id
			if forte > 0:
				inc.append({"c": sl["c"], "i": sl["i"], "s": "uccidi_unita", "t": [forte]})
				tesoro -= 5
	for sl in m.slot_magia(p, "mente"):
		if tesoro < 12:
			break
		var mie := m.controllate(p)
		var bersagli := []
		for q in mie:
			for a in Dati.province[q]["adiacenti"]:
				for id in m.militari_in(a, Motore.NEUTRALE):
					if not (id in bersagli):
						bersagli.append(id)
		if not bersagli.is_empty():
			inc.append({"c": sl["c"], "i": sl["i"], "s": "fedelta", "t": [bersagli[0]]})
			tesoro -= 5
		break
	return {"incanti": inc}

static func _chiaro(m: Motore, p: int) -> Dictionary:
	var sl := m.slot_magia(p, "mente")
	var leader := _capofila(m)
	if sl.is_empty() or leader == p:
		return {}
	return {"incanti": [{"c": sl[0]["c"], "i": sl[0]["i"], "s": "chiaroveggenza", "p": leader}]}

## Stima della forza nemica che si troverebbe in una provincia (solo unità visibili).
static func _forza_nemica(m: Motore, q: int, p: int) -> int:
	return m.forza_effettiva(m.nemici_in(q, p), q)

static func _piano(m: Motore, p: int) -> Dictionary:
	var ordini := []
	var incanti := []
	var impegnati := {}
	var capi := m.capi_di(p).filter(func(id): return Dati.is_capo(id))
	# prima gli eroi, il Re per ultimo (così resta con l'esercito più grosso)
	capi.sort_custom(func(a, b): return m.militari_in(m.u[a]["prov"], p).size() > m.militari_in(m.u[b]["prov"], p).size())
	var destinazioni := {}
	for capo in capi:
		var q0: int = m.u[capo]["prov"]
		var unita := m.militari_in(q0, p).filter(func(id): return not impegnati.has(id))
		if unita.is_empty():
			# un capo da solo va verso una provincia amica con unità senza capo
			var dove := _verso_unita_senza_capo(m, p, capo, impegnati)
			if not dove.is_empty():
				ordini.append({"capo": capo, "unita": [], "via": dove})
				impegnati[capo] = true
			continue
		# lascia una guarnigione se ci sono nemici vicini e la provincia è ricca
		var forza := m.forza_effettiva(unita, q0)
		var piano := _miglior_meta(m, p, capo, unita, destinazioni)
		if piano.is_empty():
			continue
		for id in unita:
			impegnati[id] = true
		impegnati[capo] = true
		destinazioni[piano[-1]] = true
		ordini.append({"capo": capo, "unita": unita, "via": piano})
	# invisibilità per l'esercito principale
	for sl in m.slot_magia(p, "illusione"):
		if not ordini.is_empty():
			incanti.append({"c": sl["c"], "i": sl["i"], "s": "invisibilita", "capo": ordini[0]["capo"]})
		break
	return {"ordini": ordini, "blocca": true, "incanti": incanti}

static func _verso_unita_senza_capo(m: Motore, p: int, capo: int, impegnati: Dictionary) -> Array:
	var best := []
	var bv := 0
	var frontiera := [[m.u[capo]["prov"], []]]
	var visti := {m.u[capo]["prov"]: true}
	var ma := m.mov_gruppo(capo, [])
	for passo in ma:
		var nuova := []
		for f in frontiera:
			for q in m.passi_possibili(p, capo, [], f[1]):
				if visti.has(q):
					continue
				visti[q] = true
				var via: Array = f[1] + [q]
				if not m.nemici_in(q, p).is_empty():
					continue
				var mil := m.militari_in(q, p).filter(func(id): return not impegnati.has(id)).size()
				if mil > bv and m._capi_in(q, p) == 0:
					bv = mil
					best = via
				nuova.append([q, via])
		frontiera = nuova
	return best

## Cerca la meta migliore raggiungibile: province ricche non nostre, che si possono vincere.
static func _miglior_meta(m: Motore, p: int, capo: int, unita: Array, gia: Dictionary) -> Array:
	var q0: int = m.u[capo]["prov"]
	var forza := m.forza_effettiva(unita, q0)
	var best := []
	var bv := 0.0
	var frontiera := [[q0, []]]
	var visti := {q0: true}
	for passo in 8:
		var nuova := []
		for f in frontiera:
			var poss := m.passi_possibili(p, capo, unita, f[1])
			for q in poss:
				if visti.has(q):
					continue
				visti[q] = true
				var via: Array = f[1] + [q]
				var nem := _forza_nemica(m, q, p)
				var mia := m.forza_effettiva(unita, q)
				var v: float = f[2] if f.size() > 2 else 0.0
				var tasse: int = Dati.province[q]["tasse"]
				if m.ctrl[q] != p:
					v += tasse * 2.0
					if m.ctrl[q] >= 0 and not m.alleati(m.ctrl[q], p):
						v += 2.0
				var guadagno := v
				if nem > 0:
					if mia >= nem * 2:
						v += 3.0
					elif mia >= nem:
						v -= 1.0
					else:
						v -= 50.0
				if Dati.is_mare(q) and tasse < 2:
					v -= 2.0
				if gia.has(q):
					v -= 6.0
				v -= via.size() * 0.3
				if v > bv:
					bv = v
					best = via
				# non si prosegue oltre una provincia con nemici (si verrà bloccati)
				if nem == 0:
					nuova.append([q, via, guadagno])
		frontiera = nuova
	return best

static func _rivela(m: Motore, p: int) -> Dictionary:
	return {}

static func _battaglia(m: Motore, p: int) -> Dictionary:
	var q := m.provincia_battaglia()
	var mia := m.forza_effettiva(m.forza_di_lato(q, m.lato(p)), q)
	var att := []
	for l in m.bersagli_attacco(q, p):
		var loro := m.forza_effettiva(m.forza_di_lato(q, l), q)
		if l == Motore.NEUTRALE or mia >= loro:
			att.append(l)
	return {"attacca": att}

static func _magia3(m: Motore, p: int) -> Dictionary:
	var inc := []
	for sl in m._resurrezioni_possibili(p):
		inc.append({"c": sl["c"], "i": sl["i"], "s": "resurrezione"})
	return {"incanti": inc}
