extends CanvasLayer

var _death_label: Label
var _timer_label: Label
# FIX: cache the last displayed second to avoid rebuilding the string every frame
var _last_second: int = -1

func _ready() -> void:
	_death_label = Label.new()
	_death_label.position = Vector2(20, 10)
	_death_label.text = "Deaths: 0"
	_death_label.add_theme_font_size_override("font_size", 24)
	_death_label.add_theme_color_override("font_color", Color("#ff6666"))
	_death_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_death_label.add_theme_constant_override("shadow_offset_x", 2)
	_death_label.add_theme_constant_override("shadow_offset_y", 2)
	_death_label.pivot_offset = Vector2(0, 12)
	add_child(_death_label)

	_timer_label = Label.new()
	_timer_label.position = Vector2(20, 44)
	_timer_label.text = "0:00"
	_timer_label.add_theme_font_size_override("font_size", 18)
	_timer_label.add_theme_color_override("font_color", Color("#cccccc"))
	_timer_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_timer_label.add_theme_constant_override("shadow_offset_x", 1)
	_timer_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_timer_label)

	GameManager.death_count_changed.connect(_on_death_count_changed)

func _process(_delta: float) -> void:
	var t: float  = GameManager.elapsed_time
	var secs: int = int(t)
	# FIX: only rebuild and assign the string when the second changes,
	# not every single frame (60+ string allocations/sec for a static display).
	if secs != _last_second:
		_last_second = secs
		_timer_label.text = "%d:%02d" % [secs / 60, secs % 60]

func _on_death_count_changed(count: int) -> void:
	_death_label.text = "Deaths: %d" % count
	var tween := create_tween()
	tween.tween_property(_death_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(_death_label, "scale", Vector2(1.0, 1.0), 0.15)
