extends Node2D
class_name CreatureSystem

var _enemy_script: Script
var _creature_script: Script
var _spawned_tonight: bool = false
var _seeded_daylife: bool = false
var _max_spiders: int = 5
var _max_hoppers: int = 10

func _ready():
	_enemy_script = load("res://scenes/enemy.gd")
	_creature_script = load("res://scenes/creature_ai.gd")
	Signals.time_of_day_changed.connect(_on_time_changed)
	call_deferred("_seed_day_creatures")
	call_deferred("_spawn_spiders")

func _on_time_changed(new_time: int):
	if new_time == Enums.TimeOfDay.DAY:
		_spawned_tonight = false
		_seed_day_creatures()
	if new_time == Enums.TimeOfDay.NIGHT:
		_spawned_tonight = false
		_spawn_spiders()

func _seed_day_creatures():
	if _seeded_daylife:
		return
	_seeded_daylife = true
	var player = _find_player()
	if player == null:
		return
	var existing = _count_creatures("moss_hopper")
	var to_spawn = _max_hoppers - existing
	for i in range(to_spawn):
		var pos = _pick_spawn_pos(player.global_position, 260.0, 900.0, [Enums.BiomeType.GRASSLAND, Enums.BiomeType.FOREST, Enums.BiomeType.SAVANNA])
		if pos != null:
			_spawn_creature({
				"creature_id": "moss_hopper",
				"display_name": "Moss Hopper",
				"max_hp": 8.0,
				"speed": 105.0,
				"attack_damage": 0.0,
				"sight_range": 170.0,
				"day_active": true,
				"night_aggressive": false,
				"drop_item_id": "raw_meat",
				"drop_amount": 1
			}, pos)
	if _count_creatures("moss_hopper") == 0:
		for i in range(2):
			_spawn_creature({
				"creature_id": "moss_hopper",
				"display_name": "Moss Hopper",
				"max_hp": 8.0,
				"speed": 105.0,
				"attack_damage": 0.0,
				"sight_range": 170.0,
				"day_active": true,
				"night_aggressive": false,
				"drop_item_id": "raw_meat",
				"drop_amount": 1
			}, player.global_position + Vector2(220 + i * 70, 120))
		print("[CreatureSystem] fallback passive creatures generated")
	print("[CreatureSystem] passive_creatures=%d" % _count_creatures("moss_hopper"))

func _spawn_spiders():
	if _spawned_tonight:
		return
	_spawned_tonight = true

	var player = _find_player()
	if player == null:
		return

	var existing = 0
	for child in get_parent().get_children():
		if child.is_in_group("Enemy") and not child.is_in_group("Creature"):
			existing += 1

	var to_spawn = _max_spiders - existing
	if to_spawn <= 0:
		return

	for i in range(to_spawn):
		var pos = _pick_spawn_pos(player.global_position, 280.0, 520.0, [Enums.BiomeType.FOREST, Enums.BiomeType.ROCKY, Enums.BiomeType.MARSH])
		if pos == null:
			var angle = randf() * TAU
			pos = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(260, 520)
		var spider = CharacterBody2D.new()
		spider.position = pos
		spider.set_script(_enemy_script)
		get_parent().add_child(spider)
	print("[CreatureSystem] night_creatures=%d" % to_spawn)

func _spawn_creature(data: Dictionary, pos: Vector2):
	var creature = CharacterBody2D.new()
	creature.position = pos
	creature.set_script(_creature_script)
	get_parent().add_child(creature)
	if creature.has_method("configure"):
		creature.configure(data)
	Signals.entity_spawned.emit(str(data.get("creature_id", "creature")), str(data.get("creature_id", "creature")), pos)

func _count_creatures(creature_id: String) -> int:
	var count = 0
	for child in get_parent().get_children():
		if child.is_in_group("Creature") and child.get("creature_id") == creature_id:
			count += 1
	return count

func _pick_spawn_pos(center: Vector2, min_dist: float, max_dist: float, biomes: Array) -> Variant:
	for i in range(36):
		var angle = randf() * TAU
		var pos = center + Vector2(cos(angle), sin(angle)) * randf_range(min_dist, max_dist)
		if not WorldManager.is_passable(pos):
			continue
		if not biomes.has(WorldManager.get_biome(pos)):
			continue
		return pos
	return null

func _find_player() -> Node:
	var players = get_tree().root.find_children("Player", "", true, false)
	if players.size() > 0:
		return players[0]
	return null
