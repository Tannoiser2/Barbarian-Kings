## Barbarian Kings, versione digitale: menu, partita locale (IA e passa-il-dispositivo), partita online
## su Firebase, salvataggi. Il tavolo 3D è in plancia3d.gd, le regole in motore.gd, l'IA in ia.gd.
extends Node

const CARTA := Color(0.95, 0.91, 0.80)
const CARTA_SCURA := Color(0.88, 0.82, 0.68)
const INCHIOSTRO := Color(0.20, 0.12, 0.06)
const BORDO := Color(0.38, 0.24, 0.12)
const GIALLO := Color(0.96, 0.83, 0.26)
const MARE := Color(0.42, 0.66, 0.78)

var tema: Theme
var font_testo: Font
var font_titolo: Font
var font_corsivo: Font
var plancia: Plancia3D
var ui: CanvasLayer
var radice_ui: Control
var m: Motore
var cfg: Dictionary = {}
var registro_dec: Array = []     # decisioni applicate: [{p, d}]
var ev_letti := 0
var umani_locali: Array = []     # posti giocati da persone su questo dispositivo
var online := false
var codice := ""
var mio_posto := -1
var host := false
var rete: Rete
var _in_corso := false
var _attendo_rete := false
var posto_stanza := -1
var _chiave_pannello := ""

# interfaccia di gioco
var barra: HBoxContainer
var etichetta_fase: Label
var box_giocatori: HBoxContainer
var pannello: PanelContainer
var contenuto: VBoxContainer
var info: PanelContainer
var info_testo: RichTextLabel
var diario: RichTextLabel
var diario_box: PanelContainer
var copertura: Control
var giocatore_ui := -1
var click_mode: Callable = Callable()
var _prov_info := 0

# stato dei pannelli
var st: Dictionary = {}

func _ready() -> void:
	Dati.carica()
	randomize()
	font_testo = load("res://assets/font/Fell.ttf")
	font_titolo = load("res://assets/font/FellMaiuscoletto.ttf")
	font_corsivo = load("res://assets/font/FellCorsivo.ttf")
	_crea_tema()
	plancia = Plancia3D.new()
	add_child(plancia)
	plancia.vista_iniziale()
	plancia.provincia_cliccata.connect(_su_click_provincia)
	plancia.provincia_sopra.connect(_su_sopra_provincia)
	plancia.regia_finita.connect(_dopo_regia)
	ui = CanvasLayer.new()
	add_child(ui)
	radice_ui = Control.new()
	radice_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice_ui.theme = tema
	ui.add_child(radice_ui)
	rete = Rete.new()
	add_child(rete)
	_menu()

# ---------------------------------------------------------------- tema grafico (carta, inchiostro, giallo della mappa)

func _stile(bg: Color, bordo: Color, larg := 2, raggio := 4, marg := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bordo
	s.set_border_width_all(larg)
	s.set_corner_radius_all(raggio)
	s.content_margin_left = marg
	s.content_margin_right = marg
	s.content_margin_top = marg * 0.6
	s.content_margin_bottom = marg * 0.6
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 3
	return s

func _crea_tema() -> void:
	tema = Theme.new()
	tema.default_font = font_testo
	tema.default_font_size = 18
	tema.set_stylebox("panel", "PanelContainer", _stile(Color(CARTA, 0.96), BORDO, 2, 6, 12))
	tema.set_stylebox("panel", "Panel", _stile(Color(CARTA, 0.96), BORDO, 2, 6, 12))
	tema.set_color("font_color", "Label", INCHIOSTRO)
	tema.set_color("font_color", "CheckBox", INCHIOSTRO)
	tema.set_color("font_hover_color", "CheckBox", BORDO)
	tema.set_color("font_pressed_color", "CheckBox", INCHIOSTRO)
	tema.set_color("font_hover_pressed_color", "CheckBox", INCHIOSTRO)
	tema.set_color("default_color", "RichTextLabel", INCHIOSTRO)
	tema.set_font("normal_font", "RichTextLabel", font_testo)
	tema.set_font("bold_font", "RichTextLabel", font_titolo)
	tema.set_font("italics_font", "RichTextLabel", font_corsivo)
	tema.set_font_size("normal_font_size", "RichTextLabel", 17)
	tema.set_font_size("bold_font_size", "RichTextLabel", 18)
	tema.set_font_size("italics_font_size", "RichTextLabel", 17)
	var bn := _stile(GIALLO, BORDO, 2, 5, 10)
	var bh := _stile(GIALLO.lightened(0.25), BORDO, 2, 5, 10)
	var bp := _stile(GIALLO.darkened(0.15), BORDO, 2, 5, 10)
	var bd := _stile(CARTA_SCURA, Color(BORDO, 0.4), 2, 5, 10)
	for t in ["Button", "OptionButton"]:
		tema.set_stylebox("normal", t, bn)
		tema.set_stylebox("hover", t, bh)
		tema.set_stylebox("pressed", t, bp)
		tema.set_stylebox("disabled", t, bd)
		tema.set_stylebox("focus", t, StyleBoxEmpty.new())
		tema.set_color("font_color", t, INCHIOSTRO)
		tema.set_color("font_hover_color", t, INCHIOSTRO)
		tema.set_color("font_pressed_color", t, INCHIOSTRO)
		tema.set_color("font_focus_color", t, INCHIOSTRO)
		tema.set_color("font_disabled_color", t, Color(INCHIOSTRO, 0.45))
		tema.set_font("font", t, font_titolo)
		tema.set_font_size("font_size", t, 18)
	for st_nome in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		tema.set_stylebox(st_nome, "CheckBox", StyleBoxEmpty.new())
	tema.set_font("font", "CheckBox", font_testo)
	tema.set_font_size("font_size", "CheckBox", 17)
	tema.set_stylebox("normal", "LineEdit", _stile(Color(1, 0.98, 0.92), BORDO, 1, 3, 6))
	tema.set_stylebox("focus", "LineEdit", _stile(Color(1, 0.98, 0.92), GIALLO.darkened(0.3), 2, 3, 6))
	tema.set_color("font_color", "LineEdit", INCHIOSTRO)
	tema.set_stylebox("normal", "SpinBox", _stile(Color(1, 0.98, 0.92), BORDO, 1, 3, 4))
	tema.set_stylebox("panel", "PopupMenu", _stile(CARTA, BORDO, 2, 4, 6))
	tema.set_color("font_color", "PopupMenu", INCHIOSTRO)
	tema.set_color("font_hover_color", "PopupMenu", BORDO)
	tema.set_stylebox("hover", "PopupMenu", _stile(GIALLO.lightened(0.2), Color(0, 0, 0, 0), 0, 2, 4))
	tema.set_stylebox("panel", "TooltipPanel", _stile(CARTA, BORDO, 1, 3, 6))
	tema.set_color("font_color", "TooltipLabel", INCHIOSTRO)
	tema.set_stylebox("background", "ProgressBar", _stile(CARTA_SCURA, BORDO, 1, 3, 2))
	tema.set_stylebox("fill", "ProgressBar", _stile(GIALLO, BORDO, 1, 3, 2))
	tema.set_stylebox("panel", "ItemList", _stile(Color(1, 0.98, 0.92), BORDO, 1, 3, 4))
	tema.set_color("font_color", "ItemList", INCHIOSTRO)
	tema.set_color("font_selected_color", "ItemList", INCHIOSTRO)
	tema.set_stylebox("selected", "ItemList", _stile(GIALLO, BORDO, 1, 2, 2))
	tema.set_stylebox("selected_focus", "ItemList", _stile(GIALLO, BORDO, 1, 2, 2))

func _pulisci_ui() -> void:
	for c in radice_ui.get_children():
		c.queue_free()
	click_mode = Callable()

func _etichetta(t: String, dim := 18, titolo := false, col := INCHIOSTRO) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font_titolo if titolo else font_testo)
	l.add_theme_font_size_override("font_size", dim)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _bottone(t: String, f: Callable, dim := 18) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", dim)
	b.pressed.connect(f)
	return b

func _rtl(testo: String, dim := 17) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_size_override("normal_font_size", dim)
	r.text = testo
	return r

func _hex(c: Color) -> String:
	return c.to_html(false)

func _nome_g(p: int) -> String:
	if p < 0:
		return "Indigeni"
	return m.g[p]["nome"]

func _nome_colore(p: int) -> String:
	if p < 0:
		return "[color=#%s]Indigeni[/color]" % _hex(Dati.COLORE_NEUTRALE.darkened(0.3))
	var c: Color = Dati.COLORI_RGB[p]
	if p == 0:
		c = Color(0.55, 0.5, 0.42)
	return "[color=#%s][b]%s[/b][/color]" % [_hex(c.darkened(0.2)), m.g[p]["nome"]]

