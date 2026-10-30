extends SceneTree

const GAME_SCENE_PATH: String = "res://scenes/game.tscn"
const DUNGEON_SCENE_PATH: String = "res://scenes/castle_dungeon.tscn"
const TILESET_PATH: String = "res://resources/game_tileset.tres"

func _init() -> void:
	print("Building 3-Screen Vertical Castle Dungeon with True Jump King Proportions...")
	var tileset: TileSet = load(TILESET_PATH)
	if not tileset:
		printerr("Failed to load TileSet!")
		quit(1)
		return

	# Root Node
	var root_node: Node2D = Node2D.new()
	root_node.name = "Game"
	var gm_script = load("res://script/game_manager.gd")
	root_node.set_script(gm_script)

	# 1. Solid TileMapLayer (Collision Layer)
	var solid_layer: TileMapLayer = TileMapLayer.new()
	solid_layer.name = "TileMapLayer"
	solid_layer.tile_set = tileset
	solid_layer.collision_enabled = true
	root_node.add_child(solid_layer)
	solid_layer.owner = root_node

	# 2. Decorative TileMapLayer (Props, torches, banners, animated flag & chest)
	var deco_layer: TileMapLayer = TileMapLayer.new()
	deco_layer.name = "DecorativeLayer"
	deco_layer.tile_set = tileset
	deco_layer.collision_enabled = false
	root_node.add_child(deco_layer)
	deco_layer.owner = root_node

	# =========================================================================
	# SCREEN 1: [0, 0] - THE BASTION'S CRUCIBLE (TEACHING WALL-BOUNCING)
	# Y: 0..16 tiles (0..270 px)
	# CRITICAL: NO ROOF AT Y = 0! Open vertical clearance to Screen 2.
	# =========================================================================

	# Floor (y = 15..16): Solid ground from x = 1 to 28
	for x in range(1, 29):
		solid_layer.set_cell(Vector2i(x, 15), 0, Vector2i(2, 0)) # Stone top
		solid_layer.set_cell(Vector2i(x, 16), 0, Vector2i(2, 1)) # Stone base

	# Left Boundary Wall (x = 0..1)
	for y in range(0, 16):
		solid_layer.set_cell(Vector2i(0, y), 0, Vector2i(3, 0))
		solid_layer.set_cell(Vector2i(1, y), 0, Vector2i(2, 1))

	# Right Boundary Wall (x = 28..29)
	for y in range(0, 16):
		solid_layer.set_cell(Vector2i(28, y), 0, Vector2i(3, 0))
		solid_layer.set_cell(Vector2i(29, y), 0, Vector2i(2, 1))

	# --- SCREEN 1 PLATFORMS ---
	# Platform 1: Step from spawn at x = 9..12 (144..192 px), y = 11 (176 px)
	# Delta y = 46px (~3 tiles), reachable with gentle Stage 10-12 jump!
	for x in range(9, 13):
		solid_layer.set_cell(Vector2i(x, 11), 1, Vector2i(0, 0)) # Stone platform

	# Platform 2: Wall-bounce Launch Pad at x = 15..18 (240..288 px), y = 9 (144 px)
	# Delta y = 32px (~2 tiles), reachable from Plat 1 with Stage 14-16 jump!
	for x in range(15, 19):
		solid_layer.set_cell(Vector2i(x, 9), 1, Vector2i(0, 0))

	# The Wall-Bounce Pillar: Vertical stone column at x = 21 (336 px), y = 2..8
	# Distance from launch pad is exactly 72-88px. Stage 22-24 jump hits here!
	for y in range(2, 9):
		solid_layer.set_cell(Vector2i(21, y), 0, Vector2i(3, 0))

	# Platform 3: The Target Shelf at x = 17..20 (272..320 px), y = 5 (80 px)
	# Directly above launch pad! Player leaps right into wall at x=21, rebounds left onto here!
	for x in range(17, 21):
		solid_layer.set_cell(Vector2i(x, 5), 1, Vector2i(1, 0)) # Wooden beam

	# Screen 1 Atmospheric Props
	deco_layer.set_cell(Vector2i(3, 13), 7, Vector2i(1, 60)) # Torch near spawn
	deco_layer.set_cell(Vector2i(21, 1), 7, Vector2i(1, 60)) # Torch above bounce wall
	deco_layer.set_cell(Vector2i(18, 4), 7, Vector2i(1, 60)) # Torch at shelf

	# =========================================================================
	# SCREEN 2: [0, -1] - THE FROSTBOUND VAULT (SLIPPERY ICE & TIGHT CEILING)
	# Y: -17..-1 tiles (-270..0 px)
	# CRITICAL: NO ROOF AT Y = -17! Open vertical clearance to Screen 3.
	# =========================================================================

	# Left Boundary Wall (x = 0..1)
	for y in range(-17, 0):
		solid_layer.set_cell(Vector2i(0, y), 0, Vector2i(3, 0))
		solid_layer.set_cell(Vector2i(1, y), 0, Vector2i(2, 1))

	# Right Boundary Wall (x = 28..29)
	for y in range(-17, 0):
		solid_layer.set_cell(Vector2i(28, y), 0, Vector2i(3, 0))
		solid_layer.set_cell(Vector2i(29, y), 0, Vector2i(2, 1))

	# Ice Platform 1: Arrival shelf from Screen 1 leap at x = 10..13 (160..208 px), y = -2 (-32 px)
	# Jump left from Screen 1 shelf (Stage 24-26) lands directly here across y=0 boundary!
	for x in range(10, 14):
		solid_layer.set_cell(Vector2i(x, -2), 1, Vector2i(3, 0)) # Ice platform

	# The Tight Ceiling Overhang: Stone ceiling hanging at y = -8 (-128 px) across x = 6..14
	# Distance from Plat 1 is 96px (6 tiles). Clears Stage 12-13, but bonks if > Stage 14!
	for x in range(6, 15):
		solid_layer.set_cell(Vector2i(x, -8), 0, Vector2i(3, 0))
		deco_layer.set_cell(Vector2i(x, -7), 5, Vector2i(2, 17)) # Icicle bonk hazards!

	# Ice Platform 2: Tight ceiling landing ledge at x = 3..6 (48..96 px), y = -4 (-64 px)
	# Managed low-charge jump under the ceiling lands here!
	for x in range(3, 7):
		solid_layer.set_cell(Vector2i(x, -4), 1, Vector2i(3, 0)) # Ice platform

	# Platform 3: Mid-vault ice ledge at x = 10..13 (160..208 px), y = -9 (-144 px)
	# Leap right from Plat 2 with Stage 20-22 lands cleanly here!
	for x in range(10, 14):
		solid_layer.set_cell(Vector2i(x, -9), 1, Vector2i(3, 0)) # Ice platform

	# Platform 4: Ascent threshold at x = 17..20 (272..320 px), y = -13 (-208 px)
	# Leap right from Plat 3 with Stage 18-21 lands here!
	for x in range(17, 21):
		solid_layer.set_cell(Vector2i(x, -13), 1, Vector2i(3, 0)) # Ice platform

	# Screen 2 Decor: Glowing blue crystals
	deco_layer.set_cell(Vector2i(12, -3), 6, Vector2i(1, 8))
	deco_layer.set_cell(Vector2i(5, -5), 6, Vector2i(1, 8))
	deco_layer.set_cell(Vector2i(11, -10), 6, Vector2i(1, 8))
	deco_layer.set_cell(Vector2i(18, -14), 6, Vector2i(1, 8))

	# SurfaceZone for Ice Mechanics on Screen 2 (Ground friction = 120 px/s^2)
	var ice_zone: Area2D = Area2D.new()
	ice_zone.name = "IceZoneScreen2"
	var sz_script = load("res://script/surface_zone.gd")
	ice_zone.set_script(sz_script)
	ice_zone.set("surface_type", 1) # PlayerCharacter.SurfaceType.ICE
	var ice_col = CollisionShape2D.new()
	var ice_rect = RectangleShape2D.new()
	ice_rect.size = Vector2(400, 240)
	ice_col.shape = ice_rect
	ice_col.position = Vector2(240, -135)
	ice_zone.add_child(ice_col)
	root_node.add_child(ice_zone)
	ice_zone.owner = root_node
	ice_col.owner = root_node

	# =========================================================================
	# SCREEN 3: [0, -2] - THE GALE-TORN SPIRE (HEAVY LEFTWARD WIND & SPIKES)
	# Y: -34..-18 tiles (-540..-270 px)
	# CRITICAL: NO ROOF! Open sky above the spire summit.
	# =========================================================================

	# Right Boundary Wall (x = 28..29)
	for y in range(-34, -17):
		solid_layer.set_cell(Vector2i(28, y), 0, Vector2i(3, 0))
		solid_layer.set_cell(Vector2i(29, y), 0, Vector2i(2, 1))

	# Far Left Castle Wall (x = 0) with Spikes lining the Punish Chute (x = 1..3)
	for y in range(-34, -17):
		solid_layer.set_cell(Vector2i(0, y), 0, Vector2i(3, 0))
		if y % 2 == 0:
			deco_layer.set_cell(Vector2i(1, y), 5, Vector2i(2, 17)) # Threatening spikes!

	# Note: Punish Chute at x = 1..3 is completely open down through Screen 2 and Screen 1!

	# Platform 1: Arrival Battlement at x = 5..9 (80..144 px), y = -19 (-304 px)
	# Leap left from Screen 2 Plat 4 (Stage 26-28 with wind) lands here!
	for x in range(5, 10):
		solid_layer.set_cell(Vector2i(x, -19), 0, Vector2i(2, 0)) # Castle stone

	# Platform 2: High Wind Rampart at x = 13..17 (208..272 px), y = -23 (-368 px)
	# The Crucible Jump: Leap RIGHT against the -150 px/s^2 wind with Stage 28-34!
	for x in range(13, 18):
		solid_layer.set_cell(Vector2i(x, -23), 0, Vector2i(2, 0))

	# Platform 3: The Queen's Spire Summit at x = 5..9 (80..144 px), y = -27 (-432 px)
	# Final leap LEFT with the wind using gentle Stage 16-19! (Overshooting drops to punish chute)
	for x in range(5, 10):
		solid_layer.set_cell(Vector2i(x, -27), 0, Vector2i(2, 0))

	# Spire Summit Props: Animated Golden Flag, Rune, and Treasure Chest!
	deco_layer.set_cell(Vector2i(6, -29), 14, Vector2i(0, 0)) # Golden Flag!
	deco_layer.set_cell(Vector2i(7, -28), 16, Vector2i(0, 0)) # Mystic Rune!
	deco_layer.set_cell(Vector2i(8, -28), 15, Vector2i(0, 0)) # Treasure Chest!

	# WindZone across Screen 3: -150 px/s^2 leftward gale!
	var wind_zone: Area2D = Area2D.new()
	wind_zone.name = "SpireWindZoneScreen3"
	var wz_script = load("res://script/wind_zone.gd")
	wind_zone.set_script(wz_script)
	wind_zone.set("wind_force", Vector2(-150.0, 0.0))
	var wind_col = CollisionShape2D.new()
	var wind_rect = RectangleShape2D.new()
	wind_rect.size = Vector2(440, 270)
	wind_col.shape = wind_rect
	wind_col.position = Vector2(240, -405) # Center of Screen 3
	wind_zone.add_child(wind_col)
	root_node.add_child(wind_zone)
	wind_zone.owner = root_node
	wind_col.owner = root_node

	# =========================================================================
	# PLAYER & CAMERA SETUP
	# =========================================================================
	var char_scene: PackedScene = load("res://scenes/character.tscn")
	var player: PlayerCharacter = char_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(64, 222) # Spawn on Screen 1 floor
	root_node.add_child(player)
	player.owner = root_node

	var camera: Camera2D = Camera2D.new()
	camera.name = "RoomCamera"
	var rc_script = load("res://script/room_camera.gd")
	camera.set_script(rc_script)
	camera.set("target", player)
	root_node.add_child(camera)
	camera.owner = root_node

	# =========================================================================
	# IN-GAME HUD OVERLAY
	# =========================================================================
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "HUD"

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBoxContainer"

	var title_lbl: Label = Label.new()
	title_lbl.name = "RoomTitle"
	title_lbl.text = "🏰 The Bastion's Crucible [Screen 1]"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title_lbl.add_theme_constant_override("shadow_offset_x", 1)
	title_lbl.add_theme_constant_override("shadow_offset_y", 1)

	var desc_lbl: Label = Label.new()
	desc_lbl.name = "RoomDesc"
	desc_lbl.text = "Wall-Bounce Training • Jump right into the stone pillar (x=21) to ricochet onto the target shelf."
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	desc_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	desc_lbl.add_theme_constant_override("shadow_offset_x", 1)
	desc_lbl.add_theme_constant_override("shadow_offset_y", 1)

	var controls_lbl: Label = Label.new()
	controls_lbl.name = "ControlsHint"
	controls_lbl.text = "Teleport: [1] Screen 1 (Wall-Bounce)  [2] Screen 2 (Ice)  [3] Screen 3 (Wind Spire) | [R] Reset"
	controls_lbl.add_theme_font_size_override("font_size", 9)
	controls_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0, 0.85))
	controls_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	controls_lbl.add_theme_constant_override("shadow_offset_x", 1)
	controls_lbl.add_theme_constant_override("shadow_offset_y", 1)

	vbox.add_child(title_lbl)
	vbox.add_child(desc_lbl)
	vbox.add_child(controls_lbl)
	margin.add_child(vbox)
	canvas_layer.add_child(margin)
	root_node.add_child(canvas_layer)

	canvas_layer.owner = root_node
	margin.owner = root_node
	vbox.owner = root_node
	title_lbl.owner = root_node
	desc_lbl.owner = root_node
	controls_lbl.owner = root_node

	# Package and save
	var packed: PackedScene = PackedScene.new()
	var pack_err = packed.pack(root_node)
	if pack_err != OK:
		printerr("Failed to pack scene! Error: ", pack_err)
		quit(1)
		return

	ResourceSaver.save(packed, DUNGEON_SCENE_PATH)
	var save_err = ResourceSaver.save(packed, GAME_SCENE_PATH)
	if save_err != OK:
		printerr("Failed to save scene! Error: ", save_err)
		quit(1)
		return

	print("Successfully rebuilt and saved ", GAME_SCENE_PATH, " and ", DUNGEON_SCENE_PATH, "!")
	quit(0)
