extends Control

@onready var main_buttons: VBoxContainer = $MarginContainer/VBoxContainer/MainButtons
@onready var options_panel: VBoxContainer = $MarginContainer/VBoxContainer/OptionsPanel
@onready var start_button: Button = $MarginContainer/VBoxContainer/MainButtons/StartButton
@onready var options_button: Button = $MarginContainer/VBoxContainer/MainButtons/OptionsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/MainButtons/QuitButton
@onready var volume_slider: HSlider = $MarginContainer/VBoxContainer/OptionsPanel/VolumeSection/HBoxContainer/VolumeSlider
@onready var volume_label: Label = $MarginContainer/VBoxContainer/OptionsPanel/VolumeSection/HBoxContainer/VolumeValue
@onready var back_button: Button = $MarginContainer/VBoxContainer/OptionsPanel/BackButton
@onready var sfx_test: AudioStreamPlayer = $SFXTestPlayer

const GAME_SCENE_PATH: String = "res://scenes/game.tscn"

var _test_sound_debounce: float = 0.0

func _ready() -> void:
	# Hide Quit button on Web exports where quitting is unsupported
	if OS.has_feature("web"):
		quit_button.visible = false

	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Connect volume slider
	volume_slider.value_changed.connect(_on_volume_changed)

	# Initialize volume slider from SettingsManager
	_update_volume_display(SettingsManager.get_master_volume())

	# Initial menu state
	_show_main_menu()

func _process(delta: float) -> void:
	if _test_sound_debounce > 0.0:
		_test_sound_debounce -= delta

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if options_panel.visible:
			_on_back_pressed()
			get_viewport().set_input_as_handled()

func _show_main_menu() -> void:
	main_buttons.visible = true
	options_panel.visible = false
	start_button.grab_focus()

func _show_options() -> void:
	main_buttons.visible = false
	options_panel.visible = true
	_update_volume_display(SettingsManager.get_master_volume())
	volume_slider.grab_focus()

func _update_volume_display(linear_val: float) -> void:
	var percentage: int = int(round(linear_val * 100.0))
	volume_slider.set_value_no_signal(percentage)
	volume_label.text = "%d%%" % percentage

func _on_start_pressed() -> void:
	if GameManager:
		GameManager.reset()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_options_pressed() -> void:
	_show_options()

func _on_back_pressed() -> void:
	SettingsManager.save_settings()
	_show_main_menu()
	options_button.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_volume_changed(value: float) -> void:
	var linear_val: float = value / 100.0
	volume_label.text = "%d%%" % int(value)
	SettingsManager.set_master_volume(linear_val)

	# Auditory feedback when adjusting slider
	if _test_sound_debounce <= 0.0 and sfx_test and sfx_test.stream:
		sfx_test.play()
		_test_sound_debounce = 0.12
