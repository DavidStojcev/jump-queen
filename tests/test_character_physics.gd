extends Node
class_name CharacterPhysicsTests

const JumpMetrics = preload("res://script/jump_metrics.gd")

## Character physics and kinematic regression tests.

var character: PlayerCharacter
var passed_count: int = 0
var failed_count: int = 0
var test_names: Array[String] = []
var log_lines: Array[String] = []

signal all_tests_completed(passed: int, failed: int)


func _log(msg: String) -> void:
	print(msg)
	log_lines.append(msg)


func run_all(player: PlayerCharacter) -> void:
	character = player
	character.input_override_enabled = true
	passed_count = 0
	failed_count = 0
	test_names.clear()
	log_lines.clear()

	_log("\nRunning character physics tests...")

	# Ground movement
	await _test_instant_ground_halt()

	# Jump launch & quantization
	await _test_jump_curve_scaling()
	await _test_auto_fire_at_max_charge()
	await _test_directional_commitment()
	await _test_zero_air_control()

	# Impact & collision states
	await _test_landing_recovery_lockout()
	await _test_splat_knockdown_and_recovery()
	await _test_wall_bounce_kinematics()
	await _test_ceiling_bonk()

	# Feedback & hazard zones
	await _test_charge_audio_pitch_ramp()
	await _test_camera_screen_shake_events()
	await _test_ice_friction_and_sliding_charge()
	await _test_wind_drift_in_air()
	await _test_bouncy_surface_pad()

	# Room transitions & metrics
	await _test_screen_transition_velocity_persistence()
	await _test_multi_screen_fall_splat_guarantee()
	await _test_jump_metrics_calculations()
	await _test_knight_visual_and_collision_setup()

	_log("\nResults: %d passed, %d failed\n" % [passed_count, failed_count])

	var file: FileAccess = FileAccess.open("res://tests/test_results.txt", FileAccess.WRITE)
	if file:
		file.store_string("\n".join(log_lines))
		file.close()

	all_tests_completed.emit(passed_count, failed_count)


# Ground movement
func _test_instant_ground_halt() -> void:
	var test_name: String = "test_instant_ground_halt"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	# 1. Start moving right
	character.override_horizontal_input = 1.0
	character.override_jump_held = false
	await _advance_frames(3)

	_assert_eq(character.current_state, PlayerCharacter.State.WALK, "State should be WALK while input is active")
	_assert_approx(character.velocity.x, character.walk_speed, 1.0, "Velocity.x should match walk_speed")

	# 2. Release input: velocity must drop to 0 immediately
	character.override_horizontal_input = 0.0
	await _advance_frames(1)

	_assert_eq(character.current_state, PlayerCharacter.State.IDLE, "State should be IDLE immediately on release")
	_assert_approx(character.velocity.x, 0.0, 0.001, "Velocity.x must be strictly 0.0 (no residual sliding)")


## Test 2: Jump curve scaling preserves ~70° angle and scales Vx with charge ratio
func _test_jump_curve_scaling() -> void:
	var test_name: String = "test_jump_curve_scaling"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	# --- Part A: Minimum Jump (1 frame tap) ---
	character.override_horizontal_input = 1.0
	character.override_jump_held = true
	await _advance_frames(1)
	character.override_jump_held = false
	await _advance_frames(1)

	_assert_eq(character.current_state, PlayerCharacter.State.AIRBORNE, "State should be AIRBORNE after release")
	var min_vx: float = character.velocity.x
	var min_vy: float = absf(character.velocity.y)
	var min_angle_deg: float = rad_to_deg(atan2(min_vy, min_vx))

	_assert_true(min_vx >= character.min_horizontal_jump_velocity * 0.95, "Min jump Vx should be near min_horizontal_jump_velocity")
	_assert_true(min_angle_deg >= 66.0 and min_angle_deg <= 74.0, "Min jump trajectory angle should be ~70° (actual: %.2f°)" % min_angle_deg)

	# --- Part B: Maximum Jump (Full 36 frames charge) ---
	await _reset_player_to_ground()

	character.override_horizontal_input = 1.0
	character.override_jump_held = true
	# Charge for 35 frames then release
	await _advance_frames(35)
	character.override_jump_held = false
	await _advance_frames(1)

	_assert_eq(character.current_state, PlayerCharacter.State.AIRBORNE, "State should be AIRBORNE after max release")
	var max_vx: float = character.velocity.x
	var max_vy: float = absf(character.velocity.y)
	var max_angle_deg: float = rad_to_deg(atan2(max_vy, max_vx))

	_assert_true(max_vx > min_vx * 1.8, "Max jump Vx (%.1f) must be significantly higher than Min jump Vx (%.1f)" % [max_vx, min_vx])
	_assert_approx(max_vy, character.max_jump_velocity, 10.0, "Max jump Vy should reach max_jump_velocity")
	_assert_true(max_angle_deg >= 68.0 and max_angle_deg <= 74.0, "Max jump trajectory angle should remain ~70° (actual: %.2f°)" % max_angle_deg)


