extends Node


@onready var main_menu_scene := preload("res://source/main_menu/main_menu.tscn")


func _ready() -> void:
	SceneManager.load_scene(main_menu_scene)
