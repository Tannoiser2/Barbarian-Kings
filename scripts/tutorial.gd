## Testi del libro "Come si gioca" e della partita guidata con il Saggio.
## Il libro è diviso in capitoli; la partita guidata usa le funzioni guida_*() per ogni fase.
class_name Tutorial
extends RefCounted

const ROSSO := "7a170d"
const BRUNO := "61391a"

static func _t(s: String) -> String:
	return "[color=#%s][b]%s[/b][/color]" % [ROSSO, s]

static func _ped(id: int, lato := 52) -> String:
	return "[img=%dx%d]res://assets/img/pedine_colore/%03d.png[/img]" % [lato, lato, id]

static func capitoli() -> Array:
	return [
		{"titolo": "Benvenuto a Castafon", "testo": _cap_scopo()},
		{"titolo": "La mappa", "testo": _cap_mappa()},
		{"titolo": "Le pedine", "testo": _cap_pedine()},
		{"titolo": "Un anno di gioco", "testo": _cap_anno()},
		{"titolo": "Tasse, mantenimento e reclute", "testo": _cap_denaro()},
		{"titolo": "Capi e movimento", "testo": _cap_movimento()},
		{"titolo": "Il combattimento", "testo": _cap_combattimento()},
		{"titolo": "Le abilità dei capi", "testo": _cap_abilita()},
		{"titolo": "La magia: dadi e valori", "testo": _cap_magia()},
		{"titolo": "Scuola della mente", "testo": _cap_ramo("mente")},
		{"titolo": "Scuola degli elementi", "testo": _cap_ramo("elementi")},
		{"titolo": "Scuola dell'illusione", "testo": _cap_ramo("illusione")},
		{"titolo": "Scuola della necromanzia", "testo": _cap_ramo("necromanzia")},
		{"titolo": "Alleanze e diplomazia", "testo": _cap_alleanze()},
		{"titolo": "Come si usa questa versione", "testo": _cap_comandi()},
		{"titolo": "Consigli del Saggio", "testo": _cap_consigli()},
		{"titolo": "Riassunto completo delle regole", "testo": Regole.testo()},
	]

static func _cap_scopo() -> String:
	return """[i]È l'Età Rossa di Castafon, il continente del pianeta Hypastia dove la magia funziona... a volte. Da due a cinque re barbari si contendono le sue province con la spada, l'oro e gli incantesimi.[/i]

%s
Ogni provincia rende ogni anno un certo numero di [b]sequin[/b] di tasse. Vince il primo re che, all'inizio di un anno, controlla province che insieme rendono almeno:
[indent]- [b]120[/b] sequin con due giocatori
- [b]100[/b] con tre giocatori
- [b]90[/b] con quattro o cinque[/indent]
Nella barra in alto ogni re ha uno scudo del suo colore, una barra dorata che si riempie avvicinandosi alla vittoria e il tesoro accanto alla moneta.

%s
Prima si scelgono a turno le province di partenza: tre a testa in due, due in tre o quattro giocatori, una in cinque. Poi ognuno pone il suo Re in una di esse e gli dà in segreto fino a tre abilità. Ogni re parte con 50 sequin.
Nelle province libere che rendono 6 o più compare una fanteria [i]indigena[/i]: un presidio neutrale da sconfiggere per prendere la provincia.

%s
Un anno è fatto di fasi: alleanze, finanze, reclutamento, magia, movimento, battaglia. Quasi tutte le decisioni sono [b]segrete e simultanee[/b]: tutti scelgono, poi il gioco rivela e risolve. Il capitolo "Un anno di gioco" le descrive una per una.

%s
Dal menu principale scegli [b]Partita guidata con il Saggio[/b]: giocherai davvero contro Re Baxx e io ti spiegherò ogni fase, passo per passo, per i primi tre anni.""" % [_t("Lo scopo"), _t("L'inizio"), _t("Gli anni"), _t("Il modo migliore per imparare")]

static func _cap_mappa() -> String:
	return """La mappa è divisa in [b]47 province[/b]: 17 mari e 30 province di terra. Su ognuna sono scritti il numero, il nome e le [b]tasse[/b] che rende ogni anno; sotto il nome, il [b]popolo[/b] che la abita.

%s
[indent][b]Pianura[/b]: si entra spendendo 1 punto movimento.
[b]Montagna[/b]: costa 2 (1 per i nani). I nani vi combattono al doppio, la cavalleria a metà.
[b]Foresta[/b]: costa 2 (1 per gli elfi). Gli elfi vi combattono al doppio, cavalleria e legioni a metà.
[b]Palude[/b]: costa 2 (1 per le rane). Le rane combattono al doppio, tutti gli altri a metà.
[b]Mare[/b]: costa 1, ma lo attraversano solo flotte, balene, aeronavi e rane (un solo mare).[/indent]

%s
Ogni provincia di terra appartiene a un popolo: barbari, civilizzati, elfi, orchi, nani, feudali, palustri, aeronauti, pirati o il popolo delle balene. Le [b]truppe di un popolo si reclutano solo nelle sue province[/b] che controlli: se vuoi i nani, ti serve una provincia nanica. Eroi e maghi invece si assoldano ovunque.

%s
Si controlla una provincia se vi si trovano, o vi sono passate per ultime, le tue unità militari; oppure se la possiedi dall'inizio e nessuno l'ha mai presa. Una bandierina del tuo colore la segna sulla mappa.

%s
In alto a destra ci sono due interruttori:
[indent][b]Mappa a rilievo[/b]: passa dalla mappa originale SPI del 1980 a una mappa moderna dipinta, con montagne e foreste in rilievo.
[b]3D[/b]: trasforma le pedine di cartone in miniature animate che camminano, combattono e lanciano incantesimi.[/indent]
Le regole non cambiano: valgono sempre le adiacenze del regolamento originale.""" % [_t("I terreni"), _t("I popoli"), _t("Il controllo"), _t("Due mappe e due stili")]