# ---------------------------------------------------------------- menu

func _schermo_centrale(larg := 560) -> VBoxContainer:
	_pulisci_ui()
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.03, 0.02, 0.45)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice_ui.add_child(fondo)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice_ui.add_child(cc)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(larg, 0)
	cc.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	return v

func _logo(v: VBoxContainer, h := 150) -> void:
	var tr := TextureRect.new()
	tr.texture = load("res://assets/img/logo.png")
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(0, h)
	v.add_child(tr)

func _menu() -> void:
	var v := _schermo_centrale(520)
	_logo(v)
	var s := _etichetta("Imperi fantasy in conflitto - SPI, 1980", 20, false, BORDO)
	s.add_theme_font_override("font", font_corsivo)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	v.add_child(_bottone("Nuova partita", _impostazioni_locali, 22))
	v.add_child(_bottone("Gioca online con gli amici", _menu_online, 22))
	v.add_child(_bottone("Riprendi la partita salvata", _carica_locale, 22))
	v.add_child(_bottone("Riprendi dal cloud (Firebase)", _carica_cloud, 22))
	v.add_child(_bottone("Regole del gioco", _mostra_regole, 22))
	var n := _etichetta("Versione digitale per uso personale. Mappa e pedine dal modulo TTS; miniature 3D create con Meshy.", 14, false, Color(INCHIOSTRO, 0.7))
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)

func _impostazioni_locali() -> void:
	var v := _schermo_centrale(600)
	v.add_child(_etichetta("Nuova partita", 28, true))
	v.add_child(_etichetta("Da 2 a 5 re barbari. Ogni posto può essere giocato da una persona (passandosi il dispositivo) o dall'IA.", 17))
	var righe := VBoxContainer.new()
	v.add_child(righe)
	var nomi := ["Bianco", "Rosso", "Giallo", "Verde", "Blu"]
	var posti := []
	for i in 5:
		var h := HBoxContainer.new()
		var chip := ColorRect.new()
		chip.color = Dati.COLORI_RGB[i]
		chip.custom_minimum_size = Vector2(22, 22)
		h.add_child(chip)
		var ne := LineEdit.new()
		ne.text = "Stefano" if i == 0 else nomi[i]
		ne.custom_minimum_size = Vector2(220, 0)
		h.add_child(ne)
		var ob := OptionButton.new()
		ob.add_item("Persona")
		ob.add_item("IA")
		ob.add_item("Assente")
		ob.selected = 0 if i == 0 else (1 if i < 4 else 2)
		h.add_child(ob)
		righe.add_child(h)
		posti.append([ne, ob])
	var err := _etichetta("", 16, false, Color(0.6, 0.1, 0.05))
	v.add_child(err)
	var h2 := HBoxContainer.new()
	h2.add_child(_bottone("Indietro", _menu))
	h2.add_child(_bottone("Comincia", func():
		var gioc := []
		var umani := []
		for i in 5:
			var t: int = posti[i][1].selected
			if t == 2:
				continue
			var nome: String = posti[i][0].text.strip_edges()
			if nome == "":
				nome = nomi[i]
			if t == 0:
				umani.append(gioc.size())
			gioc.append({"nome": nome.substr(0, 20), "ia": t == 1})
		if gioc.size() < 2:
			err.text = "Servono almeno due giocatori."
			return
		online = false
		umani_locali = umani
		_inizia({"giocatori": gioc, "seme": randi() % 1000000000}, [])))
	v.add_child(h2)

func _mostra_regole() -> void:
	var v := _schermo_centrale(860)
	v.add_child(_etichetta("Regole di Barbarian Kings", 28, true))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(820, 560)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.custom_minimum_size = Vector2(800, 0)
	r.text = Regole.testo()
	sc.add_child(r)
	v.add_child(_bottone("Chiudi", (func(): _menu()) if m == null else _chiudi_sovrapposto))

func _chiudi_sovrapposto() -> void:
	_costruisci_gioco()
	_aggiorna_tutto()

# ---------------------------------------------------------------- partita

func _inizia(c: Dictionary, decisioni: Array) -> void:
	cfg = c
	m = Motore.new()
	m.avvia(cfg)
	registro_dec = []
	# rigioca le decisioni salvate senza animazioni
	for x in decisioni:
		var p := int(x["p"])
		m.invia(p, x["d"])
		registro_dec.append(x)
	ev_letti = m.eventi.size()
	plancia.velocita = float(cfg.get("velocita", 1.0))
	plancia.spettatore = umani_locali[0] if umani_locali.size() > 0 else (mio_posto if online else -1)
	plancia.collega(m)
	plancia.vista_iniziale()
	_costruisci_gioco()
	_aggiorna_tutto()
	_passo()

func _costruisci_gioco() -> void:
	_pulisci_ui()
	# barra in alto
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 54
	radice_ui.add_child(top)
	barra = HBoxContainer.new()
	barra.add_theme_constant_override("separation", 14)
	top.add_child(barra)
	var lg := TextureRect.new()
	lg.texture = load("res://assets/img/logo.png")
	lg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lg.custom_minimum_size = Vector2(70, 40)
	barra.add_child(lg)
	etichetta_fase = _etichetta("", 20, true)
	etichetta_fase.autowrap_mode = TextServer.AUTOWRAP_OFF
	barra.add_child(etichetta_fase)
	box_giocatori = HBoxContainer.new()
	box_giocatori.add_theme_constant_override("separation", 10)
	box_giocatori.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(box_giocatori)
	var mb := MenuButton.new()
	mb.text = "Menu"
	mb.add_theme_font_override("font", font_titolo)
	mb.add_theme_color_override("font_color", INCHIOSTRO)
	mb.add_theme_stylebox_override("normal", _stile(GIALLO, BORDO, 2, 5, 10))
	mb.add_theme_stylebox_override("hover", _stile(GIALLO.lightened(0.2), BORDO, 2, 5, 10))
	var pm := mb.get_popup()
	pm.add_item("Velocità animazioni: normale", 1)
	pm.add_item("Velocità animazioni: doppia", 2)
	pm.add_item("Velocità animazioni: quadrupla", 4)
	pm.add_separator()
	pm.add_check_item("Colora le province per proprietario", 10)
	pm.add_item("Riporta la telecamera alla vista iniziale", 11)
	pm.add_item("Mostra o nascondi il diario", 12)
	pm.add_separator()
	pm.add_item("Salva la partita", 20)
	pm.add_item("Salva nel cloud (Firebase)", 21)
	pm.add_item("Regole", 22)
	pm.add_item("Torna al menu principale", 23)
	pm.id_pressed.connect(_voce_menu.bind(pm))
	barra.add_child(mb)
	# pannello delle decisioni a destra
	pannello = PanelContainer.new()
	pannello.anchor_left = 1.0
	pannello.anchor_right = 1.0
	pannello.anchor_top = 0.0
	pannello.anchor_bottom = 1.0
	pannello.offset_left = -420
	pannello.offset_right = -8
	pannello.offset_top = 62
	pannello.offset_bottom = -8
	radice_ui.add_child(pannello)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pannello.add_child(sc)
	contenuto = VBoxContainer.new()
	contenuto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenuto.add_theme_constant_override("separation", 8)
	sc.add_child(contenuto)
	# informazioni sulla provincia a sinistra
	info = PanelContainer.new()
	info.position = Vector2(8, 62)
	info.custom_minimum_size = Vector2(330, 0)
	info.visible = false
	radice_ui.add_child(info)
	info_testo = RichTextLabel.new()
	info_testo.bbcode_enabled = true
	info_testo.fit_content = true
	info_testo.custom_minimum_size = Vector2(320, 0)
	info.add_child(info_testo)
	# diario in basso a sinistra
	diario_box = PanelContainer.new()
	diario_box.anchor_top = 1.0
	diario_box.anchor_bottom = 1.0
	diario_box.offset_left = 8
	diario_box.offset_right = 520
	diario_box.offset_top = -190
	diario_box.offset_bottom = -8
	diario_box.add_theme_stylebox_override("panel", _stile(Color(CARTA, 0.88), BORDO, 2, 6, 8))
	radice_ui.add_child(diario_box)
	diario = RichTextLabel.new()
	diario.bbcode_enabled = true
	diario.scroll_following = true
	diario.add_theme_font_size_override("normal_font_size", 15)
	diario_box.add_child(diario)
	_riempi_diario()

func _voce_menu(id: int, pm: PopupMenu) -> void:
	match id:
		1, 2, 4:
			plancia.velocita = float(id)
			cfg["velocita"] = float(id)
		10:
			var i := pm.get_item_index(10)
			pm.set_item_checked(i, not pm.is_item_checked(i))
			plancia.tinta_controllo(pm.is_item_checked(i))
		11:
			plancia.vista_iniziale()
		12:
			diario_box.visible = not diario_box.visible
		20:
			_salva_locale()
		21:
			_salva_cloud()
		22:
			_mostra_regole()
		23:
			m = null
			online = false
			_menu()

