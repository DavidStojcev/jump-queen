extends Camera2D
class_name RoomCamera

## Fixed-screen camera that snaps between rooms as the target crosses boundaries.

@export var target: Node2D
@export var room_width: float = 480.0
@export var room_height: float = 270.0

@export_group("Screen Shake")
@export var shake_decay: float = 12.0
@export var max_shake_offset: float = 8.0

var current_room: Vector2i = Vector2i.ZERO
var current_shake: float = 0.0
var consecutive_downward_screens: int = 0

signal room_changed(old_room: Vector2i, new_room: Vector2i)


func _ready() -> void:
	position_smoothing_enabled = false
	if target:
		_snap_to_target_room()
		_connect_target_signals()


func _connect_target_signals() -> void:
	if not target:
		return
	if target.has_signal("wall_bounced"):
		target.connect("wall_bounced", Callable(self, "_on_target_wall_bounced"))
	if target.has_signal("ceiling_bonked"):
		target.connect("ceiling_bonked", Callable(self, "_on_target_ceiling_bonked"))
	if target.has_signal("splatted"):
		target.connect("splatted", Callable(self, "_on_target_splatted"))


func apply_shake(intensity: float) -> void:
	current_shake = minf(current_shake + intensity, max_shake_offset)


func _on_target_wall_bounced(_normal: Vector2) -> void:
	apply_shake(2.0)


func _on_target_ceiling_bonked() -> void:
	apply_shake(1.5)


func _on_target_splatted(_fall_speed: float) -> void:
	if consecutive_downward_screens >= 2:
		apply_shake(7.5) # heavier shake if falling through multiple screens
	else:
		apply_shake(5.0)
	consecutive_downward_screens = 0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	var pos: Vector2 = target.global_position
	var room_x: int = int(floor(pos.x / room_width))
	var room_y: int = int(floor(pos.y / room_height))
	var new_room := Vector2i(room_x, room_y)

	if new_room != current_room:
		var old_room := current_room
		if new_room.y > old_room.y:
			consecutive_downward_screens += (new_room.y - old_room.y)
		elif new_room.y < old_room.y:
			consecutive_downward_screens = 0
		current_room = new_room
		_snap_to_room(current_room)
		room_changed.emit(old_room, new_room)

	if current_shake > 0.0:
		current_shake = move_toward(current_shake, 0.0, shake_decay * delta)
		offset = Vector2(
			randf_range(-current_shake, current_shake),
			randf_range(-current_shake, current_shake)
		)
	else:
		offset = Vector2.ZERO


func _snap_to_target_room() -> void:
	var pos: Vector2 = target.global_position
	current_room = Vector2i(
		int(floor(pos.x / room_width)),
		int(floor(pos.y / room_height))
	)
	_snap_to_room(current_room)


func _snap_to_room(room: Vector2i) -> void:
	global_position = Vector2(
		room.x * room_width + (room_width / 2.0),
		room.y * room_height + (room_height / 2.0)
	)
