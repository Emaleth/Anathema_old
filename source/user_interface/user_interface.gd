extends Control

@onready var crosshair := $MarginContainer/CenterContainer/Crosshair
@onready var current_ammo_label := $MarginContainer/Ammo/HBoxContainer/Current
@onready var max_ammo_label := $MarginContainer/Ammo/HBoxContainer/Max


func _ready() -> void:
	Signals.secondary_action.connect(show_crosshair)
	Signals.update_current_ammo.connect(update_current_ammo)
	Signals.update_max_ammo.connect(update_max_ammo)


func show_crosshair(value : bool):
	crosshair.visible = not value


func update_max_ammo(value : int):
	max_ammo_label.text = str(value)


func update_current_ammo(value : int):
	current_ammo_label.text = str(value)