## Test 3: Auto-fire forced leap at Frame 36 / 0.60s without releasing jump
func _test_auto_fire_at_max_charge() -> void:
	var test_name: String = "test_auto_fire_at_max_charge"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	character.override_horizontal_input = 0.0
	character.override_jump_held = true
	await _advance_frames(1)
	_assert_eq(character.current_state, PlayerCharacter.State.CHARGING, "State should be CHARGING on jump press")

	# Wait until charge time reaches max_charge_time (36 ticks at 60fps)
	await _advance_frames(36)

	# Next tick must automatically launch into AIRBORNE even though override_jump_held is STILL TRUE
	await _advance_frames(1)
	_assert_eq(character.current_state, PlayerCharacter.State.AIRBORNE, "Must auto-launch into AIRBORNE at max charge without key release")
	var expected_y_after_1_frame: float = character.max_jump_velocity - (character.custom_gravity * (1.0 / 60.0))
	_assert_approx(absf(character.velocity.y), expected_y_after_1_frame, 2.0, "Auto-launched jump must have maximum power minus 1 frame gravity")

	character.override_jump_held = false


## Test 4: Directional commitment during crouch is preserved across release
func _test_directional_commitment() -> void:
	var test_name: String = "test_directional_commitment"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	# Start charging while holding RIGHT
	character.override_horizontal_input = 1.0
	character.override_jump_held = true
	await _advance_frames(10)

	_assert_eq(character.charge_direction, 1, "Charge direction should be committed to 1 (Right)")

	# Release directional key while still charging (neutral input)
	character.override_horizontal_input = 0.0
	await _advance_frames(5)

	# Now release jump button
	character.override_jump_held = false
	await _advance_frames(1)

	_assert_eq(character.current_state, PlayerCharacter.State.AIRBORNE, "State should be AIRBORNE")
	_assert_true(character.velocity.x > 0.0, "Velocity.x must still be positive (Right) due to committed charge direction!")


## Test 5: Strict Zero Air Control
func _test_zero_air_control() -> void:
	var test_name: String = "test_zero_air_control"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	# Launch jump to the right
	character.override_horizontal_input = 1.0
	character.override_jump_held = true
	await _advance_frames(5)
	character.override_jump_held = false
	await _advance_frames(1)

	var initial_air_vx: float = character.velocity.x
	_assert_true(initial_air_vx > 0.0, "Initial airborne velocity should be positive")

	# Attempt to steer LEFT mid-air
	character.override_horizontal_input = -1.0
	await _advance_frames(10)

	_assert_approx(character.velocity.x, initial_air_vx, 0.001, "Horizontal velocity must not change in mid-air (strict zero air control)")
	character.override_horizontal_input = 0.0


# Impact & bounce mechanics
func _test_landing_recovery_lockout() -> void:
	var test_name: String = "test_landing_recovery_lockout"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	# Hop straight up with moderate power
	character.override_jump_held = true
	await _advance_frames(10)
	character.override_jump_held = false
	await _advance_frames(1)

	_assert_eq(character.current_state, PlayerCharacter.State.AIRBORNE, "Must be airborne")

	# Wait until landing on floor enters LANDING_RECOVERY
	for i in range(60):
		await _advance_frames(1)
		if character.current_state == PlayerCharacter.State.LANDING_RECOVERY:
			break

	_assert_eq(character.current_state, PlayerCharacter.State.LANDING_RECOVERY, "Must enter LANDING_RECOVERY on touchdown")

	# Attempt to move right during recovery: must be locked out
	character.override_horizontal_input = 1.0
	await _advance_frames(1)
	_assert_eq(character.current_state, PlayerCharacter.State.LANDING_RECOVERY, "Input must be locked out during landing recovery")
	_assert_approx(character.velocity.x, 0.0, 0.01, "Velocity must remain 0 during landing lag")

	# Wait for recovery timer to expire (landing_recovery_time = 0.05s / ~3 ticks)
	await _advance_frames(4)
	_assert_true(character.current_state == PlayerCharacter.State.WALK or character.current_state == PlayerCharacter.State.IDLE, "Must exit landing recovery into WALK or IDLE")
	character.override_horizontal_input = 0.0