static func _cap_pedine() -> String:
	var t := """Ogni pedina mostra il suo valore di [b]forza[/b] (a sinistra) e di [b]movimento[/b] (a destra). Re, eroi e maghi non hanno forza: sono capi e incantatori.

%s
""" % _t("I capi")
	t += "%s  [b]Re[/b]: il tuo sovrano. Guida gli eserciti, può avere abilità militari o magiche. Se resta solo dove ci sono nemici viene [i]catturato[/i].\n" % _ped(10)
	t += "%s  [b]Eroe[/b]: un secondo capo (costo 10, mantenimento 4). Guida un esercito e ha un'abilità: Marcia, Ritirata o Tattica.\n" % _ped(11)
	t += "%s  [b]Mago[/b]: un incantatore (costo 10, mantenimento 4) con un ramo di magia. Viaggia da solo, non guida unità.\n\n" % _ped(13)
	t += _t("Le truppe") + "\n[font_size=16][table=6]"
	for h in ["", "Unità", "Popolo", "Forza", "Mov.", "Costo / mant."]:
		t += "[cell][b]%s[/b]    [/cell]" % h
	var visti := {}
	var ids := Dati.unita.keys()
	ids.sort()
	for id in ids:
		var d: Dictionary = Dati.unita[id]
		if d["tipo"] in ["re", "eroe", "mago"] or visti.has(d["tipo"]):
			continue
		visti[d["tipo"]] = true
		t += "[cell]%s  [/cell][cell]%s    [/cell][cell]%s    [/cell][cell]%d[/cell][cell]%d[/cell][cell]%d / %d[/cell]" % [_ped(id, 44), Dati.tipi[d["tipo"]]["nome"], Dati.NATIVI[d["origine"]], d["forza"], d["mov"], d["costo"], d["mant"]]
	t += "[/table][/font_size]\n\n"
	t += _t("Unità speciali") + "\n"
	t += "Le [b]flotte[/b] (barbare, galee, elfiche, pirate) vanno per mare e nelle province costiere e trasportano un'unità di terra ciascuna. Le [b]aeronavi[/b] volano ovunque ma non si fermano in mare o in montagna. Le [b]rane da guerra[/b] attraversano un solo mare e sono fortissime in palude. Le [b]balene[/b] restano sempre in mare.\n\n"
	t += _t("Pile e colori") + "\nSulla mappa le pedine di ogni re formano una pila, con i capi in cima; il bordo colorato dice a chi appartengono, il bordo bianco indica gli indigeni neutrali. Passa il mouse su una provincia per vedere la scheda con tutte le pedine che contiene."
	return t

static func _cap_anno() -> String:
	return """Ogni anno segue la stessa sequenza, mostrata dalla fascia sotto la barra in alto. La fase in corso è evidenziata in rosso.

%s Con tre o più giocatori, chi firma reciprocamente un patto è alleato per tutto l'anno. Si possono anche versare sequin.
%s Si riscuotono le tasse delle province controllate e si paga il mantenimento di ogni unità. Un mago degli elementi può scatenare un [i]tornado[/i] che cancella le tasse di una provincia.
%s Si comprano nuove unità, in ordine di precedenza.
%s Necromanti e maghi della mente colpiscono: uccidere capi, distruggere unità, comprare la fedeltà degli indigeni. Un mago della mente può anche spiare i piani di un nemico con la [i]chiaroveggenza[/i].
%s Tutti scrivono in segreto i percorsi dei loro eserciti; poi si lanciano gli incantesimi di movimento (tempeste, gelo, alluvioni, invisibilità) e tutti si muovono insieme, un punto movimento alla volta.
%s Dove si incontrano forze nemiche si combatte. Alla fine i necromanti possono risvegliare i caduti come zombi.

Poi comincia un nuovo anno e si controlla se qualcuno ha raggiunto la soglia di vittoria.""" % [_t("1. Alleanze."), _t("2. Finanze."), _t("3. Reclute."), _t("4. Magia."), _t("5. Movimento."), _t("6. Battaglia.")]

static func _cap_denaro() -> String:
	return """%s
All'inizio di ogni anno ricevi le tasse di tutte le province che controlli. È l'unica entrata, oltre ai doni degli altri re: ogni provincia conquistata ti arricchisce e ti avvicina alla vittoria.

%s
Ogni unità ha un costo di [b]mantenimento[/b] annuo. Nella fase delle finanze puoi congedare le unità che non vuoi più pagare: tornano disponibili per tutti. Se il tesoro non basta, le unità più costose vengono congedate da sole. Un esercito grande è potente, ma un esercito che non puoi pagare si scioglie.

%s
Clicca una tua provincia (in verde): a destra compaiono le unità del suo popolo, con il costo e il mantenimento. Premi [b]Recluta[/b] per metterle nell'ordine; [b]Togli[/b] per ripensarci. Le nuove unità compaiono nella provincia scelta. Eroi e maghi si assoldano in qualsiasi tua provincia; per l'eroe scegli l'abilità, per il mago il ramo di magia.
Le unità di ogni tipo sono poche: se un avversario le ha già prese tutte, non ce ne sono più. Si recluta in ordine di [i]precedenza[/i], che cambia ogni anno.

%s
Prima di spendere guarda la riga "mantenimento futuro": deve restare sotto le tasse che incassi, altrimenti l'anno prossimo dovrai congedare qualcuno.""" % [_t("Le tasse"), _t("Il mantenimento"), _t("Il reclutamento"), _t("Il conto del Saggio")]

