@tool
extends EditorScript

var autoloads : Dictionary = {
	"Keybindings" : "res://core/keybindings.gd",
}


func _run():
	var fix : EditorPlugin = EditorPlugin.new()
	for i in autoloads:
		fix.remove_autoload_singleton(i)
		fix.add_autoload_singleton(i, autoloads[i])
