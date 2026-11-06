## Prova del tavolo: una TV (BK_RUOLO=tv) e un telefono (BK_RUOLO=telefono, BK_TELEFONO=codice) sul finto
## Firebase; il telefono decide con l'IA. Foto in BK_FOTO; alla fine l'impronta del diario deve coincidere.
extends SceneTree

var main

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_via.call_deferred()

func _w(s: float) -> void:
	await create_timer(s).timeout

func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(OS.get_environment("BK_FOTO") + "/" + nome + ".png")

func _via() -> void:
	await _w(0.5)
	var ruolo := OS.get_environment("BK_RUOLO")
	var cf := OS.get_environment("BK_CODICE")
	if ruolo == "tv":
		await main._crea_tavolo_tv()
		var f := FileAccess.open(cf, FileAccess.WRITE)
		f.store_string(main.codice)
		f.close()
		while true:
			var r: Dictionary = await main.rete.room(main.codice)
			if Rete._as_dict(r.get("seats", {})).size() >= 1:
				break
			await _w(0.5)
		await _w(2.5)
		await _foto("tv_sala")
		await main._avvia_online(1)
	else:
		await _foto("tel_ingresso")
		await main._entra_stanza(main.stanza_url, "Stefano")
		await _w(1.0)
		await _foto("tel_attesa")
	while main.m == null:
		await _w(0.3)
	main.plancia.velocita = 30.0
	var viste := {}
	var t0 := Time.get_ticks_msec()
	while main.m.turno <= 1 and not main.m.finita and Time.get_ticks_msec() - t0 < 300000:
		await process_frame
		var m: Motore = main.m
		if ruolo == "tv":
			if m.fase == "piano" and not viste.has("piano") and not main.plancia.occupata():
				viste["piano"] = true
				await _w(1.0)
				await _foto("tv_piano")
			continue
		var p: int = main.mio_posto
		if p in m.attese and main.giocatore_ui == p and not main._in_corso and not main.plancia.occupata() and main._chiave_pannello != "":
			if not viste.has(m.fase):
				viste[m.fase] = true
				for i in 4:
					await process_frame
				await _foto("tel_%s" % m.fase)
			main._chiave_pannello = "fatto"
			main._applica(p, IA.decidi(m, p))
	await _w(4.0)
	if ruolo != "tv":
		var pl = main.plancia
		var ok := 0
		for q in [20, 26, 34, 36]:
			var sp: Vector2 = pl.cam.unproject_position(pl.centro(q))
			if pl._provincia_sotto(sp) == q:
				ok += 1
		print("BK clic giusti sul telefono ", ok, "/4")
	print("BK fine ", ruolo, " anno ", main.m.turno, " decisioni ", main.registro_dec.size(), " impronta ", str(main.m.registro.slice(0, 40)).hash())
	quit()