static func _cap_movimento() -> String:
	return """%s
Le unità militari si muovono [b]solo se guidate da un capo[/b] (il Re o un Eroe) che viaggia con loro. Un esercito senza capo resta fermo a presidiare. Per questo gli eroi sono preziosi: ognuno è un esercito in più.

%s
Il gruppo si muove alla velocità dell'unità più lenta. Ogni provincia costa 1 o 2 punti secondo il terreno. L'abilità [i]Marcia[/i] del capo aggiunge 1 punto per ogni volta che è stata scelta.

%s
Nel pannello a destra scegli un capo, spunta le unità che porta con sé, poi clicca una dopo l'altra le province del percorso: quelle ancora raggiungibili si illuminano in giallo. Una freccia del tuo colore mostra il cammino. Puoi togliere l'ultimo passo o annullare l'ordine. Quando hai finito con tutti i capi, premi [b]Conferma gli ordini[/b].

%s
Tutti gli ordini si eseguono insieme, un punto movimento alla volta. Se un esercito entra dove si trovano unità nemiche che hanno l'opzione [b]Blocca i nemici che arrivano[/b], si ferma lì. Gli indigeni bloccano sempre. Non si passa direttamente da una provincia nemica a un'altra provincia nemica.

%s
Le flotte trasportano un'unità di terra ciascuna attraverso i mari; chi viaggia per mare non si muove anche per terra nello stesso anno.

%s
Un capo o un mago che resta senza unità amiche dove ci sono nemici: il [b]Re viene catturato[/b] (si può liberare o riscattare), eroi e maghi muoiono. Non lasciare mai il tuo Re da solo in prima linea!""" % [_t("Chi guida chi"), _t("Punti movimento"), _t("Scrivere un ordine"), _t("Blocchi"), _t("Per mare"), _t("Il pericolo della solitudine")]

static func _cap_combattimento() -> String:
	var t := """%s
Dove si incontrano forze nemiche, in ordine di precedenza ognuno sceglie chi attaccare. Si sommano le forze di ogni lato (contando il terreno) e si calcola il [b]rapporto[/b] dal lato più forte, arrotondando a favore del più debole: 7 contro 3 fa [b]2-1[/b], 9 contro 3 fa [b]3-1[/b]. Il rapporto va da 1-1 a 6-1.

%s
Conta la [i]Tattica[/i] più alta fra i capi di ciascun lato: la differenza sposta la colonna a favore di chi ne ha di più. Un Re con Tattica 2 contro un nemico senza tattica trasforma un 1-1 in un 3-1!

%s
Si tira un dado e si legge la tabella. [b]L[/b] è la forza più grande, [b]S[/b] la più piccola; [b]e[/b] = annientata, [b]me[/b] = perde unità per almeno metà della forza, [b]r[/b] = si ritira.
""" % [_t("Il rapporto di forze"), _t("La tattica"), _t("La tabella")]
	t += "[font_size=17][table=7][cell][b]Dado[/b]  [/cell]"
	for c in 6:
		t += "[cell][b]%d-1[/b]  [/cell]" % (c + 1)
	for r in 6:
		t += "[cell][b]%d[/b][/cell]" % (r + 1)
		for c in 6:
			var ris: String = Dati.CRT[r][c]
			var col := ROSSO if ris[0] == "L" else "2d5a1e"
			t += "[cell][color=#%s]%s[/color]  [/cell]" % [col, ris]
	t += "[/table][/font_size]\n[i]In rosso i risultati che colpiscono il più forte, in verde quelli che colpiscono il più debole.[/i]\n\n"
	t += """%s
Chi deve ritirarsi si sposta in una provincia vicina. Un capo con più [i]Ritirata[/i] decide dove si ritira lo sconfitto; con due punti di vantaggio può ignorare la ritirata.

%s
Montagna: nani doppi, cavalleria a metà. Foresta: elfi doppi, cavalleria e legioni a metà. Palude: rane doppie, tutti gli altri a metà.

%s
Alla fine della battaglia gli indigeni attaccano chi non li ha combattuti. Per conquistare una provincia con un presidio neutrale porta una forza almeno doppia: a 2-1 il rischio è già basso, a 3-1 quasi nullo.""" % [_t("La ritirata"), _t("Il terreno"), _t("Gli indigeni")]
	return t

static func _carta(k: String, lato := 96) -> String:
	var p := Carte.percorso_immagine(k)
	if p == "":
		p = "res://assets/ui/carta_%s.png" % Carte.emblema(k)
	return "[img=%dx%d]%s[/img]" % [lato, int(lato * 1.5), p]

