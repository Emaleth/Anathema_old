extends Control

@onready var loading_label = $MarginContainer/CenterContainer/VBoxContainer/Label
#@onready var loading_sprite = %LoadingSprite

var loading_progress = []
var scene_load_status = 0
var next_scene : PackedScene


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

