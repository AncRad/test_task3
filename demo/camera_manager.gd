extends Node3D

## Combination Player and Camera Manager
## Included as a scene script (a bad practice) so it does not conflict with the Terrain3D demo when
## used together.

@export_range(0, 0.2, 0.001)
var atmosphere_dof : float = 0:
	set(value):
		atmosphere_dof = value
		update_camera_dof()
@export var camera : Camera3D
@export var move_speed: float = 60.0

const CAMERA_MAX_PITCH: float = deg_to_rad(70)
const CAMERA_MIN_PITCH: float = deg_to_rad(-89.9)
const CAMERA_RATIO: float = .625

@export var mouse_sensitivity: float = .002
@export var mouse_y_inversion: float = -1.0

@onready var _camera_yaw: Node3D = self
@onready var _camera_pitch: Node3D = camera


func _init() -> void:
	RenderingServer.set_debug_generate_wireframes(true)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_camera_dof()


func _physics_process(p_delta: float) -> void:
	position += get_camera_relative_input().normalized() * move_speed * p_delta

func update_camera_dof() -> void:
	if camera and camera.attributes is CameraAttributesPractical:
		var attr : CameraAttributesPractical = camera.attributes
		## увеличение выборки DOF по мере уменьшения угла обзора камеры
		attr.dof_blur_amount = atmosphere_dof * (70 / camera.fov)
		## это управление качеством DOF для компенсации нагрузки из-за увеличения выборки (размер выборки - это attr.dof_blur_amount)
		## FIXME это костыль - нет возможности управлять качеством DOF инидивидуально для каждой камеры
		if attr.dof_blur_amount < 0.4:
			RenderingServer.camera_attributes_set_dof_blur_quality(RenderingServer.DOF_BLUR_QUALITY_HIGH, false)
			$Label.text = str('dof: quality = high, amount = %.3f' % attr.dof_blur_amount, '; fov = %.1f' % camera.fov)
		elif attr.dof_blur_amount < 0.7:
			RenderingServer.camera_attributes_set_dof_blur_quality(RenderingServer.DOF_BLUR_QUALITY_MEDIUM, false)
			$Label.text = str('dof: quality = medium, amount = %.3f' % attr.dof_blur_amount, '; fov = %.1f' % camera.fov)
		else:
			RenderingServer.camera_attributes_set_dof_blur_quality(RenderingServer.DOF_BLUR_QUALITY_LOW, false)
			$Label.text = str('dof: quality = low, amount = %.3f' % attr.dof_blur_amount, '; fov = %.1f' % camera.fov)
		## отключение\включение DOF
		attr.dof_blur_far_enabled = not is_zero_approx(attr.dof_blur_amount)

func _input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(p_event.relative)
		get_viewport().set_input_as_handled()
		return
	if p_event is InputEventMouseButton and p_event.pressed:
		if p_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.fov = max(camera.fov - 2., 5.)
			update_camera_dof()
		elif p_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.fov = min(camera.fov + 2., 160.)
			update_camera_dof()
		return
	if p_event is InputEventKey and p_event.pressed:
		match p_event.keycode:
			KEY_F8:
				get_tree().quit()
			KEY_F10:
				var vp: Viewport = get_viewport()
				@warning_ignore('int_as_enum_without_cast')
				vp.debug_draw = (vp.debug_draw + 1 ) % 6
				get_viewport().set_input_as_handled()
			KEY_F11:
				toggle_fullscreen()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE, KEY_F12:
				if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				get_viewport().set_input_as_handled()


# Returns the input vector relative to the camera. Forward is always the direction the camera is facing
func get_camera_relative_input() -> Vector3:
	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_A): # Left
		input_dir -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D): # Right
		input_dir += global_transform.basis.x
	if Input.is_key_pressed(KEY_W): # Forward
		input_dir -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S): # Backward
		input_dir += global_transform.basis.z
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE): # Up
		input_dir += global_transform.basis.y
	if Input.is_key_pressed(KEY_Q): # Down
		input_dir -= global_transform.basis.y
	if Input.is_key_pressed(KEY_KP_ADD) or Input.is_key_pressed(KEY_EQUAL):
		move_speed = clamp(move_speed + .5, 5, 9999)
	if Input.is_key_pressed(KEY_KP_SUBTRACT) or Input.is_key_pressed(KEY_MINUS):
		move_speed = clamp(move_speed - .5, 5, 9999)
	return input_dir
	
	
func rotate_camera(p_relative:Vector2) -> void:
	_camera_yaw.rotation.y -= p_relative.x * mouse_sensitivity
	_camera_yaw.orthonormalize()
	_camera_pitch.rotation.x += p_relative.y * mouse_sensitivity * CAMERA_RATIO * mouse_y_inversion 
	_camera_pitch.rotation.x = clamp(_camera_pitch.rotation.x, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)


func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or \
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2(1280, 720))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
