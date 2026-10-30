extends Area2D

@export var spike_width: float  = 32.0
@export var spike_height: float = 24.0

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 1
	body_entered.connect(_on_body_entered)

	var col   := CollisionShape2D.new()
	var shape := ConvexPolygonShape2D.new()
	shape.points = _make_points()
	col.shape = shape
	add_child(col)
	queue_redraw()

func _make_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-spike_width * 0.5, 0.0),
		Vector2(0.0, -spike_height),
		Vector2( spike_width * 0.5, 0.0),
	])

func _draw() -> void:
	var pts := _make_points()
	draw_colored_polygon(pts, Color("#cc3333"))
	# Closed outline — append first point to close the loop
	var outline := PackedVector2Array([pts[0], pts[1], pts[2], pts[0]])
	draw_polyline(outline, Color("#ff4444"), 1.5)

func _on_body_entered(body: Node2D) -> void:
	# Guard: GameManager.is_dead prevents double-death when two spikes overlap
	if body is CharacterBody2D and not GameManager.is_dead:
		GameManager.die()
