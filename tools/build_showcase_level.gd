extends SceneTree

const GAME_SCENE_PATH: String = "res://scenes/game.tscn"
const TILESET_PATH: String = "res://resources/game_tileset.tres"

func _init() -> void:
	print("Building Jump Queen Showcase Level...")
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

	# 2. Decorative TileMapLayer (No Collision Layer for props, trees, water, and animated tiles)
	var deco_layer: TileMapLayer = TileMapLayer.new()
	deco_layer.name = "DecorativeLayer"
	deco_layer.tile_set = tileset
	deco_layer.collision_enabled = false
	root_node.add_child(deco_layer)
	deco_layer.owner = root_node

	# ----------------------------------------------------
	# PAINTING ROOM (0, 0): Whispering Woods & Starting Shrine
	# ----------------------------------------------------
	# Floor (y = 14..16)
	for x in range(0, 30):
		if x < 20 or x > 22: # Leave chute at 20..22 down to sewers
			solid_layer.set_cell(Vector2i(x, 14), 0, Vector2i(1, 0)) # Grass top
			solid_layer.set_cell(Vector2i(x, 15), 0, Vector2i(1, 1)) # Dirt
			solid_layer.set_cell(Vector2i(x, 16), 0, Vector2i(1, 1))

	# Left Wall (doorway at 11..13 open to Museum)
	for y in range(0, 14):
		if y < 11:
			solid_layer.set_cell(Vector2i(0, y), 0, Vector2i(3, 0))
	# Right Wall (doorway at 11..13 open to Swamp)
	for y in range(0, 14):
		if y < 11:
			solid_layer.set_cell(Vector2i(29, y), 0, Vector2i(3, 0))
	# Ceiling (shaft at 12..17 open to Caves)
	for x in range(0, 30):
		if x < 12 or x > 17:
			solid_layer.set_cell(Vector2i(x, 0), 0, Vector2i(3, 0))

	# Floating Platforms in Room (0, 0)
	for x in range(4, 8):
		solid_layer.set_cell(Vector2i(x, 11), 1, Vector2i(1, 0)) # Wooden beam
	for x in range(13, 17):
		solid_layer.set_cell(Vector2i(x, 8), 1, Vector2i(0, 0)) # Stone slab
	for x in range(21, 26):
		solid_layer.set_cell(Vector2i(x, 5), 1, Vector2i(2, 0)) # Mossy ledge

	# Decorative trees in background of Room (0, 0)
	for tx in range(0, 6):
		for ty in range(0, 5):
			deco_layer.set_cell(Vector2i(2 + tx, 7 + ty), 8, Vector2i(2 + tx, 2 + ty))
			deco_layer.set_cell(Vector2i(21 + tx, 1 + ty), 8, Vector2i(2 + tx, 2 + ty))

	# ----------------------------------------------------
	# PAINTING ROOM (-1, 0): Worldbuilder Gallery [-30..-1, 0..16]
	# ----------------------------------------------------
	# Floor (y = 14..16)
	for x in range(-30, 0):
		solid_layer.set_cell(Vector2i(x, 14), 0, Vector2i(2, 0)) # Stone tile
		solid_layer.set_cell(Vector2i(x, 15), 0, Vector2i(2, 1))
		solid_layer.set_cell(Vector2i(x, 16), 0, Vector2i(2, 1))

	# Left boundary wall & solid ceiling
	for y in range(0, 14):
		solid_layer.set_cell(Vector2i(-30, y), 0, Vector2i(3, 0))
	for x in range(-30, 0):
		solid_layer.set_cell(Vector2i(x, 0), 0, Vector2i(3, 0))

	# Mezzanine walkway across Gallery at y = 7
	for x in range(-27, -3):
		if x != -16 and x != -17: # Gap to jump through
			solid_layer.set_cell(Vector2i(x, 7), 1, Vector2i(1, 0))

	# Exhibition Pedestals at y = 11
	# Stall 1: Overworld & Platforms (x = -28..-25)
	for x in range(-28, -24):
		solid_layer.set_cell(Vector2i(x, 11), 0, Vector2i(1, 0))
		solid_layer.set_cell(Vector2i(x, 12), 0, Vector2i(1, 1))
		deco_layer.set_cell(Vector2i(x, 10), 1, Vector2i(x + 28, 0))

	# Stall 2: Deep Caves & Props (x = -23..-20)
	for x in range(-23, -19):
		solid_layer.set_cell(Vector2i(x, 11), 5, Vector2i(2, 16))
		solid_layer.set_cell(Vector2i(x, 12), 5, Vector2i(2, 17))
	deco_layer.set_cell(Vector2i(-23, 10), 6, Vector2i(1, 8)) # Cave crystal
	deco_layer.set_cell(Vector2i(-21, 10), 7, Vector2i(1, 60)) # Cave torch/pillar

	# Stall 3: Murky Swamp & Animated Objects (x = -18..-15)
	for x in range(-18, -14):
		solid_layer.set_cell(Vector2i(x, 11), 4, Vector2i(1, 1))
		solid_layer.set_cell(Vector2i(x, 12), 4, Vector2i(1, 2))
	deco_layer.set_cell(Vector2i(-18, 10), 16, Vector2i(0, 0)) # Animated Rune!
	deco_layer.set_cell(Vector2i(-17, 10), 15, Vector2i(0, 0)) # Animated Chest!
	deco_layer.set_cell(Vector2i(-15, 9), 14, Vector2i(0, 0)) # Animated Flag!

	# Stall 4: Toxic Sewers & Water (x = -13..-10)
	for x in range(-13, -9):
		solid_layer.set_cell(Vector2i(x, 11), 2, Vector2i(1, 1))
		solid_layer.set_cell(Vector2i(x, 12), 2, Vector2i(1, 2))
	deco_layer.set_cell(Vector2i(-12, 10), 3, Vector2i(0, 0)) # Sewer Water!
	deco_layer.set_cell(Vector2i(-11, 10), 3, Vector2i(1, 0))

	# Stall 5: Pixel Trees Canopy (x = -8..-5)
	for x in range(-8, -4):
		solid_layer.set_cell(Vector2i(x, 11), 0, Vector2i(1, 0))
		solid_layer.set_cell(Vector2i(x, 12), 0, Vector2i(1, 1))
	for tx in range(0, 4):
		for ty in range(0, 3):
			deco_layer.set_cell(Vector2i(-8 + tx, 8 + ty), 9, Vector2i(2 + tx, 2 + ty))

	# Stall 6: Wood VFX Display on Mezzanine at y = 6
	deco_layer.set_cell(Vector2i(-25, 5), 11, Vector2i(0, 0)) # Wood VFX 01 Hit
	deco_layer.set_cell(Vector2i(-21, 5), 12, Vector2i(0, 0)) # Wood VFX 01 Repeatable (Animated!)
	deco_layer.set_cell(Vector2i(-13, 5), 13, Vector2i(0, 0)) # Wood VFX 02 Impact

	# ----------------------------------------------------
	# PAINTING ROOM (1, 0): The Murky Swamp [30..59, 0..16]
	# ----------------------------------------------------
	# Floor (y = 14..16)
	for x in range(30, 60):
		solid_layer.set_cell(Vector2i(x, 14), 4, Vector2i(1, 1)) # Mud top
		solid_layer.set_cell(Vector2i(x, 15), 4, Vector2i(1, 2)) # Mud underground
		solid_layer.set_cell(Vector2i(x, 16), 4, Vector2i(1, 2))

	# Right boundary wall & ceiling
	for y in range(0, 14):
		solid_layer.set_cell(Vector2i(59, y), 4, Vector2i(0, 1))
	for x in range(30, 60):
		solid_layer.set_cell(Vector2i(x, 0), 4, Vector2i(1, 2))

	# Swamp Platforms
	for x in range(33, 38):
		solid_layer.set_cell(Vector2i(x, 10), 4, Vector2i(3, 1)) # Wooden dock
	for x in range(41, 46):
		solid_layer.set_cell(Vector2i(x, 8), 4, Vector2i(4, 1)) # Mossy log
	for x in range(50, 56):
		solid_layer.set_cell(Vector2i(x, 5), 4, Vector2i(3, 1)) # High willow perch

	# Swamp Animated Objects
	deco_layer.set_cell(Vector2i(35, 9), 14, Vector2i(0, 0)) # Animated Flag!
	deco_layer.set_cell(Vector2i(43, 7), 16, Vector2i(0, 0)) # Floating Rune!
	deco_layer.set_cell(Vector2i(54, 4), 15, Vector2i(0, 0)) # Treasure Chest!

	# ----------------------------------------------------
	# PAINTING ROOM (0, -1): Crystalline Caverns [0..29, -17..-1]
	# ----------------------------------------------------
	# Floor with opening at 12..17
	for x in range(0, 30):
		if x < 12 or x > 17:
			solid_layer.set_cell(Vector2i(x, -1), 5, Vector2i(2, 16))
			solid_layer.set_cell(Vector2i(x, -2), 5, Vector2i(2, 16))

	# Side walls & ceiling
	for y in range(-17, 0):
		solid_layer.set_cell(Vector2i(0, y), 5, Vector2i(1, 16))
		solid_layer.set_cell(Vector2i(29, y), 5, Vector2i(3, 16))
	for x in range(0, 30):
		solid_layer.set_cell(Vector2i(x, -17), 5, Vector2i(2, 17))

	# Cave Platforms & Bounce Pillars
	for x in range(4, 8):
		solid_layer.set_cell(Vector2i(x, -6), 5, Vector2i(2, 16))
	for x in range(23, 27):
		solid_layer.set_cell(Vector2i(x, -9), 5, Vector2i(2, 16)) # Wall bounce landing
	for x in range(11, 19):
		solid_layer.set_cell(Vector2i(x, -12), 5, Vector2i(2, 16)) # High cavern bridge

	# Cave Props (Crystals & Torches)
	deco_layer.set_cell(Vector2i(5, -7), 6, Vector2i(1, 8)) # Glowing crystal
	deco_layer.set_cell(Vector2i(25, -10), 6, Vector2i(1, 8)) # Crystal
	deco_layer.set_cell(Vector2i(15, -13), 7, Vector2i(1, 60)) # Torch brazier
	deco_layer.set_cell(Vector2i(10, -16), 5, Vector2i(2, 17)) # Stalactite bonk hazard

	# ----------------------------------------------------
	# PAINTING ROOM (0, 1): The Toxic Sewers [0..29, 17..33]
	# ----------------------------------------------------
	# Ceiling with entry drop at 20..22
	for x in range(0, 30):
		if x < 20 or x > 22:
			solid_layer.set_cell(Vector2i(x, 17), 2, Vector2i(1, 1))

	# Floor (y = 31..33)
	for x in range(0, 30):
		solid_layer.set_cell(Vector2i(x, 31), 2, Vector2i(1, 1))
		solid_layer.set_cell(Vector2i(x, 32), 2, Vector2i(1, 2))
		solid_layer.set_cell(Vector2i(x, 33), 2, Vector2i(1, 2))

	# Left and Right walls
	for y in range(17, 32):
		solid_layer.set_cell(Vector2i(0, y), 2, Vector2i(1, 1))
		solid_layer.set_cell(Vector2i(29, y), 2, Vector2i(1, 1))

	# Scaffolding & Workshop in Sewers
	for x in range(4, 11):
		solid_layer.set_cell(Vector2i(x, 26), 2, Vector2i(2, 1))
	for x in range(19, 26):
		solid_layer.set_cell(Vector2i(x, 24), 1, Vector2i(1, 0)) # Wood workshop platform

	# Sewer Water Channel at y = 30
	for x in range(7, 16):
		deco_layer.set_cell(Vector2i(x, 30), 3, Vector2i(0, 0)) # Green chemical water!

	# Wood VFX in Workshop
	deco_layer.set_cell(Vector2i(23, 23), 12, Vector2i(0, 0)) # Animated repeatable wood splinters!

	# ----------------------------------------------------
	# MUD SURFACE ZONE IN SWAMP (Room 1, 0)
	# ----------------------------------------------------
	var mud_zone: Area2D = Area2D.new()
	mud_zone.name = "SwampMudZone"
	var sz_script = load("res://script/surface_zone.gd")
	mud_zone.set_script(sz_script)
	mud_zone.set("surface_type", 2) # PlayerCharacter.SurfaceType.MUD
	var col_shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(160, 24)
	col_shape.shape = rect
	col_shape.position = Vector2(720, 230)
	mud_zone.add_child(col_shape)
	root_node.add_child(mud_zone)
	mud_zone.owner = root_node
	col_shape.owner = root_node

	# ----------------------------------------------------
	# PLAYER CHARACTER
	# ----------------------------------------------------
	var char_scene: PackedScene = load("res://scenes/character.tscn")
	var player: PlayerCharacter = char_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(64, 214)
	root_node.add_child(player)
	player.owner = root_node

	# ----------------------------------------------------
	# ROOM CAMERA
	# ----------------------------------------------------
	var camera: Camera2D = Camera2D.new()
	camera.name = "RoomCamera"
	var rc_script = load("res://script/room_camera.gd")
	camera.set_script(rc_script)
	camera.set("target", player)
	root_node.add_child(camera)
	camera.owner = root_node

	# ----------------------------------------------------
	# CANVAS LAYER HUD
	# ----------------------------------------------------
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
	title_lbl.text = "🌲 Whispering Woods [0, 0]"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title_lbl.add_theme_constant_override("shadow_offset_x", 1)
	title_lbl.add_theme_constant_override("shadow_offset_y", 1)

	var desc_lbl: Label = Label.new()
	desc_lbl.name = "RoomDesc"
	desc_lbl.text = "Spawn Sanctuary • Overworld foliage, wooden platforms, and entry crossroads."
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	desc_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	desc_lbl.add_theme_constant_override("shadow_offset_x", 1)
	desc_lbl.add_theme_constant_override("shadow_offset_y", 1)

	var controls_lbl: Label = Label.new()
	controls_lbl.name = "ControlsHint"
	controls_lbl.text = "Teleport: [1] Woods  [2] Gallery  [3] Swamp  [4] Caves  [5] Sewers | [A/D] Walk  [Space] Jump  [R] Reset"
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
		printerr("Failed to pack scene! Error: ", pack_err)
		quit(1)
		return

	var save_err = ResourceSaver.save(packed, GAME_SCENE_PATH)
	if save_err != OK:
		printerr("Failed to save scene! Error: ", save_err)
		quit(1)
		return

	print("Successfully built and saved ", GAME_SCENE_PATH, " with all 5 biomes and worldbuilding tilesets!")
	quit(0)
