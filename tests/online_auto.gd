## Prova online: due istanze (host e ospite) giocano sul finto Firebase (tests/firebase_mock.py);
## le decisioni delle persone le prende l'IA. Alla fine stampano l'impronta del diario: deve coincidere.
## BK_RUOLO=host|ospite BK_CODICE=file  (più FR_DB_URL, FR_AUTH_URL, FR_REFRESH_URL, FR_SESSION)
extends SceneTree

var main

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_via.call_deferred()

func _w(s: float) -> void:
	await create_timer(s).timeout

func _via() -> void:
	await _w(0.3)
	var ruolo := OS.get_environment("BK_RUOLO")
	var cf := OS.get_environment("BK_CODICE")
	var anni := int(OS.get_environment("BK_ANNI")) if OS.get_environment("BK_ANNI") != "" else 3
	if ruolo == "host":
		await main._crea_stanza("Host")
		var f := FileAccess.open(cf, FileAccess.WRITE)
		f.store_string(main.codice)
		f.close()
		print("BK stanza ", main.codice)
		while true:
			var r: Dictionary = await main.rete.room(main.codice)
			if Rete._as_dict(r.get("seats", {})).size() >= 2:
				break
			await _w(0.4)
		await main._avvia_online(2)
	else:
		var c := ""
		while c == "":
			if FileAccess.file_exists(cf):
				c = FileAccess.get_file_as_string(cf).strip_edges()
			await _w(0.3)
		await main._entra_stanza(c, "Ospite")
	while main.m == null:
		await _w(0.3)
	main.plancia.velocita = 40.0
	var t0 := Time.get_ticks_msec()
	while main.m.turno <= anni and not main.m.finita and Time.get_ticks_msec() - t0 < 300000:
		await process_frame
		var m: Motore = main.m
		var p: int = main.mio_posto
		if p in m.attese and main.giocatore_ui == p and not main._in_corso and not main.plancia.occupata() and main._chiave_pannello != "":
			main._chiave_pannello = "fatto"
			main._applica(p, IA.decidi(m, p))
	await _w(4.0)
	print("BK fine ", ruolo, " anno ", main.m.turno, " decisioni ", main.registro_dec.size(), " impronta ", str(main.m.registro.slice(0, 400)).hash())
	quit()
