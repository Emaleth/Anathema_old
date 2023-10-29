extends CharacterBody3D
# FIXME: SPRINTING SPEED WHEN ADSING

const RUNNING_SPEED = 5.0
const CROUCHING_SPEED = 2.0
const SPRINTING_SPEED = 10.0
const JUMP_VELOCITY = 4.5
const STANDING_HEAD_HEIGHT := 0.75
const CROUCHING_HEAD_HEIGHT := 0.2
const HEAD_TILT_DEGREES := 25.0
const UPPER_BODY_TILT_DEGREES := 27.0
const JUMP_GRACE_PERIOD := 1.0
const STEP_LENGHT := 1.5

var ads_stance := Vector3(0.0, 0.0, -0.2)
var normal_stance := Vector3(0.4, -0.1, -0.6)
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

var footstep_sounds := [
	preload("res://assets/sounds/footsteps/footstep00.ogg"),
	preload("res://assets/sounds/footsteps/footstep01.ogg"),
	preload("res://assets/sounds/footsteps/footstep02.ogg"),
	preload("res://assets/sounds/footsteps/footstep06.ogg"),
	preload("res://assets/sounds/footsteps/footstep05.ogg"),
	preload("res://assets/sounds/footsteps/footstep04.ogg"),
	preload("res://assets/sounds/footsteps/footstep03.ogg"),
	preload("res://assets/sounds/footsteps/footstep08.ogg"),
	preload("res://assets/sounds/footsteps/footstep09.ogg"),
	preload("res://assets/sounds/footsteps/footstep07.ogg"),
]

@onready var head := $UpperBody/Head
@onready var camera := $UpperBody/Head/Camera3D
@onready var footsteps_audio := $FootstepsAudio
@onready var breathing_audio := $UpperBody/Head/BreathingAudio
@onready var animation_player := $AnimationPlayer
@onready var standing_collision_shape := $StandingCollisionShape
@onready var crouching_collision_shape := $CrouchingCollisionShape
@onready var head_raycast := $RayCast3D2
@onready var feet_raycast := $RayCast3D
@onready var viewport_size : Vector2 = get_viewport().size
@onready var right_hand := $UpperBody/Head/RightHand
@onready var left_hand := $UpperBody/Head/LeftHand
@onready var upper_body := $UpperBody
@onready var voice_audio := $UpperBody/Head/VoiceAudio

var last_in_air_velocity := 0.0
var mouse_motion_event_relative_x := 0.0
var mouse_motion_event_relative_y := 0.0
var direction := Vector3.ZERO
@export var crouched := false # just for the crouch / stand animation
var tilt := 0.0
var sprinting := false
var adsing := false
var weapon : Node3D
@onready var fps_arms := $UpperBody/Head/FPSArms


signal sig_ads
signal sig_no_ads


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapon = right_hand.get_child(0) # tmp
	arms_ik_setup()


func arms_ik_setup():
	fps_arms.right_arm_ik.target_node = right_hand.get_path()
	fps_arms.left_arm_ik.target_node = left_hand.get_path()
	fps_arms.right_arm_ik.start()
	fps_arms.left_arm_ik.start()


func _physics_process(delta):
	get_direction()
	get_tilt()
	check_is_on_floor(delta)
	rotate_camera()
	head_bob()
	rotate_player()
	ads()
	tilt_head()
	tilt_upper_body()
	weapon_sway()
	footsteps()
	reset_mouse_motion_event_relative()

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_pressed("crouch") and is_on_floor():
		crouching = true
		if not crouched: animation_player.play("crouch")
	else:
		if crouched: animation_player.play("stand")
		crouching = false

	if Input.is_action_pressed("primary_action"):
		weapon.use()
	if Input.is_action_pressed("secondary_action"):
		adsing = true
		sig_ads.emit()
	else:
		adsing = false
		sig_no_ads.emit()

	if crouching:
		current_speed = CROUCHING_SPEED
		head.position.y = lerp(head.position.y, CROUCHING_HEAD_HEIGHT, 0.3)
		standing_collision_shape.set_deferred("disabled", true)
		crouching_collision_shape.set_deferred("disabled", false)
	else:
		if not head_raycast.is_colliding():
			head.position.y = lerp(head.position.y, STANDING_HEAD_HEIGHT, 0.3)
			standing_collision_shape.set_deferred("disabled", false)
			crouching_collision_shape.set_deferred("disabled", true)
			if Input.is_action_pressed("sprint") and grounded:
				current_speed = SPRINTING_SPEED
				sprinting = true
			else:
				current_speed = RUNNING_SPEED
				sprinting = false

	if Input.is_action_pressed("jump") and grounded and not jumped:
		animation_player.play("jump")
		velocity.y = JUMP_VELOCITY
		voice_audio.play()
		jumped = true
	if not is_on_floor() and velocity.y < 0:
		last_in_air_velocity = velocity.y
	if is_on_floor() and last_in_air_velocity < 0:
		animation_player.play("land")
		jumped = false
		last_in_air_velocity = 0
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleraion)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleraion)
	else:
		if crouching and sprinting:
			velocity.x = move_toward(velocity.x, 0, slide_deceleraion)
			velocity.z = move_toward(velocity.z, 0, slide_deceleraion)
		else:
			velocity.x = move_toward(velocity.x, 0, normal_deceleraion)
			velocity.z = move_toward(velocity.z, 0, normal_deceleraion)

	move_and_slide()


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


