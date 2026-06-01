# WorldSpawner — scatters resources around player, respawns over time
extends Node2D
class_name ResourceSystem

var _pickable_script: Script
var _resource_script: Script
var _common_respawn_timer: float = 0.0
var _spirit_grass_timer: float = 0.0
var _spirit_stone_timer: float = 0.0
var _spawned_items: int = 0
const MAX_ITEMS: int = 180
const COMMON_RESPAWN_INTERVAL: float = 36.0
const SPIRIT_GRASS_RESPAWN_INTERVAL: float = 48.0
const SPIRIT_STONE_RESPAWN_INTERVAL: float = 72.0
const BASE_SPAWN_RADIUS: float = 900.0
const MAX_SPAWN_RADIUS: float = 2600.0
const MIN_SEPARATION: float = 86.0
const MAX_TRIES_PER_SPAWN: int = 24

func _ready():
	_pickable_script = load("res://scenes/simple_pickable.gd")
	_resource_script = load("res://scenes/resource_node.gd")
	_spawn_initial()
	var count = _count_pickables()
	if count == 0:
		_spawn_fallback_resources()
		count = _count_pickables()
	print("[ResourceSystem] resources=%d" % count)

func _spawn_initial():
	_spawn_starter_cache()
	# Biome-based distribution.
	# Lower density, more "patchy" distribution.
	_spawn_clustered("berries", 6, [Enums.BiomeType.FOREST, Enums.BiomeType.GRASSLAND], 3, 180.0)
	_spawn_clustered("carrot", 6, [Enums.BiomeType.GRASSLAND, Enums.BiomeType.SAVANNA], 3, 180.0)
	_spawn_clustered("twigs", 10, [Enums.BiomeType.FOREST, Enums.BiomeType.GRASSLAND, Enums.BiomeType.MARSH], 4, 220.0)
	_spawn_clustered("cut_grass", 10, [Enums.BiomeType.GRASSLAND, Enums.BiomeType.SAVANNA, Enums.BiomeType.MARSH], 4, 220.0)
	_spawn_clustered("log", 8, [Enums.BiomeType.FOREST], 3, 260.0)
	_spawn_clustered("rocks", 8, [Enums.BiomeType.ROCKY], 3, 260.0)
	_spawn_clustered("flint", 8, [Enums.BiomeType.ROCKY], 3, 240.0)
	_spawn_clustered("gold_nugget", 4, [Enums.BiomeType.ROCKY], 2, 220.0)
	_spawn_clustered("raw_meat", 3, [Enums.BiomeType.SAVANNA, Enums.BiomeType.GRASSLAND], 2, 240.0)
	_spawn_clustered("spirit_grass", 8, [Enums.BiomeType.FOREST, Enums.BiomeType.SAVANNA], 3, 260.0)
	_spawn_clustered("spirit_stone", 6, [Enums.BiomeType.ROCKY], 2, 300.0)
	_spawn_clustered("lava_pool_item", 5, [Enums.BiomeType.LAVA], 2, 260.0)
	_spawn_clustered("burnt_log", 6, [Enums.BiomeType.LAVA], 2, 240.0)
	_spawn_clustered("swamp_reed_item", 8, [Enums.BiomeType.MARSH], 3, 220.0)
	_spawn_clustered("mud_patch_item", 6, [Enums.BiomeType.MARSH], 2, 240.0)
	_spawn_global_biome_resources()
	_spawned_items = _count_pickables()
	_debug_print_resource_counts()

func _spawn_global_biome_resources():
	_spawn_global_for_biome("log", Enums.BiomeType.FOREST, 18)
	_spawn_global_for_biome("berries", Enums.BiomeType.FOREST, 12)
	_spawn_global_for_biome("rocks", Enums.BiomeType.ROCKY, 16)
	_spawn_global_for_biome("gold_nugget", Enums.BiomeType.ROCKY, 8)
	_spawn_global_for_biome("swamp_reed_item", Enums.BiomeType.MARSH, 14)
	_spawn_global_for_biome("mud_patch_item", Enums.BiomeType.MARSH, 10)
	_spawn_global_for_biome("lava_pool_item", Enums.BiomeType.LAVA, 10)
	_spawn_global_for_biome("burnt_log", Enums.BiomeType.LAVA, 8)

