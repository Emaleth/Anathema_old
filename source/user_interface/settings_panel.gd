extends Control

@onready var quit_button := %QuitButton
@onready var restore_defaults_button := %RestoreDefaultsButton
@onready var return_button := %ReturnButton

@onready var crosshair_button := %CrosshairCheckButton
@onready var hitmarker_button := %HitmarkerCheckButton
@onready var fov_slider := %FieldOfViewHSlider
@onready var ads_mouse_sensitivity_slider := %AdsMouseSensitivityHSlider
@onready var hipfire_mouse_sensitivity_slider := %HipfireMouseSensitivityHSlider


func _ready() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	read_values()
	process_mode = Node.PROCESS_MODE_ALWAYS
	quit_button.pressed.connect(func(): get_tree().quit())
	return_button.pressed.connect(func(): queue_free())

	crosshair_button.toggled.connect(func(value : bool): Settings.enable_crosshair = value)
	hitmarker_button.toggled.connect(func(value : bool): Settings.enable_hit_marker = value)
	fov_slider.value_changed.connect(func(value : int): Settings.field_of_view = value; Signals.update_fov_setting.emit(value))
	ads_mouse_sensitivity_slider.value_changed.connect(func(value : float): Settings.ads_mouse_sensitivity = value; Signals.update_mouse_sensitivity_setting.emit())
	hipfire_mouse_sensitivity_slider.value_changed.connect(func(value : float): Settings.hipfire_mouse_sensitivity = value; Signals.update_mouse_sensitivity_setting.emit())


func _on_tree_exited() -> void:
	SceneManager.settings_scene_loaded = false
	if not SceneManager.main_menu:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_tree_exiting() -> void:
	get_tree().paused = false


func read_values():
	crosshair_button.button_pressed = Settings.enable_crosshair
	hitmarker_button.button_pressed = Settings.enable_hit_marker
	fov_slider.value = Settings.field_of_view
	ads_mouse_sensitivity_slider.value = Settings.ads_mouse_sensitivity
	hipfire_mouse_sensitivity_slider.value = Settings.hipfire_mouse_sensitivity
