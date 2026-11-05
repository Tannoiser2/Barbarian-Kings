# Barbarian Kings: le illustrazioni delle carte da creare con ChatGPT

Il gioco usa **35 carte illustrate**: 16 incantesimi, 7 abilità e 12 azioni. Le carte compaiono:

- nel pannello a destra, al posto dei pulsanti, quando scegli incantesimi e abilità;
- al centro dello schermo, quando un incantesimo o un'azione si risolve sulla mappa;
- in testa al pannello di alcune fasi (alleanze, finanze, reclute, piano, battaglia);
- nel libro "Come si gioca".

Finché un'immagine manca, il gioco mostra uno stemma provvisorio (occhio, fulmine, luna, teschio...),
quindi le immagini si possono aggiungere anche poche alla volta.

## Come generarle

1. In ChatGPT apri una nuova chat e incolla prima il **blocco di stile** qui sotto, scrivendo:
   *"Userai questo stile per una serie di 35 illustrazioni. Rispondi solo 'Pronto'."*
2. Poi, una alla volta, incolla il **testo** di ogni carta. Chiedi il formato **verticale 2:3**
   (1024 x 1536). Se ChatGPT propone un formato diverso, scrivi: *"formato verticale 1024x1536"*.
3. Se un'immagine contiene scritte, lettere o una cornice, chiedi: *"Rifalla senza testo, senza lettere e senza cornice"*.
   Il titolo e la cornice li aggiunge il gioco.
4. Scarica ogni immagine e rinominala **esattamente** come indicato (per esempio `tornado.png`).
5. Mettile nella cartella `assets/img/carte/` del repository (vanno bene `.png`, `.jpg` o `.webp`)
   e pubblica con un commit che contiene `[pubblica]`. Oppure mandamele qui e le preparo io
   (ridimensionamento a 512 x 768 e conversione in WebP, per non appesantire la versione web).

Consiglio: genera prima 3 o 4 carte di prova (per esempio `tornado`, `resurrezione`, `tattica`,
`battaglia`) e controlla che lo stile ti piaccia prima di fare le altre.

## Blocco di stile (da incollare per primo)

```
Style for the whole series: hand-painted fantasy illustration in the manner of 1980s fantasy
wargame box art and paperback covers: gouache and oil textures, rich saturated colours, dramatic
chiaroscuro lighting, strong silhouettes, epic but readable composition with one clear focal subject
in the centre and a darker, simpler background toward the edges. The world is Castafon, a barbaric
fantasy continent of steppes, mountains, elven forests, swamps and stormy seas, where barbarian
kings, dwarves, elves, orcs, feudal knights, airships and war-frogs fight. Vertical 2:3 format
(1024x1536). Absolutely no text, no letters, no numbers, no logos, no frame, no border, no
watermark. Each image must also read well when shown small, about 80 pixels wide.
```

## Gli incantesimi (16)

Il colore dominante segue il ramo di magia: **blu-viola** per la mente, **azzurro e grigio tempesta**
per gli elementi, **rosa-violetto iridescente** per l'illusione, **verde acido su nero** per la necromanzia.

### Magia della mente

| File | Carta | Testo per ChatGPT |
|---|---|---|
| `discordia.png` | Discordia | Two barbarian kings in a torn war tent reaching to shake hands, but a jagged crack of violet-blue psychic light splits the map table between them, their faces turning to suspicion and anger, a hooded mind-mage half hidden in the shadows with glowing blue eyes. |
| `armonia.png` | Armonia | Two rival barbarian kings in fur and bronze clasping forearms over a campaign map, a warm golden-blue halo binding their wrists like a ribbon of light, a serene mind-mage behind them with raised palms, banners of two colours intertwined. |
| `fedelta.png` | Fedeltà | A tribe of wild native warriors (orcs and barbarians with spears) kneeling and lowering their weapons before a robed mage, glowing blue-violet threads of light running from the mage's fingers to their foreheads, a small pile of gold coins at the mage's feet. |
| `chiaroveggenza.png` | Chiaroveggenza | An old mage gazing into a floating crystal orb in a dark tower room; inside the orb a tiny painted map with marching armies and arrows; a huge translucent blue eye glowing in the air above the orb. |
| `controllo.png` | Controllo mentale | An armoured enemy hero with blank glowing violet eyes marching like a puppet, thin shining strings of blue-violet light rising from his helmet and limbs up into the hands of a distant sorcerer silhouetted on a hill. |

