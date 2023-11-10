extends Control


@onready var world_scene := preload("res://source/world/world.tscn")
var click_sound := preload("res://assets/sounds/interface/click.ogg")
var hover_sound := preload("res://assets/sounds/interface/hover.ogg")


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(world_scene)
	AudioManager.play(click_sound)


func _on_settings_button_pressed() -> void:
	AudioManager.play(click_sound)


func _on_quit_button_pressed() -> void:
	AudioManager.play(click_sound)
	get_tree().quit()


func _on_play_button_mouse_entered() -> void:
	AudioManager.play(hover_sound)


func _on_settings_button_mouse_entered() -> void:
	AudioManager.play(hover_sound)


func _on_quit_button_mouse_entered() -> void:
	AudioManager.play(hover_sound)
