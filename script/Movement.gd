extends Node

func dragging_components(main_scene: Node2D, mouse_pos: Vector2) -> void:
	for selected_object in main_scene.selected_objects:
		if selected_object is Dictionary and selected_object["ref"] is Area2D:
			if not main_scene.moved_components.has(selected_object["ref"]):
				main_scene.moved_components[selected_object["ref"]] = selected_object["ref"].global_position
			selected_object["ref"].global_position += main_scene.align_to_grid(mouse_pos) - main_scene.align_to_grid(main_scene.last_mouse)
	main_scene.last_mouse = mouse_pos

func stop_dragging(main_scene: Node2D) -> void:
	main_scene.is_being_dragged = false
	for selected_object in main_scene.selected_objects:
		if selected_object != null and selected_object["ref"] is Area2D and main_scene.moved_components.has(selected_object["ref"]):
			var from_pos = main_scene.moved_components[selected_object["ref"]]
			var to_pos = selected_object["ref"].global_position

			if from_pos != to_pos:
				HistoryManager.add_history_entry(main_scene, {
					"action": "move_component",
					"data": {
						"id": selected_object["id"],
						"original_position": from_pos,
						"new_position": to_pos
					}
				})
	main_scene.moved_components.clear()


func move_connector(main_scene: Node2D, new_pos: Vector2) -> void:
	if main_scene.dragging_connector == null or \
	   new_pos.x < 0 or new_pos.y < 0 or \
	   new_pos.y > main_scene.camera.limit_bottom or new_pos.x > main_scene.camera.limit_right:
		return

	var aligned_pos = main_scene.align_to_grid(new_pos)
	var affected_cables = []
	var pos = main_scene.dragging_connector.position

	if is_instance_valid(main_scene.dragging_connector):
		main_scene.dragging_connector.position = aligned_pos

	var parent = main_scene.dragging_connector.get_parent()
	var connector_two
	for connector in parent.get_children():
		if connector != main_scene.dragging_connector:
			connector_two = connector
			
	var original_start = main_scene.dragging_connector.position
	var original_end =  connector_two.position

	if main_scene.history.size() > 0 and main_scene.history[-1].get("action") == "move_cable" and main_scene.history[-1]["data"].get("id") == parent:
		original_start = main_scene.history[-1]["data"]["original_start_pos"]
		original_end = main_scene.history[-1]["data"]["original_end_pos"]
		main_scene.history.pop_back()
		
	update_cable(main_scene, parent, main_scene.dragging_connector, connector_two)
	
		
	HistoryManager.add_history_entry(main_scene, {
		"action": "move_cable",
		"data": {
			"id": parent,
			"original_start_pos": original_start,
			"original_end_pos": original_end,
			"new_start_pos": main_scene.dragging_connector.position,
			"new_end_pos": connector_two.position
		}
	})

func update_cable(main_scene: Node2D, parent, start, end) -> void: # Odstránené 'static'
	if not (is_instance_valid(parent) and is_instance_valid(start) and is_instance_valid(end)):
		return

	var path = main_scene.find_limited_zigzag_path(start.position, end.position, parent)
	parent.set_points(path)
