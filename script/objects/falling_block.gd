extends StaticBody2D

@export var block_size: Vector2 = Vector2(64, 32)
@export var shake_duration: float = 0.4
@export var is_safe: bool = false

var original_position: Vector2
var is_triggered: bool = false
var body_collision: CollisionShape2D
var current_tween: Tween

const COLOR_NORMAL  := Color("#666666")
const COLOR_SAFE    := Color("#557755")
const COLOR_SHAKING := Color("#aa6644")

func _ready() -> void:
	original_position = position

	# Physics collision
	body_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = block_size
	body_collision.shape = shape
	add_child(body_collision)

	# Detection area — slightly taller than the block so landing on top registers
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var area_col   := CollisionShape2D.new()
	var area_shape := RectangleShape2D.new()
	area_shape.size     = block_size + Vector2(4, 8)
	area_col.shape    = area_shape
	area_col.position = Vector2(0, -4)
	area.add_child(area_col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

	# FIX: connect with CONNECT_ONE_SHOT so blocks freed at level end don't
	# accumulate stale connections on GameManager across scene reloads.
	GameManager.player_died.connect(_reset, CONNECT_ONE_SHOT)
	# Re-connect after each reset is handled inside _reset().
	queue_redraw()

func _draw() -> void:
	var c: Color = COLOR_SAFE if is_safe else (COLOR_SHAKING if is_triggered else COLOR_NORMAL)
	draw_rect(Rect2(-block_size.x * 0.5, -block_size.y * 0.5, block_size.x, block_size.y), c)
	draw_line(
		Vector2(-block_size.x * 0.5, -block_size.y * 0.5),
		Vector2( block_size.x * 0.5, -block_size.y * 0.5),
		c.lightened(0.2), 2.0)
	if not is_safe:
		draw_line(Vector2(-block_size.x * 0.25, -block_size.y * 0.25),
				  Vector2( block_size.x / 6.0,   block_size.y * 0.25), c.darkened(0.15), 1.0)
		draw_line(Vector2( block_size.x * 0.2,  -block_size.y / 3.0),
				  Vector2(-block_size.x / 8.0,   block_size.y / 6.0),  c.darkened(0.15), 1.0)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_safe:
		_trigger()

func _trigger() -> void:
	if is_triggered:
		return
	is_triggered = true
	queue_redraw()

	if current_tween:
		current_tween.kill()
	current_tween = create_tween()

	# Build the shake sequence without a while-loop accumulating float error
	var steps: int = int(shake_duration / 0.05)
	for _i in range(steps):
		var offset := Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0))
		current_tween.tween_property(self, "position", original_position + offset, 0.05)
	current_tween.tween_callback(_fall)

func _fall() -> void:
	body_collision.set_deferred("disabled", true)
	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	# FIX: capture position.y at call time; property path "position:y" reads live
	# position each step which is fine here, but the target must be absolute.
	var fall_target: float = position.y + 400.0
	current_tween.tween_property(self, "position:y", fall_target, 0.4).set_ease(Tween.EASE_IN)
	current_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	current_tween.chain().tween_callback(func() -> void: visible = false)

func _reset() -> void:
	if current_tween:
		current_tween.kill()
		current_tween = null
	position      = original_position
	is_triggered  = false
	modulate.a    = 1.0
	visible       = true
	body_collision.set_deferred("disabled", false)
	queue_redraw()
	# Re-arm the one-shot signal for the next death
	if not GameManager.player_died.is_connected(_reset):
		GameManager.player_died.connect(_reset, CONNECT_ONE_SHOT)
