extends Node3D

var cam_rot_h = 0
var cam_rot_v = 0
var cam_v_min = -35
var cam_v_max = 35
var h_sense = 0.1
var v_sense = 0.1
var h_accel = 10
var v_accel = 10

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$h/v/SpringArm.add_excluded_object(get_parent())
	
func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		$mouse_control_stay_delay.start()
		cam_rot_h += -event.relative.x * h_sense
		cam_rot_v += event.relative.y * v_sense
		
func _physics_process(delta: float) -> void:

	cam_rot_v = clamp(cam_rot_v, cam_v_min, cam_v_max)
	
	var mesh_front = get_node("../Mesh").global_transform.basis.z
	var rot_speed_multiplier = 0.15
	var auto_rotate_speed = (PI - mesh_front.angle_to($h.global_transform.basis.z)) * get_parent().velocity.length() * rot_speed_multiplier
	
	if $mouse_control_stay_delay.is_stopped():
		$h.rotation.y = lerp_angle($h.rotation.y, get_node("../Mesh").global_transform.basis.get_euler().y, delta * auto_rotate_speed)
		cam_rot_h = $h.rotation_degrees.y
	else:
		$h.rotation_degrees.y = lerpf($h.rotation_degrees.y, cam_rot_h, delta * h_accel)
		
	$h/v.rotation_degrees.x = lerpf($h/v.rotation_degrees.x, cam_rot_v, delta * v_accel)
