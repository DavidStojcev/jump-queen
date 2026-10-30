extends CharacterBody2D

const SPEED: float = 280.0
const ACCELERATION: float = 2200.0
const FRICTION: float = 2200.0
const AIR_ACCELERATION: float = 1000.0
const AIR_FRICTION: float = 400.0
const JUMP_VELOCITY: float = -620.0
const JUMP_CUT_MULTIPLIER: float = 0.4
const COYOTE_TIME: float = 0.08
const JUMP_BUFFER_TIME: float = 0.1
const GRAVITY: float = 1600.0
const MAX_FALL_SPEED: float = 800.0
const DEATH_Y: float = 800.0

# Draw-time colors as constants — avoids string-parsed Color allocation every frame
const COLOR_BODY  := Color(0x4488ffff)
const COLOR_PUPIL := Color(0x1a1a2eff)

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var facing_right: bool = true

func _ready() -> void:
	spawn_position = global_position
	GameManager.player_died.connect(_on_died)
	if GameManager.current_checkpoint != Vector2.ZERO:
		global_position = GameManager.current_checkpoint

func _draw() -> void:
	draw_rect(Rect2(-14, -56, 28, 56), COLOR_BODY)
	var eye_x: float = 4.0 if facing_right else -10.0
	draw_rect(Rect2(eye_x, -48, 6, 6), Color.WHITE)
	var pupil_x: float = eye_x + 3.0 if facing_right else eye_x + 1.0
	draw_rect(Rect2(pupil_x, -46, 2, 3), COLOR_PUPIL)

func _physics_process(delta: float) -> void:
	if GameManager.is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)

	# Coyote time — only tick down while airborne so landing always resets it cleanly
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		was_on_floor = true
	else:
		if was_on_floor:
			was_on_floor = false
		coyote_timer = max(coyote_timer - delta, 0.0)

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	# Jump execution
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Variable jump height — cut upward momentum on early release
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# Horizontal movement
	var direction: float = Input.get_axis("move_left", "move_right")
	var accel: float = ACCELERATION if is_on_floor() else AIR_ACCELERATION
	var fric: float  = FRICTION    if is_on_floor() else AIR_FRICTION

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
		var new_facing: bool = direction > 0.0
		if new_facing != facing_right:
			facing_right = new_facing
			queue_redraw()
	else:
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)

	move_and_slide()

	# Fall death
	if global_position.y > DEATH_Y:
		GameManager.die()

func _input(event: InputEvent) -> void:
	# Ignore all input while the death sequence is in progress
	if GameManager.is_dead:
		return
	if event.is_action_pressed("restart"):
		GameManager.die()

func _on_died() -> void:
	set_physics_process(false)
	visible = false
	await get_tree().create_timer(0.15).timeout
	# The scene may be reloaded during the await — bail out safely rather than crash
	if not is_instance_valid(self):
		return
	global_position = GameManager.current_checkpoint if GameManager.current_checkpoint != Vector2.ZERO \
		else spawn_position
	velocity = Vector2.ZERO
	visible = true
	set_physics_process(true)
	GameManager.respawn()
