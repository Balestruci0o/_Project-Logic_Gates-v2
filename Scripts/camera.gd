extends Camera2D

const EDGE_MARGIN = 20
const CAMERA_SPEED = 10.0  

var is_moving := false
var prev_mouse_pos := Vector2.ZERO

func _ready():
	drag_left_margin = 0
	drag_right_margin = 0
	drag_top_margin = 0
	drag_bottom_margin = 0
	set_process_input(true)

func start_moving(mouse_pos: Vector2):
	is_moving = true
	prev_mouse_pos = mouse_pos

func stop_moving():
	is_moving = false

func update_position(mouse_pos: Vector2):
	if is_moving:
		var delta = prev_mouse_pos - mouse_pos  
		position += delta * zoom.x  # Posun upravený podľa zoomu
		prev_mouse_pos = mouse_pos  

func _physics_process(delta: float) -> void:
	position += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * ((CAMERA_SPEED/zoom.x*2)  if Input.is_action_pressed("SpeedUp") else CAMERA_SPEED/zoom.x)

	# Plynulé zoomovanie
	if Input.is_action_just_pressed("zoom_in") and zoom.x > 0.4:
		zoom *= 0.9  
	elif Input.is_action_just_pressed("zoom_out") and zoom.x < 3:
		zoom *= 1.1  
		position = get_global_mouse_position() 

	# Plynulé posúvanie pri okrajoch
	var mouse_pos = get_global_mouse_position()
	var viewport_size = get_viewport_rect().size / zoom

	if abs(mouse_pos.x - (global_position.x - viewport_size.x / 2)) <= EDGE_MARGIN and position.x > 576:
		position.x -= (CAMERA_SPEED/zoom.x*2) * delta
	elif abs(mouse_pos.x - (global_position.x + viewport_size.x / 2)) <= EDGE_MARGIN and position.x < 17024:
		position.x += (CAMERA_SPEED/zoom.x*2) * delta

	if abs(mouse_pos.y - (global_position.y - viewport_size.y / 2)) <= EDGE_MARGIN and position.y > 324:
		position.y -= (CAMERA_SPEED/zoom.x*2) * delta
	elif abs(mouse_pos.y - (global_position.y + viewport_size.y / 2)) <= EDGE_MARGIN and position.y < 1596:
		position.y += (CAMERA_SPEED/zoom.x*2) * delta