### Magia degli elementi

| File | Carta | Testo per ChatGPT |
|---|---|---|
| `tornado.png` | Tornado | A colossal dust-brown tornado tearing through a fantasy village and wheat fields, roofs, sheaves and gold coins swirling up into the funnel, tiny peasants fleeing, a storm-mage on a nearby rock with arms raised and lightning crackling between his fingers. |
| `tempesta_mari.png` | Mari in tempesta | A furious storm at sea: towering black waves, lightning splitting a dark green-grey sky, a fleet of barbarian longships with striped sails tossed and unable to advance, cold blue light on the crests. |
| `tempesta_monti.png` | Tempesta sui monti | A blizzard and thunderstorm howling over jagged snowy mountain passes, an army column of soldiers and cavalry halted and huddled against the wind, avalanches sliding, blue-white lightning on the peaks. |
| `gelo.png` | Mare gelato | A sea frozen solid under a pale winter sky, cracked turquoise ice with a ship trapped in it, an army marching across the ice in single file, frost mist rising, an elemental mage breathing frost from his staff. |
| `alluvione.png` | Alluvione | A river bursting its banks and flooding a green valley, brown water rushing around farmhouses and a stranded army camp, soldiers on rooftops, rain slanting, an elemental mage on a hill commanding the waters. |

### Magia illusoria

| File | Carta | Testo per ChatGPT |
|---|---|---|
| `illusioni.png` | Unità illusorie | A great army of soldiers and cavalry on a plain at dusk, but the back ranks are translucent and shimmering like mirage, made of pink-violet light and mist; a smiling illusionist in a mask conducts them with a wand. |
| `invisibilita.png` | Invisibilità | A column of soldiers led by a hero dissolving into thin air as they march through a forest path, their bodies fading into iridescent violet sparkles from the feet up, only footprints remain in the mud. |
| `rivela.png` | Rivela illusioni | A burst of bright white-violet light from a raised crystal staff tearing away a veil of mist, revealing that half of an enemy army is only painted shadows and empty armour, and exposing hidden soldiers behind. |

### Necromanzia

| File | Carta | Testo per ChatGPT |
|---|---|---|
| `uccidi_capo.png` | Uccidi mago o eroe | A necromancer in black robes pointing a bony finger from a ruined tower; far away a bolt of sickly green lightning strikes down an enemy hero on horseback; a ghostly skull shape in the clouds. |
| `uccidi_unita.png` | Uccidi unità | A cloud of black-green deathly mist rolling over a camp of enemy soldiers, spears falling from their hands as they collapse, green wisps rising from them toward a necromancer's raised skull-topped staff. |
| `resurrezione.png` | Risveglio dei morti | A night battlefield after a battle, a necromancer standing among broken banners and fallen soldiers, glowing green fog on the ground, skeletal and zombie warriors of many armies clawing their way up from the earth with their old weapons. |

## Le abilità (7)

Queste carte si vedono soprattutto piccole, quando scegli le abilità del Re: soggetti semplici e ben leggibili.

