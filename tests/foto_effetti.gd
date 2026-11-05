## Fotografa gli effetti volumetrici: uno per provincia, sulla mappa scelta.
## Uso: xvfb-run godot --path . -s tests/foto_effetti.gd -- uscita.png [moderna|originale]
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp/effetti.png"
	var m := Motore.new()
	m.avvia({"giocatori": [{"nome": "A", "ia": true}, {"nome": "B", "ia": true}], "seme": 5})
	var pl := Plancia3D.new()
	pl.modalita = args[1] if args.size() > 1 else "moderna"
	root.add_child(pl)
	await process_frame
	pl.collega(m)
	pl.vista_iniziale()
	pl._effetto_persistente("tornado", 26)
	pl._effetto_persistente("tempesta_monti", 21)
	pl._effetto_persistente("gelo", 3)
	pl._effetto_persistente("alluvione", 35)
	pl._volume(pl.centro(33) + Vector3(0, 0.6, 0), Vector3(1.3, 1.3, 1.3), 0, Color(0.4, 0.7, 0.9), Color(1, 1, 1), 99.0, {"vortice": 4.0, "densita": 2.5})
	pl._volume(pl.centro(20) + Vector3(0, 0.7, 0), Vector3(0.9, 1.6, 0.9), 3, Color(0.05, 0.08, 0.04), Color(0.45, 1.0, 0.3), 99.0, {"densita": 4.0, "salita": -0.6, "bagliore": 1.2})
	pl._volume(pl.centro(24) + Vector3(0, 0.25, 0), Vector3(3.0, 0.7, 3.0), 2, Color(0.1, 0.35, 0.12), Color(0.5, 1.0, 0.45), 99.0, {"densita": 3.0, "scala_rumore": 4.0})
	pl._volume(pl.centro(34) + Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 2.4), 2, Color(0.55, 0.47, 0.36), Color(0.95, 0.8, 0.55), 99.0, {"densita": 2.2, "scala_rumore": 4.5})
	pl._volume(pl.centro(36) + Vector3(0, 0.4, 0), Vector3(3.0, 0.5, 3.0), 4, Color(0.95, 0.8, 1.0), Color(1, 1, 1), 99.0, {"densita": 3.5})
	pl.cam_bersaglio = pl.centro(int(args[2]) if args.size() > 2 else 26)
	pl.cam_dist = float(args[3]) if args.size() > 3 else 13.0
	pl.cam_pitch = deg_to_rad(42)
	pl._aggiorna_cam()
	for i in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out)
	print("foto ", out)
	quit()
