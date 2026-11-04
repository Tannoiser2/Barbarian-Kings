## Tavolo 3D: la mappa originale di Castafon su un tavolo di legno, le miniature (Meshy e modulo TTS),
## la telecamera da girare con il mouse o le dita, e la «regia» che anima movimenti, battaglie e incantesimi.
class_name Plancia3D
extends Node3D

signal provincia_cliccata(p: int)
signal provincia_sopra(p: int)

const LARGH := 30.0
const ALT := 30.0 * 3834.0 / 5790.0

const MODELLO := {
	"re": "re", "eroe": "eroe", "mago": "mago",
	"fanteria_barbara": "barbaro", "legione": "legionario", "arcieri_elfici": "elfo",
	"fanteria_orchesca": "orco", "fanteria_nanica": "nano", "fanteria_feudale": "feudale",
	"flotta_barbara": "flotta_barbara", "cavalleria_barbara": "cavalleria_barbara", "galea": "galea",
	"catafratti": "catafratti", "flotta_elfica": "flotta_elfica", "cavalleria_elfica": "cavalleria_elfica",
	"cavalieri_warg": "cavalieri_warg", "rana_da_guerra": "rana_da_guerra", "popolo_balena": "popolo_balena",
	"aeronave": "aeronave", "flotta_pirata": "flotta_pirata",
}
const ANIMATI := ["re", "eroe", "mago", "barbaro", "legionario", "elfo", "orco", "nano", "feudale"]

var m: Motore
var spettatore := -1          # giocatore dal cui punto di vista si guarda (-1 = tutto ciò che è pubblico)
var velocita := 1.0
var cam: Camera3D
var cam_bersaglio := Vector3.ZERO
var cam_yaw := PI
var cam_pitch := deg_to_rad(52.0)
var cam_dist := 24.0
var _trascina := 0
var _ultimo_mouse := Vector2.ZERO
var _tocchi := {}
var _dist_pizzico := 0.0
var _scena_cache := {}
var _misura_cache := {}
var figure := {}               # id unità -> Node3D
var _id_img: Image
var _evid_img: Image
var _evid_tex: ImageTexture
var _mat_mappa: ShaderMaterial
var _linee: MeshInstance3D
var _bandiere := {}
var _effetti_prov := {}
var _occupato := false
var _coda: Array = []
var _sopra := 0
var _evid_base := {}
var _evid_sel := {}
var _tinta_controllo := false

func _ready() -> void:
	Dati.carica()
	_costruisci_ambiente()
	_costruisci_tavolo()
	_costruisci_mappa()
	_linee = MeshInstance3D.new()
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.vertex_color_use_as_albedo = true
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_linee.material_override = lm
	add_child(_linee)
	cam = Camera3D.new()
	cam.fov = 45.0
	cam.near = 0.1
	cam.far = 200.0
	add_child(cam)
	_aggiorna_cam()

func collega(motore: Motore) -> void:
	m = motore
	sincronizza()

# ---------------------------------------------------------------- scena

func _costruisci_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.05, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.78, 0.68)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-58, -35, 0)
	sole.light_energy = 0.8
	sole.light_color = Color(1.0, 0.95, 0.85)
	sole.shadow_enabled = true
	sole.directional_shadow_max_distance = 60.0
	add_child(sole)
	var luce2 := OmniLight3D.new()
	luce2.position = Vector3(0, 14, 0)
	luce2.omni_range = 40.0
	luce2.light_energy = 0.15
	luce2.light_color = Color(1.0, 0.85, 0.6)
	add_child(luce2)

func _costruisci_tavolo() -> void:
	var tav := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(LARGH + 8, 0.6, ALT + 8)
	tav.mesh = bm
	tav.position = Vector3(0, -0.36, 0)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/legno.gdshader")
	tav.material_override = mat
	add_child(tav)
	# cornice scura attorno alla mappa
	var cor := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(LARGH + 0.6, 0.08, ALT + 0.6)
	cor.mesh = cm
	cor.position = Vector3(0, -0.03, 0)
	var mc := StandardMaterial3D.new()
	mc.albedo_color = Color(0.18, 0.12, 0.07)
	mc.roughness = 0.6
	cor.material_override = mc
	add_child(cor)

func _costruisci_mappa() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(LARGH, ALT)
	mi.mesh = pm
	mi.position = Vector3(0, 0.02, 0)
	_mat_mappa = ShaderMaterial.new()
	_mat_mappa.shader = load("res://scripts/mappa.gdshader")
	_mat_mappa.set_shader_parameter("mappa", load("res://assets/img/mappa.webp"))
	var idt: Texture2D = load("res://assets/img/province_id.png")
	_id_img = idt.get_image()
	_mat_mappa.set_shader_parameter("ids", idt)
	_evid_img = Image.create(64, 1, false, Image.FORMAT_RGBA8)
	_evid_img.fill(Color(0, 0, 0, 0))
	_evid_tex = ImageTexture.create_from_image(_evid_img)
	_mat_mappa.set_shader_parameter("evidenza", _evid_tex)
	mi.material_override = _mat_mappa
	add_child(mi)
	var corpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(LARGH, 0.05, ALT)
	cs.shape = box
	corpo.add_child(cs)
	corpo.position = Vector3(0, 0.0, 0)
	add_child(corpo)

