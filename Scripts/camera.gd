extends Camera2D

const EDGE_MARGIN = 20

func _physics_process(_delta: float) -> void:
	position += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * (10 if Input.is_action_pressed("SpeedUp") else 5)

	if Input.is_action_just_pressed("zoom_in") and zoom.x > 0.2:
		zoom = Vector2.ONE * (zoom.x - 0.5)
	elif Input.is_action_just_pressed("zoom_out") and zoom.x < 3:
		zoom = Vector2.ONE * (zoom.x + 0.5)
		position = get_global_mouse_position()

	if abs(get_global_mouse_position().x - (global_position.x - get_viewport_rect().size.x / (2 * zoom.x))) <= EDGE_MARGIN && position.x != 576:
		position.x -= 10
	elif abs(get_global_mouse_position().x - (global_position.x + get_viewport_rect().size.x / (2 * zoom.x))) <= EDGE_MARGIN && position.x != 17024:
		position.x += 10

	if abs(get_global_mouse_position().y - (global_position.y - get_viewport_rect().size.y / (2 * zoom.y))) <= EDGE_MARGIN && position.y != 324:
		position.y -= 10
	elif abs(get_global_mouse_position().y - (global_position.y + get_viewport_rect().size.y / (2 * zoom.y))) <= EDGE_MARGIN && position.y != 1596:
		position.y += 10
