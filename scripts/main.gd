## Barbarian Kings, versione digitale: menu, partita locale (IA e passa-il-dispositivo), partita online
## su Firebase, salvataggi, libro delle regole e partita guidata. Il tavolo 3D è in plancia3d.gd,
## le regole in motore.gd, l'IA in ia.gd, i testi del tutorial in tutorial.gd.
extends Node

const CARTA := Color(0.95, 0.91, 0.80)
const CARTA_SCURA := Color(0.88, 0.82, 0.68)
const INCHIOSTRO := Color(0.20, 0.12, 0.06)
const BORDO := Color(0.38, 0.24, 0.12)
const GIALLO := Color(0.96, 0.83, 0.26)
const MARE := Color(0.42, 0.66, 0.78)
const ROSSO_TITOLO := Color(0.48, 0.09, 0.05)
const ORO := Color(0.96, 0.84, 0.52)
const CREMA := Color(0.99, 0.93, 0.76)

var tema: Theme
var font_testo: Font
var font_titolo: Font       # Pirata One: titoli
var font_maiusc: Font       # IM Fell maiuscoletto
var font_corsivo: Font
var font_bottone: Font      # Almendra grassetto: pulsanti e nomi
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
var fascia_fasi: HBoxContainer
var pannello: PanelContainer
var contenuto: VBoxContainer
var titolo_pannello: RichTextLabel
var spiega_pannello: Label
var piede: HBoxContainer
var btn_conferma: Button
var btn_saggio: Button
var _azione_conferma: Callable = Callable()
var info: PanelContainer
var info_testo: RichTextLabel
var diario: RichTextLabel
var diario_box: PanelContainer
var diario_corpo: Control
var copertura: Control
var saggio_box: PanelContainer
var saggio_testo: RichTextLabel
var saggio_bottoni: HBoxContainer
var btn_rilievo: Button
var btn_3d: Button
var giocatore_ui := -1
var click_mode: Callable = Callable()
var _prov_info := 0

# partita guidata
var tutorial := false
var tutorial_tipo := "base"     # "base" (partita guidata) o "magia" (scuola di magia)
var tut_visti: Dictionary = {}

# stato dei pannelli
var st: Dictionary = {}

func _ready() -> void:
	Dati.carica()
	randomize()
	font_testo = load("res://assets/font/Fell.ttf")
	font_maiusc = load("res://assets/font/FellMaiuscoletto.ttf")
	font_corsivo = load("res://assets/font/FellCorsivo.ttf")
	font_titolo = load("res://assets/font/PirataOne.ttf")
	font_bottone = load("res://assets/font/AlmendraGrassetto.ttf")
	_crea_tema()
	plancia = Plancia3D.new()
	plancia.modalita = str(_imp("mappa", "originale"))
	plancia.stile = str(_imp("stile", "pedine" if plancia.modalita == "originale" else "3d"))
	add_child(plancia)
	plancia.vista_iniziale()
	plancia.provincia_cliccata.connect(_su_click_provincia)
	plancia.provincia_sopra.connect(_su_sopra_provincia)
	plancia.regia_finita.connect(_dopo_regia)
	plancia.carta.connect(_mostra_carta)
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

# ---------------------------------------------------------------- impostazioni salvate

func _imp(chiave: String, predef):
	var f := ConfigFile.new()
	f.load("user://impostazioni.cfg")
	return f.get_value("vista", chiave, predef)

func _salva_imp(chiave: String, val) -> void:
	var f := ConfigFile.new()
	f.load("user://impostazioni.cfg")
	f.set_value("vista", chiave, val)
	f.save("user://impostazioni.cfg")

## Mappa a rilievo o originale SPI. La mappa originale porta con sé le pedine di cartone,
## quella a rilievo le miniature; il tasto 3D poi cambia solo le pedine.
var _cambio_pendente: Callable = Callable()

func _cambia_mappa(rilievo: bool) -> void:
	if m != null and plancia.occupata():
		_cambio_pendente = _cambia_mappa.bind(rilievo)
		return
	var mod := "moderna" if rilievo else "originale"
	var sti := "3d" if rilievo else "pedine"
	_salva_imp("mappa", mod)
	_salva_imp("stile", sti)
	plancia.stile = sti
	plancia.imposta_mappa(mod)
	_aggiorna_interruttori()

func _cambia_stile(tre_d: bool) -> void:
	if m != null and plancia.occupata():
		_cambio_pendente = _cambia_stile.bind(tre_d)
		return
	var sti := "3d" if tre_d else "pedine"
	_salva_imp("stile", sti)
	plancia.imposta_stile(sti)
	_aggiorna_interruttori()

func _aggiorna_interruttori() -> void:
	if btn_rilievo != null and is_instance_valid(btn_rilievo):
		btn_rilievo.set_pressed_no_signal(plancia.modalita == "moderna")
		btn_rilievo.tooltip_text = "Mappa a rilievo con montagne e foreste in 3D" if plancia.modalita != "moderna" else "Torna alla mappa originale SPI del 1980"
	if btn_3d != null and is_instance_valid(btn_3d):
		btn_3d.set_pressed_no_signal(plancia.stile == "3d")
		btn_3d.tooltip_text = "Trasforma le pedine in miniature 3D animate" if plancia.stile != "3d" else "Torna alle pedine di cartone originali"

# ---------------------------------------------------------------- tema grafico fantasy (pergamena, cuoio e oro)

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

func _tex(nome: String) -> Texture2D:
	return load("res://assets/ui/%s.png" % nome)

## Riquadro a texture con bordi che non si deformano (nove parti).
func _stile_tex(nome: String, bordo: float, marg_o: float, marg_v: float) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = _tex(nome)
	s.texture_margin_left = bordo
	s.texture_margin_right = bordo
	s.texture_margin_top = bordo
	s.texture_margin_bottom = bordo
	s.content_margin_left = marg_o
	s.content_margin_right = marg_o
	s.content_margin_top = marg_v
	s.content_margin_bottom = marg_v
	return s

func _stile_bottone(nome: String) -> StyleBoxTexture:
	var s := _stile_tex(nome, 12, 18, 7)
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return s

