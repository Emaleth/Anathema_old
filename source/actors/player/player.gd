extends CharacterBody3D

enum {IDLE, RUN, JUMP, FALL, DASH, CROUCH, SLIDE, LAND}
const states_array := ["IDLE", "RUN", "JUMP", "FALL", "DASH", "CROUCH", "SLIDE", "LAND"]

const RUNNING_SPEED = 8.0
const CROUCHING_SPEED = 2.0
const SPRINTING_SPEED = 10.0
const SLIDING_SPEED = 10.0
const AIR_SPEED = 5.0
const JUMP_FORCE = 5.0
const STANDING_HEAD_HEIGHT := 0.75
const CROUCHING_HEAD_HEIGHT := 0.2
const SLIDING_HEAD_HEIGHT := 0.0
const UPPER_BODY_TILT_DEGREES := 27.0
const STEP_LENGHT := 1.5
const HIPFIRE_STANCE := Vector3(0.25, -0.4, -0.6)
const SLIDE_MAX_DISTANCE := 5

var motion_state_entered := false
var acceleraion := 0.9
var current_speed := 0.0
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_step_position := Vector2.ZERO
var mouse_sensitivity := 0.0

@onready var head := $UpperBody/Head
@onready var camera := $UpperBody/Head/Camera3D
@onready var weapon_camera := $UpperBody/Head/Camera3D/SubViewportContainer/SubViewport/Camera3D
@onready var footsteps_audio := $FootstepsAudio
@onready var breathing_audio := $UpperBody/Head/BreathingAudio
@onready var sliding_audio := $SlideAudio
@onready var standing_collision_shape := $StandingCollisionShape
@onready var crouching_collision_shape := $CrouchingCollisionShape
@onready var head_raycast := $RayCast3D
@onready var chest := $UpperBody/Head/Chest
@onready var viewport_size : Vector2 = get_viewport().size
@onready var right_hand := $UpperBody/Head/Chest/RightHand
@onready var right_weapon_pivot := $UpperBody/Head/Chest/RightHand/WeaponPivot
@onready var left_hand := $UpperBody/Head/Chest/LeftHand
@onready var upper_body := $UpperBody
@onready var voice_audio := $UpperBody/Head/VoiceAudio
@onready var fps_arms := $UpperBody/Head/Chest/FPSArms
@onready var camera_ray := $UpperBody/Head/RayCast3D
@onready var animations := $Animations

var mouse_motion_event_relative := Vector2.ZERO
var direction := Vector3.ZERO
var tilt := 0.0
var state : int
var slide_start_position := Vector3.ZERO


func _ready():
	right_hand.position = HIPFIRE_STANCE
	mouse_sensitivity = Settings.mouse_sensitivity
	get_tree().process_frame.connect(reset_mouse_motion_event_relative)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	arms_ik_setup()
	switch_state(IDLE)
	camera.fov = Settings.field_of_view
	weapon_camera.fov = Settings.field_of_view
	Signals.update_fov_setting.connect(func(value : int): camera.fov = value; weapon_camera.fov = value)
	Signals.update_mouse_sensitivity_setting.connect(update_mouse_sensitivity)
	get_tree().create_timer(0.1).timeout.connect(emit_initial_signals)


func _process(_delta: float) -> void:
	emit_camera_ray_signal()


func _physics_process(delta: float) -> void:
	get_direction()
	get_tilt()
	animations.tilt_head(head)
	animations.head_bob()
	fsm(delta)
	animations.arm_swing(chest, delta)
	rotate_camera()
	rotate_player()
	animations.weapon_sway(right_weapon_pivot)
	shoot()
	move_and_slide()


func emit_camera_ray_signal():
	var camera_ray_collision_point := Vector3.ZERO
	var camera_ray_collision_normal := Vector3.ZERO
	camera_ray.force_raycast_update()
	if camera_ray.get_collider():
		camera_ray_collision_point = camera_ray.get_collision_point()
		camera_ray_collision_normal = camera_ray.get_collision_normal()
	else:
		camera_ray_collision_point = (head.global_transform.translated(Vector3.FORWARD * head.global_transform.basis.inverse() * 100)).origin
		camera_ray_collision_normal = Vector3.ONE
	Signals.update_camera_ray_collision_point.emit(camera_ray_collision_point, camera_ray_collision_normal)



