extends Control

@onready var quit_button := %QuitButton
@onready var restore_defaults_button := %RestoreDefaultsButton
@onready var return_button := %ReturnButton

@onready var crosshair_button := %CrosshairCheckButton
@onready var hitmarker_button := %HitmarkerCheckButton
@onready var fov_slider := %FieldOfViewHSlider
@onready var fov_label := %FieldOfViewLabel
@onready var mouse_sensitivity_slider := %MouseSensitivityHSlider
@onready var mouse_sensitivity_label := %MouseSensitivityLabel
@onready var master_audio_slider := %MasterVolumeHSlider
@onready var master_audio_label := %MasterVolumeLabel
@onready var ui_audio_slider := %UIVolumeHSlider
@onready var ui_audio_label := %UIVolumeLabel
@onready var sfx_audio_slider := %SFXVolumeHSlider
@onready var sfx_audio_label := %SFXVolumeLabel
@onready var resolution_option_button := %ResolutionOptionButton
@onready var window_option_button := %WindowOptionButton

var resolutions := [
	"1920:1080", # 1.0
	"1280:720", # 1.5
	"960:540", # 2.0
	"768:432", # 2.5
	"640:360", # 3.0
]

var window_mode := [
	"windowed",
	"fullscreen",
	"borderless windowed"
]

func _ready() -> void:
	for i in resolutions:
		resolution_option_button.add_item(i)
	for i in window_mode:
		window_option_button.add_item(i)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	read_values()
	process_mode = Node.PROCESS_MODE_ALWAYS
	quit_button.pressed.connect(func(): get_tree().quit())
	return_button.pressed.connect(func(): queue_free())
	populate_keybindings()

	crosshair_button.toggled.connect(func(value : bool): Settings.enable_crosshair = value; Signals.update_config_file.emit())
	hitmarker_button.toggled.connect(func(value : bool): Settings.enable_hit_marker = value; Signals.update_config_file.emit())
	fov_slider.value_changed.connect(func(value : int): Settings.field_of_view = value; Signals.update_fov_setting.emit(value); fov_label.text = str(value); Signals.update_config_file.emit())
	mouse_sensitivity_slider.value_changed.connect(func(value : float): Settings.mouse_sensitivity = value; Signals.update_mouse_sensitivity_setting.emit(); mouse_sensitivity_label.text = str(value); Signals.update_config_file.emit())
	master_audio_slider.value_changed.connect(func(value : int): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value); master_audio_label.text = str(value); Signals.update_config_file.emit())
	ui_audio_slider.value_changed.connect(func(value : int): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), value); ui_audio_label.text = str(value); Signals.update_config_file.emit())
	sfx_audio_slider.value_changed.connect(func(value : int): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value); sfx_audio_label.text = str(value); Signals.update_config_file.emit())


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
	mouse_sensitivity_slider.value = Settings.mouse_sensitivity
	master_audio_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	ui_audio_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("UI"))
	sfx_audio_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))

	fov_label.text = str(Settings.field_of_view)
	mouse_sensitivity_label.text = str(Settings.mouse_sensitivity)
	master_audio_label.text = str(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	ui_audio_label.text = str(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("UI")))
	sfx_audio_label.text = str(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	resolution_option_button.selected = (func():
		match get_tree().root.content_scale_factor:
			1.0: return 0
			1.5: return 1
			2.0: return 2
			2.5: return 3
			3.0: return 4
	).call()
	window_option_button.selected = (func():
		var m := 0
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_WINDOWED: m = 0
			DisplayServer.WINDOW_MODE_FULLSCREEN: m = 1
		if m == 0 and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
			m = 2
		return m
	).call()

func _on_resolution_option_button_item_selected(index: int) -> void:
	var scale_factor = 1.0
	match index:
		0:
			scale_factor = 1.0
		1:
			scale_factor = 1.5
		2:
			scale_factor = 2.0
		3:
			scale_factor = 2.5
		4:
			scale_factor = 3.0

	get_tree().root.content_scale_factor = scale_factor
	Signals.update_config_file.emit()


func populate_keybindings():
	for i in Keybindings.key_bindings:
		var new_row := preload("res://source/user_interface/key_binding_line.tscn").instantiate()
		$MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Controls/MarginContainer/VBoxContainer/ScrollContainer/KeyBindings.add_child(new_row)
		new_row.action = i
		new_row.get_node("Label").text = str(i)
		new_row.get_node("Button").text = str(InputMap.action_get_events(i)[0].as_text())
	for i in Keybindings.mouse_bindings:
		var new_row := preload("res://source/user_interface/key_binding_line.tscn").instantiate()
		new_row.action = i
		$MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Controls/MarginContainer/VBoxContainer/ScrollContainer/KeyBindings.add_child(new_row)
		new_row.get_node("Label").text = str(i)
		new_row.get_node("Button").text = str(InputMap.action_get_events(i)[0].as_text())


func _on_window_option_button_item_selected(index):
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	Signals.update_config_file.emit()
