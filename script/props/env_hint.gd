extends Node2D

enum HintType { BUSH_SAFE, BUSH_DANGER, MUSHROOM_DANGER, MUSHROOM_SAFE }

@export var hint_type: HintType = HintType.BUSH_SAFE
@export var sway_amount: float  = 2.0

# FIX: accumulate time privately to avoid stomping `time` if Godot ever
# exposes a built-in property with that name in a future version.
var _time: float = 0.0

func _ready() -> void:
	_time = randf() * TAU
	queue_redraw()

func _process(delta: float) -> void:
	_time   += delta * 2.0
	# FIX: was calling deg_to_rad() every frame on a constant value.
	# Pre-multiply: sway_amount is in degrees → convert once at export-set time.
	# Since it's an export and can change in-editor, we convert inline but
	# keep it as a single cheap mul rather than a function call on a constant.
	rotation = sin(_time) * (sway_amount * (PI / 180.0))
	# queue_redraw() is NOT needed here — rotation is a built-in property
	# that Godot already handles, it does not affect _draw() output.

func _draw() -> void:
	match hint_type:
		HintType.BUSH_SAFE:
			_draw_bush(Color("#336633"), Color("#448844"))
		HintType.BUSH_DANGER:
			_draw_bush(Color("#554433"), Color("#665544"))
		HintType.MUSHROOM_DANGER:
			_draw_mushroom(Color("#cc3333"), Color("#ffdddd"))
		HintType.MUSHROOM_SAFE:
			_draw_mushroom(Color("#996633"), Color("#ffeecc"))

func _draw_bush(c1: Color, c2: Color) -> void:
	draw_circle(Vector2(-10.0, -8.0), 14.0, c1)
	draw_circle(Vector2( 10.0, -8.0), 14.0, c1)
	draw_circle(Vector2(  0.0,-16.0), 12.0, c2)

func _draw_mushroom(cap_color: Color, spot_color: Color) -> void:
	draw_rect(Rect2(-3.0, -12.0, 6.0, 12.0), Color("#ccbb99"))
	var pts := PackedVector2Array()
	pts.resize(13)
	for i in 13:
		var angle: float = PI + (PI * float(i) / 12.0)
		pts[i] = Vector2(cos(angle) * 12.0, sin(angle) * 12.0 - 12.0)
	draw_colored_polygon(pts, cap_color)
	draw_circle(Vector2(-4.0, -16.0), 2.5, spot_color)
	draw_circle(Vector2( 4.0, -18.0), 2.5, spot_color)