func _riempi_diario() -> void:
	if m == null or diario == null:
		return
	var righe := m.registro.slice(maxi(0, m.registro.size() - 160))
	var t := ""
	for r in righe:
		if r.begins_with("---"):
			t += "\n[b]" + r + "[/b]\n"
		else:
			t += r + "\n"
	diario.text = t

func _aggiorna_tutto() -> void:
	if m == null or etichetta_fase == null:
		return
	etichetta_fase.text = ("Anno %d - " % m.turno if m.turno > 0 else "") + m.descr_fase()
	for c in box_giocatori.get_children():
		c.queue_free()
	for p in m.n:
		var h := HBoxContainer.new()
		var chip := ColorRect.new()
		chip.color = Dati.COLORI_RGB[p]
		chip.custom_minimum_size = Vector2(16, 16)
		h.add_child(chip)
		var t := m.tasse_di(p)
		var att := "  ..." if p in m.attese else ""
		var l := _etichetta("%s  %d/%d  %d seq.%s" % [m.g[p]["nome"], t, m.soglia, m.g[p]["tesoro"], att], 16)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.tooltip_text = "Tasse controllate %d su %d per vincere; tesoro %d sequin" % [t, m.soglia, m.g[p]["tesoro"]]
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(l)
		box_giocatori.add_child(h)
	_riempi_diario()
	if _prov_info > 0:
		_mostra_info(_prov_info)

# ---------------------------------------------------------------- ciclo di gioco

## Manda alla plancia gli eventi nuovi; quando la regia ha finito, decide chi deve agire.
func _passo() -> void:
	if m == null:
		return
	if ev_letti < m.eventi.size():
		var nuovi := m.eventi.slice(ev_letti)
		ev_letti = m.eventi.size()
		plancia.accoda(nuovi)
		_aggiorna_tutto()
		return
	if plancia.occupata() or (online and _in_corso):
		return
	_aggiorna_tutto()
	if m.finita:
		_vittoria()
		return
	# l'IA decide (in locale, oppure sull'host nella partita online)
	for p in m.attese:
		if m.g[p]["ia"] and (not online or host):
			var d := IA.decidi(m, p)
			_applica(p, d)
			return
	# una persona su questo dispositivo
	var umano := _prossimo_umano()
	if umano >= 0:
		_chiedi(umano)
		return
	_mostra_attesa()

func _dopo_regia() -> void:
	call_deferred("_passo")

func _prossimo_umano() -> int:
	var cand := []
	for p in m.attese:
		if online:
			if p == mio_posto and not _in_corso:
				cand.append(p)
		elif p in umani_locali:
			cand.append(p)
	if cand.is_empty():
		return -1
	# con la chiaroveggenza conviene far decidere prima chi viene spiato
	if m.fase == "piano":
		for p in cand:
			if not m.chiaro.has(p) or not (m.chiaro[p] in m.attese):
				return p
	return cand[0]

func _applica(p: int, d: Dictionary) -> void:
	if online:
		_invia_online(p, d)
		return
	var err := m.invia(p, d)
	if err != "":
		_avviso(err)
		_passo()
		return
	registro_dec.append({"p": p, "d": d})
	_passo()

func _avviso(t: String) -> void:
	var l := _etichetta(t, 17, false, Color(0.65, 0.08, 0.04))
	if contenuto != null:
		contenuto.add_child(l)
		contenuto.move_child(l, 0)

func _mostra_attesa() -> void:
	_chiave_pannello = ""
	_svuota_pannello()
	var chi := ", ".join(m.attese.map(func(p): return m.g[p]["nome"]))
	contenuto.add_child(_etichetta(m.descr_fase(), 22, true))
	contenuto.add_child(_etichetta("In attesa di: " + chi, 17))
	plancia.evidenzia({})
	plancia.disegna_percorsi([])

func _svuota_pannello() -> void:
	for c in contenuto.get_children():
		c.queue_free()
	click_mode = Callable()

## Prima di una decisione segreta, se a questo dispositivo giocano più persone, si copre lo schermo.
func _chiedi(p: int) -> void:
	var chiave := "%d|%s|%d|%d|%d" % [m.turno, m.fase, p, registro_dec.size(), m.batt_k]
	if chiave == _chiave_pannello and copertura == null:
		return
	_chiave_pannello = chiave
	var segreta := m.fase != "battaglia" and m.fase != "province"
	if not online and umani_locali.size() > 1 and segreta and giocatore_ui != p:
		_copri(p)
		return
	giocatore_ui = p
	if plancia.spettatore != p:
		plancia.spettatore = p
		plancia.sincronizza()
	_pannello_fase(p)

func _copri(p: int) -> void:
	_svuota_pannello()
	plancia.evidenzia({})
	plancia.disegna_percorsi([])
	copertura = ColorRect.new()
	(copertura as ColorRect).color = Color(0.08, 0.05, 0.03, 0.97)
	copertura.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice_ui.add_child(copertura)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	copertura.add_child(cc)
	var pc := PanelContainer.new()
	cc.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(_etichetta("Passa il dispositivo a", 22, true))
	var l := _etichetta(m.g[p]["nome"], 36, true, Dati.COLORI_RGB[p].darkened(0.3))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	v.add_child(_etichetta(m.descr_fase() + ": le tue scelte restano segrete.", 17))
	v.add_child(_bottone("Sono %s, continua" % m.g[p]["nome"], func():
		copertura.queue_free()
		copertura = null
		giocatore_ui = p
		_chiave_pannello = "%d|%s|%d|%d|%d" % [m.turno, m.fase, p, registro_dec.size(), m.batt_k]
		plancia.spettatore = p
		plancia.sincronizza()
		_pannello_fase(p)))

func _vittoria() -> void:
	_svuota_pannello()
	var p := m.vincitore
	contenuto.add_child(_etichetta("La Pace del Re", 26, true))
	contenuto.add_child(_rtl("%s controlla province per %d sequin di tasse e mette fine all'Età Rossa di Castafon dopo %d anni." % [_nome_colore(p), m.tasse_di(p), m.turno - 1]))
	for q in m.n:
		contenuto.add_child(_rtl("%s: tasse %d, tesoro %d" % [_nome_colore(q), m.tasse_di(q), m.g[q]["tesoro"]]))
	contenuto.add_child(_bottone("Nuova partita", _impostazioni_locali))
	contenuto.add_child(_bottone("Menu principale", func(): m = null; _menu()))
	if p >= 0:
		plancia.inquadra(m.u[m.g[p]["re"]]["prov"] if m.u[m.g[p]["re"]]["prov"] > 0 else 26, 10.0)

# ---------------------------------------------------------------- mappa: click e informazioni

func _su_click_provincia(q: int) -> void:
	if click_mode.is_valid():
		click_mode.call(q)
	else:
		_mostra_info(q)

func _su_sopra_provincia(q: int) -> void:
	if q > 0 and m != null and info != null:
		_mostra_info(q)

func _mostra_info(q: int) -> void:
	if m == null or info == null or q <= 0:
		return
	_prov_info = q
	var pr: Dictionary = Dati.province[q]
	var t := "[b]%s[/b]\n" % Dati.nome_prov(q)
	t += "Tasse [b]%d[/b]   %s" % [pr["tasse"], Dati.TERRENI[pr["terreno"]]]
	if pr["nativi"] != "":
		t += "   popolo: %s" % Dati.NATIVI[pr["nativi"]]
	t += "\nControllo: %s" % (_nome_colore(m.ctrl[q]) if m.ctrl[q] >= 0 else "nessuno")
	if q in m.tornado:
		t += "\n[i]Un tornado devasta la provincia.[/i]"
	if q in m.tempesta_mari or q in m.tempesta_monti:
		t += "\n[i]Tempesta.[/i]"
	if q in m.gelo:
		t += "\n[i]Il mare è gelato.[/i]"
	if q in m.alluvione:
		t += "\n[i]Alluvione.[/i]"
	var spett := plancia.spettatore
	var per_own := {}
	for id in m.unita_in(q):
		if not m.visibile_a(id, spett):
			continue
		var o: int = m.u[id]["own"]
		if not per_own.has(o):
			per_own[o] = []
		per_own[o].append(id)
	for o in per_own:
		var ids: Array = per_own[o]
		var forza := m.forza_effettiva(ids.filter(func(id): return Dati.is_militare(id)), q)
		t += "\n\n%s - forza %d" % [_nome_colore(o), forza]
		for id in ids:
			t += "\n  " + _descr_unita(id, o == spett)
	info_testo.text = t
	info.visible = true

