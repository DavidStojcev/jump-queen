extends SceneTree

func _init() -> void:
	print("Building Wood VFX SpriteFrames...")
	var sf: SpriteFrames = SpriteFrames.new()
	sf.remove_animation("default")

	# 1. Hit animation (7 frames)
	sf.add_animation("hit")
	sf.set_animation_speed("hit", 12.0)
	sf.set_animation_loop("hit", true)
	for i in range(1, 8):
		var p = "res://assets/sprites/Wood VFX 01/Separated Frames/Wood VFX 01 Hit%d.png" % i
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p)
			sf.add_frame("hit", tex)

	# 2. Repeatable animation (8 frames)
	sf.add_animation("repeatable")
	sf.set_animation_speed("repeatable", 10.0)
	sf.set_animation_loop("repeatable", true)
	for i in range(1, 9):
		var p = "res://assets/sprites/Wood VFX 01/Separated Frames/Wood VFX 01 Repeatable%d.png" % i
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p)
			sf.add_frame("repeatable", tex)

	# 3. Wood VFX 02 Impact Burst (14 frames)
	sf.add_animation("impact")
	sf.set_animation_speed("impact", 14.0)
	sf.set_animation_loop("impact", true)
	for i in range(1, 15):
		var p = "res://assets/sprites/Wood VFX 02/Separated Frames/Wood VFX 02 %d.png" % i
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p)
			sf.add_frame("impact", tex)

	var save_path = "res://resources/wood_vfx_frames.tres"
	var err = ResourceSaver.save(sf, save_path)
	if err == OK:
		print("Successfully saved ", save_path, " with animations: ", sf.get_animation_names())
	else:
		printerr("Failed to save wood_vfx_frames: ", err)
		quit(1)
		return

	quit(0)
