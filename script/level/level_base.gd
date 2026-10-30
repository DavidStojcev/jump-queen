extends Node2D

@export var spawn_point: Vector2 = Vector2(100, 450)

signal level_completed

func _ready() -> void:
	var exit_zone: Area2D = get_node_or_null("ExitZone") as Area2D
	if exit_zone:
		# FIX: use CONNECT_ONE_SHOT so rapid multiple overlaps don't fire
		# level_completed more than once (e.g. player standing in the zone
		# when the signal handler is slow).
		exit_zone.body_entered.connect(_on_exit_entered, CONNECT_ONE_SHOT)

func _on_exit_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		level_completed.emit()