func _descr_unita(id: int, mio: bool) -> String:
	var d: Dictionary = Dati.unita[id]
	var s: Dictionary = m.u[id]
	var t := Dati.nome_unita(id)
	if Dati.is_militare(id):
		t += " (F%d M%d)" % [d["forza"], d["mov"]]
	if s["zombie"]:
		t += " [i]zombi[/i]"
	if s["catt"] != -9:
		t += " [i]prigioniero[/i]"
	if mio:
		var ab := []
		for a in s["abil"]:
			ab.append(Dati.NOMI_ABILITA[a])
		for mg in s["magie"]:
			ab.append("%s %d" % [Dati.NOMI_ABILITA[mg["r"]], mg["v"]])
		if not ab.is_empty():
			t += " - " + ", ".join(ab)
		if s["illus"]:
			t += " [i](illusione)[/i]"
		if s["invis"]:
			t += " [i](invisibile)[/i]"
	return t

# ---------------------------------------------------------------- pannelli delle fasi

func _intestazione(p: int, titolo: String, spiega: String) -> void:
	_svuota_pannello()
	contenuto.add_child(_rtl("%s  -  [b]%s[/b]" % [_nome_colore(p), titolo], 19))
	if spiega != "":
		var l := _etichetta(spiega, 16)
		l.add_theme_font_override("font", font_corsivo)
		contenuto.add_child(l)

func _conferma(testo: String, f: Callable) -> void:
	var b := _bottone(testo, f, 20)
	b.custom_minimum_size = Vector2(0, 44)
	contenuto.add_child(b)

func _pannello_fase(p: int) -> void:
	st = {"p": p}
	plancia.evidenzia({})
	plancia.disegna_percorsi([])
	match m.fase:
		"province": _p_province(p)
		"re": _p_re(p)
		"alleanze": _p_alleanze(p)
		"tornado": _p_tornado(p)
		"finanze": _p_finanze(p)
		"acquisti": _p_acquisti(p)
		"magia1": _p_magia1(p)
		"chiaro": _p_chiaro(p)
		"piano": _p_piano(p)
		"rivela": _p_rivela(p)
		"battaglia": _p_battaglia(p)
		"magia3": _p_magia3(p)
		_: _mostra_attesa()

const C_LIBERA := Color(0.95, 0.85, 0.3, 0.45)
const C_SCELTA := Color(0.95, 0.25, 0.1, 0.6)
const C_MIA := Color(0.3, 0.75, 0.3, 0.4)
const C_META := Color(1.0, 0.95, 0.4, 0.5)

func _p_province(p: int) -> void:
	_intestazione(p, "Scegli una provincia", "Clicca una provincia di terra libera (in giallo). Ne sceglierai %d in tutto, a turno." % (m.da_scegliere[p] + m.controllate(p).size()))
	var libere := {}
	for q in range(18, 48):
		if m.ctrl[q] == -1:
			libere[q] = C_LIBERA
	plancia.evidenzia(libere)
	var l := _etichetta("Nessuna scelta", 18, true)
	contenuto.add_child(l)
	st["prov"] = 0
	click_mode = func(q: int):
		if not libere.has(q):
			return
		st["prov"] = q
		var pr: Dictionary = Dati.province[q]
		l.text = "%s - tasse %d, %s" % [Dati.nome_prov(q), pr["tasse"], Dati.NATIVI[pr["nativi"]]]
		plancia.evidenzia(libere, {q: C_SCELTA})
		_mostra_info(q)
	_conferma("Conferma la provincia", func():
		if st["prov"] > 0:
			_applica(p, {"prov": st["prov"]}))

func _p_re(p: int) -> void:
	var re: int = m.g[p]["re"]
	_intestazione(p, Dati.unita[re]["nome"], "Clicca una tua provincia dove porre il Re, poi scegli fino a tre abilità (anche ripetute). Restano segrete.")
	var mie := {}
	for q in m.controllate(p):
		mie[q] = C_MIA
	st["prov"] = m.controllate(p)[0]
	plancia.evidenzia(mie, {st["prov"]: C_SCELTA})
	var l := _etichetta("Il Re va in: " + Dati.nome_prov(st["prov"]), 17)
	contenuto.add_child(l)
	click_mode = func(q: int):
		if mie.has(q):
			st["prov"] = q
			l.text = "Il Re va in: " + Dati.nome_prov(q)
			plancia.evidenzia(mie, {q: C_SCELTA})
	var scelte := Dati.ABILITA_EROE + Dati.RAMI
	var obs := []
	for i in 3:
		var ob := OptionButton.new()
		for a in scelte:
			ob.add_item(Dati.NOMI_ABILITA[a])
		ob.selected = [2, 2, 3][i] if i < 3 else 0
		contenuto.add_child(ob)
		obs.append(ob)
	contenuto.add_child(_rtl("[i]Marcia[/i]: +1 al movimento del Re e delle unità che guida. [i]Ritirata[/i]: decide le ritirate. [i]Tattica[/i]: sposta di una colonna la tabella del combattimento. I quattro rami di magia danno un valore magico 2 ciascuno.", 15))
	_conferma("Conferma il Re", func():
		var ab := []
		for ob in obs:
			ab.append(scelte[ob.selected])
		_applica(p, {"prov": st["prov"], "abil": ab}))

func _p_alleanze(p: int) -> void:
	_intestazione(p, "Alleanze dell'anno", "Firma con chi vuoi allearti: l'alleanza nasce solo se anche l'altro firma con te. Gli alleati non si bloccano e combattono insieme. Puoi anche versare sequin (patti, tributi, riscatti).")
	var firme := {}
	var doni := {}
	for q in m.n:
		if q == p:
			continue
		var h := HBoxContainer.new()
		var cb := CheckBox.new()
		cb.text = "Firmo con " + m.g[q]["nome"]
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(cb)
		firme[q] = cb
		var sb := SpinBox.new()
		sb.max_value = m.g[p]["tesoro"]
		sb.suffix = "seq."
		sb.tooltip_text = "Sequin da versare a " + m.g[q]["nome"]
		h.add_child(sb)
		doni[q] = sb
		contenuto.add_child(h)
	var spell := _scelte_incantesimi(p, ["mente"], ["discordia", "armonia"], "giocatori")
	_conferma("Firma e sigilla", func():
		var f := []
		var dd := []
		for q in firme:
			if firme[q].button_pressed:
				f.append(q)
			if doni[q].value > 0:
				dd.append({"a": q, "q": int(doni[q].value)})
		_applica(p, {"firme": f, "doni": dd, "incanti": _raccogli_incantesimi(spell)}))

## Righe per lanciare incantesimi: per ogni "slot" magico del giocatore, un menu con gli incantesimi ammessi.
## modo: "giocatori" (due giocatori), "provincia", "due_province", "nemico", "unita", "neutrali", "capo", "giocatore"
func _scelte_incantesimi(p: int, rami: Array, spells: Array, _modo := "") -> Array:
	var righe := []
	var slots := []
	for r in rami:
		slots += m.slot_magia(p, r)
	if slots.is_empty():
		return righe
	contenuto.add_child(_etichetta("Incantesimi", 20, true))
	for sl in slots:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		contenuto.add_child(box)
		var ammessi := spells.filter(func(s): return Dati.INCANTESIMI[s]["ramo"] == sl["r"])
		var tit := _etichetta("%s - %s (valore %d)" % [Dati.nome_unita(sl["c"]), Dati.NOMI_ABILITA[sl["r"]], sl["v"]], 16, true)
		box.add_child(tit)
		var ob := OptionButton.new()
		ob.add_item("Nessun incantesimo")
		for s in ammessi:
			var costo: int = Dati.INCANTESIMI[s]["costo"]
			ob.add_item(Dati.INCANTESIMI[s]["nome"] + ("" if costo == 0 else " (%d seq.)" % costo))
		box.add_child(ob)
		var dett := VBoxContainer.new()
		box.add_child(dett)
		var riga := {"slot": sl, "ob": ob, "ammessi": ammessi, "dett": dett, "dati": {}}
		ob.item_selected.connect(func(i: int): _dettagli_incantesimo(p, riga))
		righe.append(riga)
	return righe