func _spawn_global_for_biome(item_id: String, biome: int, count: int):
	for i in range(count):
		var pos = _pick_pos_anywhere_biome(biome)
		if pos != null:
			_spawn_one(item_id, pos)

func _pick_pos_anywhere_biome(biome: int) -> Variant:
	for i in range(160):
		var gp = Vector2i(randi_range(0, WorldManager.MAP_WIDTH - 1), randi_range(0, WorldManager.MAP_HEIGHT - 1))
		WorldManager.ensure_tile(gp)
		if WorldManager.biome_grid.get(gp, Enums.BiomeType.GRASSLAND) != biome:
			continue
		var pos = WorldManager.grid_to_world(gp)
		if not WorldManager.is_passable(pos):
			continue
		if not _is_far_enough(pos, MIN_SEPARATION):
			continue
		return pos
	return null

func _count_pickables() -> int:
	var count = 0
	for child in get_children():
		if child.is_in_group("Pickable"):
			count += 1
	return count

func _spawn_fallback_resources():
	var player = _find_player()
	var center = player.global_position if player else Vector2(640, 360)
	var items = ["twigs", "cut_grass", "berries", "rocks", "flint", "log"]
	for i in range(36):
		var item_id = items[i % items.size()]
		var angle = i * TAU / 36.0
		var ring = 150.0 + float(i % 4) * 70.0
		var pos = center + Vector2(cos(angle), sin(angle)) * ring
		if WorldManager == null or WorldManager.is_passable(pos):
			_spawn_loose(item_id, pos)
	print("[ResourceSystem] fallback resources generated")

func _spawn_starter_cache():
	# Guarantee basic crafting materials near spawn regardless of biome.
	var player = _find_player()
	var center = player.global_position if player else Vector2(640, 360)
	var near_r = 420.0
	# Always provide loose flint + rocks for tools (no tool requirement).
	_force_spawn_loose_near("flint", 8, center, near_r)
	_force_spawn_loose_near("rocks", 8, center, near_r)
	_force_spawn_loose_near("twigs", 10, center, near_r)
	_force_spawn_loose_near("cut_grass", 10, center, near_r)
	_force_spawn_loose_near("log", 4, center, near_r)

func _force_spawn_near(item_id: String, count: int, center: Vector2, radius: float):
	for _i in range(count):
		var pos = _pick_pos_any(center, radius)
		if pos != null:
			_spawn_one(item_id, pos)

func _force_spawn_loose_near(item_id: String, count: int, center: Vector2, radius: float):
	for _i in range(count):
		var pos = _pick_pos_any(center, radius)
		if pos != null:
			_spawn_loose(item_id, pos)

func _spawn_loose(item_id: String, pos: Vector2):
	var node = Area2D.new()
	node.collision_layer = 2
	node.collision_mask = 2
	node.position = pos
	node.set_script(_pickable_script)
	node.item_id = item_id
	add_child(node)

func _pick_pos_any(center: Vector2, radius: float) -> Variant:
	var occupied = _occupied_grid()
	for _i in range(MAX_TRIES_PER_SPAWN):
		var angle = randf() * TAU
		var dist = randf_range(80, radius)
		var pos = center + Vector2(cos(angle), sin(angle)) * dist
		if not WorldManager.is_passable(pos):
			continue
		var gp = WorldManager.world_to_grid(pos)
		if occupied.has(gp):
			continue
		if not _is_far_enough(pos, MIN_SEPARATION):
			continue
		return pos
	return null

