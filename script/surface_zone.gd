extends Area2D
class_name SurfaceZone

## Surface modifier area for ice, mud, and bouncy pads.

@export var surface_type: PlayerCharacter.SurfaceType = PlayerCharacter.SurfaceType.ICE


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerCharacter:
		body.current_surface = surface_type


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerCharacter and body.current_surface == surface_type:
		body.current_surface = PlayerCharacter.SurfaceType.NORMAL