static func _cap_abilita() -> String:
	var t := """Ogni Re riceve all'inizio [b]tre abilità[/b], scelte in segreto e anche ripetute; ogni Eroe ne riceve una quando lo assoldi, ogni Mago un ramo di magia. Le abilità restano per tutta la partita.

"""
	t += "[table=2][cell]%s  [/cell][cell]%s\nOgni volta che la scegli aggiunge [b]1 punto movimento[/b] al capo e a tutte le unità che guida. Un Re con Marcia 2 porta la fanteria (movimento 2) a 4: può attraversare due montagne in un anno, o colpire una provincia lontana prima che il nemico se lo aspetti.\n[i]Consiglio: utile a chi gioca d'attacco e ha province lontane fra loro.[/i]\n[/cell]" % [_carta("marcia"), _t("Marcia")]
	t += "[cell]%s  [/cell][cell]%s\nDopo una battaglia persa, si confronta la Ritirata più alta dei capi dei due lati:\n[indent]- se lo sconfitto ne ha [b]2 o più[/b] del vincitore, [b]non si ritira[/b] e resta sul campo;\n- se ne ha di meno, è il [b]vincitore[/b] a scegliere dove si ritira (magari verso un'altra trappola);\n- altrimenti sceglie lo sconfitto.[/indent]\n[i]Consiglio: un capo con Ritirata 2 difende una provincia chiave anche quando perde.[/i]\n[/cell]" % [_carta("ritirata"), _t("Ritirata")]
	t += "[cell]%s  [/cell][cell]%s\nIn battaglia conta la Tattica più alta fra i capi di ciascun lato; la differenza sposta la colonna della tabella a favore di chi ne ha di più. Esempio: 6 contro 6 è un 1-1, ma con Tattica 2 contro 0 diventa un [b]3-1[/b] a tuo favore. Può anche rovesciare un rapporto sfavorevole: chi ha meno forza ma più tattica può diventare l'attaccante \"grande\" della tabella.\n[i]Consiglio: la scelta più forte per chi combatte molto. Due Tattiche sul Re sono un classico.[/i]\n[/cell][/table]\n\n" % [_carta("tattica"), _t("Tattica")]
	t += _t("I rami di magia") + "\nSe dai al Re un ramo di magia, il Re diventa un incantatore con valore 2 in quel ramo. Scegliere due volte lo stesso ramo gli dà [b]due incantesimi[/b] di quel ramo all'anno, ognuno con il suo valore. I quattro rami sono spiegati nei prossimi capitoli.\n\n"
	t += _t("Eroi e maghi") + "\nL'[b]Eroe[/b] (10 sequin, mantenimento 4) arriva con un'abilità a tua scelta: un eroe con Tattica è il comandante ideale di un secondo esercito. Il [b]Mago[/b] (10 sequin, mantenimento 4) conosce un solo ramo, viaggia da solo e non guida truppe: tienilo lontano dai nemici, perché se resta solo dove ci sono nemici muore."
	return t

static func _cap_magia() -> String:
	var t := """%s
Un incantatore è un Mago, oppure un Re a cui hai dato un ramo di magia. In ogni ramo che conosce parte con [b]valore 2[/b]. Ogni incantesimo appartiene a un ramo e si lancia in una fase precisa dell'anno.

%s
Per lanciare si tira un dado: l'incantesimo [b]riesce con un risultato pari o inferiore al valore[/b].
""" % [_t("Chi lancia"), _t("Il dado")]
	t += "[font_size=17][table=3][cell][b]Valore  [/b][/cell][cell][b]Riesce con  [/b][/cell][cell][b]Probabilità[/b][/cell]"
	for v in range(1, 6):
		t += "[cell]%d[/cell][cell]%s[/cell][cell]%d su 6 (%d%%)[/cell]" % [v, "1" if v == 1 else "1 - %d" % v, v, int(round(v * 100.0 / 6.0))]
	t += "[/table][/font_size]\n\n"
	t += """%s
Il dado cambia anche il mago: con un [b]1[/b] il valore sale di uno (fino a 5), con un [b]6[/b] scende di uno (fino a 1). Un mago che lancia spesso, prima o poi, diventa più potente... o perde fiducia.

%s
[indent]- Ogni ramo si usa [b]una volta all'anno[/b] per ogni volta che l'incantatore lo conosce.
- Il [b]costo[/b] in sequin si paga [b]solo se l'incantesimo riesce[/b]: tentare non costa nulla.
- L'incantatore deve essere libero (non prigioniero) e sulla mappa.
- Gli incantesimi di una stessa fase si risolvono insieme; quelli di movimento dopo che tutti hanno scritto i piani.[/indent]

%s
Nel pannello di ogni fase magica compare una riga per ogni incantatore, con il valore e la probabilità di riuscita, e una fila di [b]carte[/b]: clicca quella dell'incantesimo che vuoi lanciare (cliccala di nuovo per rinunciare) e poi scegli il bersaglio, spesso direttamente sulla mappa. Mentre il gioco risolve, la carta compare al centro dello schermo e la magia prende forma sul tavolo.

%s
Fra un anno e l'altro gli incantesimi seguono quest'ordine:
[indent]Alleanze: [i]Discordia, Armonia[/i]
Tornado: [i]Tornado[/i]
Reclutamento: [i]Unità illusorie[/i]
Prima fase magica: [i]Uccidi mago o eroe, Uccidi unità, Fedeltà[/i]
Prima dei piani: [i]Chiaroveggenza[/i]
Seconda fase magica: [i]Controllo mentale, tempeste, Mare gelato, Alluvione, Invisibilità[/i]
Prima del movimento: [i]Rivela illusioni[/i]
Terza fase magica: [i]Risveglio dei morti[/i][/indent]

[i]Per imparare giocando, dal menu principale scegli [b]Scuola di magia[/b]: il tuo Re conoscerà tre rami e il Saggio ti seguirà incantesimo per incantesimo.[/i]""" % [_t("Il valore cambia"), _t("Le regole d'oro"), _t("Come si lancia"), _t("Il calendario della magia")]
	return t

