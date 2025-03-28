extends Node2D

const GRID_WIDTH = 1100 * 16
const GRID_HEIGHT = 120 * 16
const TILE_SIZE = 32  

@onready var camera = $Camera
@onready var dot_scene = preload("res://Scenes/dot.tscn")  # Prednačítanie Dot scény

var current_cable: Line2D = null
var drawing := false
var start_pos: Vector2
var viewport_size = Vector2.ZERO

var dragging_connector: Node2D = null
var selection_box: ColorRect = null  # Premenná na výberový box
var selection_start: Vector2  # Začiatočná pozícia výberu

var selected_objects: Array = []  # Pole pre uloženie vybraných objektov

var cables = []  # Zoznam všetkých káblov

func _ready():
	update_viewport_size()

func update_viewport_size():
	viewport_size = get_viewport_rect().size / camera.zoom

func _physics_process(_delta: float) -> void:
	correct_camera_position()

func correct_camera_position() -> void:
	var viewport_size = get_viewport_rect().size / camera.zoom  
	var new_position = camera.position

	new_position.x = clamp(new_position.x, viewport_size.x / 2, GRID_WIDTH - viewport_size.x / 2)
	new_position.y = clamp(new_position.y, viewport_size.y / 2, GRID_HEIGHT - viewport_size.y / 2)

	camera.position = new_position

func _input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		if event.pressed:
			var clicked_connector = get_dot_at_position(mouse_pos)
			var clicked_cable = get_cable_at_position(mouse_pos)

			if clicked_connector:
				dragging_connector = clicked_connector
			elif clicked_cable:
				if Input.is_key_pressed(KEY_CTRL):
					if clicked_cable in selected_objects:
						selected_objects.erase(clicked_cable)
					else:
						selected_objects.append(clicked_cable)

				else:
					selected_objects = [clicked_cable]
				print(selected_objects)
			else:
				selected_objects.clear()
				if Input.is_key_pressed(KEY_SHIFT):
					start_selection(mouse_pos)
				else:
					start_drawing(mouse_pos)
		else:
			if selection_box:
				finalize_selection()
			else:
				stop_drawing()
			dragging_connector = null

	elif event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		if dragging_connector:
			move_connector(mouse_pos)
		elif drawing:
			update_drawing(mouse_pos)
		elif selection_box:
			update_selection(mouse_pos)

	elif event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		delete_selected_cables()



func start_selection(mouse_pos: Vector2) -> void:
	if selection_box:  # Ak už existuje, odstráň ho
		selection_box.queue_free()
	
	selection_start = mouse_pos  # Uloženie začiatočnej pozície
	
	# Vytvorenie výberového boxu
	selection_box = ColorRect.new()
	selection_box.color = Color(0, 0, 1, 0.3)  # Modrá s priehľadnosťou
	selection_box.position = selection_start
	selection_box.size = Vector2.ZERO  # Začína ako bod
	selection_box.set_anchors_preset(Control.PRESET_TOP_LEFT)  # Kotviť hore vľavo
	
	add_child(selection_box)  # Pridanie do scény
			
			
func update_selection(mouse_pos: Vector2) -> void:

	if not selection_box:
		return
	
	var start_pos = selection_start
	var end_pos = mouse_pos
	
	# Zabezpečenie správneho smeru boxu
	selection_box.position = Vector2(
		min(start_pos.x, end_pos.x),
		min(start_pos.y, end_pos.y)
	)
	selection_box.size = Vector2(
		abs(end_pos.x - start_pos.x),
		abs(end_pos.y - start_pos.y)
	)

func finalize_selection() -> void:
	if not selection_box:
		return
	
	var box_rect = Rect2(selection_box.global_position, selection_box.size)
	selected_objects.clear()

	for obj in cables:
		if box_rect.has_point(obj["start"].position) or box_rect.has_point(obj["end"].position):
			selected_objects.append(obj["cable"])

	print("Vybrané objekty:", selected_objects)
	

	selection_box.queue_free()
	selection_box = null



