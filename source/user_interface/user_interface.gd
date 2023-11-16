extends Control

@onready var current_ammo_label := $MarginContainer/Ammo/HBoxContainer/Current
@onready var max_ammo_label := $MarginContainer/Ammo/HBoxContainer/Max


func _ready() -> void:
	Signals.secondary_action.connect(show_crosshair)
	Signals.update_current_ammo.connect(update_current_ammo)
	Signals.update_max_ammo.connect(update_max_ammo)


func _draw() -> void:
	var screen_center := size * 0.5
	var start_offset := 5
	var end_offset := 15
	var crosshair_color := Color.WHITE
	var line_size := 0.5
	if crosshair:
#		crosshair_color = Color.WHITE
#	else:
#		crosshair_color = Color.TRANSPARENT
		draw_line(screen_center + Vector2(start_offset, 0), screen_center + Vector2(end_offset, 0), crosshair_color, line_size, true)
		draw_line(screen_center + Vector2(-start_offset, 0), screen_center + Vector2(-end_offset, 0), crosshair_color, line_size, true)
		draw_line(screen_center + Vector2(0, start_offset), screen_center + Vector2(0, end_offset), crosshair_color, line_size, true)
		draw_line(screen_center + Vector2(0, -start_offset), screen_center + Vector2(0, -end_offset), crosshair_color, line_size, true)
		queue_redraw()




var crosshair = true
func show_crosshair(value : bool):
	crosshair = value


func update_max_ammo(value : int):
	max_ammo_label.text = str(value)


func update_current_ammo(value : int):
	current_ammo_label.text = str(value)