func _crea_tema() -> void:
	tema = Theme.new()
	tema.default_font = font_testo
	tema.default_font_size = 18
	var perg := _stile_tex("pergamena", 26, 20, 18)
	tema.set_stylebox("panel", "PanelContainer", perg)
	tema.set_stylebox("panel", "Panel", perg)
	tema.set_color("font_color", "Label", INCHIOSTRO)
	tema.set_color("default_color", "RichTextLabel", INCHIOSTRO)
	tema.set_font("normal_font", "RichTextLabel", font_testo)
	tema.set_font("bold_font", "RichTextLabel", font_bottone)
	tema.set_font("italics_font", "RichTextLabel", font_corsivo)
	tema.set_font_size("normal_font_size", "RichTextLabel", 17)
	tema.set_font_size("bold_font_size", "RichTextLabel", 16)
	tema.set_font_size("italics_font_size", "RichTextLabel", 17)
	# pulsanti di cuoio con bordo d'oro
	for t in ["Button", "MenuButton"]:
		tema.set_stylebox("normal", t, _stile_bottone("bottone"))
		tema.set_stylebox("hover", t, _stile_bottone("bottone_su"))
		tema.set_stylebox("pressed", t, _stile_bottone("bottone_giu"))
		tema.set_stylebox("hover_pressed", t, _stile_bottone("bottone_giu"))
		tema.set_stylebox("disabled", t, _stile_bottone("bottone_spento"))
	tema.set_stylebox("normal", "OptionButton", _stile_bottone("bottone2"))
	tema.set_stylebox("hover", "OptionButton", _stile_bottone("bottone2_su"))
	tema.set_stylebox("pressed", "OptionButton", _stile_bottone("bottone2_su"))
	tema.set_stylebox("disabled", "OptionButton", _stile_bottone("bottone_spento"))
	tema.set_icon("arrow", "OptionButton", _tex("freccia_giu"))
	for t in ["Button", "MenuButton", "OptionButton"]:
		tema.set_stylebox("focus", t, StyleBoxEmpty.new())
		tema.set_color("font_color", t, CREMA)
		tema.set_color("font_hover_color", t, Color(1, 0.98, 0.86))
		tema.set_color("font_pressed_color", t, ORO)
		tema.set_color("font_hover_pressed_color", t, ORO)
		tema.set_color("font_focus_color", t, CREMA)
		tema.set_color("font_disabled_color", t, Color(CREMA, 0.45))
		tema.set_color("font_outline_color", t, Color(0.16, 0.06, 0.02))
		tema.set_constant("outline_size", t, 3)
		tema.set_font("font", t, font_bottone)
		tema.set_font_size("font_size", t, 17)
	# caselle da spuntare
	for st_nome in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		tema.set_stylebox(st_nome, "CheckBox", StyleBoxEmpty.new())
	tema.set_icon("unchecked", "CheckBox", _tex("casella"))
	tema.set_icon("checked", "CheckBox", _tex("casella_si"))
	tema.set_icon("unchecked_disabled", "CheckBox", _tex("casella"))
	tema.set_icon("checked_disabled", "CheckBox", _tex("casella_si"))
	tema.set_constant("h_separation", "CheckBox", 8)
	tema.set_font("font", "CheckBox", font_testo)
	tema.set_font_size("font_size", "CheckBox", 17)
	tema.set_color("font_color", "CheckBox", INCHIOSTRO)
	tema.set_color("font_hover_color", "CheckBox", ROSSO_TITOLO)
	tema.set_color("font_pressed_color", "CheckBox", INCHIOSTRO)
	tema.set_color("font_hover_pressed_color", "CheckBox", ROSSO_TITOLO)
	tema.set_color("font_disabled_color", "CheckBox", Color(INCHIOSTRO, 0.45))
	# campi di testo
	var campo := _stile(Color(1, 0.97, 0.88), BORDO, 1, 3, 8)
	campo.shadow_size = 0
	tema.set_stylebox("normal", "LineEdit", campo)
	var campo_f := campo.duplicate() as StyleBoxFlat
	campo_f.border_color = Color(0.75, 0.55, 0.15)
	campo_f.set_border_width_all(2)
	tema.set_stylebox("focus", "LineEdit", campo_f)
	tema.set_color("font_color", "LineEdit", INCHIOSTRO)
	tema.set_color("caret_color", "LineEdit", INCHIOSTRO)
	tema.set_font("font", "LineEdit", font_testo)
	# menu a tendina e suggerimenti
	tema.set_stylebox("panel", "PopupMenu", _stile_tex("pergamena_scura", 26, 12, 12))
	tema.set_color("font_color", "PopupMenu", INCHIOSTRO)
	tema.set_color("font_hover_color", "PopupMenu", ROSSO_TITOLO)
	tema.set_font("font", "PopupMenu", font_testo)
	tema.set_font_size("font_size", "PopupMenu", 17)
	var sel := _stile(Color(0.96, 0.84, 0.52, 0.55), Color(0, 0, 0, 0), 0, 3, 4)
	sel.shadow_size = 0
	tema.set_stylebox("hover", "PopupMenu", sel)
	tema.set_stylebox("panel", "TooltipPanel", _stile_tex("pergamena", 26, 12, 8))
	tema.set_color("font_color", "TooltipLabel", INCHIOSTRO)
	tema.set_font("font", "TooltipLabel", font_testo)
	tema.set_font_size("font_size", "TooltipLabel", 16)
	# barra delle tasse
	var pb_fondo := _stile(Color(0.18, 0.10, 0.05, 0.85), Color(0.75, 0.58, 0.25), 1, 3, 0)
	pb_fondo.shadow_size = 0
	var pb_pieno := _stile(Color(0.85, 0.66, 0.2), Color(0, 0, 0, 0), 0, 3, 0)
	pb_pieno.shadow_size = 0
	tema.set_stylebox("background", "ProgressBar", pb_fondo)
	tema.set_stylebox("fill", "ProgressBar", pb_pieno)
	# barre di scorrimento sottili
	var sb := _stile(Color(0.3, 0.2, 0.1, 0.18), Color(0, 0, 0, 0), 0, 4, 0)
	sb.shadow_size = 0
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	var gr := _stile(Color(0.45, 0.28, 0.12, 0.8), Color(0, 0, 0, 0), 0, 4, 0)
	gr.shadow_size = 0
	var gr_h := gr.duplicate() as StyleBoxFlat
	gr_h.bg_color = Color(0.6, 0.38, 0.14, 0.95)
	tema.set_stylebox("scroll", "VScrollBar", sb)
	tema.set_stylebox("grabber", "VScrollBar", gr)
	tema.set_stylebox("grabber_highlight", "VScrollBar", gr_h)
	tema.set_stylebox("grabber_pressed", "VScrollBar", gr_h)
	tema.set_stylebox("panel", "ItemList", campo)
	tema.set_color("font_color", "ItemList", INCHIOSTRO)
	tema.set_color("font_selected_color", "ItemList", INCHIOSTRO)
	tema.set_stylebox("selected", "ItemList", sel)
	tema.set_stylebox("selected_focus", "ItemList", sel)

func _pulisci_ui() -> void:
	for c in radice_ui.get_children():
		c.queue_free()
	click_mode = Callable()
	saggio_box = null
	btn_rilievo = null
	btn_3d = null

func _etichetta(t: String, dim := 18, titolo := false, col := INCHIOSTRO) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font_titolo if titolo else font_testo)
	l.add_theme_font_size_override("font_size", dim + 4 if titolo else dim)
	l.add_theme_color_override("font_color", ROSSO_TITOLO if titolo and col == INCHIOSTRO else col)
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
	fondo.color = Color(0.05, 0.03, 0.02, 0.55)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice_ui.add_child(fondo)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice_ui.add_child(cc)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(larg, 0)
	pc.add_theme_stylebox_override("panel", _stile_tex("pergamena", 26, 34, 26))
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

func _divisore(v: Control, larg := 0) -> void:
	var tr := TextureRect.new()
	tr.texture = _tex("divisore")
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(larg, 18)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tr)

## Cambia l'aspetto di un pulsante: "verde" (azione principale), "secondario" (cuoio bruno).
func _veste(b: Button, tipo: String) -> Button:
	var base := "bottone_verde" if tipo == "verde" else "bottone2"
	b.add_theme_stylebox_override("normal", _stile_bottone(base))
	b.add_theme_stylebox_override("hover", _stile_bottone(base + "_su"))
	if tipo == "verde":
		b.add_theme_stylebox_override("pressed", _stile_bottone("bottone_verde_su"))
	return b

func _interruttori(h: HBoxContainer, dim := 16) -> void:
	btn_rilievo = _bottone("Mappa a rilievo", func(): _cambia_mappa(btn_rilievo.button_pressed), dim)
	btn_rilievo.toggle_mode = true
	_veste(btn_rilievo, "secondario")
	h.add_child(btn_rilievo)
	btn_3d = _bottone("3D", func(): _cambia_stile(btn_3d.button_pressed), dim)
	btn_3d.toggle_mode = true
	btn_3d.custom_minimum_size = Vector2(64, 0)
	_veste(btn_3d, "secondario")
	h.add_child(btn_3d)
	_aggiorna_interruttori()

