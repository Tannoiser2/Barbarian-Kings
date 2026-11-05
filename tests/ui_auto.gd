## Prova dell'interfaccia: una persona (comandata dall'IA) contro tre IA, con foto dei pannelli.
## Uso: xvfb-run godot --path . -s tests/ui_auto.gd -- cartella_foto anni
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var dir := args[0] if args.size() > 0 else "/tmp/ui"
	var anni := int(args[1]) if args.size() > 1 else 2
	DirAccess.make_dir_recursive_absolute(dir)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await _foto(dir + "/00_menu.png")
	if args.size() > 2 and args[2] == "libro":
		for i in Tutorial.capitoli().size():
			main._libro(i)
			for k in 3:
				await process_frame
			await _foto("%s/libro_%02d.png" % [dir, i])
		quit()
		return
	var guidata := args.size() > 2 and (args[2] == "guidata" or args[2] == "magia")
	if guidata:
		main._avvia_tutorial("magia" if args[2] == "magia" else "base")
		main.plancia.velocita = 12.0
	else:
		main.umani_locali = [0]
		main._inizia({"giocatori": [{"nome": "Stefano", "ia": false}, {"nome": "Rosso", "ia": true}, {"nome": "Giallo", "ia": true}, {"nome": "Verde", "ia": true}], "seme": 777, "velocita": 12.0}, [])
	var viste := {}
	var t0 := Time.get_ticks_msec()
	while main.m.turno <= anni and not main.m.finita and Time.get_ticks_msec() - t0 < 900000:
		await process_frame
		var m: Motore = main.m
		if main._carta_vista != null and is_instance_valid(main._carta_vista) and not viste.has(main._carta_vista) and viste.size() < 40:
			viste[main._carta_vista] = true
			for i in 6:
				await process_frame
			await _foto("%s/carta_%02d.png" % [dir, viste.size()])
		if 0 in m.attese and main.giocatore_ui == 0 and not main.plancia.occupata():
			var k: String = m.fase
			if not viste.has(k):
				viste[k] = true
				for i in 2:
					await process_frame
				await _foto("%s/%02d_%s.png" % [dir, viste.size(), k])
				if k in ["acquisti", "piano", "province", "magia1", "tornado"]:
					main._consiglio(0)
					for i in 3:
						await process_frame
					await _foto("%s/%02d_%s_consiglio.png" % [dir, viste.size(), k])
			if main.m.attese.has(0):
				if guidata and k == "re":
					main._azione_conferma.call()
				else:
					main._applica(0, IA.decidi(m, 0))
	print("arrivato all'anno ", main.m.turno, " fase ", main.m.fase, " in ", (Time.get_ticks_msec() - t0) / 1000, " s")
	await _foto(dir + "/99_fine.png")
	quit()

func _foto(p: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(p)
	print("foto ", p)
