extends CharacterBody3D


const RUNNING_SPEED = 5.0
const CROUCHING_SPEED = 2.0
const SPRINTING_SPEED = 10.0
const JUMP_VELOCITY = 4.5
const STANDING_HEAD_HEIGHT := 1.55
const CROUCHING_HEAD_HEIGHT := 1.0
const HEAD_TILT_MOUSE_DEGREES := 25.0
const HEAD_TILT_STRIFE_DEGREES := 5.0
const JUMP_GRACE_PERIOD := 1.0
const STEP_LENGHT := 1.5

var head_tilt_deadzone := 0.05
var hand_tilt_deadzone := 0.001
var crouching := false
var grounded := false
var time_since_grounded := 0.0
var current_speed := 0.0
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_step_position := Vector2.ZERO
var weapon_sway_amount := 3.0
var input_dir := Vector2.ZERO
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

@onready var head := $Head
@onready var camera := $Head/Camera3D
@onready var footsteps_audio := $FootstepsAudio
@onready var breathing_audio := $Head/BreathingAudio
@onready var animation_player := $AnimationPlayer
@onready var standing_collision_shape := $StandingCollisionShape
@onready var crouching_collision_shape := $CrouchingCollisionShape
@onready var head_raycast := $RayCast3D2
@onready var feet_raycast := $RayCast3D
@onready var viewport_size : Vector2 = get_viewport().size
@onready var right_hand := $Head/RightHand
@onready var left_hand := $Head/LeftHand

var last_in_air_velocity := 0.0
var mouse_motion_event_relative_x := 0.0
var mouse_motion_event_relative_y := 0.0
var direction := Vector3.ZERO
@export var crouched := false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):
	get_direction()
	check_is_on_floor(delta)
	rotate_camera()
	rotate_player()
	tilt_head()
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
			else:
				current_speed = RUNNING_SPEED

	if Input.is_action_pressed("jump") and grounded and not jumped:
		animation_player.play("jump")
		velocity.y = JUMP_VELOCITY
		jumped = true
	if not is_on_floor() and velocity.y < 0:
		last_in_air_velocity = velocity.y
	if is_on_floor() and last_in_air_velocity < 0:
		animation_player.play("land")
		jumped = false
		last_in_air_velocity = 0
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, 0.9)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, 0.9)
	else:
		velocity.x = move_toward(velocity.x, 0, 0.9)
		velocity.z = move_toward(velocity.z, 0, 0.9)

	move_and_slide()


func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion_event_relative_x = event.relative.x
		mouse_motion_event_relative_y = event.relative.y


func get_direction():
	direction = Vector3.ZERO
	input_dir = Vector2.ZERO
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


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
	head.rotate_x(mouse_motion_event_relative_y * Settings.mouse_sensitivity * -1)
	head.rotation_degrees.x = clamp(head.rotation_degrees.x, -90, 90)

func weapon_sway():
	var hand_tilt_x := 0.0
	var hand_tilt_y := 0.0
	var hand_tilt_z := 0.0

	if abs(mouse_motion_event_relative_y / viewport_size.y) > hand_tilt_deadzone:
		hand_tilt_x = mouse_motion_event_relative_y
	if abs(mouse_motion_event_relative_x / viewport_size.x) > hand_tilt_deadzone:
		hand_tilt_y = mouse_motion_event_relative_x
		hand_tilt_z = mouse_motion_event_relative_x

	for hand in [right_hand, left_hand]:
		# X AXIS
		hand.rotation_degrees.x = lerp(hand.rotation_degrees.x, sign(hand_tilt_x) * weapon_sway_amount, 0.1)
		hand.rotation_degrees.x = clamp(hand.rotation_degrees.x, -25, 25)
		# Y AXIS
		hand.rotation_degrees.y = lerp(hand.rotation_degrees.y, sign(hand_tilt_y) * weapon_sway_amount, 0.1)
		hand.rotation_degrees.y = clamp(hand.rotation_degrees.y, -25, 25)
		# > AXIS
		hand.rotation_degrees.z = lerp(hand.rotation_degrees.z, sign(hand_tilt_z) * weapon_sway_amount, 0.3)
		hand.rotation_degrees.z = clamp(hand.rotation_degrees.z, -25, 25)

func rotate_player():
	rotate_y(mouse_motion_event_relative_x * Settings.mouse_sensitivity * -1)
	rotation_degrees.y = wrap(rotation_degrees.y, -180, 180)


func tilt_head():
	var head_tilt := 0.0
	var head_tilt_strife := 0.0
	if abs(mouse_motion_event_relative_x / viewport_size.x) > head_tilt_deadzone:
		head_tilt = -mouse_motion_event_relative_x
	if input_dir.x != 0.0:
		head_tilt_strife = -input_dir.x
	camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, HEAD_TILT_MOUSE_DEGREES * sign(head_tilt), 0.1)
	camera.rotation_degrees.z = lerp(camera.rotation_degrees.z, HEAD_TILT_STRIFE_DEGREES * sign(head_tilt_strife), 0.1)
