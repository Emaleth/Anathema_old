extends Control


@onready var world_scene := preload("res://source/world/world.tscn")


func _on_play_button_pressed() -> void:
	SceneManager.load_scene(world_scene)


func _on_settings_button_pressed() -> void:
	SceneManager.load_settings()


func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _ready():
	$MarginContainer/CenterContainer/VBoxContainer2/Label.text = str(ProjectSettings.get_setting("application/config/name")).capitalize()
	$MarginContainer/Label.text = "Version: %s" % ProjectSettings.get_setting("application/config/version")

