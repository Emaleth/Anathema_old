@tool
extends EditorScript

var autoloads : Dictionary = {
	"Keybindings" : "res://source/core/keybindings.gd",
	"Settings" : "res://source/core/settings.gd",
	"Signals" : "res://source/core/signals.gd",
	"AudioManager" : "res://source/managers/audio_manager.gd",
}


func _run():
	var editor_plugin : EditorPlugin = EditorPlugin.new()
	for i in autoloads:
		editor_plugin.remove_autoload_singleton(i)
		editor_plugin.add_autoload_singleton(i, autoloads[i])
