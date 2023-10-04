@tool
extends EditorScript

var autoloads : Dictionary = {
	"Keybindings" : "res://source/core/keybindings.gd",
	"Settings" : "res://source/core/settings.gd",
}


func _run():
	var fix : EditorPlugin = EditorPlugin.new()
	for i in autoloads:
		fix.remove_autoload_singleton(i)
		fix.add_autoload_singleton(i, autoloads[i])
