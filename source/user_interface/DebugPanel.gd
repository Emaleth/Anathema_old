extends PanelContainer

@onready var motion_state_label := $VBoxContainer/MotionState
@onready var aim_state_label := $VBoxContainer/AimState


func _ready() -> void:
	Signals.update_motion_state.connect(update_motion_state)
	Signals.update_aim_state.connect(update_aim_state)


func update_motion_state(state : String):
	motion_state_label.text = "Motion State %s" % state


func update_aim_state(state : String):
	aim_state_label.text = "Aim State %s" % state
