extends Control

signal instance_nodes


func _on_button_pressed() -> void:
	emit_signal("instance_nodes", preload("res://Scenes/logic_gate_NAND.tscn"))