func _dettagli_incantesimo(p: int, riga: Dictionary) -> void:
	var dett: VBoxContainer = riga["dett"]
	for c in dett.get_children():
		c.queue_free()
	riga["dati"] = {}
	var i: int = riga["ob"].selected
	if i <= 0:
		return
	var s: String = riga["ammessi"][i - 1]
	var l := _etichetta(Dati.DESCR_INCANTESIMI[s], 15)
	l.add_theme_font_override("font", font_corsivo)
	dett.add_child(l)
	var dati: Dictionary = riga["dati"]
	match s:
		"discordia", "armonia":
			for k in ["a", "b"]:
				var ob := OptionButton.new()
				for q in m.n:
					ob.add_item(m.g[q]["nome"], q)
				ob.selected = 0 if k == "a" else mini(1, m.n - 1)
				dett.add_child(ob)
				dati[k] = ob
		"chiaroveggenza":
			var ob := OptionButton.new()
			for q in m.n:
				if q != p:
					ob.add_item(m.g[q]["nome"], q)
			dett.add_child(ob)
			dati["p"] = ob
		"tornado", "gelo", "alluvione", "rivela":
			_scelta_provincia(dett, dati, "prov", s)
		"tempesta_mari", "tempesta_monti":
			_scelta_provincia(dett, dati, "a", s)
			_scelta_provincia(dett, dati, "b", s)
		"uccidi_capo", "controllo":
			var ob := OptionButton.new()
			var tipi := ["eroe"] if s == "controllo" else ["eroe", "mago"]
			for id in m.u:
				var x: Dictionary = m.u[id]
				if x["own"] >= 0 and x["own"] != p and not m.alleati(x["own"], p) and Dati.unita[id]["tipo"] in tipi and m.visibile_a(id, p) and m.libero(id):
					ob.add_item("%s di %s in %s" % [Dati.nome_unita(id), m.g[x["own"]]["nome"], Dati.nome_prov(x["prov"])], id)
			if ob.item_count == 0:
				dett.add_child(_etichetta("Nessun bersaglio visibile.", 15))
			else:
				dett.add_child(ob)
				dati["t"] = ob
				if s == "controllo":
					dett.add_child(_etichetta("Dopo la conferma degli ordini, l'eroe seguirà il percorso che tracci qui sotto.", 14))
					dati["via"] = []
					var lv := _etichetta("Percorso: (nessuno)", 15)
					dett.add_child(lv)
					dett.add_child(_bottone("Traccia il percorso sulla mappa", func():
						var e: int = ob.get_item_id(ob.selected)
						dati["via"] = []
						_traccia_percorso_altrui(e, dati, lv)))
		"uccidi_unita", "fedelta":
			dati["t"] = []
			var lb := _etichetta("Clicca la provincia bersaglio.", 15)
			dett.add_child(lb)
			var b := _bottone("Scegli sulla mappa", func():
				click_mode = func(q: int):
					var ids := []
					for id in m.unita_in(q):
						if not Dati.is_militare(id) or not m.visibile_a(id, p):
							continue
						var o: int = m.u[id]["own"]
						if s == "fedelta" and o == Motore.NEUTRALE:
							ids.append(id)
						elif s == "uccidi_unita" and o >= 0 and o != p and not m.alleati(o, p):
							ids.append(id)
					var maxn: int = int(m.g[p]["tesoro"] / 5)
					ids = ids.slice(0, maxn)
					dati["t"] = ids
					lb.text = "%s: %d unità (%d sequin)" % [Dati.nome_prov(q), ids.size(), ids.size() * 5]
					plancia.evidenzia({}, {q: C_SCELTA})
					click_mode = Callable())
			dett.add_child(b)
		"invisibilita":
			var ob := OptionButton.new()
			for id in m.capi_di(p):
				if Dati.is_capo(id):
					ob.add_item("%s in %s" % [Dati.nome_unita(id), Dati.nome_prov(m.u[id]["prov"])], id)
			dett.add_child(ob)
			dati["capo"] = ob

func _scelta_provincia(dett: VBoxContainer, dati: Dictionary, k: String, s: String) -> void:
	dati[k] = 0
	var h := HBoxContainer.new()
	var l := _etichetta("(nessuna)", 15)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(_bottone("Scegli", func():
		var ok := {}
		for q in range(1, 48):
			if _bersaglio_valido(s, q):
				ok[q] = C_LIBERA
		plancia.evidenzia(ok)
		click_mode = func(q: int):
			if not ok.has(q):
				return
			dati[k] = q
			l.text = Dati.nome_prov(q)
			plancia.evidenzia({}, {q: C_SCELTA})
			click_mode = _click_base()))
	dett.add_child(h)

func _click_base() -> Callable:
	return st.get("click_base", Callable())

func _bersaglio_valido(s: String, q: int) -> bool:
	var t: String = Dati.province[q]["terreno"]
	match s:
		"tornado": return t != "mare" or Dati.province[q]["tasse"] > 0
		"gelo": return t == "mare" or t == "palude"
		"alluvione": return t != "mare"
		"tempesta_mari": return t == "mare"
		"tempesta_monti": return t == "montagna"
	return true

func _raccogli_incantesimi(righe: Array) -> Array:
	var out := []
	for r in righe:
		var i: int = r["ob"].selected
		if i <= 0:
			continue
		var s: String = r["ammessi"][i - 1]
		var x := {"c": r["slot"]["c"], "i": r["slot"]["i"], "s": s}
		var dati: Dictionary = r["dati"]
		for k in dati:
			var v = dati[k]
			if v is OptionButton:
				x[k] = (v as OptionButton).get_item_id((v as OptionButton).selected)
			else:
				x[k] = v
		if s == "controllo":
			x["eroe"] = x.get("t", 0)
		if s in ["tornado", "gelo", "alluvione", "rivela"] and int(x.get("prov", 0)) <= 0:
			continue
		if s in ["tempesta_mari", "tempesta_monti"] and (int(x.get("a", 0)) <= 0 or int(x.get("b", 0)) <= 0):
			continue
		out.append(x)
	return out

func _p_tornado(p: int) -> void:
	_intestazione(p, "Tornado", "I tuoi incantatori degli elementi possono scatenare un tornado: la provincia colpita non paga tasse quest'anno.")
	var righe := _scelte_incantesimi(p, ["elementi"], ["tornado"])
	_conferma("Conferma", func(): _applica(p, {"incanti": _raccogli_incantesimi(righe)}))

func _p_finanze(p: int) -> void:
	var tasse: int = m.tasse_turno[p] if m.tasse_turno.size() > p else 0
	_intestazione(p, "Finanze", "Hai riscosso %d sequin di tasse. Ora paghi il mantenimento: le unità che congedi tornano disponibili per tutti." % tasse)
	var cbs := {}
	var tot_l := _etichetta("", 18, true)
	var ricalcola := func():
		var mt := 0
		for id in m.u:
			if m.u[id]["own"] == p and not (cbs.has(id) and cbs[id].button_pressed):
				mt += Dati.unita[id]["mant"]
		tot_l.text = "Tesoro %d - mantenimento %d = %d" % [m.g[p]["tesoro"], mt, m.g[p]["tesoro"] - mt]
	var ids := []
	for id in m.u:
		if m.u[id]["own"] == p and Dati.unita[id]["mant"] > 0:
			ids.append(id)
	ids.sort()
	for id in ids:
		var cb := CheckBox.new()
		cb.text = "Congeda %s in %s (%d)" % [Dati.nome_unita(id), Dati.nome_prov(m.u[id]["prov"]), Dati.unita[id]["mant"]]
		cb.toggled.connect(func(_b): ricalcola.call())
		contenuto.add_child(cb)
		cbs[id] = cb
	var lib := {}
	for re in m._re_prigionieri(p):
		var cb := CheckBox.new()
		cb.text = "Libera %s" % Dati.nome_unita(re)
		contenuto.add_child(cb)
		lib[re] = cb
	contenuto.add_child(tot_l)
	ricalcola.call()
	contenuto.add_child(_etichetta("Se il tesoro non basta, le unità più costose vengono congedate da sole.", 15))
	_conferma("Paga il mantenimento", func():
		var c := []
		for id in cbs:
			if cbs[id].button_pressed:
				c.append(id)
		var l := []
		for id in lib:
			if lib[id].button_pressed:
				l.append(id)
		_applica(p, {"congeda": c, "libera": l}))

