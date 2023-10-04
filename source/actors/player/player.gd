extends CharacterBody3D


const RUNNING_SPEED = 5.0
const CROUCHING_SPEED = 2.0
const SPRINTING_SPEED = 10.0
const JUMP_VELOCITY = 4.5
const STANDING_HEAD_HEIGHT := 1.55
const CROUCHING_HEAD_HEIGHT := 1.0

var crouching := false

var current_speed := 5.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var step_time := 1.0
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
@onready var footsteps_audio := $FootstepsAudio
@onready var breathing_audio := $Head/BreathingAudio
@onready var footstep_timer := $FootstepTimer



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	footstep_timer.timeout.connect(footsteps)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if Input.is_action_pressed("crouch") and is_on_floor():
		crouching = true
	else:
		crouching = false
		
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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
		$StandingCollisionShape.set_deferred("disabled", true)
		$CrouchingCollisionShape.set_deferred("disabled", false)
	else:
		if not $Head/RayCast3D.is_colliding():
			head.position.y = lerp(head.position.y, STANDING_HEAD_HEIGHT, 0.3)
			$StandingCollisionShape.set_deferred("disabled", false)
			$CrouchingCollisionShape.set_deferred("disabled", true)
			if Input.is_action_pressed("sprint") and is_on_floor():
				current_speed = SPRINTING_SPEED
			else:
				current_speed = RUNNING_SPEED
		
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(event.relative.x * Settings.mouse_sensitivity * -1)
		rotation_degrees.y = wrap(rotation_degrees.y, -180, 180)
		head.rotate_x(event.relative.y * Settings.mouse_sensitivity * -1)
		head.rotation_degrees.x = clamp(head.rotation_degrees.x, -90, 90)


func footsteps():
	if is_on_floor() && velocity.length() > 0.0:
		footsteps_audio.stream = footstep_sounds.pick_random()
		footsteps_audio.play()
	footstep_timer.start(step_time / current_speed)

