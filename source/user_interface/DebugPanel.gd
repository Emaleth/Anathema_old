extends PanelContainer

@onready var motion_state_label := $VBoxContainer/MotionState
@onready var aim_state_label := $VBoxContainer/AimState
@onready var current_ammo_label := $VBoxContainer/HBoxContainer/CurrentAmmo
@onready var max_ammo_label := $VBoxContainer/HBoxContainer/MaxAmmo


func _ready() -> void:
	Signals.update_motion_state.connect(update_motion_state)
	Signals.update_aim_state.connect(update_aim_state)
	Signals.update_current_ammo.connect(update_current_ammo)
	Signals.update_max_ammo.connect(update_max_ammo)


func update_motion_state(state : String):
	motion_state_label.text = "Motion State %s" % state


func update_aim_state(state : String):
	aim_state_label.text = "Aim State %s" % state


func update_max_ammo(value : int):
	max_ammo_label.text = str(value)

func update_current_ammo(value : int):
	current_ammo_label.text = str(value)
