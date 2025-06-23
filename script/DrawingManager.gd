extends Node

func start_drawing(main_scene: Node2D, mouse_pos: Vector2) -> void:
	main_scene.drawing = true
	main_scene.start_pos = main_scene.align_to_grid(mouse_pos)
	main_scene.instance_cable()
	main_scene.current_cable.add_point(main_scene.start_pos)

func update_drawing(main_scene: Node2D, mouse_pos: Vector2) -> void:
	var end_pos = main_scene.align_to_grid(mouse_pos)
	if not main_scene.dragging_connector or not is_instance_valid(main_scene.current_cable) or \
	   end_pos.x < 0 or end_pos.y < 0 or \
	   end_pos.y > main_scene.camera.limit_bottom or end_pos.x > main_scene.camera.limit_right:
		return

	var path = main_scene.find_limited_zigzag_path(main_scene.start_pos, end_pos, main_scene.current_cable)
	main_scene.current_cable.set_points(path)

	var last_cable_entry = main_scene.dragging_connector.get_parent()
	var connector_two
	for connector in last_cable_entry.get_children():
		if connector != main_scene.dragging_connector:
			connector_two = connector
	var id = main_scene.all_cables_data.back().keys()[0]
	if connector_two and is_instance_valid(connector_two):
		connector_two.position = path.back()

	if not main_scene.history.is_empty() and \
	   main_scene.history.back().get("action") == "add_cable" and \
	   main_scene.history.back()["data"].get("id") == id:
		main_scene.history.pop_back()

		
	HistoryManager.add_history_entry(main_scene, {
		"action": "add_cable",
		"data": {
			"ref": last_cable_entry,
			"id": id,
			"start_pos":  main_scene.dragging_connector,
			"end_pos": connector_two
		}
	})

func stop_drawing(main_scene: Node2D) -> void:
	var connector_two
	if main_scene.dragging_connector:
		for connector in main_scene.dragging_connector.get_parent().get_children():
			if connector != main_scene.dragging_connector:
				connector_two = connector
		if connector_two and main_scene.dragging_connector.position == connector_two.position:
			Movement.move_connector(main_scene, main_scene.dragging_connector.position + Vector2(32,0))
		main_scene.drawing = false