func check_is_on_floor(delta):
	grounded = false
	if is_on_floor():
		grounded = true
	elif feet_raycast.is_colliding():
		grounded = true
	else:
		time_since_grounded += delta
		if time_since_grounded <= 0.1:
			grounded = true
			time_since_grounded = 0


func footsteps():
	if is_on_floor():
		var current_position = Vector2(position.x, position.z)
		if current_position.distance_squared_to(last_step_position) > pow(STEP_LENGHT, 2):
			footsteps_audio.stream = footstep_sounds.pick_random()
			footsteps_audio.play()
			last_step_position = Vector2(position.x, position.z)


func rotate_camera():
	head.rotation.x += mouse_motion_event_relative_y * Settings.mouse_sensitivity * -1
	head.rotation_degrees.x = clamp(head.rotation_degrees.x, -90, 90)


func weapon_sway():
	var hand_tilt_x := 0.0
	var hand_tilt_y := 0.0
	var hand_tilt_z := 0.0
	var hand_position := Vector3.ZERO

	if abs(mouse_motion_event_relative_y / viewport_size.y) > hand_tilt_deadzone:
		hand_tilt_x = mouse_motion_event_relative_y
	if abs(mouse_motion_event_relative_x / viewport_size.x) > hand_tilt_deadzone:
		hand_tilt_y = mouse_motion_event_relative_x
		hand_tilt_z = mouse_motion_event_relative_x

	if sprinting:
		hand_position.x = 65.0
		hand_position.y = 15.0
		hand_position.y = 15.0
	else:
		hand_position.x = 0.0
		hand_position.y = 0.0
		hand_position.y = 0.0
	# RIGHT
	right_hand.rotation_degrees.x = lerp(right_hand.rotation_degrees.x, sign(hand_tilt_x) * weapon_sway_amount + hand_position.x, 0.1)
	right_hand.rotation_degrees.y = lerp(right_hand.rotation_degrees.y, sign(hand_tilt_y) * weapon_sway_amount + hand_position.y, 0.1)
	right_hand.rotation_degrees.z = lerp(right_hand.rotation_degrees.z, sign(hand_tilt_z) * weapon_sway_amount + hand_position.z, 0.3)
	# LEFT
	left_hand.rotation_degrees.x = lerp(left_hand.rotation_degrees.x, sign(hand_tilt_x) * weapon_sway_amount + hand_position.x, 0.1)
	left_hand.rotation_degrees.y = lerp(left_hand.rotation_degrees.y, sign(hand_tilt_y) * weapon_sway_amount + -hand_position.y, 0.1)
	left_hand.rotation_degrees.z = lerp(left_hand.rotation_degrees.z, sign(hand_tilt_z) * weapon_sway_amount + -hand_position.z, 0.3)


func rotate_player():
	rotation.y += mouse_motion_event_relative_x * Settings.mouse_sensitivity * -1
	rotation_degrees.y = wrap(rotation_degrees.y, -180, 180)


func tilt_head():
	var head_tilt := 0.0
	if abs(mouse_motion_event_relative_x / viewport_size.x) > head_tilt_deadzone:
		head_tilt = -mouse_motion_event_relative_x
	head.rotation_degrees.z = lerp(head.rotation_degrees.z, HEAD_TILT_DEGREES * sign(head_tilt), 0.1)


func tilt_upper_body():
	upper_body.rotation_degrees.z = lerp(upper_body.rotation_degrees.z, UPPER_BODY_TILT_DEGREES * tilt, 0.1)


func ads():
	if adsing:
		sprinting = false
		right_hand.position = lerp(right_hand.position, ads_stance, 0.3)
		left_hand.position = lerp(left_hand.position, ads_stance * Vector3(-1.0, 1.0, 1.0), 0.3)
	else:
		right_hand.position = lerp(right_hand.position, normal_stance, 0.3)
		left_hand.position = lerp(left_hand.position, normal_stance * Vector3(-1.0, 1.0, 1.0), 0.3)


func head_bob():
	pass



func _on_right_hand_child_entered_tree(node: Node) -> void:
	set_visibility(node)


func _on_left_hand_child_entered_tree(node: Node) -> void:
	set_visibility(node)


func set_visibility(node : Node):
	for i in node.get_children():
		if i is MeshInstance3D or i is GPUParticles3D:
			i.layers = 2