func _p_acquisti(p: int) -> void:
	_intestazione(p, "Reclutamento", "Clicca una tua provincia (in verde): vi si reclutano le truppe del suo popolo. Eroi e maghi si assoldano in qualsiasi tua provincia.")
	st["carrello"] = []
	st["prov"] = 0
	var mie := {}
	for q in m.controllate(p):
		if m.militari_in(q, Motore.NEUTRALE).is_empty():
			mie[q] = C_MIA
	plancia.evidenzia(mie)
	var soldi := _etichetta("", 19, true)
	contenuto.add_child(soldi)
	var illus_cb := CheckBox.new()
	illus_cb.text = "Unità illusorie (1 sequin l'una, serve riuscire l'incantesimo)"
	illus_cb.visible = not m.slot_magia(p, "illusione").is_empty()
	contenuto.add_child(illus_cb)
	var negozio := VBoxContainer.new()
	contenuto.add_child(negozio)
	var carrello := VBoxContainer.new()
	contenuto.add_child(_etichetta("Ordine di reclutamento", 18, true))
	contenuto.add_child(carrello)
	var spesa := func() -> int:
		var t := 0
		for c in st["carrello"]:
			t += 1 if c.get("illus", false) else Dati.unita[c["id"]]["costo"]
		return t
	st["agg"] = func():
		for c in carrello.get_children():
			c.queue_free()
		var mant := m.mantenimento(p)
		for c in st["carrello"]:
			mant += Dati.unita[c["id"]]["mant"]
			var h := HBoxContainer.new()
			var t := "%s in %s%s" % [Dati.nome_tipo(c["id"]), Dati.nome_prov(c["p"]), " (illusoria)" if c.get("illus", false) else ""]
			var l := _etichetta(t, 15)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(l)
			h.add_child(_bottone("Togli", func():
				st["carrello"].erase(c)
				st["agg"].call()
				if st["prov"] > 0:
					st["riempi"].call(st["prov"]), 14))
			carrello.add_child(h)
		soldi.text = "Tesoro %d - spesa %d = %d   (mantenimento futuro %d, tasse %d)" % [m.g[p]["tesoro"], spesa.call(), m.g[p]["tesoro"] - spesa.call(), mant, m.tasse_di(p)]
	st["riempi"] = func(q: int):
		for c in negozio.get_children():
			c.queue_free()
		negozio.add_child(_etichetta(Dati.nome_prov(q), 18, true))
		var nat: String = Dati.province[q]["nativi"]
		var nel := {}
		for c in st["carrello"]:
			nel[c["id"]] = true
		var tipi := []
		for tipo in Dati.tipi:
			if tipo == "re":
				continue
			var id0 := 0
			for id in m.disponibili(tipo):
				if not nel.has(id):
					id0 = id
					break
			var dd: Dictionary = Dati.unita[id0] if id0 > 0 else {}
			if id0 > 0 and Dati.is_militare(id0) and dd["origine"] != nat:
				continue
			if id0 == 0:
				continue
			tipi.append([tipo, id0])
		if tipi.is_empty():
			negozio.add_child(_etichetta("Qui non si recluta nessuno.", 15))
		for tp in tipi:
			var id0: int = tp[1]
			var dd: Dictionary = Dati.unita[id0]
			var h := HBoxContainer.new()
			var ic := TextureRect.new()
			var nome_ic := "%03d" % id0
			ic.texture = load("res://assets/img/pedine/%s.png" % nome_ic) if ResourceLoader.exists("res://assets/img/pedine/%s.png" % nome_ic) else null
			ic.custom_minimum_size = Vector2(40, 40)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			h.add_child(ic)
			var desc := "%s\ncosto %d, mant. %d" % [Dati.nome_tipo(id0), dd["costo"], dd["mant"]]
			if Dati.is_militare(id0):
				desc += ", forza %d, mov. %d" % [dd["forza"], dd["mov"]]
			var l := _etichetta(desc, 15)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(l)
			var ab_ob: OptionButton = null
			if dd["tipo"] in ["eroe", "mago"]:
				ab_ob = OptionButton.new()
				var lista: Array = Dati.ABILITA_EROE if dd["tipo"] == "eroe" else Dati.RAMI
				for a in lista:
					ab_ob.add_item(Dati.NOMI_ABILITA[a])
				ab_ob.add_theme_font_size_override("font_size", 14)
				h.add_child(ab_ob)
			h.add_child(_bottone("Recluta", func():
				var il := illus_cb.button_pressed
				var costo: int = 1 if il else dd["costo"]
				if spesa.call() + costo > m.g[p]["tesoro"]:
					return
				var c := {"id": id0, "p": q, "illus": il}
				if ab_ob != null:
					var lista2: Array = Dati.ABILITA_EROE if dd["tipo"] == "eroe" else Dati.RAMI
					c["abil"] = [lista2[ab_ob.selected]]
				st["carrello"].append(c)
				st["agg"].call()
				st["riempi"].call(q), 15))
			negozio.add_child(h)
	click_mode = func(q: int):
		if not mie.has(q):
			_mostra_info(q)
			return
		st["prov"] = q
		plancia.evidenzia(mie, {q: C_SCELTA})
		st["riempi"].call(q)
	st["agg"].call()
	if not mie.is_empty():
		var re: int = m.g[p]["re"]
		var q0: int = m.u[re]["prov"] if mie.has(m.u[re]["prov"]) else mie.keys()[0]
		click_mode.call(q0)
	_conferma("Recluta e paga", func():
		_applica(p, {"compra": st["carrello"]}))

func _p_magia1(p: int) -> void:
	_intestazione(p, "Prima fase magica", "Necromanti e maghi della mente possono colpire ora: uccidere eroi e maghi, distruggere unità, conquistare la fedeltà degli indigeni.")
	var righe := _scelte_incantesimi(p, ["necromanzia", "mente"], ["uccidi_capo", "uccidi_unita", "fedelta"])
	_conferma("Conferma gli incantesimi", func(): _applica(p, {"incanti": _raccogli_incantesimi(righe)}))

func _p_chiaro(p: int) -> void:
	_intestazione(p, "Chiaroveggenza", "Un mago della mente può spiare i piani di movimento di un altro giocatore prima di scrivere i tuoi.")
	var righe := _scelte_incantesimi(p, ["mente"], ["chiaroveggenza"])
	_conferma("Conferma", func(): _applica(p, {"incanti": _raccogli_incantesimi(righe)}))

func _p_rivela(p: int) -> void:
	_intestazione(p, "Rivela illusioni", "Scegli una provincia: unità illusorie e forze invisibili nemiche saranno svelate.")
	var righe := _scelte_incantesimi(p, ["illusione"], ["rivela"])
	_conferma("Conferma", func(): _applica(p, {"incanti": _raccogli_incantesimi(righe)}))

func _p_magia3(p: int) -> void:
	_intestazione(p, "Terza fase magica", "Dove si è combattuto, un necromante può risvegliare i caduti di tutte le parti come zombi al tuo servizio. Con un 6 il rito fallisce e perdi unità.")
	var cbs := []
	for sl in m._resurrezioni_possibili(p):
		var q: int = m.u[sl["c"]]["prov"]
		var morti: int = m.caduti[q].filter(func(id): return m.u[id]["own"] == Motore.POOL).size()
		var cb := CheckBox.new()
		cb.text = "%s risveglia %d caduti in %s (valore %d)" % [Dati.nome_unita(sl["c"]), morti, Dati.nome_prov(q), sl["v"]]
		contenuto.add_child(cb)
		cbs.append([cb, sl])
	_conferma("Conferma", func():
		var inc := []
		for x in cbs:
			if x[0].button_pressed:
				inc.append({"c": x[1]["c"], "i": x[1]["i"], "s": "resurrezione"})
		_applica(p, {"incanti": inc}))

func _p_battaglia(p: int) -> void:
	var q := m.provincia_battaglia()
	_intestazione(p, "Battaglia in " + Dati.nome_prov(q), "Scegli chi attaccare. Il rapporto di forze si calcola sempre dal lato più forte; la Tattica dei capi sposta la colonna.")
	plancia.inquadra(q, 9.0)
	plancia.evidenzia({}, {q: C_SCELTA})
	_mostra_info(q)
	var mia := m.forza_effettiva(m.forza_di_lato(q, m.lato(p)), q)
	contenuto.add_child(_rtl("La tua forza qui: [b]%d[/b] (tattica %d)" % [mia, m._max_abil(m._capi_lato(q, m.lato(p)), "tattica")]))
	var cbs := {}
	for l in m.bersagli_attacco(q, p):
		var loro := m.forza_effettiva(m.forza_di_lato(q, l), q)
		var cb := CheckBox.new()
		var tat := m._max_abil(m._capi_lato(q, l), "tattica")
		cb.text = "Attacca %s (forza %d%s)" % [_nome_g(l), loro, ", tattica %d" % tat if tat > 0 else ""]
		cb.button_pressed = mia >= loro
		contenuto.add_child(cb)
		cbs[l] = cb
	if cbs.has(Motore.NEUTRALE):
		contenuto.add_child(_etichetta("Gli indigeni, se non li attacchi, attaccheranno comunque alla fine.", 15))
	_conferma("All'attacco!", func():
		var a := []
		for l in cbs:
			if cbs[l].button_pressed:
				a.append(l)
		_applica(p, {"attacca": a}))

# ---------------------------------------------------------------- piano di movimento

