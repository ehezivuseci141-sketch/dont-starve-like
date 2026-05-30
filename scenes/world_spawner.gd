# WorldSpawner - scatters pickable items around the world
extends Node2D

var _pickable_script: Script

func _ready():
	print("[Spawner] Loading script...")
	_pickable_script = load("res://scenes/simple_pickable.gd")
	if _pickable_script == null:
		print("[Spawner] ERROR: Could not load simple_pickable.gd!")
		return

	_spawn_scattered("berries", Color(0.9, 0.1, 0.2), 8)
	_spawn_scattered("carrot", Color(1.0, 0.5, 0.1), 6)
	_spawn_scattered("twigs", Color(0.5, 0.3, 0.15), 10)
	_spawn_scattered("cut_grass", Color(0.3, 0.7, 0.2), 10)
	_spawn_scattered("flint", Color(0.5, 0.5, 0.55), 6)
	_spawn_scattered("rocks", Color(0.6, 0.6, 0.6), 5)
	_spawn_scattered("log", Color(0.4, 0.25, 0.1), 5)
	_spawn_scattered("raw_meat", Color(0.8, 0.15, 0.2), 3)
	_spawn_scattered("gold_nugget", Color(1.0, 0.85, 0.1), 2)

	print("[Spawner] Done! Items scattered around the map")

func _spawn_scattered(item_id: String, color: Color, count: int):
	for i in range(count):
		var node = Area2D.new()
		node.collision_layer = 2
		node.collision_mask = 2
		node.position = Vector2(randf_range(200, 1080), randf_range(100, 620))
		node.set_script(_pickable_script)
		node.item_id = item_id
		node.item_color = color
		add_child(node)
