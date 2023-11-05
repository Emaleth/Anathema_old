extends CharacterBody3D

enum {IDLE, RUN, JUMP, FALL, SPRINT, CROUCH}
enum {HIPFIRE, ADS}

const RUNNING_SPEED = 5.0
const CROUCHING_SPEED = 2.0
const SPRINTING_SPEED = 10.0
const SLIDING_SPEED = 10.0
const JUMP_VELOCITY = 4.5
const STANDING_HEAD_HEIGHT := 0.75
const CROUCHING_HEAD_HEIGHT := 0.2
const HEAD_TILT_DEGREES := 25.0
const UPPER_BODY_TILT_DEGREES := 27.0
const JUMP_GRACE_PERIOD := 1.0
const STEP_LENGHT := 1.5

var ads_stance := Vector3(0.0, 0.0, -0.2)
var hipfire_stance := Vector3(0.4, -0.1, -0.6)
var acceleraion := 0.9
var normal_deceleraion := 0.9
var slide_deceleraion := 0.001
var head_tilt_deadzone := 0.05
var hand_tilt_deadzone := 0.001
var crouching := false
var grounded := false
var time_since_grounded := 0.0
var current_speed := 0.0
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_step_position := Vector2.ZERO
var weapon_sway_amount := 3.0
var jumped := false

@onready var head := $UpperBody/Head
@onready var camera := $UpperBody/Head/Camera3D
@onready var footsteps_audio := $FootstepsAudio
@onready var breathing_audio := $UpperBody/Head/BreathingAudio
@onready var animation_player := $AnimationPlayer
@onready var standing_collision_shape := $StandingCollisionShape
@onready var crouching_collision_shape := $CrouchingCollisionShape
@onready var head_raycast := $RayCast3D2
@onready var chest := $UpperBody/Head/Chest
@onready var feet_raycast := $RayCast3D
@onready var viewport_size : Vector2 = get_viewport().size
@onready var right_hand := $UpperBody/Head/Chest/RightHand
@onready var left_hand := $UpperBody/Head/Chest/LeftHand
@onready var upper_body := $UpperBody
@onready var voice_audio := $UpperBody/Head/VoiceAudio
@onready var fps_arms := $UpperBody/Head/Chest/FPSArms

var sin_time := 0.0
var sin_frequency := 2.0
var sin_amplitude := 0.0003
var last_in_air_velocity := 0.0
var mouse_motion_event_relative_x := 0.0
var mouse_motion_event_relative_y := 0.0
var direction := Vector3.ZERO
var tilt := 0.0
var adsing := false
var weapon : Node3D
var motion_state : int
var aim_state : int
var hand_position := Vector3.ZERO
var hand_tilt := Vector3.ZERO


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapon = right_hand.get_child(0) # tmp
	arms_ik_setup()
	switch_motion_state(IDLE)
	switch_aim_state(HIPFIRE)


func _physics_process(delta: float) -> void:
	hand_tilt = Vector3.ZERO
	get_direction()
	get_tilt()
	motion_fsm(delta)
	aim_fsm(delta)
	rotate_camera()
	rotate_player()
	hand_stance()
	weapon_sway()
	arm_swing(delta)
	reset_mouse_motion_event_relative()


func arms_ik_setup():
	fps_arms.right_arm_ik.target_node = right_hand.get_path()
	fps_arms.left_arm_ik.target_node = left_hand.get_path()
	fps_arms.right_arm_ik.start()
	fps_arms.left_arm_ik.start()


func switch_motion_state(_new_state : int):
	if _new_state == motion_state:
		return
	else:
		motion_state = _new_state


func switch_aim_state(_new_state : int):
	if _new_state == aim_state:
		return
	else:
		aim_state = _new_state


func motion_fsm(delta):
	match motion_state:
		IDLE:
			hand_position = Vector3.ZERO
		RUN:
			hand_position = Vector3.ZERO
		JUMP:
			hand_position = Vector3.ZERO
		FALL:
			hand_position = Vector3.ZERO
		SPRINT:
			hand_position = Vector3(65.0, 15.0, 15.0)
		CROUCH:
			hand_position = Vector3.ZERO


