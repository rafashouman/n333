extends CharacterBody3D

var direction = Vector3.FORWARD

var strafe_dir = Vector3.ZERO
var strafe = Vector3.ZERO
var aim_turn = 0

var move_speed = 0
var run_speed = 5
var walk_speed = 1.5
var acceleration = 6
var angular_acceleration = 7

var vertical_velocity = 0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var roll_magnitude = 18

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015

	if event.is_action_pressed("run"):
		if $roll_window.is_stopped():
			$roll_window.start()
			
	if event.is_action_released("run"):
		if !$roll_window.is_stopped():
			velocity = direction * roll_magnitude
			$roll_window.stop()
			$AnimationTree.set("parameters/roll/active", true)
			$AnimationTree.set("parameters/aim_transition/current_state", "not_aiming")
			$roll_timer.start()
			
func _physics_process(delta: float) -> void:
	
	if !$roll_timer.is_stopped():
		acceleration = 3.5
	else:
		acceleration = 5

	if Input.is_action_pressed("aim"):
		if !$AnimationTree.get("parameters/roll/active"):
			$AnimationTree.set("parameters/aim_transition/transition_request", "aiming")
		
	else:
		print('no-aimmmm')
		$AnimationTree.set("parameters/aim_transition/transition_request", "not_aiming")
	
	var h_rot = $Cam_root/h.global_transform.basis.get_euler().y
	
	if Input.is_action_pressed("move_forward") || Input.is_action_pressed("move_backward") || Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):
		
		direction = Vector3(Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
		0,
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward"))
	
		strafe_dir = direction
		
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
			
		if Input.is_action_pressed("run") && $AnimationTree.get("parameters/aim_transition/current_state") == "not_aiming":
			move_speed = run_speed
			#$AnimationTree.set("parameters/iwr_blend/blend_amount", lerpf($AnimationTree.get("parameters/iwr_blend/blend_amount"), 1, delta * acceleration))
		else:
			move_speed = walk_speed
			#$AnimationTree.set("parameters/iwr_blend/blend_amount", lerpf($AnimationTree.get("parameters/iwr_blend/blend_amount"), 0, delta * acceleration))
	else:
		#$AnimationTree.set("parameters/iwr_blend/blend_amount", lerpf($AnimationTree.get("parameters/iwr_blend/blend_amount"), -1, delta * acceleration))
		move_speed = 0
		strafe_dir = Vector3.ZERO
		
		if $AnimationTree.get("parameters/aim_transition/current_state") == "aiming":
			direction = $Cam_root/h.global_transform.basis.z
		
	velocity = lerp(velocity, direction *  move_speed, delta * acceleration)
	
	if !is_on_floor():
		vertical_velocity += gravity * delta
	else:
		vertical_velocity = 0
		
	velocity = velocity + Vector3.DOWN * vertical_velocity
	
	move_and_slide()
	
	if $AnimationTree.get("parameters/aim_transition/current_state") == "not_aiming":
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(direction.x, direction.z), delta * angular_acceleration)
	else:
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, h_rot, delta * angular_acceleration)
		
	strafe = lerp(strafe, strafe_dir + Vector3.RIGHT * aim_turn, delta * acceleration)

	$AnimationTree.set("parameters/strafe/blend_position", Vector2(-strafe.x, strafe.z))
	
	var iw_blend = (velocity.length() - walk_speed) / walk_speed
	var wr_blend = (velocity.length() - walk_speed) / (run_speed -walk_speed)
	
	if velocity.length() <= walk_speed:
		$AnimationTree.set("parameters/iwr_blend/blend_amount", iw_blend)
	else:
		$AnimationTree.set("parameters/iwr_blend/blend_amount", wr_blend)
	
	aim_turn = 0
	
	print('p ', $AnimationTree.get("parameters/strafe/blend_position"))
	print('v ', Vector2(-strafe.x, strafe.z))