func centro(p: int) -> Vector3:
	var q: Dictionary = Dati.province[p]
	return Vector3((q["x"] - 0.5) * LARGH, 0.05, (q["y"] - 0.5) * ALT)

func provincia_in(pos: Vector3) -> int:
	var u := pos.x / LARGH + 0.5
	var v := pos.z / ALT + 0.5
	if u < 0 or v < 0 or u >= 1 or v >= 1:
		return 0
	var c := _id_img.get_pixel(int(u * _id_img.get_width()), int(v * _id_img.get_height()))
	return int(round(c.r * 255.0))

# ---------------------------------------------------------------- evidenziazione delle province

## base: provincia -> colore (es. mete raggiungibili). sel: provincia -> colore più forte.
func evidenzia(base: Dictionary, sel := {}) -> void:
	_evid_base = base
	_evid_sel = sel
	_ridisegna_evidenza()

func tinta_controllo(attiva: bool) -> void:
	_tinta_controllo = attiva
	_ridisegna_evidenza()

func _ridisegna_evidenza() -> void:
	_evid_img.fill(Color(0, 0, 0, 0))
	if _tinta_controllo and m != null:
		for q in range(1, 48):
			if m.ctrl[q] >= 0:
				var c: Color = Dati.COLORI_RGB[m.ctrl[q]]
				_evid_img.set_pixel(q, 0, Color(c.r, c.g, c.b, 0.30))
	for q in _evid_base:
		var c: Color = _evid_base[q]
		_evid_img.set_pixel(q, 0, c)
	for q in _evid_sel:
		var c: Color = _evid_sel[q]
		_evid_img.set_pixel(q, 0, c)
	if _sopra > 0:
		var c0 := _evid_img.get_pixel(_sopra, 0)
		_evid_img.set_pixel(_sopra, 0, Color(1, 1, 0.85, maxf(c0.a, 0.22)) if c0.a < 0.05 else c0.lightened(0.25))
	_evid_tex.update(_evid_img)

## Linee dei percorsi: lista di {via: [province], colore, partenza}
func disegna_percorsi(lista: Array) -> void:
	var im := ImmediateMesh.new()
	var vuoto := true
	for pr in lista:
		var pts := [centro(pr["partenza"])]
		for q in pr["via"]:
			pts.append(centro(q))
		if pts.size() < 2:
			continue
		vuoto = false
		var col: Color = pr["colore"]
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in pts.size() - 1:
			var a: Vector3 = pts[i] + Vector3(0, 0.12, 0)
			var b: Vector3 = pts[i + 1] + Vector3(0, 0.12, 0)
			var d := (b - a)
			var lato := Vector3(-d.z, 0, d.x).normalized() * 0.09
			for v in [a - lato, a + lato, b + lato, a - lato, b + lato, b - lato]:
				im.surface_set_color(col)
				im.surface_add_vertex(v)
			# punta della freccia sull'ultima tappa
			if i == pts.size() - 2:
				var dir := d.normalized()
				var l2 := Vector3(-dir.z, 0, dir.x) * 0.3
				var punta := b + Vector3(0, 0.01, 0)
				var dietro := b - dir * 0.5
				for v in [dietro - l2, punta, dietro + l2]:
					im.surface_set_color(col.lightened(0.2))
					im.surface_add_vertex(v)
		im.surface_end()
	_linee.mesh = null if vuoto else im

# ---------------------------------------------------------------- telecamera

func _aggiorna_cam() -> void:
	cam_pitch = clampf(cam_pitch, deg_to_rad(18), deg_to_rad(88))
	cam_dist = clampf(cam_dist, 4.0, 42.0)
	cam_bersaglio.x = clampf(cam_bersaglio.x, -LARGH / 2, LARGH / 2)
	cam_bersaglio.z = clampf(cam_bersaglio.z, -ALT / 2, ALT / 2)
	var off := Vector3(cos(cam_pitch) * cos(cam_yaw), sin(cam_pitch), cos(cam_pitch) * sin(cam_yaw)) * cam_dist
	cam.position = cam_bersaglio + off
	cam.look_at(cam_bersaglio, Vector3.UP)

func inquadra(p: int, dist := 12.0) -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(func(k: float):
		cam_bersaglio = cam_bersaglio.lerp(centro(p), k * 0.25)
		cam_dist = lerpf(cam_dist, dist, k * 0.2)
		_aggiorna_cam(), 0.0, 1.0, 0.6 / velocita)

func vista_iniziale() -> void:
	cam_bersaglio = Vector3(0.6, 0, 0)
	cam_yaw = PI
	cam_pitch = deg_to_rad(62)
	cam_dist = 25.0
	_aggiorna_cam()