func _process(delta):
	var player = _find_player()
	if not player: return

	_common_respawn_timer += delta
	_spirit_grass_timer += delta
	_spirit_stone_timer += delta

	var count = 0
	for child in get_children():
		if child.is_in_group("Pickable"): count += 1

	if _common_respawn_timer >= COMMON_RESPAWN_INTERVAL:
		_common_respawn_timer = 0.0
		_respawn_common_resources(player, count)

	if _spirit_grass_timer >= SPIRIT_GRASS_RESPAWN_INTERVAL:
		_spirit_grass_timer = 0.0
		_respawn_regional_resource("spirit_grass", player.global_position, _current_spawn_radius(), [WorldManager.REGION_QINGQIU], 2)

	if _spirit_stone_timer >= SPIRIT_STONE_RESPAWN_INTERVAL:
		_spirit_stone_timer = 0.0
		_respawn_regional_resource("spirit_stone", player.global_position, _current_spawn_radius(), [WorldManager.REGION_WASTELAND], 2)

func _respawn_common_resources(player: Node, count: int):
	if count >= MAX_ITEMS:
		return
	var target_count = mini(MAX_ITEMS, int(56 + _current_spawn_radius() / 22.0))
	if count >= target_count:
		return
	var to_spawn = mini(8, target_count - count)
	var types = ["twigs", "cut_grass", "berries", "carrot", "flint", "rocks", "log"]
	for i in range(to_spawn):
		var t = types[randi() % types.size()]
		_spawn_one_biome_aware(t, player.global_position, _current_spawn_radius())

func _respawn_regional_resource(item_id: String, center: Vector2, spawn_radius: float, regions: Array, count: int):
	for i in range(count):
		var pos = _pick_pos_for_regions(center, spawn_radius, regions)
		if pos != null:
			_spawn_one(item_id, pos)

func _spawn_type_in_biomes(item_id: String, count: int, biomes: Array):
	var player = _find_player()
	var center = player.global_position if player else Vector2(640, 360)
	var spawn_radius = _current_spawn_radius()
	for i in range(count):
		var pos = _pick_pos_for_biomes(center, spawn_radius, biomes)
		if pos != null:
			_spawn_one(item_id, pos)

func _spawn_clustered(item_id: String, total_count: int, biomes: Array, clusters: int, cluster_radius: float):
	if total_count <= 0:
		return
	var player = _find_player()
	var center = player.global_position if player else Vector2(640, 360)
	var spawn_radius = _current_spawn_radius()
	var centers: Array = []
	for i in range(clusters):
		var cpos = _pick_pos_for_biomes(center, spawn_radius, biomes)
		if cpos != null:
			centers.append(cpos)
	if centers.is_empty():
		return
	for i in range(total_count):
		var c = centers[i % centers.size()]
		var pos = _pick_pos_near(c, cluster_radius, biomes)
		if pos != null:
			_spawn_one(item_id, pos)

func _spawn_one_biome_aware(item_id: String, center: Vector2, spawn_radius: float):
	var biomes = _preferred_biomes_for_item(item_id)
	var pos = _pick_pos_for_biomes(center, spawn_radius, biomes)
	if pos != null:
		_spawn_one(item_id, pos)

func _preferred_biomes_for_item(item_id: String) -> Array:
	match item_id:
		"log":
			return [Enums.BiomeType.FOREST]
		"rocks", "flint", "gold_nugget":
			return [Enums.BiomeType.ROCKY]
		"berries":
			return [Enums.BiomeType.FOREST, Enums.BiomeType.GRASSLAND]
		"carrot":
			return [Enums.BiomeType.GRASSLAND, Enums.BiomeType.SAVANNA]
		"cut_grass":
			return [Enums.BiomeType.GRASSLAND, Enums.BiomeType.SAVANNA, Enums.BiomeType.MARSH]
		"twigs":
			return [Enums.BiomeType.FOREST, Enums.BiomeType.GRASSLAND, Enums.BiomeType.MARSH]
		"raw_meat":
			return [Enums.BiomeType.SAVANNA, Enums.BiomeType.GRASSLAND]
		"spirit_grass":
			return [Enums.BiomeType.FOREST, Enums.BiomeType.SAVANNA]
		"spirit_stone":
			return [Enums.BiomeType.ROCKY]
		"lava_pool_item", "burnt_log":
			return [Enums.BiomeType.LAVA]
		"swamp_reed_item", "mud_patch_item":
			return [Enums.BiomeType.MARSH]
		_:
			return [Enums.BiomeType.GRASSLAND]

