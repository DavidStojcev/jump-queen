extends CharacterBody2D
class_name PlayerCharacter

## Jump King style precision platformer controller.

enum State {
	IDLE,
	WALK,
	CHARGING,
	AIRBORNE,
	BONK_REBOUND,
	LANDING_RECOVERY,
	SPLAT_KNOCKDOWN,
	GETTING_UP
}

enum SurfaceType {
	NORMAL,
	ICE,
	MUD,
	BOUNCY
}

signal state_changed(old_state: State, new_state: State)
signal jump_launched(charge_ratio: float, direction: int)
signal wall_bounced(normal: Vector2)
signal ceiling_bonked()
signal splatted(fall_velocity: float)
signal getting_up()
signal recovered()
signal bounced(bounce_velocity: float)

@export_group("Character Textures")
@export var character_texture: Texture2D = preload("res://assets/sprites/Basic Platform tiles/knight.png")

@export_group("Movement")
@export var walk_speed: float = 140.0
@export var ground_friction: float = 1200.0

@export_group("Jump Physics")
@export var min_jump_velocity: float = 200.0
@export var max_jump_velocity: float = 600.0
@export var min_horizontal_jump_velocity: float = 95.0
@export var max_horizontal_jump_velocity: float = 230.0
@export var max_charge_time: float = 0.6  # 36 ticks at 60hz
@export var charge_stages: int = 36        # discrete jump charge quantization
@export var use_discrete_steps: bool = true
@export var custom_gravity: float = 1150.0 # snappier gravity curve than default 980

@export_group("Wall Bounce")
@export var wall_bounce_dampening: float = 0.50 # 50% horizontal bounce retention
@export var min_wall_bounce_speed: float = 80.0
@export var wall_bounce_cooldown: float = 0.12 # debounce window to prevent multi-hit corner jitter

@export_group("Landing & Recovery")
@export var landing_recovery_time: float = 0.05  # landing lockout lag (~3 ticks)
@export var splat_velocity_threshold: float = 750.0 # downward velocity that triggers hard knockdown
@export var splat_distance_threshold: float = 380.0 # ~1.4 screens fall guarantees splat even if slowed down
@export var splat_knockdown_time: float = 0.75   # stunned faceplant duration
@export var getting_up_time: float = 0.25        # stand-up getup delay
@export var edge_slip_speed_threshold: float = 350.0 # min fall speed to slip off ledge pixels

@export_group("Environmental Modifiers (DLC)")
@export var ice_friction: float = 120.0        # reduced deceleration on ice
@export var ice_acceleration: float = 300.0    # slower directional changes on ice
@export var mud_walk_penalty: float = 0.55     # clamps walk speed by 45%
@export var mud_jump_penalty: float = 0.85     # damps max jump power by 15%
@export var bouncy_multiplier: float = 1.15    # restitution for bouncy pads

@export_group("Audio Feedback")
@export var charge_audio_stream: AudioStream = null
@export var jump_audio_stream: AudioStream = null
@export var bounce_audio_stream: AudioStream = null
@export var splat_audio_stream: AudioStream = null

var current_state: State = State.IDLE
var current_surface: SurfaceType = SurfaceType.NORMAL
var external_wind_force: Vector2 = Vector2.ZERO
var fall_apex_y: float = 0.0

var charge_time: float = 0.0
var charge_direction: int = 0
var facing_direction: int = 1
var wall_bounce_timer: float = 0.0
var landing_timer: float = 0.0
var knockdown_timer: float = 0.0
var get_up_timer: float = 0.0
var anim_timer: float = 0.0
var previous_jump_held: bool = false

var charge_audio_player: AudioStreamPlayer2D
var sfx_audio_player: AudioStreamPlayer2D

# Testing & simulation hooks
var input_override_enabled: bool = false
var override_horizontal_input: float = 0.0
var override_jump_held: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var original_sprite_scale: Vector2 = Vector2(1.5, 1.5)


