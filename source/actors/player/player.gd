extends CharacterBody3D


const RUNNING_SPEED = 5.0
const CROUCHING_SPEED = 2.0
const SPRINTING_SPEED = 10.0
const JUMP_VELOCITY = 4.5
const STANDING_HEAD_HEIGHT := 1.55
const CROUCHING_HEAD_HEIGHT := 1.0
const HEAD_TILT_DEGREES := 25.0
const JUMP_GRACE_PERIOD := 1.0
const STEP_LENGHT := 1.5

var crouching := false
var grounded := false
var time_since_grounded := 0.0
var current_speed := 0.0
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_step_position := Vector2.ZERO

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
@onready var head_raycast := $Head/RayCast3D
@onready var feet_raycast := $RayCast3D
@onready var viewport_size : Vector2 = get_viewport().size

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

	if Input.is_action_pressed("jump") and grounded:
		grounded = false
		animation_player.play("jump")
		velocity.y = JUMP_VELOCITY
	if not is_on_floor() and velocity.y < 0:
		last_in_air_velocity = velocity.y
	if is_on_floor() and last_in_air_velocity < 0:
		animation_player.play("land")
		last_in_air_velocity = 0
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

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


func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion_event_relative_x = event.relative.x
		mouse_motion_event_relative_y = event.relative.y


func get_direction():
	direction = Vector3.ZERO
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


func reset_mouse_motion_event_relative():
		mouse_motion_event_relative_x = 0
		mouse_motion_event_relative_y = 0


func check_is_on_floor(delta):
	if feet_raycast.is_colliding() and velocity.y <= 0.0:
		grounded = true
	else:
		time_since_grounded += delta
		if time_since_grounded >= 0.5:
			grounded = false


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


func rotate_player():
	rotate_y(mouse_motion_event_relative_x * Settings.mouse_sensitivity * -1)
	rotation_degrees.y = wrap(rotation_degrees.y, -180, 180)


func tilt_head():
	var head_tilt := 0.0
	if abs(mouse_motion_event_relative_x / viewport_size.x) > Settings.head_tilt_deadzone:
		head_tilt = -mouse_motion_event_relative_x
	head.rotation_degrees.z = lerp(head.rotation_degrees.z, HEAD_TILT_DEGREES * sign(head_tilt), 0.1)

