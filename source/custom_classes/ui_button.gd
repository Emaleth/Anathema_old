extends Button

class_name  ui_button

var click_sound := preload("res://assets/sounds/interface/click.ogg")
var hover_sound := preload("res://assets/sounds/interface/hover.ogg")


func _ready() -> void:
	mouse_entered.connect(AudioManager.play.bind(hover_sound))
	pressed.connect(AudioManager.play.bind(click_sound))
	focus_mode = Control.FOCUS_NONE
