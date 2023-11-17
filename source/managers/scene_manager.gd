extends Control

@onready var loading_label = $MarginContainer/CenterContainer/VBoxContainer/Label
#@onready var loading_sprite = %LoadingSprite
@onready var settins_scene := preload("res://source/user_interface/settings_panel.tscn")

var loading_progress = []
var scene_load_status = 0
var next_scene : PackedScene

var settings_scene_loaded := false


func load_settings():
	if not settings_scene_loaded:
		add_child(settins_scene.instantiate())
		settings_scene_loaded = true

func load_scene(scene : PackedScene):
	next_scene = scene
	ResourceLoader.load_threaded_request(scene.get_path())


func _process(_delta: float):
	if next_scene:
		loading_label.show()
		scene_load_status = ResourceLoader.load_threaded_get_status(next_scene.get_path(), loading_progress)
		loading_label.text = str(loading_progress)
		if (scene_load_status == ResourceLoader.THREAD_LOAD_LOADED):
			loading_label.hide()
			get_tree().change_scene_to_packed(next_scene)
			next_scene = null