func aim_fsm(delta):
	match aim_state:
		HIPFIRE:
			hipfire_mode()
			sin_frequency = lerp(sin_frequency, 2.0, 0.2)
			sin_amplitude = lerp(sin_amplitude, 0.0003, 0.2)
			get_hand_tilt()
		ADS:
			if motion_state == SPRINT:
				switch_motion_state(RUN)
			ads_mode()
			sin_frequency = lerp(sin_frequency, 0.0, 0.2)
			sin_amplitude = lerp(sin_amplitude, 0.0000, 0.2)


func arm_swing(delta):
	chest.position.y += cos(sin_time * sin_frequency) * sin_amplitude
	chest.position.x += sin(sin_time * sin_frequency * 0.5) * sin_amplitude
	sin_time += delta


func rotate_camera():
	head.rotation.x += mouse_motion_event_relative_y * Settings.mouse_sensitivity * -1
	head.rotation_degrees.x = clamp(head.rotation_degrees.x, -90, 90)


func rotate_player():
	rotation.y += mouse_motion_event_relative_x * Settings.mouse_sensitivity * -1
	rotation_degrees.y = wrap(rotation_degrees.y, -180, 180)


func ads_mode():
	weapon.set_ads(true)
	right_hand.position = lerp(right_hand.position, ads_stance, 0.3)


func hipfire_mode():
	weapon.set_ads(false)
	right_hand.position = lerp(right_hand.position, hipfire_stance, 0.3)


func hand_stance():
	right_hand.rotation_degrees.x = lerp(right_hand.rotation_degrees.x, hand_position.x, 0.1)
	right_hand.rotation_degrees.y = lerp(right_hand.rotation_degrees.y, hand_position.y, 0.1)
	right_hand.rotation_degrees.z = lerp(right_hand.rotation_degrees.z, hand_position.z, 0.3)


func get_hand_tilt():
	if abs(mouse_motion_event_relative_y / viewport_size.y) > hand_tilt_deadzone:
		hand_tilt.x = sign(mouse_motion_event_relative_y)
	if abs(mouse_motion_event_relative_x / viewport_size.x) > hand_tilt_deadzone:
		hand_tilt.y = sign(mouse_motion_event_relative_x)
		hand_tilt.z = sign(mouse_motion_event_relative_x)


func weapon_sway():
	right_hand.rotation_degrees.x += lerp(right_hand.rotation_degrees.x, sign(hand_tilt.x) * weapon_sway_amount, 0.1)
	right_hand.rotation_degrees.y += lerp(right_hand.rotation_degrees.y, sign(hand_tilt.y) * weapon_sway_amount, 0.1)
	right_hand.rotation_degrees.z += lerp(right_hand.rotation_degrees.z, sign(hand_tilt.z) * weapon_sway_amount, 0.3)


func _on_right_hand_child_entered_tree(node: Node) -> void:
	set_visibility(node)


func _on_left_hand_child_entered_tree(node: Node) -> void:
	set_visibility(node)


func set_visibility(node : Node):
	for i in node.get_children():
		if i is MeshInstance3D or i is GPUParticles3D:
			i.layers = 2

func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion_event_relative_x = event.relative.x
		mouse_motion_event_relative_y = event.relative.y


func get_direction():
	direction = Vector3.ZERO
	var input_dir := Vector2.ZERO
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


func get_tilt():
	tilt = 0.0
	tilt = Input.get_action_strength("tilt_left") - Input.get_action_strength("tilt_right")


func reset_mouse_motion_event_relative():
		mouse_motion_event_relative_x = 0
		mouse_motion_event_relative_y = 0
#
####################################################################################################
####################################################################################################
#####################################################################################################
#func _physics_process(delta):
#	check_is_on_floor(delta)
#	tilt_head()
#	tilt_upper_body()
#	weapon_sway()
#	footsteps()

