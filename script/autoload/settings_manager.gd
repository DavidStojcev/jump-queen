extends Node

signal volume_changed(bus_name: String, linear_value: float)

const CONFIG_PATH: String = "user://settings.cfg"
const DEFAULT_MASTER_VOLUME: float = 0.8

var master_volume: float = DEFAULT_MASTER_VOLUME
var master_muted: bool = false

func _ready() -> void:
	load_settings()
	apply_audio_settings()

func set_master_volume(linear_val: float) -> void:
	master_volume = clampf(linear_val, 0.0, 1.0)
	apply_audio_settings()
	volume_changed.emit("Master", master_volume)

func get_master_volume() -> float:
	return master_volume

func set_master_muted(muted: bool) -> void:
	master_muted = muted
	apply_audio_settings()

func is_master_muted() -> bool:
	return master_muted

func apply_audio_settings() -> void:
	var bus_idx: int = AudioServer.get_bus_index("Master")
	if bus_idx < 0:
		return

	if master_muted or master_volume <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume))

func save_settings() -> void:
	var config := ConfigFile.new()
	# Load existing file if present so we don't clobber other sections in future
	if FileAccess.file_exists(CONFIG_PATH):
		config.load(CONFIG_PATH)

	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "master_muted", master_muted)

	var err := config.save(CONFIG_PATH)
	if err != OK:
		push_warning("Failed to save settings to %s (error %d)" % [CONFIG_PATH, err])

func load_settings() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		master_volume = DEFAULT_MASTER_VOLUME
		master_muted = false
		return

	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		push_warning("Failed to load settings from %s (error %d)" % [CONFIG_PATH, err])
		return

	master_volume = config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
	master_muted = config.get_value("audio", "master_muted", false)
