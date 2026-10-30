extends SceneTree

const TILESET_PATH: String = "res://resources/game_tileset.tres"

func _init() -> void:
	print("Starting TileSet incorporation...")
	var tileset: TileSet = load(TILESET_PATH)
	if not tileset:
		printerr("Failed to load ", TILESET_PATH)
		quit(1)
		return

	# Ensure physics layer 0 exists
	if tileset.get_physics_layers_count() == 0:
		tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)

	var sources_to_add = [
		{
			"id": 2,
			"name": "Sewers Tileset",
			"path": "res://assets/sprites/Sewers pack files/Assets/Environment Layers/tileset.png",
			"region_size": Vector2i(16, 16),
			"has_collision": true
		},
		{
			"id": 3,
			"name": "Sewers Front Water",
			"path": "res://assets/sprites/Sewers pack files/Assets/Environment Layers/Front-water/front-water1.png",
			"region_size": Vector2i(16, 16),
			"has_collision": false
		},
		{
			"id": 4,
			"name": "Swamp Tileset",
			"path": "res://assets/sprites/Swamp game tileset/1 Tiles/Tileset.png",
			"region_size": Vector2i(16, 16),
			"has_collision": true
		},
		{
			"id": 5,
			"name": "Caves Main Build",
			"path": "res://assets/sprites/Caves/PixelFantasy_Caves_1.0/mainlev_build.png",
			"region_size": Vector2i(16, 16),
			"has_collision": true
		},
		{
			"id": 6,
			"name": "Caves Props 1",
			"path": "res://assets/sprites/Caves/PixelFantasy_Caves_1.0/props1.png",
			"region_size": Vector2i(16, 16),
			"has_collision": false
		},
		{
			"id": 7,
			"name": "Caves Props 2",
			"path": "res://assets/sprites/Caves/PixelFantasy_Caves_1.0/props2.png",
			"region_size": Vector2i(16, 16),
			"has_collision": false
		},
		{
			"id": 8,
			"name": "Trees Regular",
			"path": "res://assets/sprites/Background & Trees/PixelTreeSet/Trees.png",
			"region_size": Vector2i(16, 16),
			"has_collision": false
		},
		{
			"id": 9,
			"name": "Trees Alt",
			"path": "res://assets/sprites/Background & Trees/PixelTreeSet/Trees_Alt.png",
			"region_size": Vector2i(16, 16),
			"has_collision": false
		},
		{
			"id": 10,
			"name": "Trees Outlined",
			"path": "res://assets/sprites/Background & Trees/PixelTreeSet/Trees_Outlined.png",
			"region_size": Vector2i(16, 16),
			"has_collision": false
		},
		{
			"id": 11,
			"name": "Wood VFX 01 Hit",
			"path": "res://assets/sprites/Wood VFX 01/Wood VFX 01 Hit.png",
			"region_size": Vector2i(32, 32),
			"has_collision": false,
			"anim_frames": 7,
			"anim_speed": 12.0
		},
		{
			"id": 12,
			"name": "Wood VFX 01 Repeatable",
			"path": "res://assets/sprites/Wood VFX 01/Wood VFX 01 Repeatable.png",
			"region_size": Vector2i(32, 32),
			"has_collision": false,
			"anim_frames": 8,
			"anim_speed": 10.0
		},
		{
			"id": 13,
			"name": "Wood VFX 02 Impact",
			"path": "res://assets/sprites/Wood VFX 02/Wood VFX 02.png",
			"region_size": Vector2i(32, 32),
			"has_collision": false,
			"anim_frames": 14,
			"anim_speed": 14.0
		},
		{
			"id": 14,
			"name": "Swamp Flag",
			"path": "res://assets/sprites/Swamp game tileset/4 Animated objects/Flag.png",
			"region_size": Vector2i(48, 48),
			"has_collision": false,
			"anim_frames": 4,
			"anim_speed": 6.0
		},
		{
			"id": 15,
			"name": "Swamp Chest",
			"path": "res://assets/sprites/Swamp game tileset/4 Animated objects/Chest.png",
			"region_size": Vector2i(32, 32),
			"has_collision": false,
			"anim_frames": 4,
			"anim_speed": 4.0
		},
		{
			"id": 16,
			"name": "Swamp Rune",
			"path": "res://assets/sprites/Swamp game tileset/4 Animated objects/Rune.png",
			"region_size": Vector2i(16, 16),
			"has_collision": false,
			"anim_frames": 4,
			"anim_speed": 8.0
		}
	]

	var full_box_poly: PackedVector2Array = [
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	]

	for config in sources_to_add:
		var sid: int = config["id"]
		var path: String = config["path"]
		var reg_size: Vector2i = config["region_size"]
		var has_col: bool = config["has_collision"]

		if not ResourceLoader.exists(path):
			printerr("Texture path does not exist: ", path)
			continue

		var tex: Texture2D = load(path)
		if not tex:
			printerr("Failed to load texture at: ", path)
			continue

		var img: Image = tex.get_image()
		if not img:
			printerr("Failed to get image for texture: ", path)
			continue

		var img_w: int = img.get_width()
		var img_h: int = img.get_height()
		var cols: int = int(img_w / reg_size.x)
		var rows: int = int(img_h / reg_size.y)

		# Remove existing source if already present so we cleanly replace/update
		if tileset.has_source(sid):
			tileset.remove_source(sid)

		var source: TileSetAtlasSource = TileSetAtlasSource.new()
		source.resource_name = config["name"]
		source.texture = tex
		source.texture_region_size = reg_size
		tileset.add_source(source, sid)

		var added_count: int = 0
		var anim_frames: int = config.get("anim_frames", 0)
		var anim_speed: float = config.get("anim_speed", 0.0)

		if anim_frames > 1:
			# Animated source: tile at (0, 0) spans anim_frames columns automatically
			source.create_tile(Vector2i(0, 0))
			source.set_tile_animation_columns(Vector2i(0, 0), anim_frames)
			source.set_tile_animation_frames_count(Vector2i(0, 0), anim_frames)
			source.set_tile_animation_speed(Vector2i(0, 0), anim_speed)
			added_count = 1
		else:
			for ry in range(rows):
				for rx in range(cols):
					var sub_rect: Rect2i = Rect2i(rx * reg_size.x, ry * reg_size.y, reg_size.x, reg_size.y)
					var sub_img: Image = img.get_region(sub_rect)
					if not sub_img.is_invisible():
						source.create_tile(Vector2i(rx, ry))
						if has_col:
							var td: TileData = source.get_tile_data(Vector2i(rx, ry), 0)
							if td:
								td.add_collision_polygon(0)
								td.set_collision_polygon_points(0, 0, full_box_poly)
						added_count += 1

		print("Source ", sid, " [", config["name"], "]: created ", added_count, " tiles (Grid: ", cols, "x", rows, ")")

	var save_err = ResourceSaver.save(tileset, TILESET_PATH)
	if save_err == OK:
		print("Successfully updated and saved ", TILESET_PATH, "! Total sources: ", tileset.get_source_count())
	else:
		printerr("Failed to save tileset! Error code: ", save_err)
		quit(1)
		return

	quit(0)