func _p_piano(p: int) -> void:
	_intestazione(p, "Piano di movimento", "Scegli un capo o un mago, spunta le unità che guida e clicca le province del percorso (in giallo quelle raggiungibili). Tutti i piani si eseguono insieme, punto movimento per punto movimento.")
	st["ordini"] = {}
	st["sel"] = 0
	st["click_base"] = Callable(self, "_click_piano")
	# chiaroveggenza riuscita: si vedono gli ordini dell'altro
	if m.chiaro.has(p):
		var t: int = m.chiaro[p]
		if m.dec.has(t):
			contenuto.add_child(_rtl("Chiaroveggenza: vedi i piani di %s (frecce colorate)." % _nome_colore(t)))
			st["spiati"] = m.dec[t].get("ordini", [])
			st["spiato"] = t
		else:
			contenuto.add_child(_rtl("Chiaroveggenza: %s non ha ancora scritto i suoi ordini." % _nome_colore(t)))
	var lista := VBoxContainer.new()
	contenuto.add_child(lista)
	st["lista"] = lista
	var unita_box := VBoxContainer.new()
	contenuto.add_child(unita_box)
	st["unita_box"] = unita_box
	var h := HBoxContainer.new()
	h.add_child(_bottone("Togli l'ultimo passo", func():
		var o = st["ordini"].get(st["sel"])
		if o != null and not o["via"].is_empty():
			o["via"].pop_back()
			_ridisegna_piano(p), 15))
	h.add_child(_bottone("Annulla l'ordine", func():
		st["ordini"].erase(st["sel"])
		_seleziona_capo(p, st["sel"]), 15))
	contenuto.add_child(h)
	var blocca := CheckBox.new()
	blocca.text = "Blocca i nemici che arrivano"
	blocca.tooltip_text = "Le forze nemiche che entrano dove sono le tue unità si fermano lì"
	blocca.button_pressed = m.g[p]["blocca"]
	contenuto.add_child(blocca)
	var righe := _scelte_incantesimi(p, ["mente", "elementi", "illusione"], ["controllo", "tempesta_mari", "tempesta_monti", "gelo", "alluvione", "invisibilita"])
	click_mode = Callable(self, "_click_piano")
	_lista_capi(p)
	_conferma("Conferma gli ordini", func():
		var ordini := []
		for c in st["ordini"]:
			var o: Dictionary = st["ordini"][c]
			if not o["via"].is_empty():
				ordini.append({"capo": c, "unita": o["unita"], "via": o["via"]})
		_applica(p, {"ordini": ordini, "blocca": blocca.button_pressed, "incanti": _raccogli_incantesimi(righe)}))
	var capi := m.capi_di(p)
	if not capi.is_empty():
		_seleziona_capo(p, capi[0])