const LEZIONI := {
	"discordia": ["Alleanze", "due giocatori", "Due re che volevano allearsi restano nemici per tutto l'anno: non possono passare l'uno attraverso l'altro e non combattono insieme.", "Lanciala sui due re più forti quando temi che si coalizzino contro di te."],
	"armonia": ["Alleanze", "due giocatori", "Costringe due re ad allearsi per l'anno, anche contro la loro volontà, e annulla una Discordia.", "Usala per mettere al sicuro un confine: un vicino alleato per forza non ti attaccherà quest'anno."],
	"fedelta": ["Prima fase magica", "unità indigene di una provincia", "Ogni unità indigena che compri con 5 sequin passa al tuo servizio: non devi più combatterla e la provincia è a un passo.", "Ottima per prendere una provincia ricca senza battaglia. Prepara 5 sequin per ogni unità."],
	"chiaroveggenza": ["Prima dei piani", "un giocatore", "Vedi le frecce del piano di movimento dell'avversario prima di scrivere il tuo.", "Non costa nulla: tentala ogni anno contro il vicino più pericoloso."],
	"controllo": ["Seconda fase magica", "un eroe nemico", "L'eroe nemico ignora i suoi ordini e segue il percorso che tracci tu, con le truppe che guida.", "Portalo dentro una provincia piena delle tue truppe, o lontano dalla battaglia decisiva."],
	"tornado": ["Tornado", "una provincia", "Quest'anno la provincia non rende tasse a nessuno.", "Colpisci la provincia più ricca del re in testa alla classifica."],
	"tempesta_mari": ["Seconda fase magica", "due mari vicini", "Le unità navali nemiche restano ferme e nessuna può entrare in quei mari.", "Ferma un'invasione dal mare o isola un'isola nemica."],
	"tempesta_monti": ["Seconda fase magica", "due montagne vicine", "Unità terrestri e aeree nemiche (non i nani) restano ferme e non possono entrarvi.", "Chiudi i passi di montagna mentre attacchi altrove."],
	"gelo": ["Seconda fase magica", "un mare o una palude", "Le flotte non passano, le unità di terra sì; chi vi resta alla fine dell'anno affoga.", "Apri un ponte di ghiaccio per il tuo esercito, ma non fermarti sul mare!"],
	"alluvione": ["Seconda fase magica", "una provincia di terra", "Le forze nemiche che vi si trovano restano bloccate e lì non si combatte.", "Salva una provincia assediata o blocca un esercito nemico per un anno."],
	"illusioni": ["Reclutamento", "le unità che compri", "Ogni unità costa solo 1 sequin, ma è finta: svanisce alla prima battaglia. Il nemico però non lo sa.", "Crea un esercito di paura per difendere le province o per attirare il nemico."],
	"invisibilita": ["Seconda fase magica", "un tuo capo e la sua forza", "L'esercito sparisce dalla mappa: non può essere bloccato né attaccato durante il movimento.", "Perfetta per colpire alle spalle una provincia sguarnita."],
	"rivela": ["Prima del movimento", "una provincia", "Scopri unità illusorie e forze invisibili nemiche in quella provincia.", "Usala sull'esercito nemico troppo grande per essere vero."],
	"uccidi_capo": ["Prima fase magica", "un eroe o un mago nemico", "Costa 8 sequin: il bersaglio muore all'istante.", "Elimina l'eroe che guida il secondo esercito nemico: le sue truppe resteranno ferme."],
	"uccidi_unita": ["Prima fase magica", "unità nemiche in una provincia", "Costa 5 sequin per ogni unità distrutta.", "Indebolisci una difesa prima del tuo attacco, colpendo le unità più forti."],
	"resurrezione": ["Terza fase magica", "una provincia dove si è combattuto", "Tutti i caduti della battaglia, amici e nemici, tornano come zombi al tuo servizio. Con un 6, però, perdi unità.", "Dopo una grande battaglia può darti un esercito gratis."],
}

static func _cap_ramo(r: String) -> String:
	var intro := {
		"mente": "La magia della mente agisce sulla volontà: rompe e crea alleanze, compra la fedeltà degli indigeni, spia i piani e piega gli eroi nemici.",
		"elementi": "La magia degli elementi scatena la natura: tornado, tempeste, ghiaccio e acqua cambiano la mappa per un anno intero.",
		"illusione": "La magia illusoria inganna gli occhi: eserciti che non esistono, eserciti che nessuno vede. Il regolamento consigliava di lasciarla per le partite successive alla prima.",
		"necromanzia": "La necromanzia è la magia della morte: uccide capi e soldati da lontano e risveglia i caduti.",
	}
	var t := "%s\n\n" % intro[r]
	t += "[table=2]"
	for s in Dati.INCANTESIMI:
		var inc: Dictionary = Dati.INCANTESIMI[s]
		if inc["ramo"] != r:
			continue
		var l: Array = LEZIONI[s]
		var costo := "gratis" if inc["costo"] == 0 else "%d sequin%s" % [inc["costo"], " per unità" if s in ["fedelta", "uccidi_unita", "illusioni"] else ""]
		t += "[cell]%s  [/cell][cell]%s\n[color=#%s]Fase: %s  -  Bersaglio: %s  -  Costo: %s[/color]\n%s\n[i]%s[/i]\n[/cell]" % [_carta(s), _t(inc["nome"]), BRUNO, l[0], l[1], costo, l[2], l[3]]
	t += "[/table]"
	return t

static func _cap_alleanze() -> String:
	return """%s
Con tre o più giocatori ogni anno si apre con la fase delle alleanze. Spunta i re con cui vuoi allearti: l'alleanza nasce solo se anche l'altro firma con te, e dura fino alla fine dell'anno.

%s
Gli alleati non si bloccano a vicenda e, nella stessa provincia, combattono come una sola forza. Ma attenzione: l'anno dopo il tuo alleato può diventare il tuo nemico più vicino...

%s
Nella stessa fase puoi versare sequin a un altro re: per comprare un patto, pagare un tributo o riscattare il tuo Re catturato.

%s
Un mago della mente può lanciare [i]Discordia[/i] per impedire un'alleanza fra due nemici, oppure [i]Armonia[/i] per imporla.

%s
Chi si avvicina alla soglia di vittoria diventa il bersaglio di tutti: in molte partite gli altri re si alleano contro il primo in classifica.""" % [_t("I patti"), _t("Cosa dà un'alleanza"), _t("Doni e riscatti"), _t("La magia della mente"), _t("La regola del più forte")]

