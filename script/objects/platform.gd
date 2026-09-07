extends StaticBody2D

@export var platform_size: Vector2 = Vector2(128, 32)
@export var color: Color = Color("#444444")

func _ready() -> void:
	var shape = RectangleShape2D.new()
	shape.size = platform_size
	var col = CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-platform_size.x / 2.0, -platform_size.y / 2.0, platform_size.x, platform_size.y), color)
	# Top edge highlight
	draw_line(Vector2(-platform_size.x / 2.0, -platform_size.y / 2.0), Vector2(platform_size.x / 2.0, -platform_size.y / 2.0), color.lightened(0.3), 2.0)
