extends Control

var crosshair := true
var hit_marker := false
var screen_center := Vector2.ZERO
var crosshair_line_size := 1.0
var hit_marker_line_size := 2.0
var crosshair_offset := 10
var hit_marker_offset := 15
var target_crosshair_offset := 10
var target_hit_marker_offset := 15

@onready var settins_scene := preload("res://source/user_interface/settings_panel.tscn")

@onready var current_ammo_label := $MarginContainer/Ammo/HBoxContainer/Current
@onready var max_ammo_label := $MarginContainer/Ammo/HBoxContainer/Max
@onready var hit_marker_timer := $HitMarkerTimer


func _ready() -> void:
	Signals.secondary_action.connect(hide_crosshair)
	Signals.update_current_ammo.connect(update_current_ammo)
	Signals.update_max_ammo.connect(update_max_ammo)
	Signals.target_hit.connect(func(): hit_marker = true; hit_marker_timer.start(0.05))
	Signals.update_motion_state.connect(set_crosshair_state)


func _physics_process(_delta: float) -> void:
	crosshair_offset = lerp(crosshair_offset, target_crosshair_offset, 0.5)
	hit_marker_offset = lerp(hit_marker_offset, target_hit_marker_offset, 0.5)


func _process(_delta: float) -> void:
	queue_redraw()


func set_crosshair_state(state : String):
	match state:
		"IDLE": target_crosshair_offset = 5; target_hit_marker_offset = 15
		"RUN": target_crosshair_offset = 10; target_hit_marker_offset = 15
		"JUMP": target_crosshair_offset = 20; target_hit_marker_offset = 15
		"FALL": target_crosshair_offset = 10; target_hit_marker_offset = 15
		"SPRINT": target_crosshair_offset = 20; target_hit_marker_offset = 15
		"CROUCH": target_crosshair_offset = 5; target_hit_marker_offset = 15
		"SLIDE": target_crosshair_offset = 10; target_hit_marker_offset = 15
		"LAND": target_crosshair_offset = 20; target_hit_marker_offset = 15


func _draw() -> void:
	var crosshair_size := 5
	var hit_marker_size := 5
	var crosshair_color := Color.WHITE
	var hit_markerr_color := Color.RED
	if crosshair and Settings.enable_crosshair:
		draw_line(screen_center + Vector2(crosshair_offset, 0), screen_center + Vector2((crosshair_offset + crosshair_size), 0), crosshair_color, crosshair_line_size, true)
		draw_line(screen_center + Vector2(-crosshair_offset, 0), screen_center + Vector2(-(crosshair_offset + crosshair_size), 0), crosshair_color, crosshair_line_size, true)
		draw_line(screen_center + Vector2(0, crosshair_offset), screen_center + Vector2(0, (crosshair_offset + crosshair_size)), crosshair_color, crosshair_line_size, true)
		draw_line(screen_center + Vector2(0, -crosshair_offset), screen_center + Vector2(0, -(crosshair_offset + crosshair_size)), crosshair_color, crosshair_line_size, true)
	if hit_marker and Settings.enable_hit_marker:
		draw_line(screen_center + Vector2(hit_marker_offset, -hit_marker_offset), screen_center + Vector2((hit_marker_offset + hit_marker_size), -(hit_marker_offset + hit_marker_size)), hit_markerr_color, hit_marker_line_size, true)
		draw_line(screen_center + Vector2(-hit_marker_offset, hit_marker_offset), screen_center + Vector2(-(hit_marker_offset + hit_marker_size), (hit_marker_offset + hit_marker_size)), hit_markerr_color, hit_marker_line_size, true)
		draw_line(screen_center + Vector2(hit_marker_offset, hit_marker_offset), screen_center + Vector2((hit_marker_offset + hit_marker_size), (hit_marker_offset + hit_marker_size)), hit_markerr_color, hit_marker_line_size, true)
		draw_line(screen_center + Vector2(-hit_marker_offset, -hit_marker_offset), screen_center + Vector2(-(hit_marker_offset + hit_marker_size), -(hit_marker_offset + hit_marker_size)), hit_markerr_color, hit_marker_line_size, true)


func hide_crosshair(value : bool):
	crosshair = not value


func update_max_ammo(value : int):
	max_ammo_label.text = str(value)


func update_current_ammo(value : int):
	current_ammo_label.text = str(value)


func _on_resized() -> void:
	screen_center = size * 0.5


func _on_hit_marker_timer_timeout() -> void:
	hit_marker = false


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("settings"): SceneManager.load_settings()