#
#	if not is_on_floor():
#		velocity.y -= gravity * delta
#
#	if Input.is_action_pressed("crouch") and is_on_floor():
#		crouching = true
#		if not crouched: animation_player.play("crouch")
#	else:
#		if crouched: animation_player.play("stand")
#		crouching = false
#
#	if Input.is_action_just_pressed("reload"):
#		weapon.reload()
#	if Input.is_action_pressed("primary_action"):
#		weapon.use()
##		recoil_force += Vector2(0.01, 0.01 * sign(randf()*2-1))
#	if Input.is_action_pressed("secondary_action"):
#		adsing = true
#		sig_ads.emit()
#	else:
#		adsing = false
#		sig_no_ads.emit()
#
#	if crouching or sliding:
#		current_speed = CROUCHING_SPEED
#		head.position.y = lerp(head.position.y, CROUCHING_HEAD_HEIGHT, 0.3)
#		standing_collision_shape.set_deferred("disabled", true)
#		crouching_collision_shape.set_deferred("disabled", false)
#	else:
#		if not head_raycast.is_colliding():
#			head.position.y = lerp(head.position.y, STANDING_HEAD_HEIGHT, 0.3)
#			standing_collision_shape.set_deferred("disabled", false)
#			crouching_collision_shape.set_deferred("disabled", true)
#			if Input.is_action_pressed("sprint") and grounded:
#				current_speed = SPRINTING_SPEED
#				sprinting = true
#			else:
#				current_speed = RUNNING_SPEED
#				sprinting = false
#
#	if Input.is_action_pressed("jump") and grounded and not jumped:
#		animation_player.play("jump")
#		velocity.y = JUMP_VELOCITY
#		voice_audio.play()
#		jumped = true
#	if not is_on_floor() and velocity.y < 0:
#		last_in_air_velocity = velocity.y
#	if is_on_floor() and last_in_air_velocity < 0:
#		animation_player.play("land")
#		jumped = false
#		last_in_air_velocity = 0
#	if sliding:
#		current_speed = SPRINTING_SPEED
#		slide_timer += delta
#		if slide_timer > slide_max_time:
#			sliding = false
#			slide_timer = 0.0
#		velocity.x = move_toward(velocity.x, 0, slide_deceleraion)
#		velocity.z = move_toward(velocity.z, 0, slide_deceleraion)
#	elif direction:
#		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleraion)
#		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleraion)
#	else:
#		if crouching and sprinting:
#			sliding = true
#		else:
#			velocity.x = move_toward(velocity.x, 0, normal_deceleraion)
#			velocity.z = move_toward(velocity.z, 0, normal_deceleraion)
#
#	move_and_slide()
#
#
#
#func check_is_on_floor(delta):
#	grounded = false
#	if is_on_floor():
#		grounded = true
#	elif feet_raycast.is_colliding():
#		grounded = true
#	else:
#		time_since_grounded += delta
#		if time_since_grounded <= 0.1:
#			grounded = true
#			time_since_grounded = 0
#
#
#func footsteps():
#	if is_on_floor():
#		var current_position = Vector2(position.x, position.z)
#		if current_position.distance_squared_to(last_step_position) > pow(STEP_LENGHT, 2):
#			footsteps_audio.pitch_scale = randf_range(0.9, 1.1)
#			footsteps_audio.play()
#			last_step_position = Vector2(position.x, position.z)
#
#
#
#
#
#
#func tilt_head():
#	var head_tilt := 0.0
#	if abs(mouse_motion_event_relative_x / viewport_size.x) > head_tilt_deadzone:
#		head_tilt = -mouse_motion_event_relative_x
#	head.rotation_degrees.z = lerp(head.rotation_degrees.z, HEAD_TILT_DEGREES * sign(head_tilt), 0.1)
#
#
#func tilt_upper_body():
#	upper_body.rotation_degrees.z = lerp(upper_body.rotation_degrees.z, UPPER_BODY_TILT_DEGREES * tilt, 0.1)
#
#
#
#
#
#

#
#
#func recoil(recoil_force : Vector2):
#	rotation.y += recoil_force.y
#	head.rotation.x += recoil_force.x
#	rotation_degrees.y = wrap(rotation_degrees.y, -180, 180)
#	head.rotation_degrees.x = clamp(head.rotation_degrees.x, -90, 90)
#
#var sliding := false
#var slide_timer := 0.0
#var slide_max_time := 3.0
