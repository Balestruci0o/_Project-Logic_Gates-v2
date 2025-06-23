extends Node

func toggle_select_object(main_scene: Node2D, object_data: Dictionary) -> void:
	if main_scene.selected_objects.has(object_data):
		main_scene.selected_objects.erase(object_data)
		if object_data.has("ref") and object_data["ref"] is Area2D:
			for child in object_data["ref"].get_children():
				if child is Sprite2D:
					child.texture = load("res://Graphics/" + object_data["ref"].scene_file_path.get_file().get_basename() + ".png")
					break
	else:
		main_scene.selected_objects.append(object_data)
		if object_data.has("ref") and object_data["ref"] is Area2D:
			for child in object_data["ref"].get_children():
				if child is Sprite2D:
					child.texture = load("res://Graphics/" + object_data["ref"].scene_file_path.get_file().get_basename() + "_Oznacena.png")
					break


func start_selection_box(main_scene: Node2D, mouse_pos: Vector2) -> void:
	if main_scene.selection_box:
		main_scene.selection_box.queue_free()

	main_scene.selection_start = mouse_pos

	main_scene.selection_box = ColorRect.new()
	main_scene.selection_box.color = Color(0, 0, 1, 0.3)
	main_scene.selection_box.position = main_scene.selection_start
	main_scene.selection_box.size = Vector2.ZERO
	main_scene.selection_box.set_anchors_preset(Control.PRESET_TOP_LEFT)

	main_scene.add_child(main_scene.selection_box)

func update_selection_box(main_scene: Node2D, mouse_pos: Vector2) -> void:
	if not main_scene.selection_box:
		return

	var local_start_pos = main_scene.selection_start
	var end_pos = mouse_pos

	main_scene.selection_box.position = Vector2(
		min(local_start_pos.x, end_pos.x),
		min(local_start_pos.y, end_pos.y)
	)
	main_scene.selection_box.size = Vector2(
		abs(end_pos.x - local_start_pos.x),
		abs(end_pos.y - local_start_pos.y)
	)

func finalize_selection(main_scene: Node2D) -> void:
	if not main_scene.selection_box:
		return

	var box_rect = Rect2(main_scene.selection_box.global_position, main_scene.selection_box.size)
	main_scene.selected_objects.clear()
	main_scene.reset_all_component_textures()

	for cable_data in main_scene.all_cables_data:
		var c = cable_data["ref"]
		if is_instance_valid(c) and (box_rect.has_point(c.get_point_position(0)) or box_rect.has_point(c.get_point_position(c.get_point_count() - 1))):
			main_scene.selected_objects.append(cable_data)

	for component in main_scene.all_components:
		if is_instance_valid(component["ref"]) and box_rect.has_point(component["ref"].global_position):
			main_scene.selected_objects.append(component)
			for child in component["ref"].get_children():
				if child is Sprite2D:
					child.texture = load("res://Graphics/" + component["ref"].scene_file_path.get_file().get_basename() + "_Oznacena.png")
					break

	main_scene.selection_box.queue_free()
	main_scene.selection_box = null

func start_dragging_component(main_scene: Node2D, component_data: Dictionary) -> void:
	main_scene.is_being_dragged = true
	main_scene.last_mouse = main_scene.get_global_mouse_position()

	if not main_scene.selected_objects.has(component_data):
		main_scene.reset_all_component_textures()
		main_scene.selected_objects.clear()
		main_scene.selected_objects.append(component_data)


	for component_entry in main_scene.all_components:
		var texture_path = "res://Graphics/" + component_entry["ref"].scene_file_path.get_file().get_basename() + "_Oznacena.png" if main_scene.selected_objects.has(component_entry) else "res://Graphics/" + component_entry["ref"].scene_file_path.get_file().get_basename() + ".png"
		for child in component_entry["ref"].get_children():
			if child is Sprite2D:
				child.texture = load(texture_path)
				break


func delete_selected_objects(main_scene: Node2D) -> void:
	var components_to_delete = []
	var cables_to_delete = []

	for selected_object in main_scene.selected_objects:
		if selected_object is Dictionary:
			if selected_object.has("ref") and selected_object["ref"] is Area2D:
				components_to_delete.append(selected_object)
			elif selected_object.has("ref") and selected_object["ref"] is Line2D:
				cables_to_delete.append(selected_object)

	for component_data in components_to_delete:
		if is_instance_valid(component_data["ref"]):
			HistoryManager.add_history_entry(main_scene, {
				"action": "delete_component",
				"data": {
					"id": component_data["id"],
					"component_scene_path": component_data["ref"].scene_file_path,
					"position": component_data["ref"].position
				}
			})
			main_scene.all_components.erase(component_data)
			component_data["ref"].queue_free()

	for cable_data in cables_to_delete:
		if is_instance_valid(cable_data["ref"]):
			var start_pos = cable_data["start"].position
			var end_pos = cable_data["end"].position

			HistoryManager.add_history_entry(main_scene, {
				"action": "delete_cable",
				"data": {
					"id": cable_data["id"],
					"start_pos": start_pos,
					"end_pos": end_pos
				}
			})
			if is_instance_valid(cable_data["ref"]): cable_data["ref"].queue_free()
			if is_instance_valid(cable_data["start"]): cable_data["start"].queue_free()
			if is_instance_valid(cable_data["end"]): cable_data["end"].queue_free()
			main_scene.all_cables_data.erase(cable_data)

	main_scene.selected_objects.clear()