func _get_feet_offset_y() -> float:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect: RectangleShape2D = collision_shape.shape as RectangleShape2D
		return collision_shape.position.y + (rect.size.y * 0.5)
	return 18.0


func _get_half_width() -> float:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect: RectangleShape2D = collision_shape.shape as RectangleShape2D
		return rect.size.x * 0.5
	return 8.0


func _ready() -> void:
	_setup_default_inputs()
	_setup_audio_players()
	if sprite:
		original_sprite_scale = sprite.scale


func _setup_audio_players() -> void:
	charge_audio_player = AudioStreamPlayer2D.new()
	charge_audio_player.name = "ChargeAudioPlayer"
	if charge_audio_stream is AudioStreamWAV:
		(charge_audio_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	charge_audio_player.stream = charge_audio_stream
	add_child(charge_audio_player)

	sfx_audio_player = AudioStreamPlayer2D.new()
	sfx_audio_player.name = "SFXAudioPlayer"
	add_child(sfx_audio_player)


func _play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if not sfx_audio_player or not stream:
		return
	sfx_audio_player.stream = stream
	sfx_audio_player.pitch_scale = pitch
	sfx_audio_player.play()


func _setup_default_inputs() -> void:
	_ensure_input_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_input_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_input_action("jump", [KEY_SPACE, KEY_UP, KEY_W])


func _ensure_input_action(action_name: String, keycodes: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		for keycode in keycodes:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			event.keycode = keycode
			InputMap.action_add_event(action_name, event)


func _physics_process(delta: float) -> void:
	if wall_bounce_timer > 0.0:
		wall_bounce_timer -= delta

	match current_state:
		State.IDLE, State.WALK:
			_process_ground_state(delta)
		State.CHARGING:
			_process_charging_state(delta)
		State.AIRBORNE, State.BONK_REBOUND:
			_process_airborne_state(delta)
		State.LANDING_RECOVERY:
			_process_landing_recovery_state(delta)
		State.SPLAT_KNOCKDOWN:
			_process_splat_knockdown_state(delta)
		State.GETTING_UP:
			_process_getting_up_state(delta)

	var was_in_air: bool = (current_state == State.AIRBORNE or current_state == State.BONK_REBOUND)
	# Cache velocity prior to slide resolution for impact normal and splat checks
	var pre_slide_velocity: Vector2 = velocity

	move_and_slide()

	if was_in_air:
		_handle_airborne_collisions(pre_slide_velocity)

	_update_visuals(delta)
	previous_jump_held = _is_jump_held()

func _detect_surface() -> SurfaceType:
	if not is_on_floor():
		return SurfaceType.NORMAL

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider:
			if collider.is_in_group("ice") or (collider.has_meta("surface_type") and str(collider.get_meta("surface_type")) == "ice"):
				return SurfaceType.ICE
			elif collider.is_in_group("mud") or (collider.has_meta("surface_type") and str(collider.get_meta("surface_type")) == "mud"):
				return SurfaceType.MUD
			elif collider.is_in_group("bouncy") or (collider.has_meta("surface_type") and str(collider.get_meta("surface_type")) == "bouncy"):
				return SurfaceType.BOUNCY

	return current_surface if current_surface != SurfaceType.NORMAL else SurfaceType.NORMAL


func _process_ground_state(delta: float) -> void:
	# Ledge fall detection
	if not is_on_floor():
		_change_state(State.AIRBORNE)
		return

	current_surface = _detect_surface()

	# Jump charge start
	if _is_jump_just_pressed():
		charge_time = 0.0
		var input_dir: float = _get_horizontal_input()
		charge_direction = int(sign(input_dir)) if input_dir != 0.0 else 0
		if charge_direction != 0:
			facing_direction = charge_direction
		
		# Cut ground velocity on charge start unless sliding on ice
		if current_surface != SurfaceType.ICE:
			velocity.x = 0.0

		if charge_audio_player:
			charge_audio_player.pitch_scale = 1.0
			if charge_audio_stream:
				charge_audio_player.play()

		_change_state(State.CHARGING)
		return

	var target_speed: float = walk_speed
	if current_surface == SurfaceType.MUD:
		target_speed *= mud_walk_penalty

	var input_dir: float = _get_horizontal_input()
	if input_dir != 0.0:
		facing_direction = int(sign(input_dir))
		if current_surface == SurfaceType.ICE:
			velocity.x = move_toward(velocity.x, facing_direction * target_speed, ice_acceleration * delta)
		else:
			velocity.x = facing_direction * target_speed

		if current_state != State.WALK:
			_change_state(State.WALK)
	else:
		if current_surface == SurfaceType.ICE:
			velocity.x = move_toward(velocity.x, 0.0, ice_friction * delta)
			if absf(velocity.x) < 2.0 and current_state != State.IDLE:
				velocity.x = 0.0
				_change_state(State.IDLE)
		else:
			velocity.x = 0.0
			if current_state != State.IDLE:
				_change_state(State.IDLE)


func _process_charging_state(delta: float) -> void:
	if not is_on_floor():
		if charge_audio_player and charge_audio_player.playing:
			charge_audio_player.stop()
		_change_state(State.AIRBORNE)
		return

	current_surface = _detect_surface()

	# Preserve slide momentum while charging on ice
	if current_surface == SurfaceType.ICE:
		velocity.x = move_toward(velocity.x, 0.0, ice_friction * delta)
	else:
		velocity.x = 0.0

	# Steer jump direction while crouched
	var input_dir: float = _get_horizontal_input()
	if input_dir != 0.0:
		charge_direction = int(sign(input_dir))
		facing_direction = charge_direction

	charge_time += delta
	var effective_charge: float = minf(charge_time, max_charge_time)

	var charge_ratio: float = clampf(charge_time / max_charge_time, 0.0, 1.0)
	if charge_audio_player:
		charge_audio_player.pitch_scale = lerpf(1.0, 1.75, charge_ratio)

	# Auto-fire at full charge (tick 37) or release
	if charge_time >= max_charge_time:
		_launch_jump(max_charge_time)
	elif _is_jump_just_released():
		_launch_jump(effective_charge)


func _launch_jump(effective_charge_time: float) -> void:
	if charge_audio_player and charge_audio_player.playing:
		charge_audio_player.stop()

	var charge_ratio: float = 0.0
	if use_discrete_steps and charge_stages > 0:
		var step: int = int(floor((effective_charge_time / max_charge_time) * charge_stages))
		step = clampi(step, 0, charge_stages - 1)
		charge_ratio = float(step + 1) / float(charge_stages)
	else:
		charge_ratio = clampf(effective_charge_time / max_charge_time, 0.05, 1.0)

	var effective_max_vy: float = max_jump_velocity
	if current_surface == SurfaceType.MUD:
		effective_max_vy *= mud_jump_penalty

	var jump_power: float = lerpf(min_jump_velocity, effective_max_vy, charge_ratio)
	velocity.y = -jump_power

	# Vx scales with charge ratio (~70 deg launch arc)
	if charge_direction != 0:
		var horiz_speed: float = lerpf(min_horizontal_jump_velocity, max_horizontal_jump_velocity, charge_ratio)
		var base_vx: float = charge_direction * horiz_speed
		if current_surface == SurfaceType.ICE:
			velocity.x = base_vx + (velocity.x * 0.40)
		else:
			velocity.x = base_vx
		facing_direction = charge_direction
	else:
		if current_surface == SurfaceType.ICE:
			velocity.x = velocity.x * 0.40
		else:
			velocity.x = 0.0

	_play_sfx(jump_audio_stream, 1.0 + (charge_ratio * 0.25))
	fall_apex_y = global_position.y
	jump_launched.emit(charge_ratio, charge_direction)
	_change_state(State.AIRBORNE)


func _process_airborne_state(delta: float) -> void:
	# Track apex for multi-screen fall distance checks
	if global_position.y < fall_apex_y:
		fall_apex_y = global_position.y

	var grav: float = custom_gravity if custom_gravity > 0.0 else get_gravity().y
	velocity.y += grav * delta

	if external_wind_force != Vector2.ZERO:
		velocity.x += external_wind_force.x * delta
		velocity.y += external_wind_force.y * delta


func _handle_airborne_collisions(pre_slide_velocity: Vector2) -> void:
	# Check for breakable crates or props
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider and collider.has_method("break_crate"):
			collider.break_crate()

	# Ceiling bonk: cut upward momentum

	if is_on_ceiling() and pre_slide_velocity.y < 0.0:
		velocity.y = 0.0
		_play_sfx(bounce_audio_stream, 0.90)
		ceiling_bonked.emit()

	# Wall bounce: 50% restitution + vertical dampening
	if is_on_wall() and wall_bounce_timer <= 0.0 and absf(pre_slide_velocity.x) > 5.0:
		var wall_normal: Vector2 = get_wall_normal()
		if pre_slide_velocity.x * wall_normal.x < 0.0:
			var rebound_speed: float = maxf(absf(pre_slide_velocity.x) * wall_bounce_dampening, min_wall_bounce_speed)
			velocity.x = wall_normal.x * rebound_speed
			velocity.y = pre_slide_velocity.y * 0.85
			wall_bounce_timer = wall_bounce_cooldown
			facing_direction = int(sign(wall_normal.x))
			_play_sfx(bounce_audio_stream, randf_range(1.15, 1.35))
			_change_state(State.BONK_REBOUND)
			wall_bounced.emit(wall_normal)

	if is_on_floor() and pre_slide_velocity.y >= 0.0:
		var surface_at_landing: SurfaceType = _detect_surface()

		if surface_at_landing == SurfaceType.BOUNCY:
			var bounce_impulse: float = maxf(absf(pre_slide_velocity.y) * bouncy_multiplier, min_jump_velocity * 1.30)
			velocity.y = -bounce_impulse
			_play_sfx(bounce_audio_stream, 1.40)
			bounced.emit(bounce_impulse)
			_change_state(State.AIRBORNE)
			return

		# Edge clip: slip into open air if feet center isn't supported
		if pre_slide_velocity.y >= edge_slip_speed_threshold and _should_edge_slip():
			var slip_dir: float = _get_edge_slip_direction()
			position.x += slip_dir * 3.0
			velocity.x = slip_dir * 40.0
			velocity.y = pre_slide_velocity.y
			_change_state(State.AIRBORNE)
			return

		var fall_dist: float = global_position.y - fall_apex_y
		var is_hard_fall: bool = (pre_slide_velocity.y >= splat_velocity_threshold) or (fall_dist >= splat_distance_threshold)
		if is_hard_fall:
			velocity = Vector2.ZERO
			knockdown_timer = splat_knockdown_time
			_play_sfx(splat_audio_stream, 0.80)
			splatted.emit(pre_slide_velocity.y)
			_change_state(State.SPLAT_KNOCKDOWN)
		else:
			velocity = Vector2.ZERO
			landing_timer = landing_recovery_time
			_change_state(State.LANDING_RECOVERY)
		return


func _process_landing_recovery_state(delta: float) -> void:
	velocity = Vector2.ZERO
	landing_timer -= delta
	if landing_timer <= 0.0:
		var input_dir: float = _get_horizontal_input()
		if input_dir != 0.0:
			facing_direction = int(sign(input_dir))
			velocity.x = facing_direction * walk_speed
			_change_state(State.WALK)
		else:
			_change_state(State.IDLE)


func _process_splat_knockdown_state(delta: float) -> void:
	velocity = Vector2.ZERO
	knockdown_timer -= delta
	if knockdown_timer <= 0.0:
		get_up_timer = getting_up_time
		getting_up.emit()
		_change_state(State.GETTING_UP)


func _process_getting_up_state(delta: float) -> void:
	velocity = Vector2.ZERO
	get_up_timer -= delta
	if get_up_timer <= 0.0:
		recovered.emit()
		_change_state(State.IDLE)


func _should_edge_slip() -> bool:
	var space_state := get_world_2d().direct_space_state
	if not space_state:
		return false
	var feet_y: float = global_position.y + _get_feet_offset_y()
	var center_query := PhysicsRayQueryParameters2D.create(
		Vector2(global_position.x, feet_y),
		Vector2(global_position.x, feet_y + 4.0),
		collision_mask,
		[get_rid()]
	)
	var center_hit := space_state.intersect_ray(center_query)
	if not center_hit.is_empty():
		return false # Center of feet is safely supported

	var probe_offset: float = maxf(_get_half_width() - 2.0, 2.0)
	var left_query := PhysicsRayQueryParameters2D.create(
		Vector2(global_position.x - probe_offset, feet_y),
		Vector2(global_position.x - probe_offset, feet_y + 4.0),
		collision_mask,
		[get_rid()]
	)
	var right_query := PhysicsRayQueryParameters2D.create(
		Vector2(global_position.x + probe_offset, feet_y),
		Vector2(global_position.x + probe_offset, feet_y + 4.0),
		collision_mask,
		[get_rid()]
	)
	var left_hit := space_state.intersect_ray(left_query)
	var right_hit := space_state.intersect_ray(right_query)
	return (!left_hit.is_empty() and right_hit.is_empty()) or (left_hit.is_empty() and !right_hit.is_empty())


func _get_edge_slip_direction() -> float:
	var space_state := get_world_2d().direct_space_state
	if not space_state:
		return float(facing_direction)
	var feet_y: float = global_position.y + _get_feet_offset_y()
	var probe_offset: float = maxf(_get_half_width() - 2.0, 2.0)
	var left_query := PhysicsRayQueryParameters2D.create(
		Vector2(global_position.x - probe_offset, feet_y),
		Vector2(global_position.x - probe_offset, feet_y + 4.0),
		collision_mask,
		[get_rid()]
	)
	var left_hit := space_state.intersect_ray(left_query)
	if not left_hit.is_empty():
		return 1.0
	return -1.0


func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	var old_state: State = current_state
	current_state = new_state
	anim_timer = 0.0
	state_changed.emit(old_state, new_state)


func _get_horizontal_input() -> float:
	if input_override_enabled:
		return override_horizontal_input
	var left: bool = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left")
	var right: bool = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right")
	if left and not right:
		return -1.0
	elif right and not left:
		return 1.0
	return 0.0


func _is_jump_held() -> bool:
	if input_override_enabled:
		return override_jump_held
	return Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept")


func _is_jump_just_pressed() -> bool:
	return _is_jump_held() and not previous_jump_held


func _is_jump_just_released() -> bool:
	return not _is_jump_held() and previous_jump_held


func _update_visuals(delta: float) -> void:
	if not sprite:
		return

	sprite.flip_h = (facing_direction < 0)
	sprite.modulate = Color.WHITE

	_set_sprite_sheet(character_texture, 8, 8)

	match current_state:
		State.IDLE:
			anim_timer += delta * 6.0
			sprite.frame = int(anim_timer) % 4
			sprite.rotation = 0.0
			sprite.position = Vector2.ZERO
			sprite.scale = sprite.scale.move_toward(original_sprite_scale, delta * 8.0)

		State.WALK:
			anim_timer += delta * 14.0
			sprite.frame = 16 + (int(anim_timer) % 16)
			sprite.rotation = 0.0
			sprite.position = Vector2.ZERO
			sprite.scale = sprite.scale.move_toward(original_sprite_scale, delta * 8.0)

		State.CHARGING:
			var charge_ratio: float = clampf(charge_time / max_charge_time, 0.0, 1.0)
			# Frame 41: tension gathering, Frame 43: full crouch
			sprite.frame = 41 if charge_ratio < 0.35 else 43
			sprite.rotation = 0.0

			var coil_squash_y: float = lerpf(1.0, 0.72, charge_ratio)
			var coil_stretch_x: float = lerpf(1.0, 1.20, charge_ratio)
			sprite.scale = Vector2(original_sprite_scale.x * coil_stretch_x, original_sprite_scale.y * coil_squash_y)

			var foot_anchor_offset: float = _get_feet_offset_y() * (1.0 - coil_squash_y)
			var jitter_x: float = 0.0
			if charge_ratio > 0.75:
				var jitter_strength: float = ((charge_ratio - 0.75) / 0.25) * 1.5
				jitter_x = (randf() - 0.5) * jitter_strength

			sprite.position = Vector2(jitter_x, foot_anchor_offset)
			sprite.modulate = Color(1.0, 1.0 - (charge_ratio * 0.20), 1.0 - (charge_ratio * 0.10))

		State.AIRBORNE:
			sprite.rotation = 0.0
			sprite.position = Vector2.ZERO

			if velocity.y < 0.0:
				# Frame 18: leap ascent
				sprite.frame = 18
				var speed_ratio: float = clampf(abs(velocity.y) / max_jump_velocity, 0.0, 1.0)
				var spring_stretch_y: float = lerpf(1.0, 1.15, speed_ratio)
				var spring_squash_x: float = lerpf(1.0, 0.92, speed_ratio)
				sprite.scale = Vector2(original_sprite_scale.x * spring_squash_x, original_sprite_scale.y * spring_stretch_y)
			else:
				# Frame 26: fall descent
				sprite.frame = 26
				sprite.scale = sprite.scale.move_toward(original_sprite_scale, delta * 5.0)

		State.BONK_REBOUND:
			# Frames 48-51: hit flinch
			anim_timer += delta * 12.0
			sprite.frame = 48 + clampi(int(anim_timer), 0, 3)
			sprite.rotation = 0.0
			sprite.position = Vector2.ZERO
			sprite.scale = original_sprite_scale
			sprite.modulate = Color(1.0, 0.7, 0.7)

		State.LANDING_RECOVERY:
			sprite.frame = 43
			sprite.rotation = 0.0
			var recovery_progress: float = clampf(landing_timer / landing_recovery_time, 0.0, 1.0)
			var land_squash_y: float = lerpf(1.0, 0.78, recovery_progress)
			var land_stretch_x: float = lerpf(1.0, 1.18, recovery_progress)
			sprite.scale = Vector2(original_sprite_scale.x * land_stretch_x, original_sprite_scale.y * land_squash_y)
			sprite.position = Vector2(0, _get_feet_offset_y() * (1.0 - land_squash_y))

		State.SPLAT_KNOCKDOWN:
			# Frames 56-59: knockdown collapse
			sprite.rotation = 0.0
			sprite.position = Vector2.ZERO
			sprite.scale = original_sprite_scale
			var elapsed: float = splat_knockdown_time - knockdown_timer
			var death_step: int = int(elapsed / 0.10)
			sprite.frame = 56 + clampi(death_step, 0, 3)
			sprite.modulate = Color(0.9, 0.6, 0.6)

		State.GETTING_UP:
			# Frames 59 down to 56: standing back up
			sprite.rotation = 0.0
			sprite.position = Vector2.ZERO
			sprite.scale = original_sprite_scale
			var progress: float = 1.0 - clampf(get_up_timer / getting_up_time, 0.0, 1.0)
			var stand_frame: int = clampi(int(3.0 - (progress * 3.0)), 0, 3)
			sprite.frame = 56 + stand_frame
			sprite.modulate = Color(1.0, 0.9, 0.9)


func _set_sprite_sheet(tex: Texture2D, hf: int, vf: int) -> void:
	if not tex:
		return
	if sprite.texture != tex:
		sprite.texture = tex
		sprite.hframes = hf
		sprite.vframes = vf
