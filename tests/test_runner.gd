extends Node2D

const CharacterPhysicsTests = preload("res://tests/test_character_physics.gd")

@onready var player: PlayerCharacter = $Player
var tests: Node = CharacterPhysicsTests.new()


func _ready() -> void:
	add_child(tests)
	# Wait 2 physics ticks for collision pairs to register
	await get_tree().physics_frame
	await get_tree().physics_frame

	tests.all_tests_completed.connect(_on_tests_completed)
	tests.run_all(player)


func _on_tests_completed(passed: int, failed: int) -> void:
	print("All tests completed. Quitting engine with code: %d" % failed)
	get_tree().quit(failed)
