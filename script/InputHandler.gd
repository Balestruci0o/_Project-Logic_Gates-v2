extends Node

func handle_mouse_left_button(main_scene: Node2D, event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	if event.pressed:
		#var clicked_cable_data = main_scene.get_cable_at_position(mouse_pos)
		var clicked_cable_data = null
		var clicked_component_data: Dictionary
		for component in main_scene.all_components:
			if component["ref"] == main_scene.dragging_component:
				clicked_component_data = component
		
		if Input.is_key_pressed(KEY_ALT):
			DrawingManager.start_drawing(main_scene, mouse_pos)
		elif Input.is_key_pressed(KEY_CTRL):
			if clicked_cable_data:
				SelectionManager.toggle_select_object(main_scene, clicked_cable_data)
			elif clicked_component_data:
				SelectionManager.toggle_select_object(main_scene, clicked_component_data)
		elif Input.is_key_pressed(KEY_SHIFT):
				SelectionManager.start_selection_box(main_scene, mouse_pos)
		elif clicked_cable_data:
			main_scene.reset_all_component_textures()
			main_scene.selected_objects.clear()
			main_scene.selected_objects.append(clicked_cable_data)
			if clicked_cable_data.has("ref") and clicked_cable_data["ref"] is Area2D:
				for child in clicked_cable_data["ref"].get_children():
					if child is Sprite2D:
						child.texture = load("res://Graphics/" + clicked_cable_data["ref"].name + "_Oznacena.png")
						break
		elif clicked_component_data:
			SelectionManager.start_dragging_component(main_scene, clicked_component_data)
		else:
			main_scene.reset_all_component_textures()
			main_scene.camera.start_moving(mouse_pos)
			main_scene.selected_objects.clear()
	else:
		if main_scene.selection_box:
			SelectionManager.finalize_selection(main_scene)
		else:
			DrawingManager.stop_drawing(main_scene)
		Movement.stop_dragging(main_scene)
		main_scene.dragging_connector = null
		main_scene.camera.stop_moving()

func handle_key_pressed(main_scene: Node2D, event: InputEventKey) -> void:
	if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
		SelectionManager.delete_selected_objects(main_scene)
		
	elif event.keycode == KEY_Z and Input.is_key_pressed(KEY_CTRL):
		HistoryManager.back_to_the_future(main_scene, "undo")
		
	elif event.keycode == KEY_Y and Input.is_key_pressed(KEY_CTRL):
		HistoryManager.back_to_the_future(main_scene, "redo")
		
	elif event.keycode == KEY_R and Input.is_key_pressed(KEY_CTRL):
		for selected_object in main_scene.selected_objects:
			if selected_object is Dictionary and selected_object.has("ref") and selected_object["ref"] is Area2D:
				selected_object["ref"].rotate(deg_to_rad(-90))
				var rotate = 0
				if main_scene.history[-1]["action"] == "rotate_component" and main_scene.history[-1]["data"]["id"] == selected_object["id"]:
					rotate = main_scene.history[-1]["data"]["rotate"]
					main_scene.history.pop_back()
				HistoryManager.add_history_entry(main_scene, {
						"action": "rotate_component",
						"data": {
							"id": selected_object["id"],
							"rotate": -90 + rotate
						}
					})
					
	elif event.keycode == KEY_C and Input.is_key_pressed(KEY_CTRL):
		main_scene.copy = main_scene.selected_objects.duplicate()
		
	elif event.keycode == KEY_V and Input.is_key_pressed(KEY_CTRL):
		for copy_obj in main_scene.copy:
			if copy_obj is Dictionary and copy_obj.has("ref"):
				if copy_obj["ref"] is Area2D:
					main_scene._on_instance_nodes(load(copy_obj["ref"].scene_file_path), copy_obj["ref"].position + Vector2(50,50))

func handle_mouse_motion(main_scene: Node2D, event: InputEventMouseMotion, mouse_pos: Vector2) -> void:
	if main_scene.drawing:
		DrawingManager.update_drawing(main_scene, mouse_pos)
	elif main_scene.dragging_connector:
		Movement.move_connector(main_scene, mouse_pos)
	elif main_scene.selection_box:
		SelectionManager.update_selection_box(main_scene, mouse_pos)
	elif main_scene.is_being_dragged:
		Movement.dragging_components(main_scene, mouse_pos)
	elif main_scene.camera.is_moving:
		main_scene.camera.update_position(event.relative)
