## Fotografia del tavolo 3D dopo qualche anno di partita fra IA.
## Uso: xvfb-run godot --path . -s tests/foto3d.gd -- uscita.png [anni]
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp/foto3d.png"
	var anni := int(args[1]) if args.size() > 1 else 4
	var m := Motore.new()
	var gioc := []
	for i in 4:
		gioc.append({"nome": Dati.COLORI[i], "ia": true})
	m.avvia({"giocatori": gioc, "seme": 4242})
	while not m.finita and m.turno <= anni:
		var p: int = m.attese[0]
		m.invia(p, IA.decidi(m, p))
	var pl := Plancia3D.new()
	if args.size() > 3:
		pl.modalita = args[3]
	if args.size() > 4:
		pl.stile = args[4]
	root.add_child(pl)
	await process_frame
	pl.collega(m)
	pl.vista_iniziale()
	if args.size() > 2:
		pl.cam_bersaglio = pl.centro(int(args[2]))
		pl.cam_dist = 5.5
		pl.cam_pitch = deg_to_rad(35)
		pl._aggiorna_cam()
	for i in 3:
		await process_frame
	print(pl.cam.position, ' figure ', pl.figure.size())
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out)
	print("foto salvata ", out)
	quit()
