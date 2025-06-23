extends Node2D

const TILE_SIZE = 32

@onready var camera = $Camera
@onready var dot_scene = preload("res://Scenes/dot.tscn")
@onready var ui_control = $Control

var is_being_dragged: bool
var current_cable: Line2D = null
var drawing := false
var start_pos: Vector2
var viewport_size = Vector2.ZERO
var dragging_component
var history: Array = []
var redo: Array = []
var history_index: int = -1
const HISTORY_MAX_SIZE = 50

var dragging_connector: Area2D
var selection_box: ColorRect = null
var selection_start: Vector2
var moved_components := {}
var copy :Array
var selected_objects: Array = []
var last_mouse: Vector2

var all_components: Array = []
var all_cables_data: Array = []

func _ready() -> void:
	update_viewport_size()
	ui_control.connect("instance_nodes", Callable(self, "_on_instance_nodes"))

func _process(delta: float) -> void:
	#print(history)
	pass

func update_viewport_size():
	viewport_size = get_viewport_rect().size / camera.zoom

func _on_instance_nodes(scene, pos = null):
	print(pos)
	var node = scene.instantiate()
	node.position = align_to_grid(get_global_mouse_position() / 2)
	add_child(node)
	var id = str(Time.get_unix_time_from_system()) + "_" + str(randi())
	if pos != null:
		node.position = pos
	all_components.append({
		"id": id,
		"ref": node
	})
	
	#all_components.append({
		#id: node
	#})
	history.append({
		"action": "add_component",
		"data": {
			"id": id,
			"ref": node,
			"component_scene_path": node.scene_file_path,
			"position": node.position
		}
	})
	if len(history) > HISTORY_MAX_SIZE:
		history.pop_front()

func instance_cable() -> void:
	current_cable = Line2D.new()
	current_cable.default_color = Color.WHITE
	current_cable.width = 10
	#current_cable.texture = load("res://Graphics/kabel.png")
	current_cable.texture_mode = Line2D.LINE_TEXTURE_TILE
	current_cable.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(current_cable)

	var start_connector = dot_scene.instantiate()
	start_connector.position = start_pos
	current_cable.add_child(start_connector)

	var end_connector = dot_scene.instantiate()
	end_connector.position = start_pos 
	dragging_connector = end_connector
	current_cable.add_child(end_connector)

	#all_cables_data.append({
		#"id": str(Time.get_unix_time_from_system()) + "_" + str(randi()),
		#"ref": current_cable,
		#"start": start_connector,
		#"end": end_connector
	#})
	
	all_cables_data.append({
		str(Time.get_unix_time_from_system()) + "" + str(randi()): [current_cable, start_connector, end_connector]
	})

func _input(event) -> void:
	var mouse_pos = get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		InputHandler.handle_mouse_left_button(self, event, mouse_pos)
	elif event is InputEventKey and event.pressed:
		InputHandler.handle_key_pressed(self, event)
	elif event is InputEventMouseMotion:
		InputHandler.handle_mouse_motion(self, event, mouse_pos)

func reset_all_component_textures() -> void:
	for component in all_components:
		for child in component["ref"].get_children():
			if child is Sprite2D:
				child.texture = load("res://Graphics/" + component["ref"].scene_file_path.get_file().get_basename() + ".png")
				break

func get_cable_at_position(pos: Vector2) -> Dictionary:
	for i in range(all_cables_data.size() - 1, -1, -1):
		var cable_data = all_cables_data[i]
		var cable_ref = cable_data["ref"]

		if is_instance_valid(cable_ref):
			for j in range(cable_ref.get_point_count() - 1):
				if is_point_near_line(pos, cable_ref.get_point_position(j), cable_ref.get_point_position(j + 1)):
					return cable_data
	return {}

func is_point_near_line(point: Vector2, p1: Vector2, p2: Vector2) -> bool:
	var closest = p1.lerp(p2, clamp(point.distance_to(p1) / p1.distance_to(p2), 0, 1))
	return closest.distance_to(point) < 10

func align_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		snappedf(pos.x, TILE_SIZE),
		snappedf(pos.y, TILE_SIZE)
	)

func find_limited_zigzag_path(start: Vector2, end: Vector2, cable: Line2D = null) -> Array:
	var path = [start]

	if start == end:
		return path

	var first_segment_direction = null

	if cable and cable.get_point_count() > 1:
		first_segment_direction = cable.get_point_position(1) - start

	if not first_segment_direction:
		if abs(end.x - start.x) > abs(end.y - start.y):
			first_segment_direction = Vector2(end.x - start.x, 0)
		else:
			first_segment_direction = Vector2(0, end.y - start.y)

	if first_segment_direction.x != 0:
		path.append(Vector2(end.x, start.y))
	else:
		path.append(Vector2(start.x, end.y))

	path.append(end)
	return path
