extends Camera2D

const EDGE_MARGIN = 40
const CAMERA_SPEED = 10.0  

var is_moving := false

func _ready():
	limit_top = 0
	limit_left = 0
	limit_bottom = 120 * 32
	limit_right = 1100 * 32
	drag_left_margin = 0
	drag_right_margin = 0
	drag_top_margin = 0
	drag_bottom_margin = 0
	set_process_input(true)

func start_moving(_mouse_pos: Vector2):
	is_moving = true

func stop_moving():
	is_moving = false

func update_position(relative: Vector2):
	if is_moving:
		position -= relative / zoom
		correct_position()

func correct_position():
	var viewport_size = get_viewport_rect().size / zoom
	position.x = clamp(position.x, viewport_size.x / 2, 1100 * 32 - viewport_size.x / 2)
	position.y = clamp(position.y, viewport_size.y / 2, 120 * 32 - viewport_size.y / 2)

func _physics_process(_delta: float) -> void:
	# WASD pohyb
	position += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * ((CAMERA_SPEED / zoom.x * 2) if Input.is_action_pressed("SpeedUp") else CAMERA_SPEED / zoom.x)
	correct_position()

	# Zoom in/out s udržiavaním pozície pod kurzorom
	if Input.is_action_just_pressed("zoom_in") and zoom.x > 0.6:
		var before_zoom = (get_global_mouse_position() - position) / zoom
		zoom *= 0.9
		var after_zoom = (get_global_mouse_position() - position) / zoom
		position += (before_zoom - after_zoom) * zoom
		correct_position()

	elif Input.is_action_just_pressed("zoom_out") and zoom.x < 3:
		var before_zoom = (get_global_mouse_position() - position) / zoom
		zoom *= 1.1
		var after_zoom = (get_global_mouse_position() - position) / zoom
		position += (before_zoom - after_zoom) * zoom
		correct_position()

	# Posúvanie pri okrajoch
	var mouse_pos = get_global_mouse_position()
	var viewport_size = get_viewport_rect().size / zoom

	if abs(mouse_pos.x - (global_position.x - viewport_size.x / 2)) <= EDGE_MARGIN and position.x > 576:
		position.x -= (CAMERA_SPEED / zoom.x)
	elif abs(mouse_pos.x - (global_position.x + viewport_size.x / 2)) <= EDGE_MARGIN and position.x < 17024:
		position.x += (CAMERA_SPEED / zoom.x)

	if abs(mouse_pos.y - (global_position.y - viewport_size.y / 2)) <= EDGE_MARGIN and position.y > 324:
		position.y -= (CAMERA_SPEED / zoom.y)
	elif abs(mouse_pos.y - (global_position.y + viewport_size.y / 2)) <= EDGE_MARGIN and position.y < 1596:
		position.y += (CAMERA_SPEED / zoom.y)

	correct_position()  # ← sem tiež, ak sa posúvala cez okraj
