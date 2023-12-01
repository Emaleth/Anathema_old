extends Node

var hipfire_mouse_sensitivity := 0.007
var ads_mouse_sensitivity := 0.003
var field_of_view := 75
var enable_crosshair := true
var enable_hit_marker := true



func _ready() -> void:
	load_config()


func save_config():
	var config := ConfigFile.new()
	config.set_value("Gameplay", "enable_crosshair", enable_crosshair)
	config.set_value("Gameplay", "enable_hit_marker", enable_hit_marker)
	config.set_value("Gameplay", "field_of_view", field_of_view)
	config.set_value("Controls", "hipfire_mouse_sensitivity", hipfire_mouse_sensitivity)
	config.set_value("Controls", "ads_mouse_sensitivity", ads_mouse_sensitivity)
	config.save("user://anathema.cfg")


func load_config():
	var config := ConfigFile.new()
	var err := config.load("user://anathema.cfg")

	if err != OK:
		err = config.load("res://default.cfg")
		if err != OK:
			get_tree().quit()

	print(config.encode_to_text())
