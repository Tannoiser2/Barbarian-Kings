## Generatore di codici QR (modo byte, correzione L, versioni 1-6: fino a 134 caratteri).
## Serve per il tavolo con i telefoni: la TV mostra il QR con l'indirizzo della stanza.
class_name QR
extends RefCounted

# versione -> [codeword EC per blocco, blocchi, codeword dati per blocco]
const TAB_L := {1: [7, 1, 19], 2: [10, 1, 34], 3: [15, 1, 55], 4: [20, 1, 80], 5: [26, 1, 108], 6: [18, 2, 68]}
const ALLINEA := {1: [], 2: [6, 18], 3: [6, 22], 4: [6, 26], 5: [6, 30], 6: [6, 34]}

static var _exp := []
static var _log := []

static func _gf_init() -> void:
	if not _exp.is_empty():
		return
	_exp.resize(512)
	_log.resize(256)
	var x := 1
	for i in 255:
		_exp[i] = x
		_log[x] = i
		x <<= 1
		if x & 0x100:
			x ^= 0x11D
	for i in range(255, 512):
		_exp[i] = _exp[i - 255]

static func _mul(a: int, b: int) -> int:
	if a == 0 or b == 0:
		return 0
	return _exp[_log[a] + _log[b]]

static func _rs(dati: Array, n_ec: int) -> Array:
	# polinomio generatore
	var gen := [1]
	for i in n_ec:
		var nuovo := []
		nuovo.resize(gen.size() + 1)
		nuovo.fill(0)
		for j in gen.size():
			nuovo[j] ^= gen[j]
			nuovo[j + 1] ^= _mul(gen[j], _exp[i])
		gen = nuovo
	var resto := []
	resto.resize(n_ec)
	resto.fill(0)
	for b in dati:
		var f: int = b ^ resto[0]
		resto.pop_front()
		resto.append(0)
		for j in n_ec:
			resto[j] ^= _mul(gen[j + 1], f)
	return resto

## Restituisce la matrice (Array di Array di bool, true = nero) per il testo dato.
static func matrice(testo: String) -> Array:
	_gf_init()
	var byte := testo.to_utf8_buffer()
	var ver := 0
	for v in range(1, 7):
		var t: Array = TAB_L[v]
		if byte.size() + 2 <= t[1] * t[2]:
			ver = v
			break
	if ver == 0:
		return []
	var t: Array = TAB_L[ver]
	var cap: int = t[1] * t[2]
	# flusso di bit: modo byte (0100), lunghezza 8 bit, dati, terminatore, riempimento
	var bit := []
	var metti := func(val: int, n: int):
		for i in range(n - 1, -1, -1):
			bit.append((val >> i) & 1)
	metti.call(4, 4)
	metti.call(byte.size(), 8)
	for b in byte:
		metti.call(b, 8)
	for i in mini(4, cap * 8 - bit.size()):
		bit.append(0)
	while bit.size() % 8 != 0:
		bit.append(0)
	var dati := []
	for i in range(0, bit.size(), 8):
		var v := 0
		for j in 8:
			v = (v << 1) | bit[i + j]
		dati.append(v)
	var pad := [0xEC, 0x11]
	var k := 0
	while dati.size() < cap:
		dati.append(pad[k % 2])
		k += 1
	# blocchi, correzione e intreccio
	var blocchi := []
	var ec := []
	for b in t[1]:
		var bl: Array = dati.slice(b * t[2], (b + 1) * t[2])
		blocchi.append(bl)
		ec.append(_rs(bl, t[0]))
	var finale := []
	for i in t[2]:
		for bl in blocchi:
			finale.append(bl[i])
	for i in t[0]:
		for e in ec:
			finale.append(e[i])
	# matrice
	var n := 17 + 4 * ver
	var mod := []
	var fun := []
	for y in n:
		var r1 := []
		r1.resize(n)
		r1.fill(false)
		mod.append(r1)
		var r2 := []
		r2.resize(n)
		r2.fill(false)
		fun.append(r2)
	var setf := func(x: int, y: int, nero: bool):
		mod[y][x] = nero
		fun[y][x] = true
	# temporizzazione
	for i in n:
		setf.call(6, i, i % 2 == 0)
		setf.call(i, 6, i % 2 == 0)
	# mirini con separatore
	for c in [[3, 3], [n - 4, 3], [3, n - 4]]:
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var x: int = c[0] + dx
				var y: int = c[1] + dy
				if x < 0 or y < 0 or x >= n or y >= n:
					continue
				var d := maxi(absi(dx), absi(dy))
				setf.call(x, y, d != 2 and d != 4)
	# allineamento
	var al: Array = ALLINEA[ver]
	for ay in al:
		for ax in al:
			if (ax == 6 and ay == 6) or (ax == 6 and ay == n - 7) or (ax == n - 7 and ay == 6):
				continue
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					setf.call(ax + dx, ay + dy, maxi(absi(dx), absi(dy)) != 1)
	# formato (riservato ora, scritto dopo)
	_formato(mod, fun, n, 0, setf)
	# dati a zig-zag
	var i := 0
	var destra := n - 1
	while destra >= 1:
		if destra == 6:
			destra = 5
		for vert in n:
			for j in 2:
				var x := destra - j
				var su := ((destra + 1) & 2) == 0
				var y := n - 1 - vert if su else vert
				if not fun[y][x] and i < finale.size() * 8:
					mod[y][x] = ((finale[i >> 3] >> (7 - (i & 7))) & 1) == 1
					i += 1
		destra -= 2
	# maschera 0: (x + y) pari
	for y in n:
		for x in n:
			if not fun[y][x] and (x + y) % 2 == 0:
				mod[y][x] = not mod[y][x]
	_formato(mod, fun, n, 0, setf)
	return mod

static func _formato(_mod: Array, _fun: Array, n: int, maschera: int, setf: Callable) -> void:
	var d := (1 << 3) | maschera   # livello L = 01
	var r := d
	for i in 10:
		r = (r << 1) ^ ((r >> 9) * 0x537)
	var bits := ((d << 10) | r) ^ 0x5412
	var b := func(i: int) -> bool: return ((bits >> i) & 1) == 1
	for i in 6:
		setf.call(8, i, b.call(i))
	setf.call(8, 7, b.call(6))
	setf.call(8, 8, b.call(7))
	setf.call(7, 8, b.call(8))
	for i in range(9, 15):
		setf.call(14 - i, 8, b.call(i))
	for i in 8:
		setf.call(n - 1 - i, 8, b.call(i))
	for i in range(8, 15):
		setf.call(8, n - 15 + i, b.call(i))
	setf.call(8, n - 8, true)

## Immagine del QR con un margine bianco di 4 moduli; ogni modulo è un quadrato di "px" pixel.
static func immagine(testo: String, px := 8) -> Image:
	var mat := matrice(testo)
	if mat.is_empty():
		return null
	var n := mat.size()
	var lato := (n + 8) * px
	var img := Image.create(lato, lato, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	for y in n:
		for x in n:
			if mat[y][x]:
				img.fill_rect(Rect2i((x + 4) * px, (y + 4) * px, px, px), Color.BLACK)
	return img
