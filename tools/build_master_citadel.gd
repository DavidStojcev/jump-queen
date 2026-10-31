extends SceneTree

const GAME_SCENE_PATH: String = "res://scenes/game.tscn"
const DUNGEON_SCENE_PATH: String = "res://scenes/castle_dungeon.tscn"
const TILESET_PATH: String = "res://resources/game_tileset.tres"

func _init() -> void:
	print("Building Master Citadel: The Citadel of the Frost Gale (Definitive Edition)...")
	var tileset: TileSet = load(TILESET_PATH)
	if not tileset:
		printerr("Failed to load TileSet!")
		quit(1)
		return

	# Root Game Node
	var root_node: Node2D = Node2D.new()
	root_node.name = "Game"
	var gm_script = load("res://script/game_manager.gd")
	root_node.set_script(gm_script)

	# =========================================================================
	# 1. VISUAL BACKGROUNDS (Node2D with z_index = -20)
	# =========================================================================
	var bg_root: Node2D = Node2D.new()
	bg_root.name = "Backgrounds"
	bg_root.z_index = -20
	root_node.add_child(bg_root)
	bg_root.owner = root_node

	# Screen 1 Background (Ruined Bastion / Sewer Castle Interior)
	var bg_tex_s1: Texture2D = load("res://assets/sprites/Sewers pack files/Assets/Environment Layers/middle.png")
	if bg_tex_s1:
		var bg_s1: Sprite2D = Sprite2D.new()
		bg_s1.name = "BackgroundScreen1"
		bg_s1.texture = bg_tex_s1
		bg_s1.centered = true
		bg_s1.position = Vector2(240, 135)
		# 928x240 -> scale to cover 480x270 (scale y = 270/240 = 1.125)
		bg_s1.scale = Vector2(1.125, 1.125)
		bg_s1.modulate = Color(0.65, 0.60, 0.55, 1.0) # warm dark stone fortress tint
		bg_root.add_child(bg_s1)
		bg_s1.owner = root_node

	# Screen 2 Background (Frozen Subterranean Catacombs)
	var bg_tex_s2: Texture2D = load("res://assets/sprites/Caves/PixelFantasy_Caves_1.0/background2.png")
	if bg_tex_s2:
		var bg_s2: Sprite2D = Sprite2D.new()
		bg_s2.name = "BackgroundScreen2"
		bg_s2.texture = bg_tex_s2
		bg_s2.centered = true
		bg_s2.position = Vector2(240, -135)
		# 960x480 -> scale to cover 480x270 (scale y = 270/480 = 0.5625)
		bg_s2.scale = Vector2(0.5625, 0.5625)
		bg_s2.modulate = Color(0.75, 0.85, 1.0, 1.0) # cyan permafrost cavern tint
		bg_root.add_child(bg_s2)
		bg_s2.owner = root_node

	# Screen 3 Background (Exposed Stormy Mountain Blizzard Sky)
	var bg_tex_s3: Texture2D = load("res://assets/sprites/Swamp game tileset/2 Background/Background.png")
	if bg_tex_s3:
		var bg_s3: Sprite2D = Sprite2D.new()
		bg_s3.name = "BackgroundScreen3"
		bg_s3.texture = bg_tex_s3
		bg_s3.centered = true
		bg_s3.position = Vector2(240, -405)
		# 576x324 -> scale to cover 480x270 (scale y = 270/324 = 0.8333)
		bg_s3.scale = Vector2(0.834, 0.834)
		bg_s3.modulate = Color(0.60, 0.65, 0.85, 1.0) # cold twilight blizzard tint
		bg_root.add_child(bg_s3)
		bg_s3.owner = root_node

	# =========================================================================
	# 2. MID-GROUND ARCHITECTURE (TileMapLayer, z_index = -5, No Collision)
	# =========================================================================
	var wall_layer: TileMapLayer = TileMapLayer.new()
	wall_layer.name = "BackgroundWallLayer"
	wall_layer.tile_set = tileset
	wall_layer.z_index = -5
	wall_layer.collision_enabled = false
	wall_layer.modulate = Color(0.42, 0.42, 0.48, 0.85) # moody stone depth
	root_node.add_child(wall_layer)
	wall_layer.owner = root_node

	# =========================================================================
	# 3. SOLID PLAYFIELD (TileMapLayer, z_index = 0, Collision Enabled)
	# =========================================================================
	var solid_layer: TileMapLayer = TileMapLayer.new()
	solid_layer.name = "TileMapLayer"
	solid_layer.tile_set = tileset
	solid_layer.z_index = 0
	solid_layer.collision_enabled = true
	root_node.add_child(solid_layer)
	solid_layer.owner = root_node

	# =========================================================================
	# 4. DECORATIVE PROPS & LIGHTING (TileMapLayer, z_index = 5, No Collision)
	# =========================================================================
	var deco_layer: TileMapLayer = TileMapLayer.new()
	deco_layer.name = "DecorativeLayer"
	deco_layer.tile_set = tileset
	deco_layer.z_index = 5
	deco_layer.collision_enabled = false
	root_node.add_child(deco_layer)
	deco_layer.owner = root_node

	# Helper to place 3-piece platform (left cap, middle, right cap)
	var place_platform = func(layer: TileMapLayer, x_start: int, x_end: int, y: int, src_id: int, left_coord: Vector2i, mid_coord: Vector2i, right_coord: Vector2i):
		for x in range(x_start, x_end + 1):
			if x == x_start:
				layer.set_cell(Vector2i(x, y), src_id, left_coord)
			elif x == x_end:
				layer.set_cell(Vector2i(x, y), src_id, right_coord)
			else:
				layer.set_cell(Vector2i(x, y), src_id, mid_coord)

	# =========================================================================
	# SCREEN 1: [0, 0] - THE RUINED LOWER BASTION (Y: 0..16 tiles / 0..270 px)
	# =========================================================================

	# Outer Wall Buttresses
	for y in range(0, 16):
		solid_layer.set_cell(Vector2i(0, y), 0, Vector2i(3, 0)) # Left wall
		solid_layer.set_cell(Vector2i(1, y), 0, Vector2i(2, 1))
		solid_layer.set_cell(Vector2i(28, y), 0, Vector2i(3, 0)) # Right wall
		solid_layer.set_cell(Vector2i(29, y), 0, Vector2i(2, 1))
		# Background stone wall framing
		wall_layer.set_cell(Vector2i(2, y), 0, Vector2i(3, 1))
		wall_layer.set_cell(Vector2i(27, y), 0, Vector2i(3, 1))

	# Floor (y = 15..16):
	# Left stone ground (x = 2..7)
	for x in range(2, 8):
		solid_layer.set_cell(Vector2i(x, 15), 0, Vector2i(2, 0))
		solid_layer.set_cell(Vector2i(x, 16), 0, Vector2i(2, 1))

	# Mud Courtyard Trench (x = 8..15)
	for x in range(8, 16):
		solid_layer.set_cell(Vector2i(x, 15), 4, Vector2i(1, 1)) # Mud surface
		solid_layer.set_cell(Vector2i(x, 16), 4, Vector2i(1, 2)) # Mud foundation

	# Right stone ground (x = 16..27)
	for x in range(16, 28):
		solid_layer.set_cell(Vector2i(x, 15), 0, Vector2i(2, 0))
		solid_layer.set_cell(Vector2i(x, 16), 0, Vector2i(2, 1))

	# SurfaceZone: MUD Courtyard Basin
	var mud_zone: Area2D = Area2D.new()
	mud_zone.name = "CourtyardMudZone"
	var sz_script = load("res://script/surface_zone.gd")
	mud_zone.set_script(sz_script)
	mud_zone.set("surface_type", 2) # PlayerCharacter.SurfaceType.MUD
	var mud_col = CollisionShape2D.new()
	var mud_rect = RectangleShape2D.new()
	mud_rect.size = Vector2(128, 24)
	mud_col.shape = mud_rect
	mud_col.position = Vector2(192, 244)
	mud_zone.add_child(mud_col)
	root_node.add_child(mud_zone)
	mud_zone.owner = root_node
	mud_col.owner = root_node

	# --- SCREEN 1 PLATFORMS ---
	# Plat 1.1: Wooden beam over mud trench (x = 9..12 / 144..192 px, y = 13 / 208 px)
	place_platform.call(solid_layer, 9, 12, 13, 1, Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3))

	# Plat 1.2: Stone fortress shelf (x = 15..18 / 240..288 px, y = 10 / 160 px)
	place_platform.call(solid_layer, 15, 18, 10, 0, Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0))

	# Plat 1.3: Armory scaffolding (x = 6..9 / 96..144 px, y = 7 / 112 px)
	place_platform.call(solid_layer, 6, 9, 7, 1, Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3))

	# Plat 1.4: Chimney launch base (x = 4..7 / 64..112 px, y = 4 / 64 px)
	place_platform.call(solid_layer, 4, 7, 4, 0, Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0))

	# The Wall-Bounce Buttress Wall: Solid vertical column hanging from ceiling at x = 11 (176 px), y = 0..3
	for y in range(0, 4):
		solid_layer.set_cell(Vector2i(11, y), 0, Vector2i(3, 0))

	# Plat 1.5: High Guard Shelf (x = 7..10 / 112..160 px, y = 2 / 32 px)
	# Positioned 32px below ceiling so character body and platform are 100% visible on Screen 1!
	place_platform.call(solid_layer, 7, 10, 2, 1, Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3))

	# Screen 1 Exit Arch across screen boundary:
	# Columns x = 14..20 are 100% open sky between Screen 1 and Screen 2!
	# Surrounding ceiling masonry:
	for x in range(2, 7):
		solid_layer.set_cell(Vector2i(x, 0), 0, Vector2i(2, 0))
	for x in range(21, 28):
		solid_layer.set_cell(Vector2i(x, 0), 0, Vector2i(2, 0))

	# Screen 1 Atmospheric Props (Wall Torches, Banners)
	deco_layer.set_cell(Vector2i(3, 13), 7, Vector2i(1, 60)) # Torch near spawn
	deco_layer.set_cell(Vector2i(26, 13), 7, Vector2i(1, 60)) # Far courtyard torch
	deco_layer.set_cell(Vector2i(17, 8), 7, Vector2i(1, 60)) # Torch on Plat 1.2
	deco_layer.set_cell(Vector2i(11, 4), 7, Vector2i(1, 60)) # Torch on Wall-Bounce Buttress
	deco_layer.set_cell(Vector2i(8, 1), 7, Vector2i(1, 60)) # Torch above guard shelf


	# =========================================================================
	# SCREEN 2: [0, -1] - THE FROZEN CATACOMBS (Y: -17..-1 tiles / -270..0 px)
	# =========================================================================

	# Outer Wall Buttresses
	for y in range(-17, 0):
		solid_layer.set_cell(Vector2i(0, y), 0, Vector2i(3, 0))
		solid_layer.set_cell(Vector2i(1, y), 0, Vector2i(2, 1))
		solid_layer.set_cell(Vector2i(28, y), 0, Vector2i(3, 0))
		solid_layer.set_cell(Vector2i(29, y), 0, Vector2i(2, 1))
		# Background subterranean icy walls
		wall_layer.set_cell(Vector2i(2, y), 5, Vector2i(24, 1))
		wall_layer.set_cell(Vector2i(27, y), 5, Vector2i(24, 1))

	# --- SCREEN 2 ICE PLATFORMS ---
	# Plat 2.1: S2 Arrival Ice Shelf (x = 15..18 / 240..288 px, y = -2 / -32 px)
	place_platform.call(solid_layer, 15, 18, -2, 1, Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1))

	# Plat 2.2: Glacial Terrace (x = 5..8 / 80..128 px, y = -6 / -96 px)
	place_platform.call(solid_layer, 5, 8, -6, 1, Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1))

	# Plat 2.3: Mid Crypt Perch (x = 16..19 / 256..304 px, y = -9 / -144 px)
	place_platform.call(solid_layer, 16, 19, -9, 1, Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1))

	# The Icicle Throat Ceiling Overhang:
	# Solid stone rock hangs at y = -14 (-224 px) across x = 3..9 with menacing icicle spikes!
	for x in range(3, 10):
		solid_layer.set_cell(Vector2i(x, -14), 0, Vector2i(3, 0))
		deco_layer.set_cell(Vector2i(x, -13), 5, Vector2i(2, 17)) # Threatening stalactites!

	# Plat 2.4: The Icicle Throat Shelf (x = 4..7 / 64..112 px, y = -12 / -192 px)
	# Passing under the overhang requires tight jump control to avoid bonking!
	place_platform.call(solid_layer, 4, 7, -12, 1, Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1))

	# Plat 2.5: Glacial Spire Summit / Exit Shelf (x = 14..17 / 224..272 px, y = -15 / -240 px)
	# Positioned safely inside Screen 2 so character body and platform are 100% visible!
	place_platform.call(solid_layer, 14, 17, -15, 1, Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1))


	# Ceiling Boundary masonry between Screen 2 and Screen 3:
	# Open sky corridor at x = 18..24 leading into Screen 3!
	for x in range(2, 18):
		solid_layer.set_cell(Vector2i(x, -17), 0, Vector2i(2, 0))
	for x in range(25, 28):
		solid_layer.set_cell(Vector2i(x, -17), 0, Vector2i(2, 0))

	# Screen 2 Glowing Blue Crystals & Decorative Icicles
	deco_layer.set_cell(Vector2i(16, -3), 6, Vector2i(1, 8))
	deco_layer.set_cell(Vector2i(6, -7), 6, Vector2i(1, 8))
	deco_layer.set_cell(Vector2i(18, -10), 6, Vector2i(1, 8))
	deco_layer.set_cell(Vector2i(5, -13), 6, Vector2i(1, 8))
	deco_layer.set_cell(Vector2i(21, -17), 6, Vector2i(1, 8))

	# SurfaceZone: ICE for Screen 2 (Friction = 120, slide-charging)
	var ice_zone: Area2D = Area2D.new()
	ice_zone.name = "CatacombsIceZoneScreen2"
	ice_zone.set_script(sz_script)
	ice_zone.set("surface_type", 1) # PlayerCharacter.SurfaceType.ICE
	var ice_col = CollisionShape2D.new()
	var ice_rect = RectangleShape2D.new()
	ice_rect.size = Vector2(440, 270)
	ice_col.shape = ice_rect
	ice_col.position = Vector2(240, -135)
	ice_zone.add_child(ice_col)
	root_node.add_child(ice_zone)
	ice_zone.owner = root_node
	ice_col.owner = root_node

	# =========================================================================
	# SCREEN 3: [0, -2] - THE HOWLING BATTLEMENTS (Y: -34..-18 tiles / -540..-270 px)
	# =========================================================================

	# Right Outer Spire Wall
	for y in range(-34, -17):
		solid_layer.set_cell(Vector2i(28, y), 0, Vector2i(3, 0))
		solid_layer.set_cell(Vector2i(29, y), 0, Vector2i(2, 1))

	# Far Left Abyss Wall (x = 0) with Spikes lining the Abyss chute (x = 1)
	for y in range(-34, -17):
		solid_layer.set_cell(Vector2i(0, y), 0, Vector2i(3, 0))
		if y % 2 == 0:
			deco_layer.set_cell(Vector2i(1, y), 5, Vector2i(2, 17)) # Warning spikes!

	# Note: Column x = 1..3 is completely open through all 3 screens as THE ABYSS!

	# --- SCREEN 3 PLATFORMS (Calculated with 100% collision clearance) ---
	# Plat 3.1: S3 Arrival Battlement (x = 19..22 / 304..352 px, y = -19 / -304 px)
	place_platform.call(solid_layer, 19, 22, -19, 0, Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0))

	# Plat 3.2: Mid Rampart (x = 10..13 / 160..208 px, y = -23 / -368 px) [Jump LEFT WITH WIND: Stage 15-18]
	place_platform.call(solid_layer, 10, 13, -23, 1, Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3))

	# Plat 3.3: High Battlement Turret (x = 18..21 / 288..336 px, y = -27 / -432 px) [Crucible Jump RIGHT AGAINST GALE: Stage 27-35!]
	place_platform.call(solid_layer, 18, 21, -27, 0, Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0))

	# Plat 3.4: Summit Watchtower (x = 9..12 / 144..192 px, y = -30 / -480 px) [Jump LEFT WITH WIND: Stage 14-19]
	place_platform.call(solid_layer, 9, 12, -30, 1, Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3))

	# Plat 3.5: The Queen's Summit Throne (x = 4..8 / 64..128 px, y = -32 / -512 px) [Summit Crown Float: Stage 6-12]
	# OVERCHARGE PENALTY: Panicking and charging > 18 blows the player past the throne directly into THE ABYSS!
	place_platform.call(solid_layer, 4, 8, -32, 0, Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0))

	# Spire Summit Victory Props
	deco_layer.set_cell(Vector2i(5, -34), 14, Vector2i(0, 0)) # Animated Golden Flag!
	deco_layer.set_cell(Vector2i(6, -33), 16, Vector2i(0, 0)) # Mystic Floating Rune!
	deco_layer.set_cell(Vector2i(7, -33), 15, Vector2i(0, 0)) # Animated Treasure Chest!

	# Environmental WindZone: -180 px/s^2 leftward gale across Screen 3!
	var wind_zone: Area2D = Area2D.new()
	wind_zone.name = "MountainBlizzardZoneScreen3"
	var wz_script = load("res://script/wind_zone.gd")
	wind_zone.set_script(wz_script)
	wind_zone.set("wind_force", Vector2(-180.0, 0.0))
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
	# INTERACTIVE BREAKABLE CRATES (WOOD VFX)
	# =========================================================================
	var crate_scene: PackedScene = load("res://scenes/breakable_crate.tscn")
	if crate_scene:
		# Crate 1: In Screen 1 courtyard near spawn for immediate testing
		var crate1 = crate_scene.instantiate()
		crate1.position = Vector2(100, 229)
		root_node.add_child(crate1)
		crate1.owner = root_node

		# Crate 2: On Screen 1 armory scaffold Plat 1.3 (x=6..9, y=7 / 112px)
		var crate2 = crate_scene.instantiate()
		crate2.position = Vector2(120, 101)
		root_node.add_child(crate2)
		crate2.owner = root_node

		# Crate 3: On Screen 3 watchtower Plat 3.4 (x=9..12, y=-30 / -480px)
		var crate3 = crate_scene.instantiate()
		crate3.position = Vector2(168, -491)
		root_node.add_child(crate3)
		crate3.owner = root_node


	# =========================================================================
	# PLAYER CHARACTER & ROOM CAMERA
	# =========================================================================
	var char_scene: PackedScene = load("res://scenes/character.tscn")
	var player: PlayerCharacter = char_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(64, 230) # Spawn on Screen 1 floor
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
	# CANVAS LAYER HUD OVERLAY
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
	title_lbl.text = "🏰 Screen 1: The Ruined Lower Bastion"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title_lbl.add_theme_constant_override("shadow_offset_x", 1)
	title_lbl.add_theme_constant_override("shadow_offset_y", 1)

	var desc_lbl: Label = Label.new()
	desc_lbl.name = "RoomDesc"
	desc_lbl.text = "Armory & Wall-Bouncing • Ricochet off the stone buttress at x=11 to reach the High Guard Shelf."
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	desc_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	desc_lbl.add_theme_constant_override("shadow_offset_x", 1)
	desc_lbl.add_theme_constant_override("shadow_offset_y", 1)

	var controls_lbl: Label = Label.new()
	controls_lbl.name = "ControlsHint"
	controls_lbl.text = "Teleport: [1] Screen 1  [2] Screen 2 (Ice)  [3] Screen 3 (Gale Spire) | [R] Reset | [H] Hide HUD"
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

	# Package and save scene
	var packed: PackedScene = PackedScene.new()
	var pack_err = packed.pack(root_node)
	if pack_err != OK:
		printerr("Failed to pack master citadel scene! Error: ", pack_err)
		quit(1)
		return

	ResourceSaver.save(packed, DUNGEON_SCENE_PATH)
	var save_err = ResourceSaver.save(packed, GAME_SCENE_PATH)
	if save_err != OK:
		printerr("Failed to save master citadel to game.tscn! Error: ", save_err)
		quit(1)
		return

	print("SUCCESS! Built and saved The Citadel of the Frost Gale (Definitive Edition) to ", GAME_SCENE_PATH)
	quit(0)
