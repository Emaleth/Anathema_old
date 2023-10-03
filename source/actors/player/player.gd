extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_sensitivity := 0.01
@onready var camera := $Camera3D
@onready var footsteps_audio := $FootstepsAudio


var travelled_distance := 0
var step_lenght := 2.0
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

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		footsteps()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(event.relative.x * mouse_sensitivity * -1)
		rotation_degrees.y = wrap(rotation_degrees.y, -180, 180)
		camera.rotate_x(event.relative.y * mouse_sensitivity * -1)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -90, 90)

func footsteps():
	if is_on_floor():
		travelled_distance += velocity.length()
		if travelled_distance >= step_lenght:
			travelled_distance = 0.0
			footsteps_audio.stream = footstep_sounds.pick_random()
			footsteps_audio.play()
