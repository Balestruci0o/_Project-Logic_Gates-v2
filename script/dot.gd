extends Area2D

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_parent().get_parent().dragging_connector= self  # alebo volaj do hlavného controlleru
