extends Area2D


func _on_mouse_entered() -> void:
	get_parent().dragging_component = self

func _on_mouse_exited() -> void:
	get_parent().dragging_component = null


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if !event.pressed:
			get_parent().dragging_component = null
			get_parent().is_being_dragged = false