func _sposta(delta_schermo: Vector2) -> void:
	var avanti := Vector3(-cos(cam_yaw), 0, -sin(cam_yaw))
	var destra := Vector3(-sin(cam_yaw), 0, cos(cam_yaw))
	var k := cam_dist * 0.0016
	cam_bersaglio += (-destra * delta_schermo.x + avanti * delta_schermo.y) * k
	_aggiorna_cam()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_tocchi[e.index] = e.position
		else:
			_tocchi.erase(e.index)
		_dist_pizzico = 0.0
		return
	if e is InputEventScreenDrag:
		_tocchi[e.index] = e.position
		if _tocchi.size() >= 2:
			var k := _tocchi.keys()
			var d: float = (_tocchi[k[0]] as Vector2).distance_to(_tocchi[k[1]])
			if _dist_pizzico > 0:
				cam_dist *= _dist_pizzico / maxf(d, 1.0)
				_aggiorna_cam()
			_dist_pizzico = d
		return
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			cam_dist *= 0.9
			_aggiorna_cam()
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			cam_dist *= 1.1
			_aggiorna_cam()
		elif e.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_trascina = e.button_index if e.pressed else 0
			_ultimo_mouse = e.position
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_trascina = MOUSE_BUTTON_LEFT
				_ultimo_mouse = e.position
				set_meta("giu", e.position)
			else:
				var giu: Vector2 = get_meta("giu", e.position)
				_trascina = 0
				if giu.distance_to(e.position) < 8:
					var p := _provincia_sotto(e.position)
					if p > 0:
						provincia_cliccata.emit(p)
	elif e is InputEventMouseMotion:
		if _trascina == MOUSE_BUTTON_RIGHT:
			cam_yaw += e.relative.x * 0.006
			cam_pitch += e.relative.y * 0.005
			_aggiorna_cam()
		elif _trascina == MOUSE_BUTTON_MIDDLE or (_trascina == MOUSE_BUTTON_LEFT and get_meta("giu", e.position).distance_to(e.position) > 8):
			_sposta(e.relative)
		else:
			var p := _provincia_sotto(e.position)
			if p != _sopra:
				_sopra = p
				_ridisegna_evidenza()
				provincia_sopra.emit(p)
	elif e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_W, KEY_UP: _sposta(Vector2(0, 40))
			KEY_S, KEY_DOWN: _sposta(Vector2(0, -40))
			KEY_A, KEY_LEFT: _sposta(Vector2(40, 0))
			KEY_D, KEY_RIGHT: _sposta(Vector2(-40, 0))
			KEY_Q: cam_yaw -= 0.15; _aggiorna_cam()
			KEY_E: cam_yaw += 0.15; _aggiorna_cam()

func _provincia_sotto(pos: Vector2) -> int:
	var o := cam.project_ray_origin(pos)
	var d := cam.project_ray_normal(pos)
	if absf(d.y) < 0.0001:
		return 0
	var t := -(o.y - 0.02) / d.y
	if t < 0:
		return 0
	return provincia_in(o + d * t)

# ---------------------------------------------------------------- miniature

func _carica_modello(tipo: String) -> Node3D:
	var nome: String = MODELLO.get(tipo, "")
	if nome == "":
		return Node3D.new()
	if not _scena_cache.has(nome):
		_scena_cache[nome] = load("res://assets/modelli/%s.glb" % nome)
	var ps: PackedScene = _scena_cache[nome]
	var n3: Node3D = ps.instantiate()
	return n3

func _aabb(n3: Node) -> AABB:
	var tot := AABB()
	var primo := true
	for c in n3.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = c
		if mi.mesh == null:
			continue
		var b: AABB = _trasf_relativa(mi, n3) * mi.mesh.get_aabb()
		if primo:
			tot = b
			primo = false
		else:
			tot = tot.merge(b)
	return tot

