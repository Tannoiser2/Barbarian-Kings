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
		{"titolo": "La magia", "testo": _cap_magia()},
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
Ogni punto di [i]Tattica[/i] dei capi presenti sposta la colonna di uno a proprio favore. Due eroi tattici possono trasformare un 1-1 in un 3-1!

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

static func _cap_magia() -> String:
	var t := """%s
Ogni incantatore (un Mago, o un Re con un ramo di magia) ha valore [b]2[/b] in ogni ramo che conosce. Per lanciare si tira un dado: l'incantesimo riesce con un risultato pari o inferiore al valore. Un [b]1[/b] alza il valore (fino a 5), un [b]6[/b] lo abbassa (fino a 1). Ogni ramo si usa una volta per anno; il costo in sequin si paga solo se riesce.

%s
Nelle fasi in cui puoi lanciare, il pannello mostra un menu per ogni incantatore: scegli l'incantesimo e il bersaglio (spesso cliccando una provincia).
""" % [_t("Come funziona"), _t("Lanciare un incantesimo")]
	var rami := {"mente": [], "elementi": [], "illusione": [], "necromanzia": []}
	for s in Dati.INCANTESIMI:
		rami[Dati.INCANTESIMI[s]["ramo"]].append(s)
	for r in rami:
		t += "\n" + _t(Dati.NOMI_ABILITA[r]) + "\n"
		for s in rami[r]:
			var inc: Dictionary = Dati.INCANTESIMI[s]
			t += "[indent][i]%s[/i]%s: %s[/indent]\n" % [inc["nome"], " (costo %d)" % inc["costo"] if inc["costo"] > 0 else "", Dati.DESCR_INCANTESIMI[s]]
	t += "\n[i]Il regolamento consigliava di lasciare da parte la magia illusoria nelle prime partite.[/i]"
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