## Test 7: Splat Knockdown and Standup recovery sequence
func _test_splat_knockdown_and_recovery() -> void:
	var test_name: String = "test_splat_knockdown_and_recovery"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	# Position player in the air with high downward velocity (> splat_velocity_threshold = 750)
	character.position = Vector2(100, 150)
	character.velocity = Vector2(0, 850.0)
	character._change_state(PlayerCharacter.State.AIRBORNE)

	# Advance frames until hitting floor and entering knockdown
	for i in range(15):
		await _advance_frames(1)
		if character.current_state == PlayerCharacter.State.SPLAT_KNOCKDOWN:
			break

	_assert_eq(character.current_state, PlayerCharacter.State.SPLAT_KNOCKDOWN, "Must transition to SPLAT_KNOCKDOWN upon high velocity impact")

	# Attempt to jump during knockdown: must be ignored
	character.override_jump_held = true
	await _advance_frames(10)
	_assert_eq(character.current_state, PlayerCharacter.State.SPLAT_KNOCKDOWN, "Input must be completely locked during knockdown")
	_assert_approx(character.velocity.x, 0.0, 0.01, "Velocity must be 0 while faceplanted")
	character.override_jump_held = false

	# Wait out the rest of the 45-tick stun (0.75s)
	await _advance_frames(40)
	_assert_eq(character.current_state, PlayerCharacter.State.GETTING_UP, "Must transition to GETTING_UP after knockdown timer expires")

	# Wait out the standup animation (15 ticks / 0.25s)
	await _advance_frames(20)
	_assert_eq(character.current_state, PlayerCharacter.State.IDLE, "Must return to IDLE after standing up")


## Test 8: Wall Bounce Kinematics (Horizontal restitution + vertical friction)
func _test_wall_bounce_kinematics() -> void:
	var test_name: String = "test_wall_bounce_kinematics"
	_log("\n[RUNNING] %s..." % test_name)

	# Place player in front of Wall (Wall is at X=400, width=40 => left face is X=380)
	# Player is placed at X=360 moving right at Vx=250, Vy=-100
	character.position = Vector2(360, 150)
	character.velocity = Vector2(250.0, -100.0)
	character._change_state(PlayerCharacter.State.AIRBORNE)

	# Advance frames until wall bounce occurs
	for i in range(10):
		await _advance_frames(1)
		if character.current_state == PlayerCharacter.State.BONK_REBOUND:
			break

	_assert_eq(character.current_state, PlayerCharacter.State.BONK_REBOUND, "Must enter BONK_REBOUND state on wall impact")
	_assert_true(character.velocity.x < 0.0, "Horizontal velocity must invert away from wall (actual: %.2f)" % character.velocity.x)
	_assert_true(absf(character.velocity.x) >= character.min_wall_bounce_speed, "Horizontal rebound speed must meet or exceed min_wall_bounce_speed")


## Test 9: Ceiling Bonk (Head Bonk zeroes upward momentum)
func _test_ceiling_bonk() -> void:
	var test_name: String = "test_ceiling_bonk"
	_log("\n[RUNNING] %s..." % test_name)

	# Ceiling is at X=100, Y=80, height=30 => bottom edge at Y=95
	# Place player at X=100, Y=120 moving upward fast (Vy = -500)
	character.position = Vector2(100, 120)
	character.velocity = Vector2(0.0, -500.0)
	character._change_state(PlayerCharacter.State.AIRBORNE)

	# Track ceiling bonk signal using an Array so the lambda captures by reference
	var bonk_tracker: Array[bool] = [false]
	var cb := func(): bonk_tracker[0] = true
	character.ceiling_bonked.connect(cb)

	# Advance frames until ceiling is struck
	for i in range(10):
		await _advance_frames(1)
		if bonk_tracker[0] or character.is_on_ceiling():
			break

	character.ceiling_bonked.disconnect(cb)
	_assert_true(bonk_tracker[0], "ceiling_bonked signal must be emitted")
	_assert_true(character.velocity.y >= 0.0, "Vertical velocity must immediately zero out and begin descending (actual: %.2f)" % character.velocity.y)


