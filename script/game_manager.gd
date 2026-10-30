extends Node2D

@onready var player: PlayerCharacter = $Player
@onready var camera: RoomCamera = $RoomCamera
@onready var hud_title: Label = $HUD/MarginContainer/VBoxContainer/RoomTitle
@onready var hud_desc: Label = $HUD/MarginContainer/VBoxContainer/RoomDesc
@onready var hud_controls: Label = $HUD/MarginContainer/VBoxContainer/ControlsHint

const SPAWN_SCREEN_1: Vector2 = Vector2(64, 214)
const SPAWN_SCREEN_2: Vector2 = Vector2(210, -50)
const SPAWN_SCREEN_3: Vector2 = Vector2(360, -320)

const ROOM_INFO: Dictionary = {
	Vector2i(0, 0): {
		"title": "🏰 The Bastion's Crucible [Screen 1]",
		"desc": "Wall-Bounce Training • Jump right into the stone wall to ricochet onto the high ledge."
	},
	Vector2i(0, -1): {
		"title": "❄️ The Frostbound Vault [Screen 2]",
		"desc": "Slippery Ice & Tight Ceiling • Watch out for ceiling icicle bonks! Keep jump charge low."
	},
	Vector2i(0, -2): {
		"title": "🌪️ The Gale-Torn Spire [Screen 3]",
		"desc": "Gale Storm & Spikes • Heavy leftward wind! Fight the gale to reach the Queen's Crown."
	}
}


func _ready() -> void:
	if camera:
		camera.room_changed.connect(_on_room_changed)
		_update_hud(camera.current_room)


func _on_room_changed(_old_room: Vector2i, new_room: Vector2i) -> void:
	_update_hud(new_room)


func _update_hud(room: Vector2i) -> void:
	if not hud_title or not hud_desc:
		return
	if ROOM_INFO.has(room):
		var info: Dictionary = ROOM_INFO[room]
		hud_title.text = info["title"]
		hud_desc.text = info["desc"]
	else:
		hud_title.text = "Screen [%d, %d]" % [room.x, room.y]
		hud_desc.text = "Ascending the Castle Spire"


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return

	var key_code: Key = event.keycode
	match key_code:
		KEY_1:
			teleport_player(SPAWN_SCREEN_1)
		KEY_2:
			teleport_player(SPAWN_SCREEN_2)
		KEY_3:
			teleport_player(SPAWN_SCREEN_3)
		KEY_R:
			teleport_player(SPAWN_SCREEN_1)
		KEY_H:
			if hud_controls:
				hud_controls.visible = not hud_controls.visible


func teleport_player(target_pos: Vector2) -> void:
	if not player:
		return
	player.global_position = target_pos
	player.velocity = Vector2.ZERO
	player.current_state = PlayerCharacter.State.IDLE
	if camera:
		camera._snap_to_target_room()