func _pick_pos_for_regions(center: Vector2, spawn_radius: float, regions: Array) -> Variant:
	var occupied = _occupied_grid()
	for _i in range(MAX_TRIES_PER_SPAWN * 2):
		var angle = randf() * TAU
		var dist = randf_range(180, spawn_radius)
		var pos = center + Vector2(cos(angle), sin(angle)) * dist
		if not WorldManager.is_passable(pos):
			continue
		if not regions.has(WorldManager.get_region_id(pos)):
			continue
		var gp = WorldManager.world_to_grid(pos)
		if occupied.has(gp):
			continue
		if not _is_far_enough(pos, MIN_SEPARATION):
			continue
		return pos
	return null

func _pick_pos_for_biomes(center: Vector2, spawn_radius: float, biomes: Array) -> Variant:
	var occupied = _occupied_grid()
	for _i in range(MAX_TRIES_PER_SPAWN):
		var angle = randf() * TAU
		var dist = randf_range(120, spawn_radius)
		var pos = center + Vector2(cos(angle), sin(angle)) * dist
		if not WorldManager.is_passable(pos):
			continue
		var b = WorldManager.get_biome(pos)
		if not biomes.has(b):
			continue
		var gp = WorldManager.world_to_grid(pos)
		if occupied.has(gp):
			continue
		if not _is_far_enough(pos, MIN_SEPARATION):
			continue
		return pos
	return null

func _pick_pos_near(center: Vector2, radius: float, biomes: Array) -> Variant:
	var occupied = _occupied_grid()
	for _i in range(MAX_TRIES_PER_SPAWN):
		var angle = randf() * TAU
		var dist = randf_range(30, radius)
		var pos = center + Vector2(cos(angle), sin(angle)) * dist
		if not WorldManager.is_passable(pos):
			continue
		var b = WorldManager.get_biome(pos)
		if not biomes.has(b):
			continue
		var gp = WorldManager.world_to_grid(pos)
		if occupied.has(gp):
			continue
		if not _is_far_enough(pos, MIN_SEPARATION):
			continue
		return pos
	return null

func _occupied_grid() -> Dictionary:
	var occ: Dictionary = {}
	for child in get_children():
		if child is Node2D:
			var gp = WorldManager.world_to_grid(child.global_position)
			occ[gp] = true
	return occ

func _is_far_enough(pos: Vector2, min_sep: float) -> bool:
	for child in get_children():
		if child is Node2D:
			if child.global_position.distance_to(pos) < min_sep:
				return false
	return true

func _spawn_one(item_id: String, pos: Vector2):
	if not WorldManager.is_passable(pos):
		return
	if not _is_far_enough(pos, _min_separation_for(item_id)):
		return

	var res = _resource_from_item(item_id)
	if not res.is_empty():
		var node = Area2D.new()
		node.collision_layer = 2; node.collision_mask = 2
		node.position = pos
		node.set_script(_resource_script)
		node.node_id = res["node_id"]
		node.drop_item_id = res["drop_item_id"]
		node.drop_min = res["drop_min"]
		node.drop_max = res["drop_max"]
		node.respawn_time = res["respawn_time"]
		node.required_tool_type = res.get("tool", "")
		node.required_tool_tier = res.get("tier", 0)
		add_child(node)
		return

	var node = Area2D.new()
	node.collision_layer = 2; node.collision_mask = 2
	node.position = pos
	node.set_script(_pickable_script)
	node.item_id = item_id
	add_child(node)

