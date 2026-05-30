# WorldSpawner — scatters resources around player, respawns over time
extends Node2D

var _pickable_script: Script
var _respawn_timer: float = 0.0
var _spawned_items: int = 0
const MAX_ITEMS: int = 60
const RESPAWN_INTERVAL: float = 15.0
const SPAWN_RADIUS: float = 600.0

func _ready():
	_pickable_script = load("res://scenes/simple_pickable.gd")
	_spawn_initial()

func _spawn_initial():
	_spawn_type("berries", 8)
	_spawn_type("carrot", 6)
	_spawn_type("twigs", 12)
	_spawn_type("cut_grass", 12)
	_spawn_type("flint", 6)
	_spawn_type("rocks", 5)
	_spawn_type("log", 5)
	_spawn_type("raw_meat", 3)
	_spawn_type("gold_nugget", 2)
	_spawned_items = 59

func _process(delta):
	# Respawn items that were picked up
	_respawn_timer += delta
	if _respawn_timer < RESPAWN_INTERVAL: return
	_respawn_timer = 0.0

	var player = _find_player()
	if not player: return

	# Count existing items
	var count = 0
	for child in get_children():
		if child.is_in_group("Pickable"): count += 1

	# Respawn a few if below max
	if count < MAX_ITEMS:
		var to_spawn = mini(8, MAX_ITEMS - count)
		var types = ["twigs", "cut_grass", "berries", "carrot", "flint", "rocks"]
		for i in range(to_spawn):
			var t = types[randi() % types.size()]
			var angle = randf() * TAU
			var dist = randf_range(100, SPAWN_RADIUS)
			var pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist
			_spawn_one(t, pos)

func _spawn_type(item_id: String, count: int):
	var player = _find_player()
	var center = player.global_position if player else Vector2(640, 360)
	for i in range(count):
		var pos = center + Vector2(randf_range(-SPAWN_RADIUS, SPAWN_RADIUS), randf_range(-SPAWN_RADIUS, SPAWN_RADIUS))
		_spawn_one(item_id, pos)

func _spawn_one(item_id: String, pos: Vector2):
	var node = Area2D.new()
	node.collision_layer = 2; node.collision_mask = 2
	node.position = pos
	node.set_script(_pickable_script)
	node.item_id = item_id
	add_child(node)

func _find_player() -> Node:
	var p = get_tree().root.find_children("Player", "", true, false)
	if p.size() > 0: return p[0]
	return null