func _lista_capi(p: int) -> void:
	var lista: VBoxContainer = st["lista"]
	for c in lista.get_children():
		c.queue_free()
	lista.add_child(_etichetta("I tuoi capi e maghi", 18, true))
	for id in m.capi_di(p):
		var o = st["ordini"].get(id)
		var t := "%s - %s" % [Dati.nome_unita(id), Dati.nome_prov(m.u[id]["prov"])]
		if o != null and not o["via"].is_empty():
			t += "  >  " + Dati.nome_prov(o["via"][-1]) + (" con %d unità" % o["unita"].size() if not o["unita"].is_empty() else "")
		var b := _bottone(t, func(): _seleziona_capo(p, id), 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if id == st["sel"]:
			b.add_theme_stylebox_override("normal", _stile(GIALLO.lightened(0.35), Color(0.7, 0.15, 0.05), 3, 5, 10))
		lista.add_child(b)

func _impegnate(p: int, tranne: int) -> Dictionary:
	var out := {}
	for c in st["ordini"]:
		if c == tranne:
			continue
		for id in st["ordini"][c]["unita"]:
			out[id] = true
	return out

func _seleziona_capo(p: int, capo: int) -> void:
	st["sel"] = capo
	if not st["ordini"].has(capo):
		var unita := []
		if Dati.is_capo(capo):
			var imp := _impegnate(p, capo)
			for id in m.militari_in(m.u[capo]["prov"], p):
				if not imp.has(id):
					unita.append(id)
		st["ordini"][capo] = {"unita": unita, "via": []}
	var box: VBoxContainer = st["unita_box"]
	for c in box.get_children():
		c.queue_free()
	if Dati.is_capo(capo):
		var imp := _impegnate(p, capo)
		var ids := m.militari_in(m.u[capo]["prov"], p)
		if not ids.is_empty():
			box.add_child(_etichetta("Unità guidate", 16, true))
		for id in ids:
			var cb := CheckBox.new()
			cb.text = "%s (F%d M%d)" % [Dati.nome_unita(id), Dati.unita[id]["forza"], Dati.unita[id]["mov"]]
			cb.disabled = imp.has(id)
			cb.button_pressed = id in st["ordini"][capo]["unita"]
			cb.toggled.connect(func(on: bool):
				var o: Dictionary = st["ordini"][capo]
				if on and not (id in o["unita"]):
					o["unita"].append(id)
				elif not on:
					o["unita"].erase(id)
				o["via"] = []
				_ridisegna_piano(p))
			box.add_child(cb)
	else:
		box.add_child(_etichetta("I maghi viaggiano da soli e non guidano unità.", 15))
	plancia.inquadra(m.u[capo]["prov"], 14.0)
	_ridisegna_piano(p)

func _ridisegna_piano(p: int) -> void:
	var capo: int = st["sel"]
	var lista := []
	for c in st["ordini"]:
		var o: Dictionary = st["ordini"][c]
		if o["via"].is_empty():
			continue
		var col: Color = Dati.COLORI_RGB[p]
		lista.append({"partenza": m.u[c]["prov"], "via": o["via"], "colore": Color(col.r, col.g, col.b, 0.95 if c == capo else 0.6)})
	for o in st.get("spiati", []):
		var via := []
		for x in o.get("via", []):
			via.append(int(x))
		var cc := int(o.get("capo", 0))
		if m.u.has(cc) and m.u[cc]["prov"] > 0:
			var col2: Color = Dati.COLORI_RGB[st["spiato"]]
			lista.append({"partenza": m.u[cc]["prov"], "via": via, "colore": Color(col2.r, col2.g, col2.b, 0.7)})
	plancia.disegna_percorsi(lista)
	if capo > 0:
		var o: Dictionary = st["ordini"][capo]
		var poss := m.passi_possibili(p, capo, o["unita"], o["via"])
		var ev := {}
		for q in poss:
			ev[q] = C_META
		var fine: int = o["via"][-1] if not o["via"].is_empty() else m.u[capo]["prov"]
		plancia.evidenzia(ev, {fine: C_SCELTA})
		st["poss"] = poss
	_lista_capi(p)

func _click_piano(q: int) -> void:
	var p: int = st["p"]
	var capo: int = st["sel"]
	if capo <= 0:
		return
	if st.get("poss", {}).has(q):
		st["ordini"][capo]["via"].append(q)
		_ridisegna_piano(p)
		return
	# click su una provincia con un mio capo: lo seleziona
	for id in m.capi_di(p):
		if m.u[id]["prov"] == q and id != capo:
			_seleziona_capo(p, id)
			return
	_mostra_info(q)

func _traccia_percorso_altrui(eroe: int, dati: Dictionary, etichetta: Label) -> void:
	var p: int = st["p"]
	var mostra := func():
		var poss := m.passi_possibili(m.u[eroe]["own"], eroe, [], dati["via"])
		var ev := {}
		for q in poss:
			ev[q] = C_META
		plancia.evidenzia(ev)
		plancia.disegna_percorsi([{"partenza": m.u[eroe]["prov"], "via": dati["via"], "colore": Color(0.55, 0.65, 1.0)}])
		etichetta.text = "Percorso: " + (" > ".join(dati["via"].map(func(x): return Dati.nome_prov(x))) if not dati["via"].is_empty() else "(nessuno)")
		return poss
	var poss0: Dictionary = mostra.call()
	click_mode = func(q: int):
		var poss: Dictionary = m.passi_possibili(m.u[eroe]["own"], eroe, [], dati["via"])
		if poss.has(q):
			dati["via"].append(q)
			mostra.call()
		else:
			click_mode = Callable(self, "_click_piano")
			_ridisegna_piano(p)

# ---------------------------------------------------------------- salvataggi

func _stato_salvato() -> Dictionary:
	return {"cfg": cfg, "dec": registro_dec, "umani": umani_locali, "versione": 1}

func _salva_locale() -> void:
	if m == null or online:
		_avviso("Le partite online si salvano da sole su Firebase.")
		return
	var f := FileAccess.open("user://barbarian_kings.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_stato_salvato()))
	f.close()
	_avviso("Partita salvata su questo dispositivo.")

func _carica_locale() -> void:
	if not FileAccess.file_exists("user://barbarian_kings.json"):
		var v := _schermo_centrale()
		v.add_child(_etichetta("Nessuna partita salvata su questo dispositivo.", 18))
		v.add_child(_bottone("Indietro", _menu))
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string("user://barbarian_kings.json"))
	_riprendi(d)

func _riprendi(d) -> void:
	if not (d is Dictionary) or not d.has("cfg"):
		var v := _schermo_centrale()
		v.add_child(_etichetta("Il salvataggio non è leggibile.", 18))
		v.add_child(_bottone("Indietro", _menu))
		return
	online = false
	umani_locali = []
	for x in d.get("umani", [0]):
		umani_locali.append(int(x))
	var c: Dictionary = d["cfg"]
	var gioc := []
	for gc in c["giocatori"]:
		gioc.append({"nome": str(gc["nome"]), "ia": bool(gc["ia"])})
	c["giocatori"] = gioc
	c["seme"] = int(c["seme"])
	_inizia(c, d.get("dec", []))

func _salva_cloud() -> void:
	if m == null or online:
		return
	_avviso("Salvataggio nel cloud in corso...")
	var ok := await rete.salva_partita(_stato_salvato())
	_avviso("Partita salvata su Firebase." if ok else "Salvataggio non riuscito: " + rete.last_error)

func _carica_cloud() -> void:
	var v := _schermo_centrale()
	v.add_child(_etichetta("Recupero la partita da Firebase...", 18))
	var d := await rete.carica_partita()
	if d.is_empty():
		v.add_child(_etichetta("Nessuna partita trovata per questo dispositivo. " + rete.last_error, 16))
		v.add_child(_bottone("Indietro", _menu))
		return
	_riprendi(d)

# ---------------------------------------------------------------- partita online

func _menu_online() -> void:
	var v := _schermo_centrale(560)
	v.add_child(_etichetta("Partita online", 28, true))
	v.add_child(_etichetta("Chi crea la stanza riceve un codice di quattro lettere da dare agli amici. I posti liberi possono essere presi dall'IA.", 17))
	var nome := LineEdit.new()
	nome.placeholder_text = "Il tuo nome"
	nome.text = str(rete.load_session().get("nome", ""))
	v.add_child(nome)
	v.add_child(_bottone("Crea una stanza", func(): _crea_stanza(nome.text.strip_edges())))
	var h := HBoxContainer.new()
	var cod := LineEdit.new()
	cod.placeholder_text = "Codice"
	cod.max_length = 4
	cod.custom_minimum_size = Vector2(120, 0)
	h.add_child(cod)
	h.add_child(_bottone("Entra nella stanza", func(): _entra_stanza(cod.text.strip_edges().to_upper(), nome.text.strip_edges())))
	v.add_child(h)
	var sess := rete.load_session()
	if str(sess.get("room", "")) != "":
		v.add_child(_bottone("Rientra nella stanza %s" % sess["room"], func(): _entra_stanza(str(sess["room"]), nome.text.strip_edges())))
	v.add_child(_bottone("Indietro", _menu))

func _crea_stanza(nome: String) -> void:
	if nome == "":
		nome = "Re"
	rete._save({"nome": nome})
	var v := _schermo_centrale()
	v.add_child(_etichetta("Creo la stanza...", 18))
	var c := await rete.create_room(nome, {"ia": []})
	if c == "":
		v.add_child(_etichetta("Non riesco a creare la stanza: " + rete.last_error, 16))
		v.add_child(_bottone("Indietro", _menu_online))
		return
	codice = c
	host = true
	mio_posto = 0
	posto_stanza = 0
	rete.remember_room(codice, 0)
	_sala_attesa()

func _entra_stanza(c: String, nome: String) -> void:
	if c.length() != 4:
		return
	if nome == "":
		nome = "Re"
	rete._save({"nome": nome})
	var v := _schermo_centrale()
	v.add_child(_etichetta("Entro nella stanza %s..." % c, 18))
	var posto := await rete.join_room(c, nome, 5)
	if posto < 0:
		v.add_child(_etichetta("Stanza piena o inesistente. " + rete.last_error, 16))
		v.add_child(_bottone("Indietro", _menu_online))
		return
	codice = c
	mio_posto = posto
	posto_stanza = posto
	var r: Dictionary = rete.last_room
	host = str(r.get("host", "")) == rete.uid
	rete.remember_room(codice, posto)
	if str(r.get("status", "")) == "playing":
		await _avvia_da_stanza(r)
	else:
		_sala_attesa()

func _sala_attesa() -> void:
	var v := _schermo_centrale(520)
	v.add_child(_etichetta("Stanza  " + codice, 30, true))
	v.add_child(_etichetta("Dai questo codice agli altri re. %s" % ("Tu sei l'host: quando siete pronti avvia la partita." if host else "Aspetta che l'host avvii la partita."), 17))
	var lista := VBoxContainer.new()
	v.add_child(lista)
	var ia_n := SpinBox.new()
	ia_n.min_value = 0
	ia_n.max_value = 4
	ia_n.prefix = "Re guidati dall'IA:"
	if host:
		v.add_child(ia_n)
		v.add_child(_bottone("Avvia la partita", func(): _avvia_online(int(ia_n.value))))
	v.add_child(_bottone("Esci", func(): online = false; _menu()))
	while is_inside_tree() and m == null and lista.is_inside_tree():
		var r := await rete.room(codice)
		if not lista.is_inside_tree():
			return
		for c in lista.get_children():
			c.queue_free()
		var seats := Rete._as_dict(r.get("seats", {}))
		var k := seats.keys()
		k.sort()
		for s in k:
			lista.add_child(_etichetta("Posto %d: %s" % [int(s) + 1, seats[s]["name"]], 18))
		if str(r.get("status", "")) == "playing":
			await _avvia_da_stanza(r)
			return
		await get_tree().create_timer(2.0).timeout

func _avvia_online(n_ia: int) -> void:
	var r := await rete.room(codice)
	var seats := Rete._as_dict(r.get("seats", {}))
	var k := seats.keys()
	k.sort_custom(func(a, b): return int(a) < int(b))
	var gioc := []
	var posti := {}
	for s in k:
		if gioc.size() >= 5:
			break
		posti[int(s)] = gioc.size()
		gioc.append({"nome": str(seats[s]["name"]).substr(0, 20), "ia": false, "posto": int(s)})
	for i in n_ia:
		if gioc.size() >= 5:
			break
		gioc.append({"nome": "IA " + Dati.COLORI[gioc.size()], "ia": true, "posto": -1})
	if gioc.size() < 2:
		_avviso("Servono almeno due giocatori.")
		return
	var c := {"giocatori": gioc, "seme": randi() % 1000000000}
	await rete.start_room(codice, c)

func _avvia_da_stanza(r: Dictionary) -> void:
	var c = JSON.parse_string(str(r.get("game", "{}")))
	if not (c is Dictionary) or not c.has("giocatori"):
		return
	online = true
	var gioc := []
	var mio := -1
	for i in c["giocatori"].size():
		var gc: Dictionary = c["giocatori"][i]
		gioc.append({"nome": str(gc["nome"]), "ia": bool(gc["ia"])})
		if int(gc.get("posto", -1)) == posto_stanza:
			mio = i
	var cc := {"giocatori": gioc, "seme": int(c["seme"])}
	mio_posto = mio
	umani_locali = []
	host = str(r.get("host", "")) == rete.uid
	# decisioni già presenti nel registro della stanza
	var dd := await rete.get_decisions(codice, 0)
	var lista := []
	var i := 0
	while dd.has(i):
		lista.append(dd[i])
		i += 1
	_inizia(cc, lista)
	_ciclo_online()

func _invia_online(p: int, d: Dictionary) -> void:
	_in_corso = true
	_mostra_attesa()
	var n := registro_dec.size()
	for tentativo in 6:
		var ok := await rete.post_decision(codice, n, {"p": p, "d": d})
		if ok:
			break
		# qualcun altro ha scritto la decisione n: si leggono le nuove e si riprova
		await _leggi_online()
		n = registro_dec.size()
		if not (p in m.attese):
			break
	_in_corso = false
	await _leggi_online()

func _leggi_online() -> void:
	if _attendo_rete:
		return
	_attendo_rete = true
	var dd := await rete.get_decisions(codice, registro_dec.size())
	var n := registro_dec.size()
	var nuove := false
	while dd.has(n):
		var x: Dictionary = dd[n]
		var p := int(x.get("p", -1))
		var dec = x.get("d", {})
		m.invia(p, dec if dec is Dictionary else {})
		registro_dec.append(x)
		n += 1
		nuove = true
	_attendo_rete = false
	if nuove:
		_passo()

func _ciclo_online() -> void:
	while online and m != null and not m.finita:
		await get_tree().create_timer(1.5).timeout
		if not online or m == null:
			return
		await _leggi_online()
		if not plancia.occupata() and not _in_corso:
			_passo()
		rete.heartbeat(codice, maxi(0, posto_stanza))
