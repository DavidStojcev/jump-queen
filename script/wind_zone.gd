extends Area2D
class_name WindZone

## Area volume that applies wind acceleration to airborne bodies.

@export var wind_force: Vector2 = Vector2(240.0, 0.0)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerCharacter:
		body.external_wind_force += wind_force


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerCharacter:
		body.external_wind_force -= wind_force