# Feedback & hazard zones
func _test_charge_audio_pitch_ramp() -> void:
	var test_name: String = "test_charge_audio_pitch_ramp"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	character.override_jump_held = true
	await _advance_frames(1)

	_assert_eq(character.current_state, PlayerCharacter.State.CHARGING, "Must be CHARGING")
	var initial_pitch: float = character.charge_audio_player.pitch_scale
	_assert_approx(initial_pitch, 1.0, 0.05, "Initial charge audio pitch must begin near 1.0x")

	# Advance 20 frames into charge
	await _advance_frames(20)
	var mid_pitch: float = character.charge_audio_player.pitch_scale
	_assert_true(mid_pitch > 1.30, "Mid-charge pitch must ramp upwards (actual: %.2fx)" % mid_pitch)

	# Advance near max charge (34 frames)
	await _advance_frames(14)
	var high_pitch: float = character.charge_audio_player.pitch_scale
	_assert_true(high_pitch >= 1.65, "High-charge pitch must reach near 1.75x (actual: %.2fx)" % high_pitch)

	character.override_jump_held = false
	await _advance_frames(1)


## Test 11: Screen Shake events on Camera
func _test_camera_screen_shake_events() -> void:
	var test_name: String = "test_camera_screen_shake_events"
	_log("\n[RUNNING] %s..." % test_name)

	var camera := RoomCamera.new()
	camera.target = character
	character.get_parent().add_child(camera)
	await _advance_frames(1)

	_assert_approx(camera.current_shake, 0.0, 0.01, "Camera shake should begin at 0.0")

	# Emit wall bonk: should trigger 2.0 shake
	character.wall_bounced.emit(Vector2.LEFT)
	_assert_approx(camera.current_shake, 2.0, 0.01, "Camera must apply 2.0 shake on wall bonk")

	# Emit splat: should trigger 5.0 shake
	character.splatted.emit(800.0)
	_assert_true(camera.current_shake >= 5.0, "Camera must apply 5.0 shake on hard splat")

	character.get_parent().remove_child(camera)
	camera.free()
	await _advance_frames(1)


## Test 12: Ice Friction & Slide-Charging
func _test_ice_friction_and_sliding_charge() -> void:
	var test_name: String = "test_ice_friction_and_sliding_charge"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()
	character.current_surface = PlayerCharacter.SurfaceType.ICE

	# Start moving right on ice
	character.override_horizontal_input = 1.0
	await _advance_frames(8)

	# Release movement keys: on ice, character must slide with momentum (Vx > 0)
	character.override_horizontal_input = 0.0
	await _advance_frames(1)
	_assert_true(character.velocity.x > 15.0, "Character must slide along ice upon releasing movement keys (actual: %.2f)" % character.velocity.x)

	# Charge jump while sliding: momentum must be preserved during crouch!
	character.override_jump_held = true
	await _advance_frames(3)
	_assert_eq(character.current_state, PlayerCharacter.State.CHARGING, "Must be CHARGING on ice")
	_assert_true(character.velocity.x > 10.0, "Character must slide along ice while charging jump (actual: %.2f)" % character.velocity.x)

	character.override_jump_held = false
	await _advance_frames(1)
	character.current_surface = PlayerCharacter.SurfaceType.NORMAL


## Test 13: Wind Drift Acceleration in Air
func _test_wind_drift_in_air() -> void:
	var test_name: String = "test_wind_drift_in_air"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()
	character.external_wind_force = Vector2(300.0, 0.0) # 300 px/s² wind to the right

	# Neutral jump (Vx0 = 0)
	character.override_horizontal_input = 0.0
	character.override_jump_held = true
	await _advance_frames(5)
	character.override_jump_held = false
	await _advance_frames(1)

	_assert_eq(character.current_state, PlayerCharacter.State.AIRBORNE, "Must be airborne")

	# Wait 6 frames: wind should have accelerated character horizontally to the right
	await _advance_frames(6)
	_assert_true(character.velocity.x > 20.0, "Wind must accelerate horizontal velocity while airborne (actual Vx: %.2f)" % character.velocity.x)

	character.external_wind_force = Vector2.ZERO