func start_drawing(mouse_pos: Vector2) -> void:
	drawing = true
	start_pos = align_to_grid(mouse_pos)
	current_cable = Line2D.new()
	
	current_cable.default_color = Color.WHITE
	current_cable.width = 10
	current_cable.texture = load("res://Graphics/kabel.png")
	current_cable.texture_mode = Line2D.LINE_TEXTURE_TILE
	current_cable.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	

	add_child(current_cable)
	current_cable.add_point(start_pos)

	var start_connector = dot_scene.instantiate()
	start_connector.position = start_pos
	add_child(start_connector)

	var end_connector = dot_scene.instantiate()
	end_connector.position = start_pos  # Začína na rovnakom mieste ako začiatok
	add_child(end_connector)

	cables.append({
		"cable": current_cable,
		"start": start_connector,
		"end": end_connector
	})

func update_drawing(mouse_pos: Vector2) -> void:
	if not is_instance_valid(current_cable):
		return

	var end_pos = align_to_grid(mouse_pos)
	var path = find_limited_zigzag_path(start_pos, end_pos, current_cable)

	current_cable.set_points(path)

	if is_instance_valid(cables[-1]["end"]):
		cables[-1]["end"].position = path[-1]


func stop_drawing() -> void:
	drawing = false

func move_connector(new_pos: Vector2) -> void:
	if not is_instance_valid(dragging_connector):
		return

	var aligned_pos = align_to_grid(new_pos)
	dragging_connector.position = aligned_pos

	var affected_cables = cables.filter(func(c): return c["start"] == dragging_connector or c["end"] == dragging_connector)
	for cable_data in affected_cables:
		update_cable(cable_data)


func update_cable(cable_data) -> void:
	if not (is_instance_valid(cable_data["cable"]) and is_instance_valid(cable_data["start"]) and is_instance_valid(cable_data["end"])):
		return

	var path = find_limited_zigzag_path(cable_data["start"].position, cable_data["end"].position, cable_data["cable"])
	cable_data["cable"].clear_points()
	
	for point in path:
		cable_data["cable"].add_point(point)


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

	# Ak kábel už má body, zachováme smer prvého segmentu
	if cable and cable.get_point_count() > 1:
		first_segment_direction = cable.get_point_position(1) - start

	if not first_segment_direction:
		# Detekcia hlavného smeru (prvý pohyb)
		if abs(end.x - start.x) > abs(end.y - start.y):
			first_segment_direction = Vector2(end.x - start.x, 0)  # Horizontálny prvý segment
		else:
			first_segment_direction = Vector2(0, end.y - start.y)  # Vertikálny prvý segment

	# Aplikujeme zachovaný smer
	if first_segment_direction.x != 0:
		path.append(Vector2(end.x, start.y))  # Udrží horizontálny smer
	else:
		path.append(Vector2(start.x, end.y))  # Udrží vertikálny smer

	path.append(end)
	return path


func delete_selected_cables() -> void:
	var to_remove = cables.filter(func(cable_data): return cable_data["cable"] in selected_objects)
	
	for cable_data in to_remove:
		if is_instance_valid(cable_data["cable"]):
			cable_data["cable"].queue_free()
		if is_instance_valid(cable_data["start"]):
			cable_data["start"].queue_free()
		if is_instance_valid(cable_data["end"]):
			cable_data["end"].queue_free()

	cables = cables.filter(func(cable_data): return cable_data["cable"] not in selected_objects)
	selected_objects.clear()


func get_cable_at_position(pos: Vector2) -> Line2D:
	for i in range(cables.size() - 1, -1, -1):
		var cable = cables[i]["cable"]
		if is_instance_valid(cable):
			for j in range(cable.get_point_count() - 1):
				if is_point_near_line(pos, cable.get_point_position(j), cable.get_point_position(j + 1)):
					return cable
	return null

func get_dot_at_position(pos: Vector2) -> Node2D:
	for i in range(cables.size() - 1, -1, -1):
		var cable_data = cables[i]
		if is_instance_valid(cable_data["start"]) and cable_data["start"].position.distance_to(pos) < 10:
			return cable_data["start"]
		if is_instance_valid(cable_data["end"]) and cable_data["end"].position.distance_to(pos) < 10:
			return cable_data["end"]
	return null


func is_point_near_line(point: Vector2, p1: Vector2, p2: Vector2) -> bool:
	var closest = p1.lerp(p2, clamp(point.distance_to(p1) / p1.distance_to(p2), 0, 1))
	return closest.distance_to(point) < 10