func shoot():
	if Input.is_action_pressed("primary_action"):
		Signals.primary_action.emit()


func arms_ik_setup():
	fps_arms.right_arm_ik.target_node = right_hand.get_path()
	fps_arms.left_arm_ik.target_node = left_hand.get_path()
	fps_arms.right_arm_ik.start()
	fps_arms.left_arm_ik.start()


func switch_state(_new_state : int):
	if _new_state == state:
		return
	else:
		motion_state_entered = false
		state = _new_state
		Signals.update_motion_state.emit(states_array[_new_state])


func fsm(delta):
	match state:
		IDLE:
			if not motion_state_entered:
				current_speed = 0
				standing_collision_shape.set_deferred("disabled", false)
				crouching_collision_shape.set_deferred("disabled", true)
				motion_state_entered = true
			if not is_on_floor():
				switch_state(FALL)
			tilt_upper_body()
			if head_raycast.is_colliding():
				switch_state(CROUCH)
			head.position.y = lerp(head.position.y, STANDING_HEAD_HEIGHT, 0.3)
			if direction != Vector3.ZERO:
				switch_state(RUN)
			if Input.is_action_pressed("jump"):
				switch_state(JUMP)
			if Input.is_action_pressed("crouch"):
				switch_state(CROUCH)
		RUN:
			if not motion_state_entered:
				current_speed = RUNNING_SPEED
				standing_collision_shape.set_deferred("disabled", false)
				crouching_collision_shape.set_deferred("disabled", true)
				motion_state_entered = true
			if Input.is_action_pressed("crouch"):
				switch_state(SLIDE)
			if Input.is_action_pressed("jump"):
				switch_state(JUMP)
			if not is_on_floor():
				switch_state(FALL)
			if direction == Vector3.ZERO:
				switch_state(IDLE)
			if head_raycast.is_colliding():
				switch_state(CROUCH)
			footsteps()
			head.position.y = lerp(head.position.y, STANDING_HEAD_HEIGHT, 0.3)
			if Input.is_action_pressed("dash"):
				switch_state(DASH)
		JUMP:
			if not motion_state_entered:
				current_speed = AIR_SPEED
				standing_collision_shape.set_deferred("disabled", false)
				crouching_collision_shape.set_deferred("disabled", true)
				animations.jump_animation(camera)
				voice_audio.play()
				velocity.y = JUMP_FORCE
				motion_state_entered = true
			head.position.y = lerp(head.position.y, STANDING_HEAD_HEIGHT, 0.3)
			velocity.y -= gravity * delta
			if velocity.y <= 0:
				switch_state(FALL)
		FALL:
			if not motion_state_entered:
				standing_collision_shape.set_deferred("disabled", false)
				crouching_collision_shape.set_deferred("disabled", true)
				current_speed = AIR_SPEED
				motion_state_entered = true
			head.position.y = lerp(head.position.y, STANDING_HEAD_HEIGHT, 0.3)
			velocity.y -= gravity * delta
			if Input.is_action_pressed("jump"):
				switch_state(JUMP)
			if is_on_floor():
				switch_state(LAND)
		DASH:
			if not motion_state_entered:
				current_speed = SPRINTING_SPEED
				standing_collision_shape.set_deferred("disabled", false)
				crouching_collision_shape.set_deferred("disabled", true)
				motion_state_entered = true
			if Input.is_action_pressed("crouch"):
				switch_state(SLIDE)
			if Input.is_action_pressed("jump"):
				switch_state(JUMP)
			if not is_on_floor():
				switch_state(FALL)
			if direction == Vector3.ZERO:
				switch_state(IDLE)
			else:
				if not Input.is_action_pressed("dash"):
					switch_state(RUN)
			if head_raycast.is_colliding():
				switch_state(CROUCH)
			footsteps()
			head.position.y = lerp(head.position.y, STANDING_HEAD_HEIGHT, 0.3)
		CROUCH:
			if not motion_state_entered:
				current_speed = CROUCHING_SPEED
				standing_collision_shape.set_deferred("disabled", true)
				crouching_collision_shape.set_deferred("disabled", false)
				motion_state_entered = true
			if not is_on_floor():
				switch_state(FALL)
			if not Input.is_action_pressed("crouch") and not head_raycast.is_colliding():
				switch_state(IDLE)
			footsteps()
			tilt_upper_body()
			head.position.y = lerp(head.position.y, CROUCHING_HEAD_HEIGHT, 0.3)
		SLIDE:
			if not motion_state_entered:
				slide_start_position = position
				current_speed = SLIDING_SPEED
				standing_collision_shape.set_deferred("disabled", true)
				crouching_collision_shape.set_deferred("disabled", false)
				motion_state_entered = true
			if Input.is_action_pressed("jump"):
				switch_state(JUMP)
			if not is_on_floor():
				switch_state(FALL)
			sliding_audio.play()
			direction = (transform.basis * Vector3.FORWARD).normalized()
			head.position.y = lerp(head.position.y, SLIDING_HEAD_HEIGHT, 0.3)
			if slide_start_position.distance_squared_to(position) > pow(SLIDE_MAX_DISTANCE, 2) or is_on_wall():
				switch_state(IDLE)
		LAND:
			if not motion_state_entered:
				current_speed = 0
				animations.land_animation(camera)
				motion_state_entered = true
			head.position.y = lerp(head.position.y, STANDING_HEAD_HEIGHT, 0.3)
			switch_state(IDLE)

	velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleraion)
	velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleraion)