## Test 14: Bouncy Pad Surface
func _test_bouncy_surface_pad() -> void:
	var test_name: String = "test_bouncy_surface_pad"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()
	character.current_surface = PlayerCharacter.SurfaceType.BOUNCY

	# Fall downwards onto bouncy surface
	character.position = Vector2(100, 190)
	character.velocity = Vector2(0.0, 600.0)
	character._change_state(PlayerCharacter.State.AIRBORNE)

	# Advance frames until character bounces upward
	for i in range(10):
		await _advance_frames(1)
		if character.velocity.y < 0.0:
			break

	_assert_eq(character.current_state, PlayerCharacter.State.AIRBORNE, "Must bounce back into AIRBORNE without entering splat or landing recovery")
	_assert_true(character.velocity.y < -300.0, "Vertical velocity must rebound upwards with high velocity (actual Vy: %.2f)" % character.velocity.y)

	character.current_surface = PlayerCharacter.SurfaceType.NORMAL


# Transitions & jump metrics
func _test_screen_transition_velocity_persistence() -> void:
	var test_name: String = "test_screen_transition_velocity_persistence"
	_log("\n[RUNNING] %s..." % test_name)

	var camera := RoomCamera.new()
	camera.target = character
	camera.room_width = 480.0
	camera.room_height = 270.0
	character.get_parent().add_child(camera)
	await _advance_frames(1)

	var room_changed_tracker: Array[bool] = [false]
	var cb := func(_old_r: Vector2i, _new_r: Vector2i): room_changed_tracker[0] = true
	camera.room_changed.connect(cb)

	# Launch character upward across Y=0 boundary (moving into room (0, -1))
	character.position = Vector2(100, 10)
	character.velocity = Vector2(80.0, -400.0)
	character._change_state(PlayerCharacter.State.AIRBORNE)

	# Advance 2 frames to cross Y=0 into negative coordinate space
	await _advance_frames(2)

	_assert_true(character.position.y < 0.0, "Player must cross into upper screen boundary (Y < 0)")
	_assert_true(room_changed_tracker[0], "RoomCamera must emit room_changed when crossing boundary")
	_assert_eq(camera.current_room, Vector2i(0, -1), "Camera must snap to upper room (0, -1)")
	_assert_true(character.velocity.x > 75.0, "Horizontal velocity must persist across room boundary without reset")
	_assert_true(character.velocity.y < -300.0, "Vertical velocity must persist across room boundary without reset")

	camera.room_changed.disconnect(cb)
	character.get_parent().remove_child(camera)
	camera.free()
	await _advance_frames(1)


## Test 16: Multi-Screen Fall Splat Guarantee
func _test_multi_screen_fall_splat_guarantee() -> void:
	var test_name: String = "test_multi_screen_fall_splat_guarantee"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	# Position player two screens above (Y = -220, floor is at Y=216 => distance ~436px > 380px threshold)
	character.position = Vector2(100, -220)
	character.velocity = Vector2(0.0, 50.0)
	character._change_state(PlayerCharacter.State.AIRBORNE)
	character.fall_apex_y = -220.0

	# Advance frames until hitting floor
	for i in range(50):
		await _advance_frames(1)
		if character.current_state == PlayerCharacter.State.SPLAT_KNOCKDOWN or character.is_on_floor():
			break

	_assert_eq(character.current_state, PlayerCharacter.State.SPLAT_KNOCKDOWN, "Falling > 1.4 screens distance must guarantee SPLAT_KNOCKDOWN")


## Test 17: Jump Metrics Envelope Calculations
func _test_jump_metrics_calculations() -> void:
	var test_name: String = "test_jump_metrics_calculations"
	_log("\n[RUNNING] %s..." % test_name)

	var apex_max: float = JumpMetrics.get_apex_height(36)
	_assert_approx(apex_max, 201.0, 2.0, "Max apex height should calculate to ~201 px")

	var dist_max: float = JumpMetrics.get_jump_distance(36)
	_assert_approx(dist_max, 272.0, 3.0, "Max jump distance should calculate to ~272 px")

	var reachable_close: bool = JumpMetrics.is_platform_reachable(140.0, -120.0)
	_assert_true(reachable_close, "Platform at (140, -120) must be within reachable jump envelope")

	var unreachable_far: bool = JumpMetrics.is_platform_reachable(380.0, -240.0)
	_assert_true(not unreachable_far, "Platform at (380, -240) must be rejected as outside reach envelope")


