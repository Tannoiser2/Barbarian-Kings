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
- **Mappa moderna in rilievo** (predefinita): dipinta con ChatGPT sulla geometria originale, con le montagne estruse
  in 3D, migliaia di alberi 3D nelle foreste, canneti nelle paludi, mare che luccica e nomi delle province scritti
  sul terreno. Dal menu si torna alla mappa originale SPI.
- **Tavolo 3D** con la mappa originale ad alta risoluzione su un tavolo di legno; telecamera libera (mouse, tastiera,
  dita); province evidenziabili e cliccabili; stendardi dei proprietari.
- **Miniature 3D**: Re, Eroe, Mago, Nano, Barbaro, Legionario, Arciere elfico, Orco e Fante feudale creati con Meshy,
  con scheletro e animazioni (camminata, corsa, attacco, morte, incantesimo); flotte, cavallerie, warg, rane, balene
  e aeronavi dai modelli 3D del modulo TTS.
- **Effetti speciali**: battaglie con scintille e lampi, tornado, tempeste con fulmini, mare gelato, alluvioni,
  maledizioni necromantiche, risveglio dei morti, monete delle tasse.
- **Avversari IA**, partita a più persone sullo stesso dispositivo (passandoselo, con le scelte segrete coperte),
  **partita online** con codice stanza e **salvataggi** locali o su Firebase.
- Interfaccia in italiano con i caratteri IM Fell, il logo e il giallo della tabella delle fasi della mappa originale.

## Struttura

- `scripts/motore.gd` regole (deterministiche: seme + decisioni), `scripts/ia.gd` giocatori artificiali,
  `scripts/plancia3d.gd` tavolo 3D e animazioni, `scripts/main.gd` interfaccia, `scripts/rete.gd` Firebase.
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
