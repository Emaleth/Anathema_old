extends PanelContainer

@onready var motion_state_label := $VBoxContainer/MotionState


func _ready() -> void:
	Signals.update_motion_state.connect(update_motion_state)


func update_motion_state(state : String):
	motion_state_label.text = "Motion State %s" % state



