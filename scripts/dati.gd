## Dati statici di Barbarian Kings (SPI, 1980): province, pedine, tabelle.
## Tutto viene da assets/dati/gioco.json, ricavato dalla mappa e dal regolamento del modulo TTS.
class_name Dati
extends RefCounted

static var _caricati := false
static var province := {}      # id -> {id, nome, tasse, nativi, terreno, adiacenti, x, y, costiera}
static var unita := {}         # id -> {id, tipo, origine, costo, mant, forza, mov, casa, nome}
static var tipi := {}          # tipo -> {nome, classe}
static var fanteria_nativa := {}

const COLORI := ["Bianco", "Rosso", "Giallo", "Verde", "Blu"]
const COLORI_RGB := [Color(0.95, 0.93, 0.86), Color(0.80, 0.14, 0.12), Color(0.95, 0.78, 0.15), Color(0.20, 0.58, 0.22), Color(0.18, 0.36, 0.80)]
const COLORE_NEUTRALE := Color(0.45, 0.42, 0.38)

const NATIVI := {
	"barbari": "Barbari", "civili": "Civilizzati", "elfi": "Elfi", "orchi": "Orchi", "nani": "Nani",
	"feudali": "Feudali", "palustri": "Palustri", "balene": "Popolo delle balene", "aeronauti": "Aeronauti", "pirati": "Pirati", "": "nessuno"
}
const TERRENI := {"pianura": "Pianura", "montagna": "Montagna", "foresta": "Foresta", "palude": "Palude", "mare": "Mare"}

## Abilità: tre militari (solo per Re ed Eroi) e quattro rami di magia (per Re e Maghi).
const ABILITA_EROE := ["marcia", "ritirata", "tattica"]
const RAMI := ["mente", "elementi", "illusione", "necromanzia"]
const NOMI_ABILITA := {
	"marcia": "Marcia", "ritirata": "Ritirata", "tattica": "Tattica",
	"mente": "Magia della mente", "elementi": "Magia degli elementi", "illusione": "Magia illusoria", "necromanzia": "Necromanzia"
}

## Gli incantesimi: ramo, fase in cui si lanciano, costo in sequin (pagato solo se riesce).
const INCANTESIMI := {
	"discordia":       {"nome": "Discordia", "ramo": "mente", "fase": "alleanze", "costo": 0},
	"armonia":         {"nome": "Armonia", "ramo": "mente", "fase": "alleanze", "costo": 0},
	"tornado":         {"nome": "Tornado", "ramo": "elementi", "fase": "tornado", "costo": 0},
	"illusioni":       {"nome": "Unità illusorie", "ramo": "illusione", "fase": "acquisti", "costo": 1},
	"uccidi_capo":     {"nome": "Uccidi mago o eroe", "ramo": "necromanzia", "fase": "magia1", "costo": 8},
	"uccidi_unita":    {"nome": "Uccidi unità", "ramo": "necromanzia", "fase": "magia1", "costo": 5},
	"fedelta":         {"nome": "Fedeltà", "ramo": "mente", "fase": "magia1", "costo": 5},
	"chiaroveggenza":  {"nome": "Chiaroveggenza", "ramo": "mente", "fase": "chiaro", "costo": 0},
	"controllo":       {"nome": "Controllo mentale", "ramo": "mente", "fase": "piano", "costo": 0},
	"tempesta_mari":   {"nome": "Mari in tempesta", "ramo": "elementi", "fase": "piano", "costo": 0},
	"tempesta_monti":  {"nome": "Tempesta sui monti", "ramo": "elementi", "fase": "piano", "costo": 0},
	"gelo":            {"nome": "Mare gelato", "ramo": "elementi", "fase": "piano", "costo": 0},
	"alluvione":       {"nome": "Alluvione", "ramo": "elementi", "fase": "piano", "costo": 0},
	"invisibilita":    {"nome": "Invisibilità", "ramo": "illusione", "fase": "piano", "costo": 0},
	"rivela":          {"nome": "Rivela illusioni", "ramo": "illusione", "fase": "rivela", "costo": 0},
	"resurrezione":    {"nome": "Risveglio dei morti", "ramo": "necromanzia", "fase": "magia3", "costo": 0},
}