static func _cap_comandi() -> String:
	return """%s
[indent][b]In alto[/b]: gli scudi dei re, con la barra delle tasse e il tesoro. Il nome in oro indica chi deve ancora decidere.
[b]Sotto la barra[/b]: la fascia delle fasi dell'anno.
[b]A destra[/b]: il pannello delle decisioni. In fondo ci sono sempre il pulsante verde per confermare e il [b]Consiglio[/b] del Saggio.
[b]A sinistra[/b]: la scheda della provincia sotto il mouse, con le pedine che contiene.
[b]In basso a sinistra[/b]: la cronaca di tutto ciò che accade; si può nascondere.[/indent]

%s
Quando non sai cosa fare, premi [b]Consiglio[/b]: il Saggio ti propone una mossa e ti spiega perché. Nel reclutamento riempie l'ordine, nel movimento traccia i percorsi; puoi seguirli o modificarli prima di confermare.

%s
[indent]Tasto destro e trascina: ruota la vista.
Tasto sinistro o centrale e trascina: sposta la mappa.
Rotellina o due dita: avvicina e allontana.
W A S D o frecce: sposta. Q ed E: ruota.
Clic su una provincia: la sceglie o ne mostra la scheda.[/indent]

%s
Nella stessa partita possono giocare persone e IA. Se più persone giocano sullo stesso dispositivo, prima di ogni decisione segreta lo schermo si copre e chiede di passarlo al giocatore giusto.
Dal menu in alto puoi salvare la partita sul dispositivo o nel cloud (Firebase) e riprenderla più tardi. Con [b]Gioca online[/b] crei una stanza e la condividi con un codice: ognuno gioca dal suo dispositivo.""" % [_t("Lo schermo"), _t("Il Consiglio del Saggio"), _t("La telecamera"), _t("Persone, IA e salvataggi")]

static func _cap_consigli() -> String:
	return """%s Province vicine fra loro si difendono a vicenda e permettono di spostare le truppe in fretta. Cerca un buon equilibrio tra tasse alte e popoli forti da reclutare.

%s Tattica sposta le battaglie a tuo favore, Marcia rende il Re veloce, un ramo di magia lo fa incantatore. Una scelta solida per cominciare: due Tattiche e un ramo di magia.

%s Ogni eroe è un esercito in più che può muoversi. Senza capi le truppe restano ferme.

%s Gli indigeni non si muovono mai: prendili a 2-1 o meglio, e ogni provincia conquistata ripaga l'esercito con le sue tasse.

%s Non mandare il Re da solo dove possono arrivare nemici: un Re catturato è un disastro.

%s Prima di reclutare guarda il mantenimento futuro. Un esercito che non puoi pagare l'anno dopo è denaro buttato.

%s Ricorda che anche gli altri si muovono nello stesso momento: una provincia che lasci vuota può essere presa mentre tu attacchi altrove. L'opzione "blocca i nemici" ferma chi entra dove ti trovi.

%s Chi è vicino alla soglia deve aspettarsi attacchi da tutti. Spesso conviene restare secondi fino all'ultimo anno.""" % [_t("Scegli province vicine."), _t("Il Re."), _t("Assolda presto un eroe."), _t("Mangia gli indigeni."), _t("Proteggi il Re."), _t("Fai i conti."), _t("Pensa simultaneo."), _t("Non correre troppo.")]

# ---------------------------------------------------------------- partita guidata

static func intro() -> Array:
	return [
		"Benvenuto, giovane re! Io sono il [b]Saggio[/b] e ti accompagnerò nei primi anni di regno. Questa è [b]Castafon[/b], terra di barbari, elfi, nani, orchi... e magia.",
		"Tu sei il re [b]Bianco[/b]. Il tuo rivale è [b]Re Baxx[/b], il re Rosso, guidato dal computer. Vince chi, all'inizio di un anno, controlla province che rendono almeno [b]120 sequin[/b] di tasse.",
		"Puoi trascinare la mappa con il mouse, ruotarla con il tasto destro e avvicinarti con la rotellina. Passando sopra una provincia, a sinistra compare la sua scheda.\nIn alto a destra, [b]Mappa a rilievo[/b] e [b]3D[/b] cambiano l'aspetto del tavolo quando vuoi.",
	]

