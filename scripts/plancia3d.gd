## Tavolo 3D: la mappa originale di Castafon su un tavolo di legno, le miniature (Meshy e modulo TTS),
## la telecamera da girare con il mouse o le dita, e la «regia» che anima movimenti, battaglie e incantesimi.
class_name Plancia3D
extends Node3D

signal provincia_cliccata(p: int)
signal provincia_sopra(p: int)
## Chiede all'interfaccia di mostrare la carta illustrata di un incantesimo o di un'azione.
signal carta(chiave: String, esito: String)

## Due mappe: «moderna» (dipinta, verticale, con rilievo e foreste 3D) e «originale» (la mappa SPI del 1980).
var modalita := "moderna"
## «3d»: miniature; «pedine»: le pedine di cartone originali, in pile come sul tavolo.
var stile := "3d"
var LARGH := 20.0
var ALT := 20.0 * 1541.0 / 1021.0
var _rilievo: Image
var _hmax := 1.0
var _nodo_mappa: Node3D

const MODELLO := {
	"re": "re", "eroe": "eroe", "mago": "mago",
	"fanteria_barbara": "barbaro", "legione": "legionario", "arcieri_elfici": "elfo",
	"fanteria_orchesca": "orco", "fanteria_nanica": "nano", "fanteria_feudale": "feudale",
	"flotta_barbara": "meshy_nave", "cavalleria_barbara": "cavalleria_barbara", "galea": "galea",
	"catafratti": "catafratti", "flotta_elfica": "meshy_nave", "cavalleria_elfica": "cavalleria_elfica",
	"cavalieri_warg": "cavalieri_warg", "rana_da_guerra": "meshy_rana", "popolo_balena": "meshy_balena",
	"aeronave": "meshy_aeronave", "flotta_pirata": "meshy_nave",
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
	_nodo_mappa.add_child(tav)
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
	_nodo_mappa.add_child(cor)

## Cambia mappa (moderna/originale) e ricostruisce tavolo, rilievo e miniature.
func imposta_stile(st: String) -> void:
	stile = st
	for id in figure.keys():
		figure[id].queue_free()
	figure = {}
	if m != null:
		sincronizza()

## Cambia la grafica delle pedine di cartone ("spi" o "illustrate") e le ridisegna.
func imposta_grafica(g: String) -> void:
	Dati.grafica_pedine = g
	if stile == "pedine":
		imposta_stile("pedine")

func imposta_mappa(mod: String) -> void:
	modalita = mod
	_costruisci_mappa()
	vista_iniziale()
	for id in figure.keys():
		figure[id].queue_free()
	figure = {}
	for q in _bandiere:
		_bandiere[q].queue_free()
	_bandiere = {}
	if m != null:
		sincronizza()

func _costruisci_mappa() -> void:
	if _nodo_mappa != null:
		_nodo_mappa.queue_free()
	_nodo_mappa = Node3D.new()
	_nodo_mappa.name = "Mappa"
	add_child(_nodo_mappa)
	if modalita == "moderna":
		LARGH = 20.0
		ALT = 20.0 * 1541.0 / 1021.0
	else:
		LARGH = 30.0
		ALT = 30.0 * 3834.0 / 5790.0
	_costruisci_tavolo()
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(LARGH, ALT)
	_mat_mappa = ShaderMaterial.new()
	var idt: Texture2D
	if modalita == "moderna":
		pm.subdivide_width = 220
		pm.subdivide_depth = 335
		_mat_mappa.shader = load("res://scripts/terreno.gdshader")
		_mat_mappa.set_shader_parameter("mappa", load("res://assets/img/mappa_moderna.webp"))
		var ril: Texture2D = load("res://assets/img/rilievo.png")
		_rilievo = ril.get_image()
		_rilievo.decompress()
		_mat_mappa.set_shader_parameter("rilievo", ril)
		var veg = JSON.parse_string(FileAccess.get_file_as_string("res://assets/dati/vegetazione.json"))
		_hmax = float(veg["hmax"])
		_mat_mappa.set_shader_parameter("altezza", _hmax)
		_mat_mappa.set_shader_parameter("dim", Vector2(LARGH, ALT))
		_mat_mappa.set_shader_parameter("passo", Vector2(1.0 / _rilievo.get_width(), 1.0 / _rilievo.get_height()))
		idt = load("res://assets/img/province_id_moderna.png")
	else:
		_rilievo = null
		_mat_mappa.shader = load("res://scripts/mappa.gdshader")
		_mat_mappa.set_shader_parameter("mappa", load("res://assets/img/mappa.webp"))
		idt = load("res://assets/img/province_id.png")
	mi.mesh = pm
	mi.position = Vector3(0, 0.02, 0)
	_id_img = idt.get_image()
	_id_img.decompress()
	_mat_mappa.set_shader_parameter("ids", idt)
	_evid_img = Image.create(64, 1, false, Image.FORMAT_RGBA8)
	_evid_img.fill(Color(0, 0, 0, 0))
	_evid_tex = ImageTexture.create_from_image(_evid_img)
	_mat_mappa.set_shader_parameter("evidenza", _evid_tex)
	mi.material_override = _mat_mappa
	_nodo_mappa.add_child(mi)
	if modalita == "moderna":
		_costruisci_vegetazione()
		_costruisci_scritte()

## Altezza del terreno in un punto del tavolo (0 sulla mappa originale, piatta).
func altezza(pos: Vector3) -> float:
	if _rilievo == null:
		return 0.0
	var u := clampf(pos.x / LARGH + 0.5, 0.0, 0.9999)
	var v := clampf(pos.z / ALT + 0.5, 0.0, 0.9999)
	var fx := u * (_rilievo.get_width() - 1)
	var fy := v * (_rilievo.get_height() - 1)
	var x0 := int(fx)
	var y0 := int(fy)
	var tx := fx - x0
	var ty := fy - y0
	var x1 := mini(x0 + 1, _rilievo.get_width() - 1)
	var y1 := mini(y0 + 1, _rilievo.get_height() - 1)
	var a := lerpf(_rilievo.get_pixel(x0, y0).r, _rilievo.get_pixel(x1, y0).r, tx)
	var b := lerpf(_rilievo.get_pixel(x0, y1).r, _rilievo.get_pixel(x1, y1).r, tx)
	return lerpf(a, b, ty) * _hmax + 0.02

func a_terra(pos: Vector3) -> Vector3:
	return Vector3(pos.x, altezza(pos), pos.z)

## Foreste di alberi 3D (due varietà) e canneti nelle paludi, disegnati in un colpo solo con MultiMesh.
func _costruisci_vegetazione() -> void:
	var veg = JSON.parse_string(FileAccess.get_file_as_string("res://assets/dati/vegetazione.json"))
	var ancore := []
	for q in Dati.province:
		var pr: Dictionary = Dati.province[q]
		ancore.append(Vector2((pr["mx"] - 0.5) * LARGH, (pr["my"] - 0.5) * ALT))
	var gruppi := [[], []]
	for a in veg["alberi"]:
		var pos := Vector3((float(a[0]) - 0.5) * LARGH, 0, (float(a[1]) - 0.5) * ALT)
		var libero := true
		for c in ancore:
			if (c as Vector2).distance_to(Vector2(pos.x, pos.z)) < 0.85:
				libero = false
				break
		if libero:
			gruppi[int(a[3]) % 2].append([pos, float(a[2]), int(a[3])])
	var mesh_tipi := [_mesh_abete(), _mesh_latifoglia()]
	for k in 2:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh_tipi[k]
		mm.instance_count = gruppi[k].size()
		for i in gruppi[k].size():
			var e: Array = gruppi[k][i]
			var pos: Vector3 = e[0]
			pos.y = altezza(pos) - 0.01
			var s: float = e[1] * (0.16 if k == 0 else 0.13)
			var b := Basis(Vector3.UP, float(i) * 1.7).scaled(Vector3(s, s * randf_range(0.9, 1.25), s))
			mm.set_instance_transform(i, Transform3D(b, pos))
			var tinte := [Color(0.85, 1.0, 0.85), Color(1.0, 1.0, 0.8), Color(0.75, 0.9, 0.7), Color(1.05, 0.95, 0.75)]
			mm.set_instance_color(i, tinte[e[2] % 4])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.9
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_nodo_mappa.add_child(mmi)
	# canneti
	var mm2 := MultiMesh.new()
	mm2.transform_format = MultiMesh.TRANSFORM_3D
	mm2.mesh = _mesh_canna()
	mm2.instance_count = veg["canne"].size()
	for i in veg["canne"].size():
		var a: Array = veg["canne"][i]
		var pos := Vector3((float(a[0]) - 0.5) * LARGH, 0, (float(a[1]) - 0.5) * ALT)
		pos.y = altezza(pos) - 0.01
		var s: float = float(a[2]) * 0.09
		mm2.set_instance_transform(i, Transform3D(Basis(Vector3.UP, i * 2.3).scaled(Vector3(s, s, s)), pos))
	var mmi2 := MultiMeshInstance3D.new()
	mmi2.multimesh = mm2
	var mc := StandardMaterial3D.new()
	mc.vertex_color_use_as_albedo = true
	mc.roughness = 0.9
	mmi2.material_override = mc
	_nodo_mappa.add_child(mmi2)

func _aggiungi_cono(st: SurfaceTool, base_y: float, alto: float, r: float, col: Color, lati := 7, off := Vector3.ZERO) -> void:
	for i in lati:
		var a0 := TAU * i / lati
		var a1 := TAU * (i + 1) / lati
		var p0 := off + Vector3(cos(a0) * r, base_y, sin(a0) * r)
		var p1 := off + Vector3(cos(a1) * r, base_y, sin(a1) * r)
		var t := off + Vector3(0, base_y + alto, 0)
		var n := (p1 - p0).cross(t - p0).normalized()
		for v in [p0, t, p1]:
			st.set_color(col)
			st.set_normal(-n)
			st.add_vertex(v)

func _mesh_abete() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_aggiungi_cono(st, 0.0, 0.5, 0.07, Color(0.35, 0.22, 0.12), 5)
	_aggiungi_cono(st, 0.25, 0.9, 0.42, Color(0.12, 0.32, 0.14))
	_aggiungi_cono(st, 0.6, 0.8, 0.33, Color(0.15, 0.38, 0.16))
	_aggiungi_cono(st, 0.95, 0.7, 0.24, Color(0.18, 0.44, 0.18))
	return st.commit()

func _mesh_latifoglia() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_aggiungi_cono(st, 0.0, 0.7, 0.08, Color(0.38, 0.25, 0.13), 5)
	# chioma: icosfera schiacciata
	var sf := SphereMesh.new()
	sf.radius = 0.5
	sf.height = 0.85
	sf.radial_segments = 8
	sf.rings = 5
	var arr := sf.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	for k in idx:
		st.set_color(Color(0.22, 0.42, 0.15))
		st.set_normal(norms[k])
		st.add_vertex(verts[k] + Vector3(0, 0.95, 0))
	return st.commit()

func _mesh_canna() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a := k * 2.1
		var off := Vector3(cos(a) * 0.12, 0, sin(a) * 0.12)
		_aggiungi_cono(st, 0.0, 1.0 + k * 0.2, 0.03, Color(0.55, 0.52, 0.25), 4, off)
	return st.commit()

## Nomi, numeri e tasse delle province, scritti in piano sulla mappa con i caratteri del gioco.
func _costruisci_scritte() -> void:
	var f_dritto: Font = load("res://assets/font/FellMaiuscoletto.ttf")
	var f_corsivo: Font = load("res://assets/font/FellCorsivo.ttf")
	for q in Dati.province:
		var pr: Dictionary = Dati.province[q]
		var mare: bool = pr["mare"]
		var l := Label3D.new()
		l.text = "%02d %s\n%d" % [q, pr.get("nome_it", pr["nome"]) if mare else pr["nome"], pr["tasse"]]
		l.font = f_corsivo if mare else f_dritto
		l.font_size = 64
		l.pixel_size = 0.0058
		l.line_spacing = -8
		l.outline_size = 10
		if mare:
			l.modulate = Color(0.95, 0.92, 0.82)
			l.outline_modulate = Color(0.05, 0.12, 0.18, 0.9)
		else:
			l.modulate = Color(0.16, 0.10, 0.05)
			l.outline_modulate = Color(0.96, 0.90, 0.74, 0.85)
		l.rotation_degrees = Vector3(-90, 0, 0)
		l.double_sided = false
		var pos := Vector3((pr["lx"] - 0.5) * LARGH, 0, (pr["ly"] - 0.5) * ALT)
		# sopra il punto più alto lì attorno, così le montagne non coprono il nome
		var hm := altezza(pos)
		for k in 12:
			var a := TAU * k / 12.0
			for r in [0.35, 0.7]:
				hm = maxf(hm, altezza(pos + Vector3(cos(a) * r, 0, sin(a) * r * 0.5)))
		pos.y = hm + 0.05
		l.position = pos
		l.render_priority = 2
		_nodo_mappa.add_child(l)

func centro(p: int) -> Vector3:
	var q: Dictionary = Dati.province[p]
	if modalita == "moderna":
		return a_terra(Vector3((q["mx"] - 0.5) * LARGH, 0, (q["my"] - 0.5) * ALT))
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
	if modalita == "moderna":
		cam_bersaglio = Vector3(0, 0, 1.6)
		cam_yaw = PI / 2.0
		cam_pitch = deg_to_rad(66)
		cam_dist = 33.0
	else:
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
	var y := 0.02
	var punto := Vector3.ZERO
	for k in 4:
		var t := -(o.y - y) / d.y
		if t < 0:
			return 0
		punto = o + d * t
		y = altezza(punto)
	return provincia_in(punto)

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

## Modelli senza texture (colori per faccia) e varianti tinte (la flotta pirata usa la nave elfica, più scura).
func _sistema_materiali(mod: Node, tipo: String) -> void:
	for c in mod.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = c
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat = mi.mesh.surface_get_material(i)
			var nuovo: StandardMaterial3D = null
			if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture == null:
				nuovo = (mat as StandardMaterial3D).duplicate()
				nuovo.vertex_color_use_as_albedo = true
			elif mat == null:
				nuovo = StandardMaterial3D.new()
				nuovo.vertex_color_use_as_albedo = true
			if tipo in ["flotta_pirata", "flotta_barbara"]:
				nuovo = (mat as StandardMaterial3D).duplicate() if mat is StandardMaterial3D else StandardMaterial3D.new()
				nuovo.albedo_color = Color(0.45, 0.38, 0.36) if tipo == "flotta_pirata" else Color(1.0, 0.72, 0.6)
			if nuovo != null:
				mi.set_surface_override_material(i, nuovo)

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
		"flotta": return 0.62
		"aeronave": return 0.62
		"balena": return 0.8
		"rana": return 0.5
	return 0.5

## Crea la miniatura di un'unità: modello scalato, basetta col colore del proprietario.
var _tex_pedine := {}

## Pedina di cartone: la faccia è la scansione a colori del modulo TTS, sotto una piastrina col colore del giocatore.
func _crea_pedina(id: int) -> Node3D:
	var radice := Node3D.new()
	radice.name = "U%d" % id
	var cont := Node3D.new()
	cont.name = "Modello"
	radice.add_child(cont)
	var lato := 0.58 if modalita == "originale" else 0.46
	var spess := 0.06
	# il lato alto della pedina guarda lontano dalla telecamera nella vista iniziale, così le scritte si leggono dritte
	cont.rotation.y = PI / 2.0 - (PI if modalita == "originale" else PI / 2.0)
	var corpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(lato, spess, lato)
	corpo.mesh = bm
	corpo.position = Vector3(0, spess / 2 + 0.03, 0)
	var mc := StandardMaterial3D.new()
	mc.albedo_color = Color(0.86, 0.80, 0.66)
	mc.roughness = 0.95
	corpo.material_override = mc
	cont.add_child(corpo)
	var faccia := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(lato - 0.01, lato - 0.01)
	faccia.mesh = qm
	faccia.rotation_degrees = Vector3(-90, 0, 0)
	faccia.position = Vector3(0, spess + 0.031, 0)
	var mf := StandardMaterial3D.new()
	var chiave := "%s|%d" % [Dati.grafica_pedine, id]
	if not _tex_pedine.has(chiave):
		var perc := Dati.img_pedina(id)
		_tex_pedine[chiave] = load(perc) if perc != "" else null
	mf.albedo_texture = _tex_pedine[chiave]
	mf.roughness = 0.8
	mf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	faccia.material_override = mf
	cont.add_child(faccia)
	# piastrina e bordo del proprietario
	var base := MeshInstance3D.new()
	base.name = "Base"
	var pb := BoxMesh.new()
	pb.size = Vector3(lato + 0.06, 0.03, lato + 0.06)
	base.mesh = pb
	base.position = Vector3(0, 0.015, 0)
	radice.add_child(base)
	var anello := MeshInstance3D.new()
	anello.name = "Anello"
	var am := BoxMesh.new()
	am.size = Vector3(lato + 0.075, 0.012, lato + 0.075)
	anello.mesh = am
	anello.position = Vector3(0, 0.032, 0)
	radice.add_child(anello)
	return radice

func _crea_figura(id: int) -> Node3D:
	if stile == "pedine":
		return _crea_pedina(id)
	var tipo: String = Dati.unita[id]["tipo"]
	var radice := Node3D.new()
	radice.name = "U%d" % id
	var mod := _carica_modello(tipo)
	_sistema_materiali(mod, tipo)
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
	if stile == "pedine":
		# una pila per proprietario, come sul tavolo vero: truppe sotto, capi in cima
		var pile := {}
		for id in ids:
			var o: int = m.u[id]["own"]
			if not pile.has(o):
				pile[o] = []
			pile[o].append(id)
		var proprietari := pile.keys()
		var np := proprietari.size()
		for k in np:
			var o = proprietari[k]
			var lista: Array = pile[o]
			lista.sort_custom(func(a, b):
				var ca := 1 if Dati.classe(a) in ["capo", "mago"] else 0
				var cb := 1 if Dati.classe(b) in ["capo", "mago"] else 0
				return ca < cb if ca != cb else a < b)
			var off := Vector3.ZERO
			if np > 1:
				var ang := TAU * k / np + 0.6
				off = Vector3(cos(ang), 0, sin(ang)) * (0.55 if modalita == "originale" else 0.44)
			var base := a_terra(c + off)
			for j in lista.size():
				out[lista[j]] = base + Vector3(j * 0.025, j * 0.075, -j * 0.025)
		return out
	var passo := 0.36
	for i in ids.size():
		var off := Vector3.ZERO
		if i > 0:
			var ang := i * 2.39996
			var r := passo * sqrt(float(i)) * 0.95
			off = Vector3(cos(ang) * r, 0, sin(ang) * r)
		out[ids[i]] = a_terra(c + off)
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
		b.position = a_terra(centro(q) + Vector3(0.55, 0, -0.55))
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
				carta.emit("fuga", "")
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
				await _anima_cattura(e)
			"liberato":
				_anima_liberato(e)
			"fedelta":
				await _anima_fedelta(e)
			"invisibile":
				await _anima_invisibile(e)
			"svelato", "rivela":
				await _anima_rivela(e)
			"blocco":
				_anima_blocco(e)
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
		var pos_fin := posizioni(a) if a > 0 else {}
		var k := 0
		for id in ids:
			var f: Node3D = figure.get(id)
			if f == null or not m.visibile_a(id, spettatore):
				continue
			qualcosa = true
			var ang := k * 2.39996
			var r := 0.36 * sqrt(float(k)) * 0.95
			var meta: Vector3 = pos_fin.get(id, a_terra(arrivo + Vector3(cos(ang) * r, 0, sin(ang) * r)))
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
			var da_pos := f.position
			tw.tween_method(func(k: float):
				if is_instance_valid(f):
					var pp := da_pos.lerp(meta, k)
					f.position = Vector3(pp.x, maxf(altezza(pp), lerpf(da_pos.y, meta.y, k)), pp.z), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
	carta.emit("battaglia", "")
	_volume(centro(e["prov"]) + Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 2.4), 2, Color(0.55, 0.47, 0.36), Color(0.95, 0.8, 0.55), 2.6, {"densita": 2.2, "scala_rumore": 4.5})
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
			tw.tween_property(f, "position", a_terra(f.position.lerp(c, 0.18)), 0.4 / velocita)
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
	carta.emit(e["s"], "riuscito" if e["ok"] else "fallito")
	_aura(pos, col, 1.4)
	_volume(pos + Vector3(0, 0.55, 0), Vector3(1.3, 1.3, 1.3), 0, col.darkened(0.2), Color(1, 1, 1), 1.8, {"vortice": 4.0, "densita": 2.5})
	if e["s"] == "chiaroveggenza" and e["ok"]:
		_volume(pos + Vector3(0, 1.4, 0), Vector3(0.9, 0.9, 0.9), 4, Color(0.6, 0.7, 1.0), Color(1, 1, 1), 2.0, {"densita": 3.0})
	elif e["s"] in ["discordia", "armonia"] and e["ok"]:
		var c2 := Color(0.9, 0.2, 0.15) if e["s"] == "discordia" else Color(1.0, 0.85, 0.4)
		_volume(pos + Vector3(0, 0.9, 0), Vector3(2.2, 0.6, 2.2), 4, c2, Color(1, 1, 0.9), 2.0, {"densita": 3.0})
	if not e["ok"]:
		_etichetta(pos + Vector3(0, 1.0, 0), "fallito", Color(0.8, 0.7, 0.6), 1.5)
		_volume(pos + Vector3(0, 0.5, 0), Vector3(0.9, 0.9, 0.9), 3, Color(0.3, 0.3, 0.32), Color(0.6, 0.6, 0.6), 1.4, {"salita": 0.8})
	await _attesa(1.1)
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
	_volume(pos + Vector3(0, 0.7, 0), Vector3(0.9, 1.6, 0.9), 3, Color(0.05, 0.08, 0.04), Color(0.45, 1.0, 0.3), 1.8, {"densita": 4.0, "salita": -0.6, "bagliore": 1.2})
	await _attesa(0.4)
	_fulmine(pos, Color(0.6, 1.0, 0.4))
	await _attesa(0.6)

func _anima_resurrezione(e: Dictionary) -> void:
	var c := centro(e["prov"])
	inquadra(e["prov"], 9.0)
	carta.emit("resurrezione", "")
	_volume(c + Vector3(0, 0.25, 0), Vector3(3.0, 0.7, 3.0), 2, Color(0.1, 0.35, 0.12), Color(0.5, 1.0, 0.45), 3.2, {"densita": 3.0, "scala_rumore": 4.0})
	_volume(c + Vector3(0, 1.0, 0), Vector3(1.4, 2.2, 1.4), 3, Color(0.2, 0.6, 0.2), Color(0.7, 1.0, 0.6), 2.8, {"salita": 0.7})
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

func _pos_unita(id: int, q: int) -> Vector3:
	var f: Node3D = figure.get(id)
	return f.position if f != null else centro(q)

func _anima_cattura(e: Dictionary) -> void:
	carta.emit("cattura", "")
	var pos := _pos_unita(e["id"], e["prov"])
	_volume(pos + Vector3(0, 0.7, 0), Vector3(1.1, 1.6, 1.1), 1, Color(0.3, 0.08, 0.06), Color(0.9, 0.3, 0.15), 1.8, {"vortice": -4.0, "densita": 3.0})
	await _attesa(1.0)

func _anima_liberato(e: Dictionary) -> void:
	var q: int = m.u[e["id"]]["prov"] if m != null and m.u.has(e["id"]) else 0
	if q <= 0:
		return
	carta.emit("liberazione", "")
	_volume(_pos_unita(e["id"], q) + Vector3(0, 0.9, 0), Vector3(1.0, 1.9, 1.0), 3, Color(0.9, 0.7, 0.25), Color(1, 1, 0.85), 2.0, {"salita": 0.8})

func _anima_fedelta(e: Dictionary) -> void:
	var pos := _pos_unita(e["id"], e["prov"])
	_volume(pos + Vector3(0, 0.55, 0), Vector3(1.2, 1.2, 1.2), 0, Color(0.95, 0.75, 0.25), Color(1, 1, 0.8), 2.0, {"vortice": 3.0, "densita": 3.0})
	_lampo(pos + Vector3(0, 0.8, 0), Color(1.0, 0.85, 0.4), 1.5)
	await _attesa(0.9)

func _anima_invisibile(e: Dictionary) -> void:
	var ids: Array = e.get("ids", [])
	if ids.is_empty():
		return
	var q: int = m.u[ids[0]]["prov"] if m != null and m.u.has(ids[0]) else 0
	if q <= 0:
		return
	_volume(centro(q) + Vector3(0, 0.6, 0), Vector3(2.0, 1.3, 2.0), 0, Color(0.7, 0.55, 0.95, 0.8), Color(1, 1, 1), 1.8, {"vortice": 2.0, "densita": 2.0, "scala_rumore": 6.0})
	await _attesa(0.8)

func _anima_rivela(e: Dictionary) -> void:
	var q: int = e.get("prov", 0)
	if q <= 0:
		return
	_volume(centro(q) + Vector3(0, 0.4, 0), Vector3(3.0, 0.5, 3.0), 4, Color(0.95, 0.8, 1.0), Color(1, 1, 1), 1.6, {"densita": 3.5})
	_lampo(centro(q) + Vector3(0, 1.0, 0), Color(1.0, 0.9, 1.0), 1.2)
	await _attesa(0.7)

func _anima_blocco(e: Dictionary) -> void:
	var q: int = e.get("prov", 0)
	if q <= 0:
		return
	carta.emit("blocco", "")
	_volume(centro(q) + Vector3(0, 0.3, 0), Vector3(2.0, 0.5, 2.0), 4, Color(0.75, 0.2, 0.1), Color(1.0, 0.7, 0.4), 1.4, {"densita": 3.0})

# ---------------------------------------------------------------- effetti volumetrici (nebbie e vortici disegnati dallo shader)

var _shader_volume: Shader

## Un volume di nebbia animata. forma: 0 sfera, 1 vortice, 2 nube piatta, 3 colonna, 4 anello.
## durata <= 0: resta finché non si toglie il nodo genitore (effetti che durano tutto l'anno).
func _volume(pos: Vector3, dim: Vector3, forma: int, c1: Color, c2: Color, durata: float, opz := {}, genitore: Node3D = null) -> MeshInstance3D:
	if _shader_volume == null:
		_shader_volume = load("res://scripts/volume.gdshader")
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mi.mesh = bm
	mi.scale = dim
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = _shader_volume
	mat.set_shader_parameter("colore", c1)
	mat.set_shader_parameter("colore2", c2)
	mat.set_shader_parameter("forma", forma)
	mat.set_shader_parameter("seme", randf() * 50.0)
	for k in opz:
		mat.set_shader_parameter(k, opz[k])
	mat.set_shader_parameter("dissolvenza", 0.0)
	mi.material_override = mat
	(genitore if genitore != null else self).add_child(mi)
	var tw := create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("dissolvenza", v), 0.0, 1.0, 0.35 / velocita)
	if durata > 0.0:
		tw.tween_interval(maxf(0.1, durata - 0.8) / velocita)
		tw.tween_method(func(v: float): mat.set_shader_parameter("dissolvenza", v), 1.0, 0.0, 0.45 / velocita)
		tw.tween_callback(mi.queue_free)
	return mi

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
			_volume(Vector3(0, 1.4, 0), Vector3(1.8, 2.8, 1.8), 1, Color(0.42, 0.38, 0.33), Color(0.85, 0.8, 0.72), 0.0, {"vortice": 5.0, "densita": 3.0, "salita": 0.9}, radice)
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
			_volume(Vector3(0, 2.4, 0), Vector3(3.2, 0.9, 3.2), 2, Color(0.16, 0.17, 0.22), Color(0.55, 0.6, 0.7), 0.0, {"densita": 4.0, "scala_rumore": 3.5}, radice)
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
			_volume(Vector3(0, 0.3, 0), Vector3(3.2, 0.6, 3.2), 2, Color(0.75, 0.88, 1.0), Color(1, 1, 1), 0.0, {"densita": 2.0, "scala_rumore": 5.0}, radice)
		"alluvione":
			var acqua := MeshInstance3D.new()
			var cy2 := CylinderMesh.new()
			cy2.top_radius = 1.4
			cy2.bottom_radius = 1.4
			cy2.height = 0.02
			acqua.mesh = cy2
			var ma := StandardMaterial3D.new()
			ma.albedo_color = Color(0.2, 0.45, 0.75, 0.35)
			ma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ma.roughness = 0.05
			ma.metallic = 0.3
			acqua.material_override = ma
			acqua.position = Vector3(0, 0.0, 0)
			radice.add_child(acqua)
			create_tween().tween_property(acqua, "position:y", 0.16, 1.2 / velocita)
			_volume(Vector3(0, 0.35, 0), Vector3(3.0, 0.5, 3.0), 2, Color(0.35, 0.5, 0.65), Color(0.85, 0.92, 1.0), 0.0, {"densita": 1.6, "scala_rumore": 5.0}, radice)
			_spruzzo(c)
		"controllo":
			_aura(c, Color(0.55, 0.65, 1.0), 2.0)
			_volume(Vector3(0, 0.8, 0), Vector3(1.4, 1.4, 1.4), 0, Color(0.85, 0.35, 0.85), Color(0.6, 0.75, 1.0), 2.4, {"vortice": 6.0, "densita": 3.0}, radice)

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
