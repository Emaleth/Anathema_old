extends Node

var key_bindings : Dictionary = {
	"move_forward" : KEY_W,
	"move_backward" : KEY_S,
	"move_left" : KEY_A,
	"move_right" : KEY_D,
	"tilt_left" : KEY_Q,
	"tilt_right" : KEY_E,
	"jump" : KEY_SPACE,
	"crouch" : KEY_SHIFT,
	"dash" : KEY_P,
	"reload" : KEY_R,
	"settings" : KEY_ESCAPE,
}

var mouse_bindings : Dictionary = {
	"primary_action" : MOUSE_BUTTON_LEFT,
	"secondary_action" : MOUSE_BUTTON_RIGHT,
}

func _ready():
	for i in key_bindings:
		var new_event = InputEventKey.new()
		new_event.keycode = key_bindings[i]
		if not InputMap.has_action(i):
			InputMap.add_action(i)
		if not InputMap.action_has_event(i, new_event):
			InputMap.action_add_event(i, new_event)

	for i in mouse_bindings:
		var new_event = InputEventMouseButton.new()
		new_event.button_index = mouse_bindings[i]
		if not InputMap.has_action(i):
			InputMap.add_action(i)
		if not InputMap.action_has_event(i, new_event):
			InputMap.action_add_event(i, new_event)
