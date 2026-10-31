extends Node2D

@onready var player: PlayerCharacter = $Player
@onready var camera: RoomCamera = $RoomCamera
@onready var hud_title: Label = $HUD/MarginContainer/VBoxContainer/RoomTitle
@onready var hud_desc: Label = $HUD/MarginContainer/VBoxContainer/RoomDesc
@onready var hud_controls: Label = $HUD/MarginContainer/VBoxContainer/ControlsHint

const SPAWN_SCREEN_1: Vector2 = Vector2(64, 230)
const SPAWN_SCREEN_2: Vector2 = Vector2(264, -48)
const SPAWN_SCREEN_3: Vector2 = Vector2(328, -320)

const ROOM_INFO: Dictionary = {
	Vector2i(0, 0): {
		"title": "🏰 Screen 1: The Ruined Lower Bastion",
		"desc": "Armory & Wall-Bouncing • Ricochet off the stone buttress at x=11 to reach the High Guard Shelf."
	},
	Vector2i(0, -1): {
		"title": "❄️ Screen 2: The Frozen Catacombs",
		"desc": "Permafrost & Icicle Vaults • Slide-charging on ice! Keep low under the icicle arch (Stage 13 max) to avoid bonking."
	},
	Vector2i(0, -2): {
		"title": "🌪️ Screen 3: The Howling Battlements",
		"desc": "Spire Summit & The Abyss • Constant leftward blizzard (-180 px/s²)! Commit to max charge against the gale."
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
		hud_desc.text = "Ascending the Citadel of the Frost Gale"


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
			var hud = get_node_or_null("HUD")
			if hud:
				hud.visible = not hud.visible
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")



func teleport_player(target_pos: Vector2) -> void:
	if not player:
		player = get_node_or_null("Player")
	if not player:
		return
	player.global_position = target_pos
	player.velocity = Vector2.ZERO
	player.current_state = PlayerCharacter.State.IDLE
	if not camera:
		camera = get_node_or_null("RoomCamera")
	if camera:
		camera._snap_to_target_room()

