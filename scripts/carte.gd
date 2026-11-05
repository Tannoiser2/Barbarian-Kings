## Catalogo delle carte illustrate: incantesimi, abilità e azioni del gioco.
## Le illustrazioni vanno in assets/img/carte/<chiave>.webp (o .png, .jpg); finché mancano si usa
## uno stemma provvisorio disegnato da tools/carte_provvisorie.py. L'elenco delle immagini da creare
## con ChatGPT, con i testi da usare, è in docs/immagini_chatgpt.md.
class_name Carte
extends RefCounted

const ABILITA := ["marcia", "ritirata", "tattica", "mente", "elementi", "illusione", "necromanzia"]

const AZIONI := {
	"battaglia": ["Battaglia", "Le forze nemiche si scontrano: si confrontano le forze e si tira il dado."],
	"blocco": ["Blocco", "Un esercito entra dove ci sono nemici e deve fermarsi."],
	"fuga": ["Ritirata", "Lo sconfitto ripiega in una provincia vicina."],
	"cattura": ["Re catturato", "Un Re rimasto solo fra i nemici cade prigioniero."],
	"liberazione": ["Re liberato", "Il Re torna libero e riprende il comando."],
	"alleanza": ["Alleanza", "Due re firmano un patto per l'anno."],
	"tributo": ["Tributo", "Sequin versati a un altro re: patti, tributi, riscatti."],
	"tasse": ["Tasse", "Le province versano i loro sequin al re che le controlla."],
	"reclutamento": ["Reclutamento", "Nuove truppe, eroi e maghi si uniscono al re."],
	"piano": ["Piano di guerra", "In segreto, ogni re traccia i percorsi dei suoi eserciti."],
	"vittoria": ["La Pace del Re", "Un re controlla abbastanza tasse e mette fine all'Età Rossa."],
	"fallito": ["Incantesimo fallito", "Il dado supera il valore magico: la magia si disperde."],
}

const DESCR_ABILITA := {
	"marcia": "+1 al movimento del capo e delle unità che guida, per ogni volta che è scelta.",
	"ritirata": "Decide le ritirate; con due punti di vantaggio permette di non ritirarsi.",
	"tattica": "Sposta di una colonna la tabella del combattimento, per ogni punto.",
	"mente": "Discordia, Armonia, Fedeltà, Chiaroveggenza, Controllo mentale.",
	"elementi": "Tornado, tempeste sui mari e sui monti, mare gelato, alluvione.",
	"illusione": "Unità illusorie, invisibilità, rivelazione delle illusioni.",
	"necromanzia": "Uccidere capi e unità, risvegliare i caduti come zombi.",
}

static func titolo(k: String) -> String:
	if Dati.INCANTESIMI.has(k):
		return Dati.INCANTESIMI[k]["nome"]
	if Dati.NOMI_ABILITA.has(k):
		return Dati.NOMI_ABILITA[k]
	if AZIONI.has(k):
		return AZIONI[k][0]
	return k

static func descrizione(k: String) -> String:
	if Dati.DESCR_INCANTESIMI.has(k):
		return Dati.DESCR_INCANTESIMI[k]
	if DESCR_ABILITA.has(k):
		return DESCR_ABILITA[k]
	if AZIONI.has(k):
		return AZIONI[k][1]
	return ""

## Lo stemma provvisorio: il ramo per gli incantesimi, l'abilità stessa, oppure un'azione generica.
static func emblema(k: String) -> String:
	if Dati.INCANTESIMI.has(k):
		return Dati.INCANTESIMI[k]["ramo"]
	if k in ABILITA:
		return k
	return "azione"

static func percorso_immagine(k: String) -> String:
	for est in ["webp", "png", "jpg", "jpeg"]:
		var p := "res://assets/img/carte/%s.%s" % [k, est]
		if ResourceLoader.exists(p):
			return p
	return ""

static func ha_immagine(k: String) -> bool:
	return percorso_immagine(k) != ""

static var _cache := {}

static func tex(k: String) -> Texture2D:
	if _cache.has(k):
		return _cache[k]
	var p := percorso_immagine(k)
	if p == "":
		p = "res://assets/ui/carta_%s.png" % emblema(k)
	var t: Texture2D = load(p)
	_cache[k] = t
	return t

## Il colore del ramo o dell'abilità, per bordi e aloni.
static func colore(k: String) -> Color:
	match emblema(k):
		"mente": return Color(0.59, 0.63, 1.0)
		"elementi": return Color(0.43, 0.84, 1.0)
		"illusione": return Color(0.94, 0.59, 1.0)
		"necromanzia": return Color(0.51, 1.0, 0.39)
		"marcia": return Color(1.0, 0.78, 0.35)
		"ritirata": return Color(0.78, 0.86, 1.0)
		"tattica": return Color(1.0, 0.47, 0.31)
	return Color(0.94, 0.78, 0.47)
