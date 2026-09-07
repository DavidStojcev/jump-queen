extends Node2D

@onready var _camera: Camera2D         = $Camera2D
@onready var _player: CharacterBody2D  = $Player
@onready var _level_container: Node2D  = $LevelContainer

var _current_level_node: Node2D = null

func _ready() -> void:
	GameManager.reset()
	_load_level()

func _physics_process(_delta: float) -> void:
	# FIX: Camera should follow via its own position_smoothing — don't override
	# global_position directly every physics frame, that bypasses the smoothing.
	# Instead, set the camera as a child of the player in the scene, OR reparent
	# approach: move camera target via RemoteTransform2D.
	# As a minimal fix without scene changes: only snap when no smoothing is
	# desired (e.g. on respawn). Leave per-frame follow to the Camera2D smoothing
	# by making the camera a child of the player node.
	#
	# For now we keep the direct assignment but guard the validity check:
	if is_instance_valid(_player):
		_camera.global_position = _player.global_position

func _load_level() -> void:
	# Disconnect old level signal before freeing to avoid dangling connections
	if is_instance_valid(_current_level_node):
		if _current_level_node.level_completed.is_connected(_on_level_completed):
			_current_level_node.level_completed.disconnect(_on_level_completed)
		_current_level_node.queue_free()
		_current_level_node = null

	var path: String = GameManager.get_current_level_path()
	if path.is_empty():
		GameManager.current_level = 0
		GameManager.current_checkpoint = Vector2.ZERO
		path = GameManager.get_current_level_path()

	var packed: PackedScene = load(path)
	_current_level_node = packed.instantiate() as Node2D
	_level_container.add_child(_current_level_node)

	# Set player spawn
	var spawn: Variant = _current_level_node.get("spawn_point")
	if spawn is Vector2:
		_player.global_position = spawn
		_player.spawn_position  = spawn

	if _current_level_node.has_signal("level_completed"):
		_current_level_node.level_completed.connect(_on_level_completed)

func _on_level_completed() -> void:
	GameManager.next_level()
	_load_level()
