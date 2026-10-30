extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/test_runner.tscn")
	var instance: Node = scene.instantiate()
	root.add_child(instance)