func _trasf_relativa(n: Node3D, radice: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var x: Node = n
	while x != null and x != radice:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t

func _altezza_tipo(tipo: String) -> float:
	var c: String = Dati.tipi[tipo]["classe"]
	match c:
		"capo", "mago": return 0.78
		"fanteria": return 0.66
		"cavalleria": return 0.75
		"flotta": return 0.55
		"aeronave": return 0.55
		"balena": return 0.4
		"rana": return 0.45
	return 0.5

## Crea la miniatura di un'unità: modello scalato, basetta col colore del proprietario.
func _crea_figura(id: int) -> Node3D:
	var tipo: String = Dati.unita[id]["tipo"]
	var radice := Node3D.new()
	radice.name = "U%d" % id
	var mod := _carica_modello(tipo)
	var cont := Node3D.new()
	cont.name = "Modello"
	cont.add_child(mod)
	radice.add_child(cont)
	var nome: String = MODELLO.get(tipo, "")
	if not _misura_cache.has(nome):
		# le figure di Meshy sono riggate a 1,7 m con l'origine ai piedi: le dimensioni della mesh
		# non tengono conto dello scheletro, quindi si usa la misura nota
		var b := AABB(Vector3(-0.4, 0, -0.4), Vector3(0.8, 1.7, 0.8)) if nome in ANIMATI else _aabb(mod)
		_misura_cache[nome] = b
	var bb: AABB = _misura_cache[nome]
	var classe: String = Dati.tipi[tipo]["classe"]
	var lungo := maxf(bb.size.y, 0.001)
	if classe in ["flotta", "balena", "aeronave", "cavalleria", "rana"]:
		lungo = maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
	var s := _altezza_tipo(tipo) / lungo
	mod.scale = Vector3.ONE * s
	mod.position = Vector3(-(bb.position.x + bb.size.x / 2) * s, -bb.position.y * s + 0.05, -(bb.position.z + bb.size.z / 2) * s)
	if classe == "aeronave":
		mod.position.y += 0.55
	# basetta
	var base := MeshInstance3D.new()
	base.name = "Base"
	var cy := CylinderMesh.new()
	cy.top_radius = 0.16 if classe in ["capo", "mago", "fanteria", "rana"] else 0.22
	cy.bottom_radius = cy.top_radius + 0.015
	cy.height = 0.05
	cy.radial_segments = 20
	base.mesh = cy
	base.position = Vector3(0, 0.025, 0)
	radice.add_child(base)
	var anello := MeshInstance3D.new()
	anello.name = "Anello"
	var tm := TorusMesh.new()
	tm.inner_radius = cy.top_radius - 0.02
	tm.outer_radius = cy.top_radius + 0.035
	tm.rings = 24
	tm.ring_segments = 6
	anello.mesh = tm
	anello.position = Vector3(0, 0.03, 0)
	anello.scale = Vector3(1, 0.35, 1)
	radice.add_child(anello)
	_avvia_posa(radice)
	return radice

func _anim(f: Node3D) -> AnimationPlayer:
	var l := f.find_children("*", "AnimationPlayer", true, false)
	return l[0] if not l.is_empty() else null

func _avvia_posa(f: Node3D) -> void:
	var ap := _anim(f)
	if ap == null:
		return
	if ap.has_animation("cammina"):
		ap.get_animation("cammina").loop_mode = Animation.LOOP_LINEAR
	if ap.has_animation("corsa"):
		ap.get_animation("corsa").loop_mode = Animation.LOOP_LINEAR
	_posa_ferma(f)

func _posa_ferma(f: Node3D) -> void:
	var ap := _anim(f)
	if ap == null:
		return
	if ap.has_animation("cammina"):
		ap.play("cammina")
		ap.seek(0.42, true)
		ap.pause()

func _colora(f: Node3D, id: int) -> void:
	var s: Dictionary = m.u[id]
	var o: int = s["own"]
	var c: Color = Dati.COLORE_NEUTRALE if o < 0 else Dati.COLORI_RGB[o]
	var base: MeshInstance3D = f.get_node("Base")
	var mb := StandardMaterial3D.new()
	mb.albedo_color = c.darkened(0.15)
	mb.roughness = 0.5
	mb.metallic = 0.2
	base.material_override = mb
	var an: MeshInstance3D = f.get_node("Anello")
	var ma := StandardMaterial3D.new()
	ma.albedo_color = c.lightened(0.2)
	ma.emission_enabled = true
	ma.emission = c
	ma.emission_energy_multiplier = 0.6
	if s["zombie"]:
		ma.albedo_color = Color(0.35, 0.9, 0.35)
		ma.emission = Color(0.2, 0.8, 0.2)
	an.material_override = ma
	# illusioni e invisibili: visti in trasparenza solo dal loro proprietario
	var fantasma: bool = (s["illus"] or s["invis"]) and o == spettatore
	_trasparenza(f, 0.45 if fantasma else 1.0)

func _trasparenza(f: Node3D, a: float) -> void:
	for c in f.get_node("Modello").find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = c
		mi.transparency = 1.0 - a

## Posizioni delle miniature in una provincia: a gruppi per proprietario, a spirale attorno al centro.
func posizioni(p: int) -> Dictionary:
	var ids := []
	for id in m.unita_in(p):
		if m.visibile_a(id, spettatore):
			ids.append(id)
	ids.sort_custom(func(a, b):
		var oa: int = m.u[a]["own"]
		var ob: int = m.u[b]["own"]
		if oa != ob:
			return oa < ob
		var ca := 0 if Dati.classe(a) in ["capo", "mago"] else 1
		var cb := 0 if Dati.classe(b) in ["capo", "mago"] else 1
		if ca != cb:
			return ca < cb
		return a < b)
	var out := {}
	var c := centro(p)
	var passo := 0.36
	for i in ids.size():
		var off := Vector3.ZERO
		if i > 0:
			var ang := i * 2.39996
			var r := passo * sqrt(float(i)) * 0.95
			off = Vector3(cos(ang) * r, 0, sin(ang) * r)
		out[ids[i]] = c + off
	return out

func sincronizza() -> void:
	if m == null:
		return
	var vive := {}
	for p in range(1, 48):
		var pos := posizioni(p)
		for id in pos:
			vive[id] = true
			var f: Node3D = figure.get(id)
			if f == null:
				f = _crea_figura(id)
				add_child(f)
				figure[id] = f
			f.position = pos[id]
			f.visible = true
			_colora(f, id)
			var cap: bool = m.u[id]["catt"] != -9
			f.rotation.z = 1.4 if cap else 0.0
	for id in figure.keys():
		if not vive.has(id):
			figure[id].queue_free()
			figure.erase(id)
	_aggiorna_bandiere()
	_ridisegna_evidenza()

## Piccoli stendardi del proprietario su ogni provincia controllata.
func _aggiorna_bandiere() -> void:
	for q in range(1, 48):
		var o: int = m.ctrl[q]
		var b: Node3D = _bandiere.get(q)
		if o < 0:
			if b != null:
				b.queue_free()
				_bandiere.erase(q)
			continue
		if b == null:
			b = _crea_bandiera()
			add_child(b)
			_bandiere[q] = b
		b.position = centro(q) + Vector3(0.55, 0, -0.55)
		b.rotation.y = -PI / 2.0
		var tela: MeshInstance3D = b.get_node("Tela")
		var mt := StandardMaterial3D.new()
		mt.albedo_color = Dati.COLORI_RGB[o]
		mt.cull_mode = BaseMaterial3D.CULL_DISABLED
		mt.roughness = 0.8
		tela.material_override = mt

func _crea_bandiera() -> Node3D:
	var b := Node3D.new()
	var asta := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.012
	cm.bottom_radius = 0.015
	cm.height = 0.55
	asta.mesh = cm
	asta.position = Vector3(0, 0.275, 0)
	var ma := StandardMaterial3D.new()
	ma.albedo_color = Color(0.35, 0.25, 0.12)
	asta.material_override = ma
	b.add_child(asta)
	var tela := MeshInstance3D.new()
	tela.name = "Tela"
	var qm := QuadMesh.new()
	qm.size = Vector2(0.34, 0.22)
	tela.mesh = qm
	tela.position = Vector3(0.17, 0.48, 0)
	b.add_child(tela)
	return b

# ---------------------------------------------------------------- regia degli eventi

func accoda(eventi: Array) -> void:
	_coda.append_array(eventi)
	if not _occupato:
		_esegui_coda()

func occupata() -> bool:
	return _occupato or not _coda.is_empty()

signal regia_finita

func _esegui_coda() -> void:
	_occupato = true
	while not _coda.is_empty():
		var e: Dictionary = _coda.pop_front()
		match e["t"]:
			"muovi":
				# tutti i movimenti dello stesso istante partono insieme
				var gruppo := [e]
				while not _coda.is_empty() and _coda[0]["t"] == "muovi" and _coda[0].get("T", -1) == e.get("T", -2):
					gruppo.append(_coda.pop_front())
				await _anima_movimenti(gruppo)
			"ritirata":
				await _anima_movimenti([e])
			"battaglia":
				await _anima_battaglia(e)
			"morte", "eliminata":
				await _anima_morte(e)
			"arrivo":
				_anima_arrivo(e)
			"incantesimo":
				await _anima_incantesimo(e)
			"effetto":
				_effetto_persistente(e["s"], e["prov"])
			"maledizione":
				await _anima_maledizione(e)
			"resurrezione":
				await _anima_resurrezione(e)
			"cattura":
				await _attesa(0.3)
			"controllo":
				_aggiorna_bandiere_dopo()
			"tasse":
				_anima_tasse(e)
			"turno":
				_pulisci_effetti()
	_occupato = false
	sincronizza()
	regia_finita.emit()

func _attesa(s: float) -> void:
	await get_tree().create_timer(s / velocita).timeout

func _aggiorna_bandiere_dopo() -> void:
	if m != null:
		_aggiorna_bandiere()

func _anima_movimenti(lista: Array) -> void:
	var dur := 0.9 / velocita
	var tw := create_tween().set_parallel(true)
	var qualcosa := false
	for e in lista:
		var ids: Array = e["ids"]
		var a: int = e["a"]
		var da: int = e["da"]
		var arrivo := centro(a)
		var k := 0
		for id in ids:
			var f: Node3D = figure.get(id)
			if f == null or not m.visibile_a(id, spettatore):
				continue
			qualcosa = true
			var ang := k * 2.39996
			var r := 0.36 * sqrt(float(k)) * 0.95
			var meta := arrivo + Vector3(cos(ang) * r, 0, sin(ang) * r)
			k += 1
			var dir := meta - f.position
			if dir.length() > 0.01:
				var giro := atan2(dir.x, dir.z)
				f.rotation.y = giro
			var ap := _anim(f)
			if ap != null and ap.has_animation("corsa"):
				ap.play("corsa", 0.1, 1.2 * velocita)
			else:
				# miniature senza scheletro: un piccolo saltello lungo la strada
				var mod: Node3D = f.get_node("Modello")
				var tb := create_tween()
				tb.tween_property(mod, "position:y", 0.12, dur / 4).set_trans(Tween.TRANS_SINE)
				tb.tween_property(mod, "position:y", 0.0, dur / 4).set_trans(Tween.TRANS_SINE)
				tb.tween_property(mod, "position:y", 0.12, dur / 4).set_trans(Tween.TRANS_SINE)
				tb.tween_property(mod, "position:y", 0.0, dur / 4).set_trans(Tween.TRANS_SINE)
			tw.tween_property(f, "position", meta, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_polvere(f.position)
		if a > 0 and da > 0 and Dati.is_mare(a) != Dati.is_mare(da):
			_spruzzo(arrivo)
	if not qualcosa:
		tw.kill()
		return
	await tw.finished
	for e in lista:
		for id in e["ids"]:
			var f: Node3D = figure.get(id)
			if f != null:
				_posa_ferma(f)

func _anima_battaglia(e: Dictionary) -> void:
	var q: int = e["prov"]
	inquadra(q, 9.0)
	await _attesa(0.5)
	var c := centro(q)
	var lati := [e["ids_a"], e["ids_b"]]
	var tw := create_tween().set_parallel(true)
	var centri := []
	for l in 2:
		var cc := Vector3.ZERO
		var nn := 0
		for id in lati[l]:
			var f: Node3D = figure.get(id)
			if f != null:
				cc += f.position
				nn += 1
		centri.append(cc / maxf(nn, 1))
	for l in 2:
		for id in lati[l]:
			var f: Node3D = figure.get(id)
			if f == null:
				continue
			var verso: Vector3 = centri[1 - l]
			var dir := verso - f.position
			f.rotation.y = atan2(dir.x, dir.z)
			var ap := _anim(f)
			if ap != null and ap.has_animation("attacco"):
				ap.play("attacco", 0.1, 1.1 * velocita)
			else:
				var mod: Node3D = f.get_node("Modello")
				var t2 := create_tween()
				t2.tween_property(mod, "position", Vector3(0, 0.05, 0) + Vector3(0, 0, 0.12), 0.18 / velocita)
				t2.tween_property(mod, "position", Vector3.ZERO, 0.25 / velocita)
				t2.tween_property(mod, "position", Vector3(0, 0.05, 0.12), 0.18 / velocita)
				t2.tween_property(mod, "position", Vector3.ZERO, 0.25 / velocita)
			tw.tween_property(f, "position", f.position.lerp(c, 0.18), 0.4 / velocita)
	_scintille(c + Vector3(0, 0.3, 0), 1.3)
	_lampo(c + Vector3(0, 1.2, 0), Color(1.0, 0.7, 0.3), 1.2)
	_etichetta(c + Vector3(0, 1.4, 0), "%s   dado %d" % [e["col"], e["dado"]], Color(1, 0.92, 0.7), 2.2)
	await _attesa(1.6)
	for l in 2:
		for id in lati[l]:
			var f: Node3D = figure.get(id)
			if f != null:
				_posa_ferma(f)

func _anima_morte(e: Dictionary) -> void:
	var id: int = e["id"]
	var f: Node3D = figure.get(id)
	if f == null:
		return
	figure.erase(id)
	var ap := _anim(f)
	var tw := create_tween()
	if ap != null and ap.has_animation("morte"):
		ap.play("morte", 0.1, 1.3 * velocita)
		tw.tween_interval(0.9 / velocita)
	else:
		tw.tween_property(f, "rotation:z", 1.5, 0.45 / velocita).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(f, "position:y", -0.6, 0.6 / velocita)
	tw.tween_callback(f.queue_free)
	_fumo(f.position + Vector3(0, 0.2, 0), Color(0.3, 0.28, 0.25, 0.8))
	await _attesa(0.35)

func _anima_arrivo(e: Dictionary) -> void:
	var id: int = e["id"]
	if not m.visibile_a(id, spettatore) or figure.has(id):
		return
	var f := _crea_figura(id)
	add_child(f)
	figure[id] = f
	var pos: Dictionary = posizioni(e["prov"])
	f.position = pos.get(id, centro(e["prov"]))
	_colora(f, id)
	f.scale = Vector3.ONE * 0.01
	var tw := create_tween()
	tw.tween_property(f, "scale", Vector3.ONE, 0.45 / velocita).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_polvere(f.position)

func _anima_incantesimo(e: Dictionary) -> void:
	var c: int = e["c"]
	var f: Node3D = figure.get(c)
	var pos := centro(e["prov"]) if e["prov"] > 0 else Vector3.ZERO
	if f != null:
		pos = f.position
		var ap := _anim(f)
		if ap != null and ap.has_animation("incantesimo"):
			ap.play("incantesimo", 0.1, 1.2 * velocita)
		elif ap != null and ap.has_animation("attacco"):
			ap.play("attacco", 0.1, 1.0 * velocita)
	var col := _colore_ramo(Dati.INCANTESIMI[e["s"]]["ramo"])
	_aura(pos, col, 1.4)
	if not e["ok"]:
		_etichetta(pos + Vector3(0, 1.0, 0), "fallito", Color(0.8, 0.7, 0.6), 1.5)
	await _attesa(0.9)
	if f != null:
		_posa_ferma(f)

func _colore_ramo(r: String) -> Color:
	match r:
		"mente": return Color(0.55, 0.65, 1.0)
		"elementi": return Color(0.4, 0.85, 1.0)
		"illusione": return Color(0.95, 0.6, 1.0)
		"necromanzia": return Color(0.5, 1.0, 0.35)
	return Color.WHITE

func _anima_maledizione(e: Dictionary) -> void:
	var f: Node3D = figure.get(e["id"])
	var pos := f.position if f != null else centro(e["prov"])
	_fulmine(pos, Color(0.6, 1.0, 0.4))
	await _attesa(0.5)

func _anima_resurrezione(e: Dictionary) -> void:
	var c := centro(e["prov"])
	inquadra(e["prov"], 9.0)
	_nebbia(c, Color(0.35, 1.0, 0.4, 0.6), 3.0)
	_lampo(c + Vector3(0, 0.8, 0), Color(0.3, 1.0, 0.3), 2.5)
	await _attesa(1.2)

func _anima_tasse(e: Dictionary) -> void:
	if e["q"] <= 0:
		return
	var re: int = m.g[e["p"]]["re"]
	var f: Node3D = figure.get(re)
	if f == null:
		return
	_etichetta(f.position + Vector3(0, 1.0, 0), "+%d" % e["q"], Color(1.0, 0.85, 0.3), 2.0)
	_monete(f.position + Vector3(0, 0.6, 0))

# ---------------------------------------------------------------- effetti speciali (particelle CPU, vanno anche sul web)

func _particelle(pos: Vector3, n: int, colore: Color, vita: float, vel: float, grav: Vector3, dim: float, uno_scatto := true) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = n
	p.lifetime = vita
	p.one_shot = uno_scatto
	p.explosiveness = 0.85 if uno_scatto else 0.0
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = vel * 0.5
	p.initial_velocity_max = vel
	p.gravity = grav
	p.scale_amount_min = dim * 0.6
	p.scale_amount_max = dim
	var qm := QuadMesh.new()
	qm.size = Vector2(0.1, 0.1)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = _tex_punto()
	mat.vertex_color_use_as_albedo = true
	qm.material = mat
	p.mesh = qm
	var g := Gradient.new()
	g.set_color(0, colore)
	g.set_color(1, Color(colore.r, colore.g, colore.b, 0.0))
	p.color_ramp = g
	add_child(p)
	p.emitting = true
	if uno_scatto:
		get_tree().create_timer(vita + 0.5).timeout.connect(p.queue_free)
	return p

var _punto: Texture2D
func _tex_punto() -> Texture2D:
	if _punto == null:
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var d := Vector2(x - 15.5, y - 15.5).length() / 15.5
				var a := clampf(1.0 - d, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a * a))
		_punto = ImageTexture.create_from_image(img)
	return _punto

func _polvere(pos: Vector3) -> void:
	_particelle(pos + Vector3(0, 0.05, 0), 10, Color(0.75, 0.65, 0.5, 0.7), 0.7, 0.6, Vector3(0, -0.4, 0), 1.6)

func _spruzzo(pos: Vector3) -> void:
	_particelle(pos + Vector3(0, 0.05, 0), 24, Color(0.7, 0.85, 1.0, 0.9), 0.9, 1.8, Vector3(0, -4, 0), 0.9)

func _scintille(pos: Vector3, forza: float) -> void:
	_particelle(pos, int(40 * forza), Color(1.0, 0.75, 0.3, 1.0), 0.7, 2.5 * forza, Vector3(0, -5, 0), 0.6)

func _fumo(pos: Vector3, c: Color) -> void:
	_particelle(pos, 16, c, 1.2, 0.5, Vector3(0, 0.6, 0), 3.0)

func _monete(pos: Vector3) -> void:
	_particelle(pos, 18, Color(1.0, 0.82, 0.25, 1.0), 1.0, 1.6, Vector3(0, -3, 0), 0.8)

func _aura(pos: Vector3, c: Color, durata: float) -> void:
	var p := _particelle(pos + Vector3(0, 0.1, 0), 40, Color(c.r, c.g, c.b, 0.9), durata, 1.0, Vector3(0, 1.2, 0), 1.2)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.35
	p.emission_ring_inner_radius = 0.25
	p.emission_ring_height = 0.02
	_lampo(pos + Vector3(0, 0.6, 0), c, durata)

func _nebbia(pos: Vector3, c: Color, durata: float) -> void:
	var p := _particelle(pos, 60, c, durata, 0.4, Vector3(0, 0.5, 0), 4.0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.8

func _lampo(pos: Vector3, c: Color, durata: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = c
	l.omni_range = 4.0
	l.light_energy = 3.0
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 0.0, durata / velocita)
	tw.tween_callback(l.queue_free)

func _fulmine(pos: Vector3, c: Color) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var p0 := pos + Vector3(0, 5, 0)
	var prec := p0
	for i in 8:
		var k := float(i + 1) / 8.0
		var nx := pos + Vector3(randf_range(-0.3, 0.3) * (1 - k), 5 * (1 - k) + 0.3, randf_range(-0.3, 0.3) * (1 - k))
		var lato := Vector3(0.05, 0, 0.05)
		for v in [prec - lato, prec + lato, nx + lato, prec - lato, nx + lato, nx - lato]:
			im.surface_set_color(c)
			im.surface_add_vertex(v)
		prec = nx
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	add_child(mi)
	_lampo(pos + Vector3(0, 1, 0), c, 0.8)
	_scintille(pos + Vector3(0, 0.3, 0), 0.8)
	var tw := create_tween()
	tw.tween_interval(0.35 / velocita)
	tw.tween_callback(mi.queue_free)

func _etichetta(pos: Vector3, testo: String, c: Color, durata: float) -> void:
	var l := Label3D.new()
	l.text = testo
	l.font = load("res://assets/font/FellMaiuscoletto.ttf")
	l.font_size = 64
	l.pixel_size = 0.006
	l.modulate = c
	l.outline_size = 12
	l.outline_modulate = Color(0.1, 0.06, 0.03)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y + 0.6, durata / velocita)
	tw.tween_property(l, "modulate:a", 0.0, durata / velocita).set_delay(durata * 0.5 / velocita)
	tw.chain().tween_callback(l.queue_free)

## Effetti che restano sulla provincia per tutto l'anno (tempeste, gelo, alluvioni, tornado).
func _effetto_persistente(s: String, q: int) -> void:
	var c := centro(q)
	var radice := Node3D.new()
	radice.position = c
	add_child(radice)
	if not _effetti_prov.has(q):
		_effetti_prov[q] = []
	_effetti_prov[q].append(radice)
	match s:
		"tornado":
			for i in 3:
				var p := _particelle(Vector3.ZERO, 50, Color(0.75, 0.7, 0.6, 0.55), 1.6, 0.5, Vector3(0, 1.8, 0), 2.4, false)
				p.reparent(radice, false)
				p.position = Vector3(0, i * 0.15, 0)
				p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
				p.emission_ring_axis = Vector3.UP
				p.emission_ring_radius = 0.2 + i * 0.25
				p.emission_ring_inner_radius = 0.1 + i * 0.2
				p.emission_ring_height = 0.05
				p.orbit_velocity_min = 1.2
				p.orbit_velocity_max = 1.6
			_lampo(c + Vector3(0, 1, 0), Color(0.8, 0.8, 0.7), 1.5)
		"tempesta_mari", "tempesta_monti":
			var p := _particelle(Vector3(0, 2.2, 0), 120, Color(0.7, 0.8, 1.0, 0.6), 0.8, 0.2, Vector3(0, -9, 0), 0.7, false)
			p.reparent(radice, false)
			p.position = Vector3(0, 2.2, 0)
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			p.emission_box_extents = Vector3(1.2, 0.1, 1.2)
			var nube := _particelle(Vector3(0, 2.4, 0), 30, Color(0.35, 0.37, 0.42, 0.7), 2.0, 0.1, Vector3.ZERO, 6.0, false)
			nube.reparent(radice, false)
			nube.position = Vector3(0, 2.4, 0)
			nube.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			nube.emission_box_extents = Vector3(1.0, 0.1, 1.0)
			_fulmine(c, Color(0.8, 0.9, 1.0))
		"gelo":
			var disco := MeshInstance3D.new()
			var cy := CylinderMesh.new()
			cy.top_radius = 1.5
			cy.bottom_radius = 1.5
			cy.height = 0.03
			disco.mesh = cy
			var mt := StandardMaterial3D.new()
			mt.albedo_color = Color(0.85, 0.95, 1.0, 0.55)
			mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mt.metallic = 0.4
			mt.roughness = 0.1
			disco.material_override = mt
			disco.position = Vector3(0, 0.06, 0)
			disco.scale = Vector3(0.01, 1, 0.01)
			radice.add_child(disco)
			create_tween().tween_property(disco, "scale", Vector3.ONE, 1.0 / velocita)
			var neve := _particelle(Vector3(0, 2, 0), 60, Color(1, 1, 1, 0.8), 2.5, 0.1, Vector3(0, -0.8, 0), 0.6, false)
			neve.reparent(radice, false)
			neve.position = Vector3(0, 2, 0)
			neve.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			neve.emission_box_extents = Vector3(1.3, 0.1, 1.3)
		"alluvione":
			var acqua := MeshInstance3D.new()
			var cy2 := CylinderMesh.new()
			cy2.top_radius = 1.4
			cy2.bottom_radius = 1.4
			cy2.height = 0.02
			acqua.mesh = cy2
			var ma := StandardMaterial3D.new()
			ma.albedo_color = Color(0.2, 0.45, 0.75, 0.6)
			ma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ma.roughness = 0.05
			ma.metallic = 0.3
			acqua.material_override = ma
			acqua.position = Vector3(0, 0.0, 0)
			radice.add_child(acqua)
			create_tween().tween_property(acqua, "position:y", 0.16, 1.2 / velocita)
			_spruzzo(c)
		"controllo":
			_aura(c, Color(0.55, 0.65, 1.0), 2.0)

func _pulisci_effetti() -> void:
	for q in _effetti_prov:
		for n3 in _effetti_prov[q]:
			if is_instance_valid(n3):
				var tw := create_tween()
				tw.tween_property(n3, "scale", Vector3.ONE * 0.01, 0.5)
				tw.tween_callback(n3.queue_free)
	_effetti_prov = {}

## Fotografia: rende il tavolo in un'immagine (per le prove automatiche).
func foto(percorso: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(percorso)