func _menu() -> void:
	tutorial = false
	var v := _schermo_centrale(540)
	_logo(v, 140)
	var s := _etichetta("Imperi fantasy in conflitto  -  SPI, 1980", 20, false, BORDO)
	s.add_theme_font_override("font", font_corsivo)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	_divisore(v)
	var g := _veste(_bottone("Partita guidata con il Saggio", _avvia_tutorial, 22), "verde")
	g.custom_minimum_size = Vector2(0, 54)
	g.tooltip_text = "Una vera partita contro Re Baxx: il Saggio ti spiega ogni fase, passo per passo."
	v.add_child(g)
	var hg := HBoxContainer.new()
	hg.add_theme_constant_override("separation", 8)
	var sm := _veste(_bottone("Scuola di magia", func(): _avvia_tutorial("magia"), 18), "verde")
	sm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sm.tooltip_text = "Il tuo Re conosce tre rami di magia: il Saggio ti insegna ogni incantesimo e ogni abilità, dado per dado."
	hg.add_child(sm)
	var lb := _veste(_bottone("Come si gioca", func(): _libro(0), 18), "secondario")
	lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hg.add_child(lb)
	v.add_child(hg)
	_divisore(v)
	v.add_child(_bottone("Nuova partita", _impostazioni_locali, 21))
	v.add_child(_bottone("Gioca online con gli amici", _menu_online, 21))
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 8)
	var b1 := _bottone("Riprendi la partita", _carica_locale, 17)
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hr.add_child(b1)
	var b2 := _bottone("Riprendi dal cloud", _carica_cloud, 17)
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b2.tooltip_text = "Carica una partita salvata su Firebase con il suo codice"
	hr.add_child(b2)
	v.add_child(hr)
	_divisore(v)
	var hm := HBoxContainer.new()
	hm.alignment = BoxContainer.ALIGNMENT_CENTER
	hm.add_theme_constant_override("separation", 10)
	var lm := _etichetta("Aspetto del tavolo:", 17)
	lm.autowrap_mode = TextServer.AUTOWRAP_OFF
	hm.add_child(lm)
	_interruttori(hm)
	v.add_child(hm)
	var n := _etichetta("Versione digitale per uso personale. Mappa e pedine originali dal modulo TTS, mappa a rilievo dipinta con ChatGPT, miniature 3D create con Meshy.", 14, false, Color(INCHIOSTRO, 0.7))
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
	_libro(0)

## Il libro "Come si gioca": capitoli illustrati con le pedine, da sfogliare.
func _libro(cap: int) -> void:
	var capitoli := Tutorial.capitoli()
	cap = clampi(cap, 0, capitoli.size() - 1)
	_pulisci_ui()
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.03, 0.02, 0.6)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice_ui.add_child(fondo)
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_FULL_RECT)
	pc.offset_left = 40
	pc.offset_right = -40
	pc.offset_top = 24
	pc.offset_bottom = -24
	pc.add_theme_stylebox_override("panel", _stile_tex("pagina", 40, 46, 34))
	radice_ui.add_child(pc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	pc.add_child(h)
	# indice dei capitoli
	var indice := VBoxContainer.new()
	indice.custom_minimum_size = Vector2(250, 0)
	indice.add_theme_constant_override("separation", 3)
	h.add_child(indice)
	var lt := _etichetta("Come si gioca", 30, true)
	indice.add_child(lt)
	_divisore(indice)
	var isc := ScrollContainer.new()
	isc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	isc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	indice.add_child(isc)
	var elenco := VBoxContainer.new()
	elenco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elenco.add_theme_constant_override("separation", 0)
	isc.add_child(elenco)
	for i in capitoli.size():
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, capitoli[i]["titolo"]]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", font_testo)
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_constant_override("outline_size", 0)
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		b.add_theme_color_override("font_color", ROSSO_TITOLO if i == cap else INCHIOSTRO)
		b.add_theme_color_override("font_hover_color", ROSSO_TITOLO)
		b.add_theme_color_override("font_pressed_color", ROSSO_TITOLO)
		b.add_theme_color_override("font_focus_color", INCHIOSTRO)
		if i == cap:
			b.add_theme_font_override("font", font_bottone)
		b.pressed.connect(_libro.bind(i))
		elenco.add_child(b)
	if m == null:
		indice.add_child(_veste(_bottone("Partita guidata", func(): _avvia_tutorial("base"), 15), "verde"))
		indice.add_child(_veste(_bottone("Scuola di magia", func(): _avvia_tutorial("magia"), 15), "verde"))
	indice.add_child(_bottone("Chiudi il libro", (func(): _menu()) if m == null else _chiudi_sovrapposto, 17))
	# pagina
	var dx := VBoxContainer.new()
	dx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(dx)
	var tit := _etichetta(capitoli[cap]["titolo"], 34, true)
	dx.add_child(tit)
	_divisore(dx)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dx.add_child(sc)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_size_override("normal_font_size", 18)
	r.add_theme_font_size_override("italics_font_size", 18)
	r.add_theme_font_size_override("bold_font_size", 17)
	r.add_theme_constant_override("line_separation", 3)
	r.text = capitoli[cap]["testo"]
	sc.add_child(r)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	var bp := _veste(_bottone("Pagina precedente", _libro.bind(cap - 1), 16), "secondario")
	bp.disabled = cap == 0
	nav.add_child(bp)
	var num := _etichetta("pagina %d di %d" % [cap + 1, capitoli.size()], 16, false, BORDO)
	num.add_theme_font_override("font", font_corsivo)
	num.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(num)
	var bn := _bottone("Pagina seguente", _libro.bind(cap + 1), 16)
	bn.disabled = cap == capitoli.size() - 1
	nav.add_child(bn)
	dx.add_child(nav)