const DESCR_INCANTESIMI := {
	"discordia": "Impedisce a due giocatori nemici di allearsi in questo turno.",
	"armonia": "Costringe due giocatori ad allearsi in questo turno; annulla la discordia.",
	"tornado": "In una provincia non si riscuotono le tasse in questo turno.",
	"illusioni": "Le unità comprate in questo turno possono essere illusorie: costano 1 sequin, spariscono al primo combattimento.",
	"uccidi_capo": "Elimina un mago o un eroe nemico. Costa 8 sequin.",
	"uccidi_unita": "Elimina unità nemiche in una provincia. Costa 5 sequin per unità.",
	"fedelta": "Le unità neutrali scelte passano sotto il tuo controllo. Costa 5 sequin per unità.",
	"chiaroveggenza": "Vedi gli ordini di movimento di un altro giocatore prima di scrivere i tuoi.",
	"controllo": "Muovi tu un eroe nemico in questa fase di movimento.",
	"tempesta_mari": "Due mari vicini: le unità navali nemiche restano ferme e nessuna può entrarvi.",
	"tempesta_monti": "Due montagne vicine: unità terrestri e aeree nemiche (non i nani) restano ferme e non possono entrarvi.",
	"gelo": "Un mare gela: le flotte non passano, le unità di terra sì; chi vi resta alla fine affoga.",
	"alluvione": "Una provincia: le forze nemiche restano bloccate e non vi si combatte.",
	"invisibilita": "Un tuo capo e la sua forza spariscono dalla mappa; non possono essere bloccati né attaccati.",
	"rivela": "In una provincia scopri unità illusorie e forze invisibili.",
	"resurrezione": "Dove c'è stata battaglia, i caduti tornano come zombi al tuo servizio. Con un 6 perdi unità.",
}

## Tabella dei risultati del combattimento (9.6): righe dado 1-6, colonne 1-1 ... 6-1.
const CRT := [
	["Le", "Lr", "Lr", "Sr", "Sr", "Sme"],
	["Lme", "Lr", "Sr", "Sr", "Sme", "Sme"],
	["Lr", "Sr", "Sr", "Sme", "Sme", "Se"],
	["Sr", "Sr", "Sme", "Sme", "Se", "Se"],
	["Sme", "Sme", "Sme", "Se", "Se", "Se"],
	["Se", "Se", "Se", "Se", "Se", "Se"],
]

static func carica() -> void:
	if _caricati:
		return
	var f := FileAccess.open("res://assets/dati/gioco.json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	for p in d["province"]:
		var q: Dictionary = p.duplicate(true)
		q["id"] = int(q["id"])
		var adj := []
		for a in q["adiacenti"]:
			adj.append(int(a))
		q["adiacenti"] = adj
		q["mare"] = q["terreno"] == "mare"
		q["tasse"] = int(q["tasse"])
		province[q["id"]] = q
	for u in d["unita"]:
		var v: Dictionary = u.duplicate(true)
		for k in ["id", "costo", "mant", "forza", "mov"]:
			v[k] = int(v[k])
		unita[v["id"]] = v
	tipi = d["tipi"]
	fanteria_nativa = d["fanteria_nativa"]
	_caricati = true

static func classe(id: int) -> String:
	return tipi[unita[id]["tipo"]]["classe"]

static func is_militare(id: int) -> bool:
	return not (classe(id) in ["capo", "mago"])

static func is_capo(id: int) -> bool:
	return classe(id) == "capo"

static func is_mare(p: int) -> bool:
	return province[p]["mare"]

static func nome_prov(p: int) -> String:
	if p <= 0 or not province.has(p):
		return "?"
	var q: Dictionary = province[p]
	return "%02d %s" % [p, q.get("nome_it", q["nome"])]

static func nome_unita(id: int) -> String:
	var u: Dictionary = unita[id]
	if u["tipo"] == "re":
		return "%s (%03d)" % [u["nome"], id]
	return "%s %03d" % [tipi[u["tipo"]]["nome"], id]

static func nome_tipo(id: int) -> String:
	return tipi[unita[id]["tipo"]]["nome"]

static func adiacenti(a: int, b: int) -> bool:
	return b in province[a]["adiacenti"]
