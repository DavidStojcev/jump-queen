extends Area2D

var is_activated: bool = false

const INACTIVE_COLOR := Color("#ffdd00")
const ACTIVE_COLOR   := Color("#44ff44")

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 1
	body_entered.connect(_on_body_entered)

	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size    = Vector2(16, 64)
	col.shape     = shape
	col.position  = Vector2(0, -32)
	add_child(col)
	queue_redraw()

func _draw() -> void:
	var flag_color: Color = ACTIVE_COLOR if is_activated else INACTIVE_COLOR
	draw_rect(Rect2(-2, -64, 4, 64), Color("#aaaaaa"))
	var flag_pts := PackedVector2Array([Vector2(2, -64), Vector2(22, -54), Vector2(2, -44)])
	draw_colored_polygon(flag_pts, flag_color)
	draw_rect(Rect2(-8, -2, 16, 4), Color("#888888"))

func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D or is_activated:
		return
	is_activated = true
	# FIX: store checkpoint at the player's feet (global_position of the player),
	# not the checkpoint flag position, so respawn lands on solid ground.
	# The caller (body) is the player; use its global_position.
	GameManager.set_checkpoint(body.global_position)
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
