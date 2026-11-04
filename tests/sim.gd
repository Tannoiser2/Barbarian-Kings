## Partite automatiche fra IA: controlla che il motore arrivi in fondo senza errori.
## Uso: godot --headless --path . -s tests/sim.gd -- [partite] [giocatori] [turni_max]
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var partite := int(args[0]) if args.size() > 0 else 5
	var ng := int(args[1]) if args.size() > 1 else 4
	var tmax := int(args[2]) if args.size() > 2 else 30
	var vittorie := {}
	var t0 := Time.get_ticks_msec()
	for k in partite:
		var m := Motore.new()
		var gioc := []
		for i in ng:
			gioc.append({"nome": Dati.COLORI[i], "ia": true})
		m.avvia({"giocatori": gioc, "seme": 1000 + k * 77, "turni_max": tmax})
		var passi := 0
		while not m.finita and passi < 20000:
			passi += 1
			if m.attese.is_empty():
				push_error("nessuno atteso in fase " + m.fase)
				break
			var p: int = m.attese[0]
			if OS.get_environment("TRACCIA") != "": print(m.turno, " ", m.fase, " ", p)
			var d := IA.decidi(m, p)
			var err := m.invia(p, d)
			if err != "":
				push_error("decisione rifiutata (%s, %s): %s" % [m.fase, m.g[p]["nome"], err])
				m.invia(p, {})
		var bat := 0
		var inc := 0
		for e in m.eventi:
			if e["t"] == "battaglia": bat += 1
			if e["t"] == "incantesimo": inc += 1
		var tasse := []
		for p in ng:
			tasse.append(m.tasse_di(p))
		print("partita %d: turni %d, vincitore %s, tasse %s, battaglie %d, incantesimi %d, passi %d" % [k, m.turno, m.g[m.vincitore]["nome"] if m.vincitore >= 0 else "-", str(tasse), bat, inc, passi])
		vittorie[m.vincitore] = vittorie.get(m.vincitore, 0) + 1
		if k == 0:
			for r in m.registro.slice(0, 80):
				print("   ", r)
	print("vittorie: ", vittorie, " in ", Time.get_ticks_msec() - t0, " ms")
	quit()
