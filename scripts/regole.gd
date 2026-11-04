## Riassunto delle regole in italiano (dal regolamento SPI del 1980, Ares n. 3).
class_name Regole
extends RefCounted

static func testo() -> String:
	var t := """[b]L'Età Rossa di Castafon[/b]
Da 2 a 5 re barbari si contendono il continente di Castafon, sul pianeta Hypastia, dove la magia funziona (a volte). Con la forza, l'inganno e gli incantesimi bisogna controllare province che rendano abbastanza tasse: [b]120[/b] con due giocatori, [b]100[/b] con tre, [b]90[/b] con quattro o cinque. La vittoria si controlla all'inizio di ogni anno.

[b]Inizio[/b]
A turno ogni giocatore sceglie le sue province (3 a testa in due, 2 in tre o quattro, 1 in cinque). Poi pone il suo Re in una di esse e gli assegna in segreto fino a tre abilità, anche ripetute: Marcia, Ritirata, Tattica, oppure uno dei quattro rami della magia. Ognuno parte con 50 sequin. Nelle province libere con tasse 6 o più compare una fanteria indigena neutrale.

[b]Sequenza di un anno[/b]
1. [i]Alleanze[/i] (con tre o più giocatori): chi firma reciprocamente è alleato per tutto l'anno; gli alleati non si bloccano e combattono come una sola forza. Si possono versare sequin. Gli incantesimi Discordia e Armonia possono impedire o imporre un'alleanza.
2. [i]Tornado[/i]: un incantatore degli elementi può impedire le tasse di una provincia.
3. [i]Finanze[/i]: si riscuotono le tasse delle province controllate, si paga il mantenimento (le unità non pagate sono congedate), poi si recluta in ordine di precedenza. Le truppe si reclutano solo nelle province del loro popolo che controlli; eroi e maghi ovunque.
4. [i]Prima fase magica[/i]: uccidere maghi ed eroi, distruggere unità, conquistare gli indigeni.
5. [i]Piano di movimento[/i]: tutti scrivono in segreto i percorsi; la Chiaroveggenza permette di spiare un avversario.
6. [i]Seconda fase magica[/i]: tempeste, gelo, alluvioni, controllo mentale, invisibilità.
7. [i]Movimento[/i]: tutti si muovono insieme, un punto movimento alla volta. Chi entra dove ci sono nemici può essere bloccato; gli indigeni bloccano sempre.
8. [i]Combattimento[/i] e [i]terza fase magica[/i] (risveglio dei morti).

[b]Capi, unità e movimento[/b]
Le unità si muovono solo guidate da un capo (Re o Eroe) che le accompagna. Il gruppo ha il movimento dell'unità più lenta; la Marcia del capo aggiunge 1 per ogni volta che è stata scelta. Entrare in pianura o mare costa 1, in montagna, foresta e palude 2 (1 per nani in montagna, elfi in foresta, rane in palude). Le flotte vanno per mare e nelle province costiere e trasportano un'unità di terra ciascuna; le aeronavi volano ovunque ma non possono fermarsi in mare o in montagna; le rane attraversano un solo mare; le balene restano in mare. Chi viaggia per mare non si muove anche per terra nello stesso anno. Non si passa direttamente da una provincia occupata da nemici a un'altra provincia nemica.
Un capo o un mago che resta senza unità amiche dove ci sono nemici: il Re viene catturato (lo si può liberare o riscattare), eroi e maghi muoiono.
Si controlla una provincia se vi si trova, o vi è passato per ultimo, con unità militari, oppure se la si possiede dall'inizio e nessuno l'ha mai presa.

[b]Combattimento[/b]
Dove si incontrano forze nemiche, in ordine di precedenza ognuno sceglie chi attaccare. Il rapporto si calcola dal lato più forte, arrotondando a favore del più debole, da 1-1 a 6-1. Ogni Tattica sposta di una colonna a favore di chi la possiede. Il terreno conta: in montagna i nani valgono doppio e la cavalleria la metà; in foresta gli elfi doppio e cavalleria e legioni la metà; in palude le rane doppio e tutti gli altri la metà.
Risultati: [i]e[/i] forza annientata, [i]1/2 e[/i] perde unità per almeno metà della forza, [i]r[/i] ritirata. L = la forza più grande, S = la più piccola. Una Ritirata superiore decide dove si ritira lo sconfitto; due di vantaggio permettono di ignorare la ritirata.
Alla fine gli indigeni attaccano chi non li ha combattuti.

[b]Magia[/b]
Ogni incantatore ha valore 2 in ogni ramo che conosce. Per lanciare si tira un dado: riesce con un risultato pari o inferiore al valore. Un 1 alza il valore (fino a 5), un 6 lo abbassa (fino a 1). Ogni ramo si usa una volta per anno; il costo in sequin si paga solo se riesce.
"""
	var rami := {"mente": [], "elementi": [], "illusione": [], "necromanzia": []}
	for s in Dati.INCANTESIMI:
		rami[Dati.INCANTESIMI[s]["ramo"]].append(s)
	for r in rami:
		t += "\n[b]%s[/b]\n" % Dati.NOMI_ABILITA[r]
		for s in rami[r]:
			t += "[i]%s[/i]: %s\n" % [Dati.INCANTESIMI[s]["nome"], Dati.DESCR_INCANTESIMI[s]]
	t += """
[b]Note su questa versione[/b]
Il modulo TTS è la versione "revised, scripted" del gioco originale: qui il computer tiene la contabilità (tasse, mantenimento, reclutamento) che in origine si faceva con carta e matita. Un Re catturato resta dove è stato preso, sorvegliato da chi l'ha catturato: torna libero se i suoi carcerieri se ne vanno o vengono distrutti, oppure se lo liberano nella fase delle finanze. Il regolamento consigliava di evitare la magia illusoria nelle prime partite.

[b]Comandi[/b]
Tasto destro e trascina: ruota la vista. Tasto centrale, oppure sinistro e trascina: sposta la mappa. Rotellina o due dita: zoom. Tasti W A S D o frecce per spostarsi, Q ed E per ruotare. Clic su una provincia: informazioni o scelta.
"""
	return t