static func guida(fase: String, anno: int) -> Array:
	if anno <= 1:
		match fase:
			"province":
				return ["Prima di tutto si scelgono le province di partenza: [b]tre a testa[/b], a turno. Il numero su ogni provincia sono le [b]tasse[/b] che rende ogni anno.",
					"Conta anche il [b]popolo[/b]: le truppe si reclutano solo nelle province del loro popolo. Nani ed elfi sono forti ma costosi, gli orchi deboli ma a buon mercato. Le province libere sono in giallo."]
			"re":
				return ["Ora il tuo [b]Re[/b]. Clicca una delle tue province (in verde) per porvelo, poi scegli tre abilità nei menu: puoi ripeterle.",
					"[i]Tattica[/i] sposta di una colonna le battaglie a tuo favore. [i]Marcia[/i] aggiunge movimento. [i]Ritirata[/i] decide le ritirate. Un [i]ramo di magia[/i] fa del Re un incantatore.\nPer cominciare ti propongo due Tattiche e la Magia della mente. Poi premi [b]Conferma il Re[/b]."]
			"tornado":
				return ["Fase dei tornado: un incantatore degli elementi potrebbe cancellare le tasse di una provincia nemica. Se non hai magia degli elementi, premi semplicemente [b]Conferma[/b]."]
			"finanze":
				return ["Comincia il [b]primo anno[/b]! Nelle finanze hai riscosso le tasse delle tue province. Ora si paga il [b]mantenimento[/b]: ogni unità costa qualcosa ogni anno.",
					"Puoi spuntare le unità da congedare per risparmiare. Il tuo Re non costa nulla, quindi per ora premi [b]Paga il mantenimento[/b]."]
			"acquisti":
				return ["È il momento di [b]reclutare[/b]. Clicca una tua provincia in verde: a destra compaiono le unità del suo popolo, con forza, movimento, costo e mantenimento.",
					"Premi [b]Recluta[/b] per aggiungerle all'ordine. Ricorda: le truppe si muovono [b]solo con un capo[/b]. Un [b]Eroe[/b] (si assolda ovunque) è un secondo capo che guida un altro esercito.",
					"Tieni d'occhio la riga del tesoro: il [i]mantenimento futuro[/i] non deve superare le tasse. Se vuoi, premi [b]Consiglio[/b] e riempirò io l'ordine; poi premi [b]Recluta e paga[/b]."]
			"magia1":
				return ["Prima fase magica: necromanti e maghi della mente possono uccidere capi, distruggere unità o comprare la fedeltà degli indigeni. Ogni incantesimo riesce tirando un dado pari o inferiore al valore dell'incantatore (2 all'inizio).",
					"Se non vuoi rischiare i sequin, premi [b]Conferma[/b] senza lanciare nulla."]
			"chiaro":
				return ["La [b]chiaroveggenza[/b] permette a un mago della mente di spiare il piano di movimento di un avversario prima di scrivere il tuo. Vale la pena provarci: non costa nulla!"]
			"piano":
				return ["Il [b]piano di movimento[/b] è il cuore del gioco. Tutti scrivono gli ordini in segreto, poi gli eserciti si muovono insieme, un punto movimento alla volta.",
					"Scegli un capo nell'elenco, spunta le unità che porta con sé, poi clicca le province del percorso: quelle raggiungibili sono in [b]giallo[/b]. Una freccia mostra il cammino.",
					"Il gruppo ha il movimento dell'unità più lenta; montagne, foreste e paludi costano 2. Nel primo anno conviene prendere [b]province libere vicine[/b]. Contro gli indigeni porta una forza almeno doppia.",
					"Non lasciare il Re da solo dove possono arrivare nemici: verrebbe catturato! Premi [b]Consiglio[/b] per vedere un piano pronto, modificalo se vuoi e poi [b]Conferma gli ordini[/b]."]
			"rivela":
				return ["Un mago illusionista può svelare unità illusorie e forze invisibili in una provincia. Se non ne hai, premi [b]Conferma[/b]."]
			"battaglia":
				return ["[b]Battaglia![/b] Qui si incontrano forze nemiche. Si divide la forza maggiore per la minore, arrotondando per difetto: 7 contro 3 fa [b]2-1[/b]. Ogni Tattica sposta di una colonna.",
					"Poi si tira un dado sulla tabella: [i]e[/i] annientato, [i]me[/i] perde metà, [i]r[/i] si ritira. A 3-1 o più rischi molto poco. Spunta chi vuoi attaccare e premi [b]All'attacco![/b]"]
			"magia3":
				return ["Terza fase magica: dove si è combattuto, un necromante può risvegliare i caduti come [b]zombi[/b] al suo servizio. Con un 6 però il rito fallisce. Se non hai necromanti, premi [b]Conferma[/b]."]
	else:
		match fase:
			"finanze":
				return ["Anno %d. Nuove tasse in cassa! Paga il mantenimento, oppure congeda le unità che non ti servono più." % anno]
			"acquisti":
				return ["Rinforzi: hai più tasse di prima? Allora puoi permetterti un altro capo o truppe migliori. Controlla sempre il mantenimento futuro."]
			"piano":
				return ["Nuovo piano di movimento. Guarda la scheda delle province vicine: dove gli indigeni sono deboli, attacca; dove arriva Re Baxx, lascia un presidio con [i]blocca i nemici[/i]."]
			"battaglia":
				return ["Un'altra battaglia: confronta le forze nel pannello e decidi se attaccare. Ricorda che gli indigeni attaccano comunque alla fine."]
	return []

# ---------------------------------------------------------------- scuola di magia

static func intro_magia() -> Array:
	return [
		"Benvenuto alla [b]Scuola di magia[/b]! In questa partita il tuo Re sarà un incantatore: conoscerà tre rami di magia e io ti spiegherò ogni incantesimo nel momento in cui potrai lanciarlo.",
		"La regola fondamentale: per lanciare si tira un dado e l'incantesimo riesce se il risultato è [b]pari o inferiore al valore magico[/b]. All'inizio il valore è 2, quindi riesci con 1 o 2: [b]una volta su tre[/b]. Con un 1 il valore sale, con un 6 scende.",
		"Il costo in sequin si paga [b]solo se l'incantesimo riesce[/b]: tentare è gratis! Ogni ramo si usa una volta all'anno. Le carte degli incantesimi compaiono nel pannello a destra: clicca quella che vuoi lanciare.",
	]