func _chiudi_sovrapposto() -> void:
	_costruisci_gioco()
	_aggiorna_tutto()
	_chiave_pannello = ""
	_passo()

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
	# barra in alto: cuoio scuro con i re in gara
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 60
	top.add_theme_stylebox_override("panel", _stile_tex("barra", 6, 12, 4))
	radice_ui.add_child(top)
	barra = HBoxContainer.new()
	barra.add_theme_constant_override("separation", 12)
	top.add_child(barra)
	var lg := _etichetta("Barbarian Kings", 24, true, ORO)
	lg.autowrap_mode = TextServer.AUTOWRAP_OFF
	lg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lg.add_theme_color_override("font_outline_color", Color(0.1, 0.04, 0.0))
	lg.add_theme_constant_override("outline_size", 4)
	barra.add_child(lg)
	box_giocatori = HBoxContainer.new()
	box_giocatori.add_theme_constant_override("separation", 16)
	box_giocatori.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(box_giocatori)
	_interruttori(barra, 15)
	var mb := MenuButton.new()
	mb.text = "Menu"
	mb.flat = false
	mb.add_theme_font_size_override("font_size", 16)
	var pm := mb.get_popup()
	pm.add_item("Animazioni a velocità normale", 1)
	pm.add_item("Animazioni a velocità doppia", 2)
	pm.add_item("Animazioni a velocità quadrupla", 4)
	pm.add_separator()
	pm.add_check_item("Colora le province per proprietario", 10)
	pm.add_item("Riporta la telecamera alla vista iniziale", 11)
	pm.add_separator()
	pm.add_item("Salva la partita", 20)
	pm.add_item("Salva nel cloud (Firebase)", 21)
	pm.add_item("Come si gioca (libro delle regole)", 22)
	pm.add_item("Torna al menu principale", 23)
	pm.id_pressed.connect(_voce_menu.bind(pm))
	barra.add_child(mb)
	# fascia delle fasi dell'anno
	var fc := CenterContainer.new()
	fc.anchor_right = 1.0
	fc.offset_left = 8
	fc.offset_right = -440
	fc.offset_top = 64
	fc.offset_bottom = 98
	fc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice_ui.add_child(fc)
	fascia_fasi = HBoxContainer.new()
	fascia_fasi.add_theme_constant_override("separation", 4)
	fc.add_child(fascia_fasi)
	# pannello delle decisioni a destra: intestazione, contenuto che scorre, piede fisso
	pannello = PanelContainer.new()
	pannello.anchor_left = 1.0
	pannello.anchor_right = 1.0
	pannello.anchor_bottom = 1.0
	pannello.offset_left = -432
	pannello.offset_right = -6
	pannello.offset_top = 64
	pannello.offset_bottom = -6
	radice_ui.add_child(pannello)
	var colonna := VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 6)
	pannello.add_child(colonna)
	titolo_pannello = RichTextLabel.new()
	titolo_pannello.bbcode_enabled = true
	titolo_pannello.fit_content = true
	titolo_pannello.scroll_active = false
	titolo_pannello.add_theme_font_override("normal_font", font_titolo)
	titolo_pannello.add_theme_font_override("bold_font", font_titolo)
	titolo_pannello.add_theme_font_size_override("normal_font_size", 27)
	titolo_pannello.add_theme_font_size_override("bold_font_size", 27)
	titolo_pannello.add_theme_color_override("default_color", ROSSO_TITOLO)
	colonna.add_child(titolo_pannello)
	spiega_pannello = _etichetta("", 16, false, Color(INCHIOSTRO, 0.85))
	spiega_pannello.add_theme_font_override("font", font_corsivo)
	colonna.add_child(spiega_pannello)
	_divisore(colonna)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonna.add_child(sc)
	contenuto = VBoxContainer.new()
	contenuto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenuto.add_theme_constant_override("separation", 8)
	sc.add_child(contenuto)
	_divisore(colonna)
	piede = HBoxContainer.new()
	piede.add_theme_constant_override("separation", 8)
	colonna.add_child(piede)
	btn_saggio = _veste(_bottone("Consiglio", func(): _consiglio(giocatore_ui), 16), "secondario")
	btn_saggio.icon = _icona_saggio()
	btn_saggio.expand_icon = false
	btn_saggio.tooltip_text = "Il Saggio suggerisce una mossa e ti spiega perché."
	piede.add_child(btn_saggio)
	btn_conferma = _veste(_bottone("Conferma", func():
		if _azione_conferma.is_valid():
			_azione_conferma.call(), 19), "verde")
	btn_conferma.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_conferma.custom_minimum_size = Vector2(0, 48)
	piede.add_child(btn_conferma)
	piede.visible = false
	# scheda della provincia sotto il mouse, a sinistra
	info = PanelContainer.new()
	info.position = Vector2(8, 102)
	info.custom_minimum_size = Vector2(340, 0)
	info.visible = false
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice_ui.add_child(info)
	info_testo = RichTextLabel.new()
	info_testo.bbcode_enabled = true
	info_testo.fit_content = true
	info_testo.custom_minimum_size = Vector2(300, 0)
	info_testo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_testo.add_theme_font_size_override("normal_font_size", 16)
	info.add_child(info_testo)
	# cronaca dell'anno in basso a sinistra, comprimibile
	diario_box = PanelContainer.new()
	diario_box.anchor_top = 1.0
	diario_box.anchor_bottom = 1.0
	diario_box.offset_left = 6
	diario_box.offset_right = 500
	diario_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	diario_box.offset_bottom = -6
	diario_box.add_theme_stylebox_override("panel", _stile_tex("pergamena_scura", 26, 16, 12))
	radice_ui.add_child(diario_box)
	var dv := VBoxContainer.new()
	diario_box.add_child(dv)
	var dh := HBoxContainer.new()
	dv.add_child(dh)
	var dt := _etichetta("Cronaca", 18, true)
	dt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dh.add_child(dt)
	var db := _veste(_bottone("Nascondi", func(): pass, 13), "secondario")
	db.custom_minimum_size = Vector2(90, 0)
	dh.add_child(db)
	diario_corpo = MarginContainer.new()
	diario_corpo.custom_minimum_size = Vector2(0, 130)
	dv.add_child(diario_corpo)
	diario = RichTextLabel.new()
	diario.bbcode_enabled = true
	diario.scroll_following = true
	diario.add_theme_font_size_override("normal_font_size", 15)
	diario.add_theme_font_size_override("bold_font_size", 14)
	diario_corpo.add_child(diario)
	db.pressed.connect(func():
		diario_corpo.visible = not diario_corpo.visible
		db.text = "Nascondi" if diario_corpo.visible else "Mostra"
		diario_box.offset_top = diario_box.offset_bottom)
	diario_box.offset_top = diario_box.offset_bottom
	# fumetto del Saggio (consigli e partita guidata)
	saggio_box = PanelContainer.new()
	saggio_box.anchor_top = 1.0
	saggio_box.anchor_bottom = 1.0
	saggio_box.anchor_right = 1.0
	saggio_box.offset_left = 354
	saggio_box.offset_right = -440
	saggio_box.offset_bottom = -6
	saggio_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	saggio_box.visible = false
	saggio_box.add_theme_stylebox_override("panel", _stile_tex("pergamena", 26, 18, 14))
	radice_ui.add_child(saggio_box)
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 12)
	saggio_box.add_child(sh)
	var ritr := TextureRect.new()
	ritr.texture = _tex("saggio")
	ritr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ritr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ritr.custom_minimum_size = Vector2(96, 96)
	ritr.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sh.add_child(ritr)
	var sv := VBoxContainer.new()
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sv)
	sv.add_child(_etichetta("Il Saggio", 22, true))
	saggio_testo = RichTextLabel.new()
	saggio_testo.bbcode_enabled = true
	saggio_testo.fit_content = true
	saggio_testo.custom_minimum_size = Vector2(320, 0)
	saggio_testo.add_theme_font_size_override("normal_font_size", 17)
	saggio_testo.add_theme_font_size_override("italics_font_size", 17)
	sv.add_child(saggio_testo)
	saggio_bottoni = HBoxContainer.new()
	saggio_bottoni.alignment = BoxContainer.ALIGNMENT_END
	saggio_bottoni.add_theme_constant_override("separation", 8)
	sv.add_child(saggio_bottoni)
	_riempi_diario()

var _icona_s: Texture2D
func _icona_saggio() -> Texture2D:
	if _icona_s == null:
		var img: Image = _tex("saggio").get_image()
		img.resize(28, 28, Image.INTERPOLATE_LANCZOS)
		_icona_s = ImageTexture.create_from_image(img)
	return _icona_s

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
		20:
			_salva_locale()
		21:
			_salva_cloud()
		22:
			_libro(0)
		23:
			m = null
			online = false
			tutorial = false
			_menu()

func _riempi_diario() -> void:
	if m == null or diario == null:
		return
	var righe := m.registro.slice(maxi(0, m.registro.size() - 160))
	var t := ""
	for r in righe:
		if r.begins_with("---"):
			t += "\n[b]" + r.replace("-", " ").strip_edges() + "[/b]\n"
		else:
			t += r + "\n"
	diario.text = t

## Fase del motore -> voce della fascia in alto.
func _gruppo_fase(f: String) -> String:
	match f:
		"province", "re": return "Preparativi"
		"alleanze": return "Alleanze"
		"tornado", "finanze": return "Finanze"
		"acquisti": return "Reclute"
		"magia1", "chiaro", "rivela", "magia3": return "Magia"
		"piano": return "Movimento"
		"battaglia": return "Battaglia"
	return ""