## Test 18: Knight Character Visuals & Collision Proportions
func _test_knight_visual_and_collision_setup() -> void:
	var test_name: String = "test_knight_visual_and_collision_setup"
	_log("\n[RUNNING] %s..." % test_name)

	await _reset_player_to_ground()

	# 1. Texture & Sprite Sheet
	_assert_true(character.sprite != null, "Character must have a Sprite2D child")
	_assert_true(character.sprite.texture != null, "Sprite2D must have a texture assigned")
	_assert_true(character.sprite.texture.resource_path.ends_with("knight.png"), "Sprite2D texture must be knight.png")
	_assert_eq(character.sprite.hframes, 8, "Sprite sheet must have 8 horizontal frames")
	_assert_eq(character.sprite.vframes, 8, "Sprite sheet must have 8 vertical frames")

	# 2. Collision Shape & Proportions
	_assert_true(character.collision_shape != null, "Character must have a CollisionShape2D")
	_assert_true(character.collision_shape.shape is RectangleShape2D, "Collision shape must be RectangleShape2D")
	var rect: RectangleShape2D = character.collision_shape.shape as RectangleShape2D
	_assert_true(rect.size.x >= 14.0, "Collision width (%.1f) must be >= 14.0px to firmly span 16px tiles" % rect.size.x)
	_assert_true(rect.size.y >= 24.0, "Collision height (%.1f) must be >= 24.0px for solid presence" % rect.size.y)
	_assert_approx(character._get_feet_offset_y(), 18.0, 0.5, "Feet offset must calculate to ~18.0px")

	# 3. State-driven sprite frame mapping
	character._change_state(PlayerCharacter.State.IDLE)
	character._update_visuals(0.016)
	_assert_true(character.sprite.frame >= 0 and character.sprite.frame <= 3, "IDLE frame must be within 0..3 (actual: %d)" % character.sprite.frame)

	character._change_state(PlayerCharacter.State.WALK)
	character._update_visuals(0.016)
	_assert_true(character.sprite.frame >= 16 and character.sprite.frame <= 31, "WALK frame must be within 16..31 (actual: %d)" % character.sprite.frame)

	character._change_state(PlayerCharacter.State.CHARGING)
	character.charge_time = 0.5
	character._update_visuals(0.016)
	_assert_true(character.sprite.frame == 41 or character.sprite.frame == 43, "CHARGING frame must be 41 or 43 (actual: %d)" % character.sprite.frame)

	character._change_state(PlayerCharacter.State.BONK_REBOUND)
	character._update_visuals(0.016)
	_assert_true(character.sprite.frame >= 48 and character.sprite.frame <= 51, "BONK_REBOUND frame must be within 48..51 (actual: %d)" % character.sprite.frame)

	character._change_state(PlayerCharacter.State.SPLAT_KNOCKDOWN)
	character.knockdown_timer = character.splat_knockdown_time
	character._update_visuals(0.016)
	_assert_true(character.sprite.frame >= 56 and character.sprite.frame <= 59, "SPLAT_KNOCKDOWN frame must be within 56..59 (actual: %d)" % character.sprite.frame)

	await _reset_player_to_ground()


func _advance_frames(frames: int) -> void:
	for i in range(frames):
		await character.get_tree().physics_frame


func _reset_player_to_ground() -> void:
	character.override_jump_held = false
	character.override_horizontal_input = 0.0
	character.velocity = Vector2.ZERO
	character.position = Vector2(100, 212)
	character.current_state = PlayerCharacter.State.IDLE
	character.landing_timer = 0.0
	character.knockdown_timer = 0.0
	character.get_up_timer = 0.0
	character.charge_time = 0.0
	if character.charge_audio_player:
		character.charge_audio_player.pitch_scale = 1.0
	# Wait for physics frames to ensure body is settled on floor in IDLE
	for i in range(10):
		await character.get_tree().physics_frame
		if character.is_on_floor() and character.current_state == PlayerCharacter.State.IDLE:
			break


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_log("  [PASS] %s" % message)
		passed_count += 1
	else:
		_log("  [FAIL] %s" % message)
		failed_count += 1


func _assert_eq(actual, expected, message: String) -> void:
	if actual == expected:
		_log("  [PASS] %s" % message)
		passed_count += 1
	else:
		_log("  [FAIL] %s (Expected: %s, Actual: %s)" % [message, str(expected), str(actual)])
		failed_count += 1


func _assert_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) <= tolerance:
		_log("  [PASS] %s (Value: %.3f, Target: %.3f)" % [message, actual, expected])
		passed_count += 1
	else:
		_log("  [FAIL] %s (Expected approx: %.3f, Actual: %.3f, Diff: %.3f > %.3f)" % [message, expected, actual, absf(actual - expected), tolerance])
		failed_count += 1