| File | Carta | Testo per ChatGPT |
|---|---|---|
| `marcia.png` | Marcia | A barbarian king on horseback leading an army at forced march along a mountain road at dawn, dust trails, banners streaming in the wind, a strong sense of speed and forward motion, warm golden light. |
| `ritirata.png` | Ritirata | A disciplined rearguard of shield-bearers holding a narrow bridge while the rest of the army retreats in order behind them through the mist, their commander signalling with a raised sword, cool silver-blue tones. |
| `tattica.png` | Tattica | A battle-scarred warlord leaning over a sand table with carved wooden army pieces and a dagger marking the enemy flank, candlelight, war banners, red and orange tones, a determined and cunning expression. |
| `mente.png` | Magia della mente | A wise mage meditating with a third eye glowing blue-violet on his forehead, translucent thoughts and faces swirling around his head like smoke, dark starry background. |
| `elementi.png` | Magia degli elementi | An elemental mage on a cliff with arms spread, a vortex of wind, fire, water and lightning spiralling around him above a stormy sea, cyan and storm-grey palette. |
| `illusione.png` | Magia illusoria | A masked illusionist in a jester-like cloak juggling glowing mirror-images of himself, a hall of shimmering reflections, iridescent pink and violet palette, a crescent moon behind. |
| `necromanzia.png` | Necromanzia | A gaunt necromancer holding a skull-topped staff in a crypt, green spectral fire in the eye sockets of the skulls lining the walls, black and acid-green palette. |

## Le azioni (12)

| File | Carta | Dove compare | Testo per ChatGPT |
|---|---|---|---|
| `battaglia.png` | Battaglia | ogni battaglia, pannello del combattimento | A chaotic clash of two fantasy armies on a plain: barbarian infantry, elven archers, orc wolf-riders and knights, clouds of dust, banners of different colours, a king fighting in the centre, dramatic sunset sky. |
| `blocco.png` | Blocco | quando un esercito viene fermato | A marching army stopped in its tracks by a wall of locked shields and levelled spears across a mountain pass, the enemy commander raising a fist to halt, tension before the clash. |
| `fuga.png` | Ritirata | quando lo sconfitto ripiega | A defeated army retreating across a river at twilight, wounded soldiers helped by comrades, a torn banner dragged in the mud, the victorious enemy watching from the ridge. |
| `cattura.png` | Re catturato | quando un Re cade prigioniero | A proud barbarian king in chains, forced to kneel before an enemy war tent, his crown on the ground, enemy guards with torches around him, dark red tones. |
| `liberazione.png` | Re liberato | quando un Re torna libero | A barbarian king breaking free, chains shattering, his loyal warriors storming the prison camp at dawn, golden light bursting through the smoke. |
| `alleanza.png` | Alleanza | fase delle alleanze | Two kings signing a treaty on a parchment with a dagger and wax seal in a torch-lit hall, their banners crossed above them, their generals watching warily. |
| `tributo.png` | Tributo | doni e riscatti | A herald on one knee offering an open chest of gold coins and jewels to a seated barbarian king on a fur-covered throne, envoys and guards around. |
| `tasse.png` | Tasse | fase delle finanze | Tax collectors with ledgers and scales in a busy village square, peasants bringing sacks of grain and pouches of coins, a royal banner, a heavy chest filling with gold. |
| `reclutamento.png` | Reclutamento | fase delle reclute | A recruiting camp at the edge of a fantasy town: dwarves, elves, orcs and human volunteers lining up before an officer's table, a sergeant handing out spears and shields, a mercenary hero and a robed mage waiting their turn. |
| `piano.png` | Piano di guerra | piano di movimento | A war council at night in a tent, a king and his heroes leaning over a large painted map of a fantasy continent covered with wooden army markers and arrows drawn in ink, candlelight. |
| `vittoria.png` | La Pace del Re | fine della partita | A triumphant barbarian king crowned on a hilltop at sunrise, his banner planted, armies of many peoples kneeling below in a vast valley, peace returning to a war-torn land. |
| `fallito.png` | Incantesimo fallito | quando la magia non riesce | A mage stumbling backwards as his spell backfires, sparks fizzling, smoke puffing from his staff, a scorched circle on the ground, half-comic, half-dramatic. |

## Controllo finale

- 35 file in `assets/img/carte/`, con i nomi esattamente come nelle tabelle (minuscolo, con il trattino basso).
- Formato verticale 2:3, senza scritte né cornici.
- Per vedere le carte nel gioco: Menu > Come si gioca > i capitoli delle scuole di magia e delle abilità,
  oppure una partita della **Scuola di magia**.
