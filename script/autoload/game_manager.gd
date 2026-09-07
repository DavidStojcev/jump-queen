extends Node

signal player_died
signal checkpoint_set(pos: Vector2)
signal death_count_changed(count: int)

var death_count: int = 0
var current_checkpoint: Vector2 = Vector2.ZERO
var current_level: int = 0
var elapsed_time: float = 0.0
var is_dead: bool = false
var level_scenes: Array[String] = [
	"res://scenes/level/level_01.tscn",
	"res://scenes/level/level_02.tscn",
]

var sarcastic_messages: Array[String] = [
	"Nice one.",
	"Try again, genius.",
	"That was the wrong block.",
	"Skill issue.",
	"Have you tried not dying?",
	"The floor is lava. Literally.",
	"Bold strategy.",
	"You'll get it... eventually.",
	"Pain is temporary. Death count is forever.",
	"That signpost was lying, by the way.",
	"Maybe read the signs? Or don't.",
	"Gravity wins again.",
]

func _ready() -> void:
	_setup_input_map()

func _process(delta: float) -> void:
	if not is_dead:
		elapsed_time += delta

func die() -> void:
	if is_dead:
		return
	is_dead = true
	death_count += 1
	death_count_changed.emit(death_count)
	player_died.emit()

func respawn() -> void:
	is_dead = false

func set_checkpoint(pos: Vector2) -> void:
	current_checkpoint = pos
	checkpoint_set.emit(pos)

func get_random_death_message() -> String:
	return sarcastic_messages[randi() % sarcastic_messages.size()]

func get_current_level_path() -> String:
	if current_level < level_scenes.size():
		return level_scenes[current_level]
	return ""

func next_level() -> void:
	current_level += 1
	current_checkpoint = Vector2.ZERO

func reset() -> void:
	death_count = 0
	current_checkpoint = Vector2.ZERO
	current_level = 0
	elapsed_time = 0.0
	is_dead = false

func _setup_input_map() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_action("interact", [KEY_E])
	_add_action("restart", [KEY_R])

func _add_action(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		var has_event: bool = false
		for existing: InputEvent in InputMap.action_get_events(action_name):
			if existing is InputEventKey and existing.physical_keycode == key:
				has_event = true
				break
		if not has_event:
			InputMap.action_add_event(action_name, ev)