func _resource_from_item(item_id: String) -> Dictionary:
	match item_id:
		"berries":
			return {"node_id": "berry_bush", "drop_item_id": "berries", "drop_min": 1, "drop_max": 3, "respawn_time": 55.0, "tool": "", "tier": 0}
		"carrot":
			return {"node_id": "carrot_patch", "drop_item_id": "carrot", "drop_min": 1, "drop_max": 2, "respawn_time": 65.0, "tool": "", "tier": 0}
		"cut_grass":
			return {"node_id": "grass_patch", "drop_item_id": "cut_grass", "drop_min": 1, "drop_max": 2, "respawn_time": 40.0, "tool": "", "tier": 0}
		"twigs":
			return {"node_id": "sapling", "drop_item_id": "twigs", "drop_min": 1, "drop_max": 2, "respawn_time": 45.0, "tool": "", "tier": 0}
		"rocks":
			return {"node_id": "rock_node", "drop_item_id": "rocks", "drop_min": 1, "drop_max": 2, "respawn_time": 95.0, "tool": "mine", "tier": 1}
		"flint":
			return {"node_id": "flint_node", "drop_item_id": "flint", "drop_min": 1, "drop_max": 2, "respawn_time": 95.0, "tool": "mine", "tier": 1}
		"gold_nugget":
			return {"node_id": "gold_node", "drop_item_id": "gold_nugget", "drop_min": 1, "drop_max": 1, "respawn_time": 120.0, "tool": "mine", "tier": 1}
		"log":
			return {"node_id": "tree", "drop_item_id": "log", "drop_min": 1, "drop_max": 2, "respawn_time": 140.0, "tool": "chop", "tier": 1}
		"spirit_grass":
			return {"node_id": "spirit_grass_node", "drop_item_id": "spirit_grass", "drop_min": 1, "drop_max": 2, "respawn_time": 48.0, "tool": "", "tier": 0}
		"spirit_stone":
			return {"node_id": "spirit_stone_node", "drop_item_id": "spirit_stone", "drop_min": 1, "drop_max": 2, "respawn_time": 72.0, "tool": "mine", "tier": 1}
		"lava_pool_item":
			return {"node_id": "lava_pool", "drop_item_id": "rocks", "drop_min": 0, "drop_max": 1, "respawn_time": 120.0, "tool": "", "tier": 0}
		"burnt_log":
			return {"node_id": "burnt_tree", "drop_item_id": "log", "drop_min": 1, "drop_max": 1, "respawn_time": 150.0, "tool": "chop", "tier": 1}
		"swamp_reed_item":
			return {"node_id": "swamp_reed", "drop_item_id": "cut_grass", "drop_min": 1, "drop_max": 2, "respawn_time": 60.0, "tool": "", "tier": 0}
		"mud_patch_item":
			return {"node_id": "mud_patch", "drop_item_id": "rocks", "drop_min": 0, "drop_max": 1, "respawn_time": 80.0, "tool": "", "tier": 0}
		_:
			return {}

func _min_separation_for(item_id: String) -> float:
	match item_id:
		"log", "rocks", "flint", "gold_nugget":
			return 120.0
		"spirit_stone":
			return 150.0
		"spirit_grass":
			return 112.0
		"lava_pool_item", "burnt_log":
			return 150.0
		"swamp_reed_item", "mud_patch_item":
			return 96.0
		"berries", "carrot":
			return 100.0
		"cut_grass", "twigs":
			return 88.0
		_:
			return MIN_SEPARATION

func _current_spawn_radius() -> float:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return BASE_SPAWN_RADIUS
	var viewport_size = get_viewport_rect().size
	var zoom_x = maxf(0.05, camera.zoom.x)
	var zoom_y = maxf(0.05, camera.zoom.y)
	var visible_span = maxf(viewport_size.x / zoom_x, viewport_size.y / zoom_y)
	return clampf(visible_span * 0.65, BASE_SPAWN_RADIUS, MAX_SPAWN_RADIUS)

func _find_player() -> Node:
	var p = get_tree().root.find_children("Player", "", true, false)
	if p.size() > 0: return p[0]
	return null

func _debug_print_resource_counts():
	var counts: Dictionary = {}
	for child in get_children():
		if child is Node2D:
			var biome = WorldManager.get_biome(child.global_position)
			counts[biome] = int(counts.get(biome, 0)) + 1
	var parts: Array[String] = []
	for biome in counts:
		parts.append("%s=%d" % [Enums.biome_name(biome), counts[biome]])
	print("[ResourceSystem] resource_by_biome %s" % ", ".join(parts))