static func guida_magia(fase: String, anno: int) -> Array:
	if anno == 0:
		match fase:
			"province":
				return ["Scegli prima le tue tre province, come in una partita normale. Il pulsante [b]Consiglio[/b] ti suggerisce sempre una buona scelta."]
			"re":
				return ["Ecco il momento più importante per un mago: le [b]abilità del Re[/b]. Ho già preparato tre carte: [b]Magia della mente[/b], [b]Magia degli elementi[/b] e [b]Necromanzia[/b].",
					"La [b]mente[/b] spia, compra e confonde; gli [b]elementi[/b] scatenano tempeste e tornado; la [b]necromanzia[/b] uccide da lontano e risveglia i morti. L'illusione la impareremo nel libro.",
					"Le altre carte sono le abilità militari: [i]Marcia[/i] (+1 movimento), [i]Ritirata[/i] (decide le ritirate), [i]Tattica[/i] (sposta la colonna in battaglia). Clicca una carta scelta per toglierla, una disponibile per aggiungerla. Poi [b]Conferma il Re[/b]."]
	match fase:
		"tornado":
			return ["[b]Tornado[/b], magia degli elementi. Scegli una provincia nemica: se riesce, quest'anno [b]non renderà tasse[/b] a nessuno. È gratis, quindi conviene quasi sempre tentarlo sulla provincia più ricca di Re Baxx.",
				"Clicca la carta [b]Tornado[/b] e poi la provincia sulla mappa. Se il dado fa 1 o 2 vedrai il vortice alzarsi sulla provincia."]
		"acquisti":
			return ["Con la magia illusoria si potrebbero comprare [b]unità illusorie[/b] a 1 sequin l'una. Il tuo Re non la conosce, ma un [b]Mago[/b] sì: si assolda in qualsiasi tua provincia, scegliendo il ramo nel menu accanto alla carta.",
				"Un secondo incantatore raddoppia le tue possibilità: due tentativi all'anno invece di uno. Ma costa 10 sequin e 4 di mantenimento: pensaci!"]
		"magia1":
			return ["[b]Prima fase magica[/b]. Qui agiscono necromanzia e mente:\n- [i]Uccidi mago o eroe[/i] (8 sequin): elimina un capo nemico.\n- [i]Uccidi unità[/i] (5 sequin per unità): distrugge truppe in una provincia.\n- [i]Fedeltà[/i] (5 sequin per unità): gli indigeni di una provincia passano con te.",
				"Ricorda: paghi solo se riesce. [i]Fedeltà[/i] è perfetta nei primi anni: una provincia ricca difesa da indigeni diventa tua senza combattere. Clicca la carta, poi [b]Scegli sulla mappa[/b] e clicca la provincia."]
		"chiaro":
			return ["[b]Chiaroveggenza[/b], magia della mente, gratuita. Se riesce, quando scriverai il piano di movimento vedrai le [b]frecce dei piani di Re Baxx[/b]: saprai dove attaccherà e dove resterà sguarnito."]
		"piano":
			return ["Mentre scrivi il piano puoi lanciare gli incantesimi della [b]seconda fase magica[/b], che agiscono durante il movimento:\n- [i]Controllo mentale[/i] (mente): un eroe nemico segue il percorso che tracci tu.\n- [i]Mari in tempesta[/i] e [i]Tempesta sui monti[/i] (elementi): due mari o due montagne vicini diventano invalicabili per i nemici.\n- [i]Mare gelato[/i] e [i]Alluvione[/i] (elementi).",
				"Una buona combinazione: una [i]Tempesta sui monti[/i] davanti all'esercito nemico mentre il tuo attacca dall'altra parte. Trovi le carte in fondo al pannello, sotto gli ordini."]
		"rivela":
			return ["[b]Rivela illusioni[/b]: un illusionista può scoprire unità illusorie e forze invisibili in una provincia. Se non ne hai, premi [b]Conferma[/b]."]
		"magia3":
			return ["[b]Terza fase magica[/b]: dove si è combattuto, il necromante può tentare il [b]Risveglio dei morti[/b]. Se riesce, tutti i caduti tornano come zombi al tuo servizio; ma con un 6 il rito si ritorce contro di te e perdi unità.",
				"Il necromante deve trovarsi nella provincia della battaglia. Spunta la casella e conferma: è il rito più spettacolare del gioco!"]
		"alleanze":
			return ["Con tre o più re, la mente lancia [i]Discordia[/i] e [i]Armonia[/i] sulle alleanze. Qui siamo in due, quindi non serve."]
	return []

static func evento_magia(ok: bool, dado: int, nome: String) -> String:
	var t := "%s: il dado fa [b]%d[/b]. " % [nome, dado]
	t += "[b]Riuscito![/b] " if ok else "[b]Fallito.[/b] "
	if dado == 1:
		t += "E con un 1 il valore magico [b]sale di uno[/b]: d'ora in poi riuscirai più spesso."
	elif dado == 6:
		t += "Con un 6 il valore magico [b]scende di uno[/b] (mai sotto 1)."
	elif ok:
		t += "Il costo, se c'era, è stato pagato ora."
	else:
		t += "Non hai speso nulla: riprova l'anno prossimo."
	return t

static func evento(t: String) -> String:
	match t:
		"blocco":
			return "Un esercito è stato [b]bloccato[/b]: è entrato dove c'erano unità nemiche (o indigeni) e ha dovuto fermarsi. Ora lì si combatterà."
		"cattura":
			return "Un Re è stato [b]catturato[/b]! Era rimasto senza unità amiche dove c'erano nemici. Potrà tornare libero se i carcerieri se ne vanno, o con un riscatto."
		"controllo":
			return "Una provincia ha cambiato [b]padrone[/b]: la bandierina mostra il nuovo controllo. Le sue tasse andranno a lui dall'anno prossimo."
		"incantesimo":
			return "Qualcuno ha lanciato un [b]incantesimo[/b]! Guarda la cronaca in basso: dice chi l'ha lanciato, con quale dado e con quale esito."
		"morte":
			return "Un'unità è [b]caduta[/b]. Le unità eliminate tornano nella riserva: chiunque potrà reclutarle di nuovo."
		"ritirata":
			return "Lo sconfitto si [b]ritira[/b] in una provincia vicina. Chi ha più abilità di Ritirata sceglie dove."
	return ""

static func fine() -> String:
	return "Hai regnato per tre anni: ora conosci tutte le fasi del gioco! Puoi continuare questa partita contro Re Baxx fino alla vittoria (il pulsante [b]Consiglio[/b] resta sempre a disposizione) oppure tornare al menu e iniziare una partita vera, anche con altri re o online."
