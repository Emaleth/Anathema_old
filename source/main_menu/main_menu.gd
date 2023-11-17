extends Control


@onready var world_scene := preload("res://source/world/world.tscn")


func _on_play_button_pressed() -> void:
	SceneManager.load_scene(world_scene)


func _on_settings_button_pressed() -> void:
	SceneManager.load_settings()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


