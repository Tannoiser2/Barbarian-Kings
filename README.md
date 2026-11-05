# Barbarian Kings - versione digitale

Versione digitale per uso personale di **Barbarian Kings** (Greg Costikyan, SPI 1980, uscito come gioco
staccabile su *Ares* n. 3): da 2 a 5 re barbari si contendono il continente di Castafon con eserciti,
alleanze di un anno e magia.

Si gioca nel browser: https://tannoiser2.github.io/Barbarian-Kings/

## Cosa c'è

- **Regole complete** del regolamento originale (sezioni 1-11): scelta delle province, Re con tre abilità segrete,
  alleanze e tributi, tornado, finanze (tasse, mantenimento, reclutamento per popolo), le tre fasi magiche con tutti
  i 16 incantesimi delle quattro scuole, piani di movimento segreti eseguiti punto movimento per punto movimento
  con blocchi, trasporto navale, aeronavi, rane e balene, cattura dei Re, combattimento con la tabella dei risultati,
  terreni, Tattica e Ritirata, indigeni neutrali, vittoria a 120/100/90 di tasse.
- **Partita guidata con il Saggio**: una vera partita contro Re Baxx in cui un vecchio mago spiega ogni fase dei
  primi tre anni, suggerisce le scelte e commenta la prima battaglia, il primo blocco, la prima cattura.
- **Libro "Come si gioca"** in dodici capitoli illustrati con le pedine originali: scopo, mappa, pedine, anno di
  gioco, denaro, movimento, combattimento con la tabella dei risultati, magia, alleanze, comandi, consigli.
- **Scuola di magia**: una partita guidata in cui il Re conosce mente, elementi e necromanzia; il Saggio spiega
  ogni incantesimo quando si può lanciare, con valori e probabilità, e commenta ogni tiro di dado.
- **Carte illustrate** per incantesimi, abilità e azioni (scelta a carte nel pannello, carta in sovrimpressione
  durante la regia). Le illustrazioni si creano con ChatGPT seguendo `docs/immagini_chatgpt.md` e vanno in
  `assets/img/carte/` (verticali) e `assets/img/carte_o/` (orizzontali, per pulsanti lunghi, testate e carta in
  sovrimpressione); finché mancano si vedono stemmi provvisori.
- **Effetti volumetrici** (`scripts/volume.gdshader`): vortici, nubi, nebbie e colonne di luce per magie,
  tornado, tempeste, gelo, alluvioni, maledizioni, risvegli, catture e battaglie.
- **Consiglio del Saggio** in ogni fase: l'IA propone la mossa e la spiega; nel reclutamento riempie l'ordine e nel
  movimento traccia i percorsi, che si possono ritoccare prima di confermare.
- **Pedine originali** sulla mappa SPI (predefinita), in pile per proprietario. Il tasto **3D** le trasforma in
  miniature animate; il tasto **Mappa a rilievo** passa alla mappa moderna dipinta con ChatGPT sulla geometria
  originale, con le montagne estruse in 3D, migliaia di alberi nelle foreste, canneti nelle paludi e mare che luccica.
- **Tavolo 3D** con la mappa originale ad alta risoluzione su un tavolo di legno; telecamera libera (mouse, tastiera,
  dita); province evidenziabili e cliccabili; stendardi dei proprietari.
- **Miniature 3D**: Re, Eroe, Mago, Nano, Barbaro, Legionario, Arciere elfico, Orco e Fante feudale creati con Meshy,
  con scheletro e animazioni (camminata, corsa, attacco, morte, incantesimo); balena da guerra, aeronave, rana da
  guerra e nave a vele (usata, con tinte diverse, per le flotte barbara, elfica e pirata) creati con Meshy;
  galea, cavallerie e warg dai modelli 3D del modulo TTS.
- **Effetti speciali**: battaglie con scintille e lampi, tornado, tempeste con fulmini, mare gelato, alluvioni,
  maledizioni necromantiche, risveglio dei morti, monete delle tasse.
- **Avversari IA**, partita a più persone sullo stesso dispositivo (passandoselo, con le scelte segrete coperte),
  **partita online** con codice stanza e **salvataggi** locali o su Firebase.
- Interfaccia fantasy in italiano: pergamene, pulsanti di cuoio con bordo d'oro, scudi dei re, fascia delle fasi
  dell'anno, scheda della provincia con le pedine, cronaca comprimibile; caratteri Pirata One, Almendra e IM Fell.

## Struttura

- `scripts/motore.gd` regole (deterministiche: seme + decisioni), `scripts/ia.gd` giocatori artificiali,
  `scripts/plancia3d.gd` tavolo 3D e animazioni, `scripts/main.gd` interfaccia, `scripts/tutorial.gd` libro e partita guidata,
  `scripts/rete.gd` Firebase. `assets/ui/` grafica dell'interfaccia (generata da `tools/grafica_ui.py`).
- `assets/dati/gioco.json` province (tasse, popoli, terreni, adiacenze, posizione sulla mappa) e pedine.
- `assets/img/province_id.png` mappa delle province per il clic e l'evidenziazione.
- `tools/` script usati per estrarre i dati dal modulo TTS, preparare i modelli e controllare i glifi.
- `firebase/database.rules.json` regole del database per la radice `barbariankings`.

## Prove

```
godot --headless --path . -s tests/sim.gd -- 6 4 60          # partite IA complete
xvfb-run godot --path . -s tests/ui_auto.gd -- /tmp/ui 2      # foto dei pannelli
python3 tests/firebase_mock.py 8765 & ...  tests/online_auto.gd # due istanze online sul finto Firebase
python3 tools/controlla_glifi.py                              # nessun carattere mancante nei font
```

## Pubblicazione

Solo su richiesta: Actions -> Pubblica -> Run workflow, oppure un commit con `[pubblica]` nel messaggio.
Con i segreti `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID` il gioco va anche sulla ludoteca privata
(https://barbariankings.ludoteca-digitale.com).
