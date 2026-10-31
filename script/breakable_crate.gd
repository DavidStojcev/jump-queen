extends StaticBody2D
class_name BreakableCrate

signal crate_broken

@export var required_fall_speed: float = 0.0

var broken: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var vfx: AnimatedSprite2D = $WoodVFX
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	add_to_group("breakable")
	if vfx:
		vfx.visible = false
		vfx.animation_finished.connect(_on_vfx_finished)


func break_crate() -> void:
	if broken:
		return
	broken = true
	if sprite:
		sprite.visible = false
	if col_shape:
		col_shape.set_deferred("disabled", true)
	var detector_col = get_node_or_null("ImpactDetector/CollisionShape2D")
	if detector_col:
		detector_col.set_deferred("disabled", true)
	if audio and audio.stream:
		audio.play()
	if vfx:
		vfx.visible = true
		vfx.play("impact")
	crate_broken.emit()


func _on_vfx_finished() -> void:
	if vfx:
		vfx.visible = false
	queue_free()


func _on_impact_detector_body_entered(body: Node2D) -> void:
	if body is PlayerCharacter:
		break_crate()