func _aggiorna_tutto() -> void:
	if m == null or box_giocatori == null or not is_instance_valid(box_giocatori):
		return
	# i re in gara
	for c in box_giocatori.get_children():
		c.queue_free()
	for p in m.n:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		var sc := TextureRect.new()
		sc.texture = _tex("scudo_%d" % p)
		sc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sc.custom_minimum_size = Vector2(32, 40)
		h.add_child(sc)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		h.add_child(v)
		var attesa: bool = p in m.attese and not m.finita
		var nome := _etichetta(m.g[p]["nome"], 15, false, ORO if attesa else CREMA)
		nome.add_theme_font_override("font", font_bottone)
		nome.autowrap_mode = TextServer.AUTOWRAP_OFF
		nome.add_theme_color_override("font_outline_color", Color(0.1, 0.04, 0.0))
		nome.add_theme_constant_override("outline_size", 3)
		v.add_child(nome)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 4)
		v.add_child(r)
		var t := m.tasse_di(p)
		var pb := ProgressBar.new()
		pb.max_value = m.soglia
		pb.value = t
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(70, 9)
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(pb)
		var mo := TextureRect.new()
		mo.texture = _tex("moneta")
		mo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mo.custom_minimum_size = Vector2(16, 16)
		r.add_child(mo)
		var ts := _etichetta(str(m.g[p]["tesoro"]), 14, false, CREMA)
		ts.autowrap_mode = TextServer.AUTOWRAP_OFF
		r.add_child(ts)
		h.tooltip_text = "%s\nTasse delle province controllate: %d su %d per vincere\nTesoro: %d sequin%s" % [m.g[p]["nome"], t, m.soglia, m.g[p]["tesoro"], "\nSta decidendo..." if attesa else ""]
		h.mouse_filter = Control.MOUSE_FILTER_PASS
		box_giocatori.add_child(h)
	# fascia delle fasi
	for c in fascia_fasi.get_children():
		c.queue_free()
	var voci := ["Preparativi"] if m.turno == 0 else (["Alleanze"] if m.n >= 3 else []) + ["Finanze", "Reclute", "Magia", "Movimento", "Battaglia"]
	var corrente := _gruppo_fase(m.fase)
	fascia_fasi.add_child(_pillola("Anno %d" % m.turno if m.turno > 0 else "Inizio", false, true))
	for vce in voci:
		fascia_fasi.add_child(_pillola(vce, vce == corrente))
	_riempi_diario()
	if _prov_info > 0:
		_mostra_info(_prov_info)

func _pillola(testo: String, attiva: bool, scura := false) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if scura:
		pc.add_theme_stylebox_override("panel", _stile(Color(0.16, 0.08, 0.03, 0.88), Color(0.8, 0.62, 0.28), 1, 12, 12))
		attiva = true
	elif attiva:
		pc.add_theme_stylebox_override("panel", _stile_bottone("bottone"))
	else:
		var s := _stile(Color(0.95, 0.89, 0.74, 0.82), Color(0.45, 0.3, 0.14, 0.8), 1, 12, 12)
		s.shadow_size = 1
		pc.add_theme_stylebox_override("panel", s)
	var l := _etichetta(testo, 15, false, CREMA if attiva else Color(INCHIOSTRO, 0.75))
	l.add_theme_font_override("font", font_bottone)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	if attiva:
		l.add_theme_color_override("font_outline_color", Color(0.16, 0.06, 0.02))
		l.add_theme_constant_override("outline_size", 3)
	pc.add_child(l)
	return pc

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
		if tutorial:
			_guida_eventi(nuovi)
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
	if _cambio_pendente.is_valid():
		var c := _cambio_pendente
		_cambio_pendente = Callable()
		c.call()
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
	if _saggio_modo in ["consiglio", "guida"] and p == giocatore_ui and saggio_box != null and is_instance_valid(saggio_box) and saggio_box.visible:
		_chiudi_saggio()
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
	titolo_pannello.text = m.descr_fase()
	var chi := ", ".join(m.attese.map(func(p): return _nome_colore(p)))
	contenuto.add_child(_rtl("In attesa di: " + chi))
	if plancia.occupata():
		contenuto.add_child(_etichetta("Gli eserciti si muovono sulla mappa...", 16, false, BORDO))
	plancia.evidenzia({})
	plancia.disegna_percorsi([])

func _svuota_pannello() -> void:
	for c in contenuto.get_children():
		c.queue_free()
	click_mode = Callable()
	titolo_pannello.text = ""
	spiega_pannello.text = ""
	spiega_pannello.visible = false
	piede.visible = false
	_azione_conferma = Callable()

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
	titolo_pannello.text = "La Pace del Re"
	_mostra_carta("vittoria", "")
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
	if m == null or info == null or not is_instance_valid(info) or q <= 0:
		return
	_prov_info = q
	var pr: Dictionary = Dati.province[q]
	var t := "[font_size=24][color=#%s][font=res://assets/font/PirataOne.ttf]%s[/font][/color][/font_size]\n" % [_hex(ROSSO_TITOLO), Dati.nome_prov(q)]
	t += "[img=16x16]res://assets/ui/moneta.png[/img] tasse [b]%d[/b]   %s" % [pr["tasse"], Dati.TERRENI[pr["terreno"]]]
	if pr["nativi"] != "":
		t += "   popolo [i]%s[/i]" % Dati.NATIVI[pr["nativi"]]
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
		t += "\n\n%s  -  forza [b]%d[/b]\n" % [_nome_colore(o), forza]
		var righe := []
		var gruppi := {}
		var ordine := []
		for id in ids:
			var s0: Dictionary = m.u[id]
			if Dati.is_militare(id) and not s0["zombie"] and s0["catt"] == -9 and not (o == spett and (s0["illus"] or s0["invis"])):
				var k := "%s (F%d M%d)" % [Dati.nome_tipo(id), Dati.unita[id]["forza"], Dati.unita[id]["mov"]]
				if not gruppi.has(k):
					gruppi[k] = 0
					ordine.append(k)
				gruppi[k] += 1
			else:
				righe.append(_descr_unita(id, o == spett))
		for k in ordine:
			righe.append(("%d x " % gruppi[k] if gruppi[k] > 1 else "") + k)
		# le pedine originali in fila, poi la descrizione
		for id in ids:
			t += _img_pedina(id, 34)
		t += "\n[font_size=14]" + "\n".join(righe) + "[/font_size]"
	info_testo.text = t
	info.visible = true
	info.reset_size()

func _img_pedina(id: int, lato := 34) -> String:
	var perc := "res://assets/img/pedine_colore/%03d.png" % id
	if not ResourceLoader.exists(perc):
		return ""
	return "[img=%dx%d]%s[/img] " % [lato, lato, perc]

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
	titolo_pannello.text = "[img=30x36]res://assets/ui/scudo_%d.png[/img] %s" % [p, titolo]
	titolo_pannello.tooltip_text = "Decide " + m.g[p]["nome"]
	spiega_pannello.text = spiega
	spiega_pannello.visible = spiega != ""
	var k := _carta_fase(m.fase)
	if k != "" and Carte.ha_immagine(k):
		var img := TextureRect.new()
		img.texture = Carte.tex(k)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.custom_minimum_size = Vector2(0, 120)
		contenuto.add_child(img)

## Il pulsante principale, sempre in fondo al pannello, accanto al consiglio del Saggio.
func _conferma(testo: String, f: Callable) -> void:
	btn_conferma.text = testo
	_azione_conferma = f
	piede.visible = true

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
	if tutorial:
		_guida_fase(p)

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
	contenuto.add_child(_etichetta("Le tre abilità del Re", 19, true))
	contenuto.add_child(_etichetta("Clicca una carta per aggiungerla (anche più volte); clicca una carta scelta per toglierla.", 15, false, Color(INCHIOSTRO, 0.8)))
	st["abil"] = ["mente", "elementi", "necromanzia"] if tutorial_tipo == "magia" else ["tattica", "tattica", "mente"]
	var scelte_box := HBoxContainer.new()
	scelte_box.add_theme_constant_override("separation", 6)
	contenuto.add_child(scelte_box)
	var descr := _rtl("", 15)
	var agg := func():
		for c in scelte_box.get_children():
			c.queue_free()
		for i in 3:
			if i < st["abil"].size():
				var k: String = st["abil"][i]
				var b := _bottone_carta(k, 74, false)
				b.tooltip_text = "Togli " + Carte.titolo(k)
				b.pressed.connect(func():
					st["abil"].remove_at(i)
					st["agg_abil"].call())
				scelte_box.add_child(b)
			else:
				var vuota := PanelContainer.new()
				vuota.custom_minimum_size = Vector2(74, 128)
				vuota.add_theme_stylebox_override("panel", _stile(Color(0.3, 0.2, 0.1, 0.15), Color(BORDO, 0.5), 1, 6, 4))
				scelte_box.add_child(vuota)
		var t := ""
		for k in st["abil"]:
			t += "[b]%s[/b]: %s\n" % [Carte.titolo(k), Carte.descrizione(k)]
		descr.text = t
	st["agg_abil"] = agg
	contenuto.add_child(_etichetta("Abilità disponibili", 17, true))
	var griglia := HFlowContainer.new()
	griglia.add_theme_constant_override("h_separation", 6)
	griglia.add_theme_constant_override("v_separation", 6)
	contenuto.add_child(griglia)
	for k in Carte.ABILITA:
		var b := _bottone_carta(k, 82, true)
		b.pressed.connect(func():
			if st["abil"].size() < 3:
				st["abil"].append(k)
				st["agg_abil"].call())
		griglia.add_child(b)
	contenuto.add_child(descr)
	agg.call()
	_conferma("Conferma il Re", func():
		_applica(p, {"prov": st["prov"], "abil": st["abil"].duplicate()}))

