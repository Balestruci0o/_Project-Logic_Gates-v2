extends Node

func add_history_entry(main_scene: Node2D, entry: Dictionary) -> void:
	main_scene.history.append(entry)
	if len(main_scene.history) > main_scene.HISTORY_MAX_SIZE:
		main_scene.history.pop_front()

func back_to_the_future(main_scene: Node2D, action) -> void:
	if (main_scene.history.is_empty() and action == "undo") or (main_scene.redo.is_empty() and action == "redo"):
		return

	var last_action
	if action == "undo":
		main_scene.redo.append(main_scene.history[-1])
		last_action = main_scene.history.pop_back()
	elif action == "redo":
		last_action = main_scene.redo[-1]
		main_scene.history.append(main_scene.redo.pop_back())

	match last_action["action"]:
		"add_cable":
			var cable_to_remove = last_action["data"]["ref"]
			var connector_one = cable_to_remove.get_children()[0]
			var connector_two = cable_to_remove.get_children()[1]
	
			if is_instance_valid(connector_one): connector_one.queue_free()
			if is_instance_valid(connector_two): connector_two.queue_free()
			if is_instance_valid(cable_to_remove): cable_to_remove.queue_free()
			last_action["action"] = "delete_cable"
		"delete_cable":
			main_scene.instance_cable()
			var start_connector = main_scene.all_cables_data[-1]["start"]
			start_connector.position = last_action["data"]["start_pos"]

			var end_connector = main_scene.all_cables_data[-1]["end"]
			end_connector.position = last_action["data"]["end_pos"]
			
			main_scene.all_cables_data[-1]["id"] = last_action["data"]["id"]

			Movement.update_cable(main_scene , start_connector.get_parent() ,start_connector, end_connector)
			last_action["action"] = "add_cable"

		"move_cable":
			var start_pos 
			var end_pos 
			if action == "undo":
				start_pos = last_action["data"]["original_start_pos"]
				end_pos = last_action["data"]["original_end_pos"]
			else:
				start_pos = last_action["data"]["new_start_pos"]
				end_pos = last_action["data"]["new_end_pos"]

			for entry in main_scene.all_cables_data:
				if entry["id"] == last_action["data"]["id"]:
					if is_instance_valid(entry["start"]):
						entry["start"].position = start_pos
					if is_instance_valid(entry["end"]):
						entry["end"].position = end_pos
					Movement.update_cable(main_scene, entry["start"].get_parent(), entry["start"], entry["end"])
					break

		"add_component":
			var component_id_to_remove = last_action["data"]["id"]
			var component_to_remove = null
			for component in main_scene.all_components:
				if component["id"] == component_id_to_remove:
					component_to_remove = component
					break
			if component_to_remove:
				if is_instance_valid(component_to_remove["ref"]): component_to_remove["ref"].queue_free()
				main_scene.all_components.erase(component_to_remove)
			last_action["action"] = "delete_component"
			
		"delete_component":
			var scene = load(str(last_action["data"]["component_scene_path"]))
			var node = scene.instantiate()
			node.position = last_action["data"]["position"]
			main_scene.add_child(node)
			main_scene.all_components.append({
				"id": last_action["data"]["id"],
				"ref": node
			})
			last_action["action"] = "add_component"

		"move_component":
			var component_id = last_action["data"]["id"]
			var original_pos 
			if action == "undo":
				original_pos = last_action["data"]["original_position"]
			elif action == "redo":
				original_pos = last_action["data"]["new_position"]
			for component in main_scene.all_components:
				if component["id"] == component_id:
					if is_instance_valid(component["ref"]):
						component["ref"].global_position = original_pos
					break

		"rotate_component":
			var component_id = last_action["data"]["id"]
			var rotation_amount = last_action["data"]["rotate"]
			for component in main_scene.all_components:
				if component["id"] == component_id:
					if is_instance_valid(component["ref"]):
						component["ref"].rotate(deg_to_rad(rotation_amount))
					break
			last_action["data"]["rotate"] = -last_action["data"]["rotate"]
