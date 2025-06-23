extends RefCounted
class_name CableData

var cable: Line2D
var start: Node2D
var end: Node2D

func _init(cable: Line2D, start: Node2D, end: Node2D) -> void:
	self.cable = cable
	self.start = start
	self.end = end