## Una carta illustrata cliccabile: immagine (o stemma provvisorio) e nome sotto.
func _bottone_carta(k: String, larg := 82, con_nome := true, sotto := "") -> Button:
	var b := Button.new()
	b.icon = Carte.tex(k)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.custom_minimum_size = Vector2(larg, larg * 1.5 + (30 if con_nome else 0))
	b.text = (Carte.titolo(k) + ("\n" + sotto if sotto != "" else "")) if con_nome else ""
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_constant_override("outline_size", 2)
	var col := Carte.colore(k)
	var n := _stile(Color(0.13, 0.08, 0.05, 0.92), col.darkened(0.25), 2, 6, 4)
	var h := _stile(Color(0.2, 0.13, 0.08, 0.95), col, 3, 6, 4)
	var sel := _stile(Color(0.12, 0.3, 0.1, 0.95), Color(0.95, 0.84, 0.5), 3, 6, 4)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", sel)
	b.add_theme_stylebox_override("hover_pressed", sel)
	b.tooltip_text = "%s\n%s" % [Carte.titolo(k), Carte.descrizione(k)]
	return b

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
		var prob := _etichetta("Riesce con un dado da 1 a %d: %d probabilità su 6." % [sl["v"], sl["v"]], 14, false, BORDO)
		prob.add_theme_font_override("font", font_corsivo)
		box.add_child(prob)
		var ob := OptionButton.new()
		ob.add_item("Nessun incantesimo")
		for s in ammessi:
			var costo: int = Dati.INCANTESIMI[s]["costo"]
			ob.add_item(Dati.INCANTESIMI[s]["nome"] + ("" if costo == 0 else " (%d seq.)" % costo))
		ob.visible = false
		box.add_child(ob)
		var fila := HFlowContainer.new()
		fila.add_theme_constant_override("h_separation", 6)
		fila.add_theme_constant_override("v_separation", 6)
		box.add_child(fila)
		var dett := VBoxContainer.new()
		box.add_child(dett)
		var riga := {"slot": sl, "ob": ob, "ammessi": ammessi, "dett": dett, "dati": {}}
		var bottoni := []
		for j in ammessi.size():
			var sp: String = ammessi[j]
			var costo2: int = Dati.INCANTESIMI[sp]["costo"]
			var bc := _bottone_carta(sp, 78, true, "%d seq." % costo2 if costo2 > 0 else "")
			bc.toggle_mode = true
			bc.pressed.connect(func():
				var gia: bool = ob.selected == j + 1
				ob.selected = 0 if gia else j + 1
				for k2 in bottoni.size():
					bottoni[k2].set_pressed_no_signal(ob.selected == k2 + 1)
				_dettagli_incantesimo(p, riga))
			bottoni.append(bc)
			fila.add_child(bc)
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
	var soldi := _etichetta("", 16, false, BORDO)
	soldi.add_theme_font_override("font", font_bottone)
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
		soldi.text = "Tesoro %d - spesa %d = %d\nMantenimento futuro %d, tasse %d" % [m.g[p]["tesoro"], spesa.call(), m.g[p]["tesoro"] - spesa.call(), mant, m.tasse_di(p)]
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
			ic.texture = load("res://assets/img/pedine_colore/%s.png" % nome_ic) if ResourceLoader.exists("res://assets/img/pedine_colore/%s.png" % nome_ic) else null
			ic.custom_minimum_size = Vector2(46, 46)
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
				ab_ob.add_theme_font_size_override("font_size", 13)
				ab_ob.fit_to_longest_item = false
				ab_ob.clip_text = true
				ab_ob.custom_minimum_size = Vector2(118, 0)
				ab_ob.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				h.add_child(ab_ob)
			var br := _bottone("Recluta", func():
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
				st["riempi"].call(q), 15)
			br.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(br)
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
		cb.text = "Attacca %s (forza %d%s): %s" % [_nome_g(l), loro, ", tattica %d" % tat if tat > 0 else "", _rapporto(mia, loro)]
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
			_veste(b, "verde")
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
	var tt = c.get("tutorial", false)
	tutorial = tt is String or bool(tt)
	tutorial_tipo = tt if tt is String else "base"
	tut_visti = {"intro": true}
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

# ---------------------------------------------------------------- carte illustrate in sovrimpressione

var _carta_vista: Control

