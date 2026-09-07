extends Area2D

@export var sign_text: String   = "Beware!"
@export var is_misleading: bool = false

var _label: Label
var _label_tween: Tween  # track the active tween so we can kill it on re-entry

const POST_COLOR       := Color("#886633")
const SIGN_COLOR       := Color("#ddcc88")
const MISLEADING_COLOR := Color("#ffeeaa")

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 1
	monitoring      = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var col   := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 80.0
	col.shape = shape
	add_child(col)

	_label = Label.new()
	_label.text = sign_text
	_label.position = Vector2(-60, -100)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.visible = false
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(120.0, 0.0)
	add_child(_label)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-3, -40, 6, 40), POST_COLOR)
	var sc: Color = MISLEADING_COLOR if is_misleading else SIGN_COLOR
	draw_rect(Rect2(-26, -64, 52, 28), sc)
	draw_rect(Rect2(-26, -64, 52, 28), POST_COLOR, false, 2.0)

func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	# FIX: kill any active fade-out tween before starting fade-in,
	# otherwise the label can fade in from alpha=0 mid-way through a fade-out.
	if _label_tween:
		_label_tween.kill()
	_label.visible = true
	_label.modulate.a = 0.0
	_label_tween = create_tween()
	_label_tween.tween_property(_label, "modulate:a", 1.0, 0.2)

func _on_body_exited(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	if _label_tween:
		_label_tween.kill()
	_label_tween = create_tween()
	_label_tween.tween_property(_label, "modulate:a", 0.0, 0.2)
	_label_tween.tween_callback(func() -> void: _label.visible = false)
