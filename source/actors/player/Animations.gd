extends Node

const HEAD_TILT_DEGREES := 25.0
const HIPFIRE_SIN_FREQUENCY := 2.0
const HIPFIRE_SIN_AMPLITUDE := 0.03
const ADS_SIN_FREQUENCY := 1.0
const ADS_SIN_AMPLITUDE := 0.001

var head_tilt_deadzone := 0.05
var hand_tilt_deadzone := 0.001
var mouse_motion_event_relative := Vector2.ZERO
var sin_time := 0.0
var weapon_sway_amount := 3.0

@onready var viewport_size : Vector2 = get_viewport().size


func _ready() -> void:
	get_tree().process_frame.connect(reset_mouse_motion_event_relative)


func _input(event):
	if event is InputEventMouseMotion:
		mouse_motion_event_relative.x = event.relative.x
		mouse_motion_event_relative.y = event.relative.y


func jump_animation(camera : Camera3D):
	var tween = create_tween()
	tween.tween_property( camera, "position:y", 0.1, 0.1 ).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property( camera, "rotation:x", deg_to_rad(-5), 0.1 ).set_trans(Tween.TRANS_LINEAR)

	tween.tween_property( camera, "position:y", 0.0, 0.2 ).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property( camera, "rotation:x", 0.0, 0.2 ).set_trans(Tween.TRANS_LINEAR)


func land_animation(camera : Camera3D):
	var tween = create_tween()
	tween.tween_property( camera, "position:y", 0.1, 0.1 ).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property( camera, "rotation:x", deg_to_rad(-5), 0.1 ).set_trans(Tween.TRANS_LINEAR)

	tween.tween_property( camera, "position:y", 0.0, 0.2 ).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property( camera, "rotation:x", 0.0, 0.2 ).set_trans(Tween.TRANS_LINEAR)


func head_bob():
	pass


func tilt_head(head : Node3D):
	var head_tilt := 0.0
	if abs(mouse_motion_event_relative.x / viewport_size.x) > head_tilt_deadzone:
		head_tilt = -mouse_motion_event_relative.x
	head.rotation_degrees.z = lerp(head.rotation_degrees.z, HEAD_TILT_DEGREES * sign(head_tilt), 0.1)


func arm_swing(chest : Node3D, delta : float):
	chest.position.y = cos(sin_time * HIPFIRE_SIN_FREQUENCY) * HIPFIRE_SIN_AMPLITUDE
	chest.position.x = sin(sin_time * HIPFIRE_SIN_FREQUENCY * 0.5) * HIPFIRE_SIN_AMPLITUDE
	sin_time += delta


func weapon_sway(right_weapon_pivot : Node3D):
	var hand_tilt := Vector3.ZERO
	if abs(mouse_motion_event_relative.y / viewport_size.y) > hand_tilt_deadzone:
		hand_tilt.x = sign(mouse_motion_event_relative.y)
	if abs(mouse_motion_event_relative.x / viewport_size.x) > hand_tilt_deadzone:
		hand_tilt.y = sign(mouse_motion_event_relative.x)
		hand_tilt.z = sign(mouse_motion_event_relative.x)

	right_weapon_pivot.rotation_degrees.x = lerp(right_weapon_pivot.rotation_degrees.x, sign(-hand_tilt.x) * weapon_sway_amount, 0.1)
	right_weapon_pivot.rotation_degrees.y = lerp(right_weapon_pivot.rotation_degrees.y, sign(-hand_tilt.y) * weapon_sway_amount, 0.1)
	right_weapon_pivot.rotation_degrees.z = lerp(right_weapon_pivot.rotation_degrees.z, sign(hand_tilt.z) * weapon_sway_amount, 0.1)


func reset_mouse_motion_event_relative():
		mouse_motion_event_relative.x = 0
		mouse_motion_event_relative.y = 0
