extends Control

@onready var quit_button := %QuitButton
@onready var restore_defaults_button := %RestoreDefaultsButton
@onready var return_button := %ReturnButton

@onready var crosshair_button := %CrosshairCheckButton
@onready var hitmarker_button := %HitmarkerCheckButton
@onready var fov_slider := %FieldOfViewHSlider
@onready var fov_label := %FieldOfViewLabel
@onready var ads_mouse_sensitivity_slider := %AdsMouseSensitivityHSlider
@onready var ads_mouse_sensitivity_label := %AdsMouseSensitivityLabel
@onready var hipfire_mouse_sensitivity_slider := %HipfireMouseSensitivityHSlider
@onready var hipfire_mouse_sensitivity_label := %HipfireMouseSensitivityLabel
@onready var master_audio_slider := %MasterVolumeHSlider
@onready var master_audio_label := %MasterVolumeLabel
@onready var ui_audio_slider := %UIVolumeHSlider
@onready var ui_audio_label := %UIVolumeLabel
@onready var sfx_audio_slider := %SFXVolumeHSlider
@onready var sfx_audio_label := %SFXVolumeLabel
@onready var resolution_option_button := %ResolutionOptionButton

var resolutions := [
	"1920:1080", # 1.0
	"1280:720", # 1.5
	"960:540", # 2.0
	"768:432", # 2.5
	"640:360", # 3.0
]


func _ready() -> void:
	for i in resolutions:
		resolution_option_button.add_item(i)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	read_values()
	process_mode = Node.PROCESS_MODE_ALWAYS
	quit_button.pressed.connect(func(): get_tree().quit())
	return_button.pressed.connect(func(): queue_free())

	crosshair_button.toggled.connect(func(value : bool): Settings.enable_crosshair = value; Signals.update_config_file.emit())
	hitmarker_button.toggled.connect(func(value : bool): Settings.enable_hit_marker = value; Signals.update_config_file.emit())
	fov_slider.value_changed.connect(func(value : int): Settings.field_of_view = value; Signals.update_fov_setting.emit(value); fov_label.text = str(value); Signals.update_config_file.emit())
	ads_mouse_sensitivity_slider.value_changed.connect(func(value : float): Settings.ads_mouse_sensitivity = value; Signals.update_mouse_sensitivity_setting.emit(); ads_mouse_sensitivity_label.text = str(value); Signals.update_config_file.emit())
	hipfire_mouse_sensitivity_slider.value_changed.connect(func(value : float): Settings.hipfire_mouse_sensitivity = value; Signals.update_mouse_sensitivity_setting.emit(); hipfire_mouse_sensitivity_label.text = str(value); Signals.update_config_file.emit())
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
	ads_mouse_sensitivity_slider.value = Settings.ads_mouse_sensitivity
	hipfire_mouse_sensitivity_slider.value = Settings.hipfire_mouse_sensitivity
	master_audio_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	ui_audio_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("UI"))
	sfx_audio_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))

	fov_label.text = str(Settings.field_of_view)
	ads_mouse_sensitivity_label.text = str(Settings.ads_mouse_sensitivity)
	hipfire_mouse_sensitivity_label.text = str(Settings.hipfire_mouse_sensitivity)
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