func rotate_camera():
	head.rotation.x += mouse_motion_event_relative.y * mouse_sensitivity * -1
	head.rotation_degrees.x = clamp(head.rotation_degrees.x, -90, 90)


func rotate_player():
	rotation.y += mouse_motion_event_relative.x * mouse_sensitivity * -1
	rotation_degrees.y = wrap(rotation_degrees.y, -180, 180)


func _on_weapon_pivot_child_entered_tree(node: Node) -> void:
	set_visibility(node)


func set_visibility(node : Node):
	for i in node.get_children():
		if i is MeshInstance3D or i is GPUParticles3D:
			i.layers = 2
		set_visibility(i)


func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion_event_relative.x = event.relative.x
		mouse_motion_event_relative.y = event.relative.y

	if Input.is_action_just_pressed("reload"):
		Signals.reload.emit()


func get_direction():
	direction = Vector3.ZERO
	var input_dir := Vector2.ZERO
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


func get_tilt():
	tilt = 0.0
	tilt = Input.get_action_strength("tilt_left") - Input.get_action_strength("tilt_right")


func reset_mouse_motion_event_relative():
		mouse_motion_event_relative.x = 0
		mouse_motion_event_relative.y = 0


func recoil(recoil_force : Vector2):
	rotation.y += recoil_force.y
	head.rotation.x += recoil_force.x
	rotation_degrees.y = wrap(rotation_degrees.y, -180, 180)
	head.rotation_degrees.x = clamp(head.rotation_degrees.x, -90, 90)


func footsteps():
	var current_position = Vector2(position.x, position.z)
	if current_position.distance_squared_to(last_step_position) > pow(STEP_LENGHT, 2):
		footsteps_audio.pitch_scale = randf_range(0.9, 1.1)
		footsteps_audio.play()
		last_step_position = Vector2(position.x, position.z)


func tilt_upper_body():
	upper_body.rotation_degrees.z = lerp(upper_body.rotation_degrees.z, UPPER_BODY_TILT_DEGREES * tilt, 0.3)


func emit_initial_signals():
	Signals.update_motion_state.emit(states_array[state])


func update_mouse_sensitivity():
	mouse_sensitivity = Settings.mouse_sensitivity




