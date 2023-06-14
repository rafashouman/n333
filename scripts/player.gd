extends CharacterBody3D
#class_name MovementController

#Move variables
@export var gravity_multiplier := 3.0
@export var speed := 3
@export var acceleration := 4
@export var deceleration := 10
@export_range(0.0, 1.0, 0.05) var air_control := 0.3
@export var jump_height := 10

#@export var sense_horizontal = 0.3
#@export var sense_vertical = 0.5
@export var mouse_sensitivity := 1.0
@export var y_limit := 54.0

var direction := Vector3()
var rot := Vector3()
var input_axis := Vector2()
var mouse_axis := Vector2()
var walking_speed := 3.0
var running_speed := 5.0
var look_free := false

#Control variables
var is_running := false
var is_locked := false

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
@onready var gravity: float = (ProjectSettings.get_setting("physics/3d/default_gravity") 
		* gravity_multiplier)
@onready var camera_mount = $camera_mount
@onready var animation_player: AnimationPlayer = $visuals/mixamo_base/AnimationPlayer
@onready var visuals: Node3D = $visuals


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#Sense and vertical move
	mouse_sensitivity = mouse_sensitivity / 1000
	y_limit = deg_to_rad(y_limit)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_axis = event.relative
		camera_rotation()

# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	#Joystick adjusts
#	var joystick_axis := Input.get_vector(&"look_left", &"look_right",
#			&"look_down", &"look_up")
#
#	if joystick_axis != Vector2.ZERO:
#		mouse_axis = joystick_axis * 1000.0 * delta
#		camera_rotation()
	
	if !animation_player.is_playing():
		is_locked = false
	
	if Input.is_action_just_pressed("kick"):
		if animation_player.current_animation != "kick":
			animation_player.play("kick")
			is_locked = true
	
	if Input.is_action_pressed("run"):
		speed = running_speed
		is_running = true
	else:
		speed = walking_speed
		is_running = false
	
	input_axis = Input.get_vector(&"move_back", &"move_forward",
			&"move_left", &"move_right")
	
	direction_input()
	
	if is_on_floor():
		if Input.is_action_just_pressed(&"jump"):
			velocity.y = jump_height
	else:
		velocity.y -= gravity * delta
	
	accelerate(delta)
	
	if !is_locked:
		move_and_slide()


func direction_input() -> void:
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	direction = aim.z * -input_axis.x + aim.x * input_axis.y

	if direction:
		if !is_locked:
			visuals.look_at(position + direction)

func accelerate(delta: float) -> void:
	# Using only the horizontal velocity, interpolate towards the input.
	var temp_vel := velocity
	temp_vel.y = 0
	
	var temp_accel: float
	var target: Vector3 = direction * speed
	
	if direction.dot(temp_vel) > 0:
		temp_accel = acceleration
	else:
		temp_accel = deceleration
	
	if not is_on_floor():
		temp_accel *= air_control
	
	temp_vel = temp_vel.lerp(target, temp_accel * delta)
	
	velocity.x = temp_vel.x
	velocity.z = temp_vel.z

	if abs(velocity.x) > 0.5 or abs(velocity.z) > 0.5:
		if !is_locked:
			if is_running:
				if animation_player.current_animation != "running":
					animation_player.play("running")
			else:
				if animation_player.current_animation != "walking":
					animation_player.play("walking")
	else:
		if !is_locked:
			if animation_player.current_animation != "idle":
				animation_player.play("idle")

func camera_rotation() -> void:
	# Horizontal mouse look.
	rot.y -= mouse_axis.x * mouse_sensitivity
	# Vertical mouse look.
	rot.x = clamp(rot.x - mouse_axis.y * mouse_sensitivity, -y_limit, y_limit)
	
	rotation.y = rot.y
	if Input.is_action_pressed(&"look_free"):
		visuals.rotation.y = -rot.y
	camera_mount.rotation.x = rot.x
#	rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
#	visuals.rotate_y(deg_to_rad(event.relative.x * sense_horizontal))
#	camera_mount.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
	
