extends CanvasLayer

var _flash_rect: ColorRect
var _message_label: Label
var _flash_tween: Tween
var _msg_tween: Tween

func _ready() -> void:
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 0, 0, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)

	_message_label = Label.new()
	_message_label.position = Vector2(440, 330)
	_message_label.size = Vector2(400, 60)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 28)
	_message_label.add_theme_color_override("font_color", Color.WHITE)
	_message_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_message_label.add_theme_constant_override("shadow_offset_x", 2)
	_message_label.add_theme_constant_override("shadow_offset_y", 2)
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_label.visible = false
	add_child(_message_label)

	GameManager.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	# FIX: kill previous tweens before starting new ones.
	# Without this, rapid deaths (e.g. falling through two spikes in one frame,
	# or hitting R while the flash is still going) stack tweens that fight each
	# other, leaving the overlay permanently red or the label stuck.
	if _flash_tween:
		_flash_tween.kill()
	if _msg_tween:
		_msg_tween.kill()

	_flash_rect.color = Color(1, 0, 0, 0.4)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, 0.2)

	_message_label.text      = GameManager.get_random_death_message()
	_message_label.visible   = true
	_message_label.modulate.a = 1.0
	_msg_tween = create_tween()
	_msg_tween.tween_interval(0.5)
	_msg_tween.tween_property(_message_label, "modulate:a", 0.0, 0.3)
	_msg_tween.tween_callback(func() -> void: _message_label.visible = false)