## Mostra per un attimo la carta di un incantesimo o di un'azione mentre la regia la anima sulla mappa.
## Le azioni comuni (battaglie) compaiono solo se esiste la loro illustrazione.
func _mostra_carta(k: String, esito: String) -> void:
	if radice_ui == null or m == null:
		return
	if not Dati.INCANTESIMI.has(k) and not Carte.ha_immagine(k) and not (k in ["cattura", "liberazione", "vittoria"]):
		return
	if _carta_vista != null and is_instance_valid(_carta_vista):
		_carta_vista.queue_free()
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _stile_tex("pergamena", 26, 16, 14))
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	var img := TextureRect.new()
	img.texture = Carte.tex(k)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.custom_minimum_size = Vector2(170, 255)
	v.add_child(img)
	var t := _etichetta(Carte.titolo(k), 24, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(t)
	if esito != "":
		var e := _etichetta(esito.capitalize(), 17, false, Color(0.15, 0.45, 0.1) if esito == "riuscito" else Color(0.65, 0.1, 0.05))
		e.add_theme_font_override("font", font_bottone)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e.autowrap_mode = TextServer.AUTOWRAP_OFF
		v.add_child(e)
	radice_ui.add_child(pc)
	pc.reset_size()
	var vp := radice_ui.get_viewport_rect().size
	pc.position = Vector2((vp.x - 440) * 0.5 - pc.size.x * 0.5, 104)
	pc.pivot_offset = pc.size * 0.5
	pc.scale = Vector2(0.6, 0.6)
	pc.modulate.a = 0.0
	var vel := maxf(plancia.velocita, 1.0)
	var tw := pc.create_tween()
	tw.set_parallel(true)
	tw.tween_property(pc, "scale", Vector2.ONE, 0.35 / vel).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(pc, "modulate:a", 1.0, 0.25 / vel)
	tw.chain().tween_interval(1.8 / vel)
	tw.chain().tween_property(pc, "modulate:a", 0.0, 0.4 / vel)
	tw.chain().tween_callback(pc.queue_free)
	_carta_vista = pc

## Fase -> carta d'azione usata come illustrazione in testa al pannello (solo se l'immagine esiste).
func _carta_fase(f: String) -> String:
	match f:
		"alleanze": return "alleanza"
		"finanze": return "tasse"
		"acquisti": return "reclutamento"
		"piano": return "piano"
		"battaglia": return "battaglia"
	return ""

# ---------------------------------------------------------------- il Saggio: consigli e partita guidata

var _saggio_pagine: Array = []
var _saggio_finale: Array = []
var _saggio_consiglio := false   # il fumetto aperto è un consiglio (si chiude quando decidi)
var _saggio_modo := ""

## Mostra il fumetto del Saggio. pagine: testi da sfogliare; finale: pulsanti [testo, callable, aspetto]
## dell'ultima pagina. modo: "consiglio" (si chiude quando decidi), "guida" (spiegazione di una fase:
## sostituisce le spiegazioni vecchie ma lascia finire i commenti agli eventi), "evento" (si accoda).
func _saggio(pagine: Array, finale: Array = [], modo := "consiglio") -> void:
	if saggio_box == null or not is_instance_valid(saggio_box) or pagine.is_empty():
		return
	var aperto := saggio_box.visible
	if modo == "evento" and aperto and _saggio_modo != "consiglio":
		_saggio_pagine += pagine
	elif modo == "guida" and aperto and _saggio_modo == "evento":
		_saggio_pagine += pagine
		_saggio_finale = finale
		_saggio_modo = "guida"
	else:
		_saggio_pagine = pagine.duplicate()
		_saggio_finale = finale
		_saggio_modo = modo
	_saggio_consiglio = _saggio_modo == "consiglio"
	saggio_box.visible = true
	diario_box.visible = false
	_saggio_pagina()

func _saggio_pagina() -> void:
	saggio_testo.text = _saggio_pagine[0]
	for c in saggio_bottoni.get_children():
		c.queue_free()
	if _saggio_pagine.size() > 1:
		var n := _etichetta("ancora %d" % (_saggio_pagine.size() - 1), 14, false, BORDO)
		n.add_theme_font_override("font", font_corsivo)
		n.autowrap_mode = TextServer.AUTOWRAP_OFF
		n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		saggio_bottoni.add_child(n)
		saggio_bottoni.add_child(_bottone("Avanti", func():
			_saggio_pagine.pop_front()
			_saggio_pagina(), 15))
		var salta := _veste(_bottone("Salta", _chiudi_saggio, 15), "secondario")
		saggio_bottoni.add_child(salta)
	else:
		for f in _saggio_finale:
			var b := _bottone(f[0], f[1], 15)
			if f.size() > 2:
				_veste(b, f[2])
			saggio_bottoni.add_child(b)
		if _saggio_finale.is_empty():
			saggio_bottoni.add_child(_veste(_bottone("Ho capito", _chiudi_saggio, 15), "secondario"))
	saggio_box.offset_top = saggio_box.offset_bottom

func _chiudi_saggio() -> void:
	if saggio_box != null and is_instance_valid(saggio_box):
		saggio_box.visible = false
		diario_box.visible = true

func _descr_incanto(inc: Dictionary) -> String:
	var s: String = inc.get("s", "")
	var t := "%s lancia [i]%s[/i]" % [Dati.nome_unita(int(inc["c"])), Dati.INCANTESIMI[s]["nome"] if Dati.INCANTESIMI.has(s) else s]
	if inc.has("prov"):
		t += " su %s" % Dati.nome_prov(int(inc["prov"]))
	if inc.has("p") and int(inc["p"]) >= 0 and int(inc["p"]) < m.n:
		t += " contro %s" % _nome_colore(int(inc["p"]))
	return t

## Descrive a parole la decisione che l'IA prenderebbe al posto del giocatore.
func _descrivi(p: int, d: Dictionary) -> String:
	var inc: Array = d.get("incanti", [])
	var magia := ""
	if not inc.is_empty():
		magia = "\n" + "\n".join(inc.map(func(x): return _descr_incanto(x))) + "."
	match m.fase:
		"province":
			var q := int(d.get("prov", 0))
			if q <= 0:
				return "Non vedo province libere adatte."
			var pr: Dictionary = Dati.province[q]
			var vicine := ""
			for a in pr["adiacenti"]:
				if m.ctrl[a] == p:
					vicine = " È vicina alle tue altre province: potrai difenderle insieme."
					break
			return "Prendi [b]%s[/b]: rende [b]%d[/b] sequin di tasse e vi abita il popolo [i]%s[/i], che potrai reclutare.%s" % [Dati.nome_prov(q), pr["tasse"], Dati.NATIVI[pr["nativi"]], vicine]
		"re":
			var ab: Array = d.get("abil", [])
			return "Metti il Re in [b]%s[/b] e dagli: %s." % [Dati.nome_prov(int(d["prov"])), ", ".join(ab.map(func(a): return Dati.NOMI_ABILITA[a]))]
		"alleanze":
			var f: Array = d.get("firme", [])
			if f.is_empty():
				return "Quest'anno non firmerei con nessuno: gli altri sono troppo vicini o troppo forti." + magia
			return "Firma con %s: un alleato non ti blocca e combatte con te." % ", ".join(f.map(func(q): return _nome_colore(q))) + magia
		"finanze":
			var mt := m.mantenimento(p)
			if mt <= m.g[p]["tesoro"]:
				return "Paga tutto: il mantenimento è %d e nel tesoro hai %d sequin. Non c'è bisogno di congedare nessuno." % [mt, m.g[p]["tesoro"]]
			return "Il mantenimento (%d) supera il tesoro (%d): congeda le unità meno utili, o lo farà il gioco partendo dalle più costose." % [mt, m.g[p]["tesoro"]]
		"battaglia":
			var a: Array = d.get("attacca", [])
			var q := m.provincia_battaglia()
			var mia := m.forza_effettiva(m.forza_di_lato(q, m.lato(p)), q)
			if a.is_empty():
				return "Non attaccare: la tua forza qui è %d e il rischio è troppo alto. Se ti attaccano, ti difenderai comunque." % mia
			var righe := []
			for l in a:
				var loro := m.forza_effettiva(m.forza_di_lato(q, l), q)
				righe.append("%s (forza %d contro la tua %d, %s)" % [_nome_g(l), loro, mia, _rapporto(mia, loro)])
			return "Attacca " + ", ".join(righe) + "."
		"tornado", "magia1", "chiaro", "rivela", "magia3":
			if inc.is_empty():
				return "Quest'anno non lancerei nulla in questa fase: conserva sequin e incantatori. Premi pure [b]Conferma[/b]."
			return "Tenta la sorte:" + magia
	return "Fai come ti suggerisco." + magia

func _rapporto(a: int, b: int) -> String:
	if a <= 0 or b <= 0:
		return "senza confronto"
	var r := clampi(int(maxi(a, b) / mini(a, b)), 1, 6)
	return ("%d-1 a tuo favore" if a >= b else "%d-1 contro di te") % r

## Il pulsante Consiglio: l'IA decide per te e il Saggio lo spiega. Nel reclutamento e nel
## movimento riempie il pannello, così puoi ritoccare prima di confermare.
func _consiglio(p: int) -> void:
	if m == null or p < 0 or not (p in m.attese):
		return
	var d := IA.decidi(m, p)
	match m.fase:
		"acquisti":
			st["carrello"] = d.get("compra", []).duplicate(true)
			st["agg"].call()
			if st["prov"] > 0:
				st["riempi"].call(st["prov"])
			var c: Array = st["carrello"]
			if c.is_empty():
				_saggio(["Quest'anno non recluterei nessuno: meglio tenere i sequin per il mantenimento. Premi [b]Recluta e paga[/b] lo stesso per passare oltre."])
			else:
				var conta := {}
				var ordine := []
				for x in c:
					var k := "%s in %s" % [Dati.nome_tipo(int(x["id"])), Dati.nome_prov(int(x["p"]))]
					if not conta.has(k):
						conta[k] = 0
						ordine.append(k)
					conta[k] += 1
				var nomi := ordine.map(func(k): return ("%d x " % conta[k] if conta[k] > 1 else "") + k)
				_saggio(["Ho preparato l'ordine: " + ", ".join(nomi) + ". Puoi togliere ciò che non ti convince; poi premi [b]Recluta e paga[/b]."])
		"piano":
			st["ordini"] = {}
			for o in d.get("ordini", []):
				st["ordini"][int(o["capo"])] = {"unita": o["unita"].duplicate(), "via": o["via"].duplicate()}
			var capi := m.capi_di(p)
			_lista_capi(p)
			if not capi.is_empty():
				_seleziona_capo(p, st["sel"] if st["sel"] in capi else capi[0])
			var righe := []
			for o in d.get("ordini", []):
				if not o["via"].is_empty():
					righe.append("%s va in %s%s" % [Dati.nome_unita(int(o["capo"])), Dati.nome_prov(int(o["via"][-1])), " con %d unità" % o["unita"].size() if not o["unita"].is_empty() else ""])
			var t := ("Ecco il mio piano: " + "; ".join(righe) + ". Le frecce sulla mappa mostrano i percorsi.") if not righe.is_empty() else "Quest'anno terrei fermi i tuoi eserciti a difendere le province."
			var inc: Array = d.get("incanti", [])
			if not inc.is_empty():
				t += "\nE poi: " + "; ".join(inc.map(func(x): return _descr_incanto(x))) + "."
			_saggio([t + " Puoi cambiare gli ordini oppure confermarli così."], [
				["Conferma il piano del Saggio", func(): _chiudi_saggio(); _applica(p, d), "verde"],
				["Lo ritocco io", _chiudi_saggio, "secondario"]])
		_:
			_saggio([_descrivi(p, d)], [
				["Segui il consiglio", func(): _chiudi_saggio(); _applica(p, d), "verde"],
				["Decido io", _chiudi_saggio, "secondario"]])

## Per la scuola di magia: chi può lanciare in questa fase, con che probabilità, e cosa consiglierei.
func _info_incantatori(p: int) -> String:
	var spells := []
	for sp in Dati.INCANTESIMI:
		var f: String = Dati.INCANTESIMI[sp]["fase"]
		if f == m.fase or (m.fase == "piano" and f == "piano"):
			spells.append(sp)
	if spells.is_empty():
		return ""
	var righe := []
	var visti := {}
	for sp in spells:
		var r: String = Dati.INCANTESIMI[sp]["ramo"]
		if visti.has(r):
			continue
		visti[r] = true
		for sl in m.slot_magia(p, r):
			righe.append("%s, %s: valore [b]%d[/b], riesce %d volte su 6" % [Dati.nome_unita(sl["c"]), Dati.NOMI_ABILITA[r], sl["v"], sl["v"]])
	if righe.is_empty():
		return "In questa fase nessuno dei tuoi incantatori può lanciare: premi [b]Conferma[/b] e passa oltre."
	var t := "I tuoi incantatori adesso:\n" + "\n".join(righe)
	var d := IA.decidi(m, p)
	var inc: Array = d.get("incanti", [])
	if not inc.is_empty():
		t += "\nIo tenterei: " + "; ".join(inc.map(func(x): return _descr_incanto(x))) + ". Premi [b]Consiglio[/b] se vuoi che lo prepari io."
	return t

func _avvia_tutorial(tipo := "base") -> void:
	online = false
	umani_locali = [0]
	tutorial = true
	tutorial_tipo = tipo
	tut_visti = {}
	_inizia({"giocatori": [{"nome": "Tu", "ia": false}, {"nome": "Re Baxx", "ia": true}], "seme": 1980 if tipo == "base" else 1313, "tutorial": tipo}, [])

## In partita guidata, il Saggio spiega ogni fase la prima volta in ciascuno dei primi tre anni.
func _guida_fase(p: int) -> void:
	if not tutorial or tut_visti.has("fine"):
		return
	if m.turno >= 4:
		tut_visti["fine"] = true
		_saggio([Tutorial.fine()], [
			["Continuo la partita", _chiudi_saggio, "verde"],
			["Torna al menu", func(): m = null; tutorial = false; _menu(), "secondario"]], "guida")
		return
	var chiave := "%s|%d" % [m.fase, m.turno]
	var pagine := []
	var magia := tutorial_tipo == "magia"
	if not tut_visti.has("intro"):
		tut_visti["intro"] = true
		pagine += Tutorial.intro_magia() if magia else Tutorial.intro()
	if not tut_visti.has(chiave):
		tut_visti[chiave] = true
		if magia:
			var gm := Tutorial.guida_magia(m.fase, m.turno)
			pagine += gm if not gm.is_empty() else Tutorial.guida(m.fase, mini(m.turno, 2))
			var inf := _info_incantatori(p)
			if inf != "":
				pagine.append(inf)
		else:
			pagine += Tutorial.guida(m.fase, m.turno)
	# suggerimenti concreti per le scelte iniziali
	if m.fase == "province":
		var d := IA.decidi(m, p)
		var q := int(d.get("prov", 0))
		if q > 0:
			pagine.append("Ti suggerisco [b]%s[/b] (tasse %d, popolo %s). Cliccala sulla mappa e premi [b]Conferma la provincia[/b]. Il pulsante [b]Consiglio[/b] in basso a destra ti dice sempre cosa farei io." % [Dati.nome_prov(q), Dati.province[q]["tasse"], Dati.NATIVI[Dati.province[q]["nativi"]]])
	elif m.fase == "battaglia":
		var q := m.provincia_battaglia()
		var mia := m.forza_effettiva(m.forza_di_lato(q, m.lato(p)), q)
		var righe := []
		for l in m.bersagli_attacco(q, p):
			var loro := m.forza_effettiva(m.forza_di_lato(q, l), q)
			righe.append("contro %s (forza %d) saresti a [b]%s[/b]" % [_nome_g(l), loro, _rapporto(mia, loro)])
		if not righe.is_empty():
			pagine.append("In %s la tua forza è [b]%d[/b]: %s. La Tattica dei capi può spostare ancora la colonna." % [Dati.nome_prov(q), mia, "; ".join(righe)])
	if not pagine.is_empty():
		_saggio(pagine, [], "guida")

## In partita guidata, la prima volta che succede qualcosa di nuovo il Saggio lo commenta.
func _guida_eventi(nuovi: Array) -> void:
	if not tutorial or tut_visti.has("fine"):
		return
	for e in nuovi:
		var t: String = e.get("t", "")
		if tut_visti.has("ev_" + t):
			continue
		if t == "battaglia":
			tut_visti["ev_battaglia"] = true
			var na: String = "gli indigeni" if int(e["a"]) < 0 else m.g[int(e["a"])]["nome"]
			var nb: String = "gli indigeni" if int(e["b"]) < 0 else m.g[int(e["b"])]["nome"]
			_saggio(["Guarda la battaglia in [b]%s[/b]: %s (forza %d) contro %s (forza %d). Il rapporto dà la colonna [b]%s[/b]; il dado fa [b]%d[/b] e la tabella dice [b]%s[/b]: %s." % [Dati.nome_prov(int(e["prov"])), na, int(e["fa"]), nb, int(e["fb"]), e["col"], int(e["dado"]), e["ris"], m._testo_ris(e["ris"], e["grande_a"], na, nb)]], [], "evento")
			continue
		if t == "incantesimo" and tutorial_tipo == "magia" and m.turno <= 3:
			var nome := "%s lancia [i]%s[/i]" % [Dati.nome_unita(int(e["c"])), Dati.INCANTESIMI[e["s"]]["nome"]]
			_saggio([Tutorial.evento_magia(bool(e["ok"]), int(e["dado"]), nome)], [], "evento")
			continue
		var testo := Tutorial.evento(t)
		if testo != "":
			tut_visti["ev_" + t] = true
			_saggio([testo], [], "evento")
