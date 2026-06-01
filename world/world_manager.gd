# ============================================================
# world/world_manager.gd — 世界管理器
# 伙伴的 Claude 负责
# 统筹地图生成、实体管理、世界状态
# ============================================================
extends Node

# 地图尺寸（瓦片数）
const MAP_WIDTH: int = 256
const MAP_HEIGHT: int = 256
const TILE_SIZE: int = 96

const REGION_TAOYUAN: String = "taoyuan"
const REGION_QINGQIU: String = "qingqiu"
const REGION_WATER: String = "water"
const REGION_WASTELAND: String = "wasteland"
const REGION_WILD: String = "wild"

# 地图数据：world[Vector2i] = tile_type (int)
var world_grid: Dictionary = {}
var biome_grid: Dictionary = {}  # 每个格子的生物群系
var explored_grid: Dictionary = {}  # 已探索格子：explored_grid[Vector2i] = true
var last_player_dir: Vector2 = Vector2.DOWN

# 已生成的实体列表
var spawned_entities: Array = []

# 可采集物刷新计时器
var _respawn_timer: float = 0.0
const RESPAWN_INTERVAL: float = 120.0  # 每 2 分钟刷新一波

const MAP_GENERATOR_SCRIPT: Script = preload("res://world/map_generator.gd")

@onready var map_generator: Node = $MapGenerator if has_node("MapGenerator") else null

func _ready():
	if map_generator == null:
		map_generator = MAP_GENERATOR_SCRIPT.new()
		add_child(map_generator)

	# 生成世界地图
	generate_world()

	# 监听昼夜，晚上刷蜘蛛
	Signals.time_of_day_changed.connect(_on_time_of_day_changed)
	Signals.player_moved.connect(_on_player_moved)

func _process(delta: float):
	# 定时刷新可采集物
	_respawn_timer += delta
	if _respawn_timer >= RESPAWN_INTERVAL:
		_respawn_timer = 0.0
		_respawn_pickables()

# ----- 地图 -----

func generate_world(seed: int = -1):
	"""生成整个世界"""
	if seed == -1:
		seed = randi()

	map_generator.generate(self, seed)
	if world_grid.is_empty() or biome_grid.is_empty():
		_generate_fallback_world()
	explored_grid.clear()
	print("[WorldGenerator] seed=%d terrain_tiles=%d biome_tiles=%d" % [seed, world_grid.size(), biome_grid.size()])
	_debug_print_biome_counts()

func _generate_fallback_world():
	world_grid.clear()
	biome_grid.clear()
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var gp = Vector2i(x, y)
			world_grid[gp] = 1
			biome_grid[gp] = Enums.BiomeType.GRASSLAND
	print("[WorldGenerator] fallback grass world generated")

func get_tile(world_pos: Vector2) -> int:
	"""获取某个世界坐标的地形类型"""
	var grid_pos = world_to_grid(world_pos)
	ensure_tile(grid_pos)
	return world_grid.get(grid_pos, 0)

func get_biome(world_pos: Vector2) -> int:
	var grid_pos = world_to_grid(world_pos)
	ensure_tile(grid_pos)
	return biome_grid.get(grid_pos, Enums.BiomeType.GRASSLAND)

func ensure_tile(grid_pos: Vector2i):
	if world_grid.has(grid_pos):
		return
	if map_generator == null:
		map_generator = MAP_GENERATOR_SCRIPT.new()
		add_child(map_generator)
	map_generator.generate_tile(self, grid_pos)

func ensure_region(min_grid: Vector2i, max_grid: Vector2i):
	if map_generator == null:
		map_generator = MAP_GENERATOR_SCRIPT.new()
		add_child(map_generator)

	var from_x = mini(min_grid.x, max_grid.x)
	var to_x = maxi(min_grid.x, max_grid.x)
	var from_y = mini(min_grid.y, max_grid.y)
	var to_y = maxi(min_grid.y, max_grid.y)

	for x in range(from_x, to_x + 1):
		for y in range(from_y, to_y + 1):
			var grid_pos = Vector2i(x, y)
			if not world_grid.has(grid_pos):
				map_generator.generate_tile(self, grid_pos)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / TILE_SIZE)),
		int(floor(world_pos.y / TILE_SIZE))
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
				   grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)

func is_passable(world_pos: Vector2) -> bool:
	var tile = get_tile(world_pos)
	return tile != 5  # 5 = OCEAN，不可通行

func get_terrain_speed_multiplier(world_pos: Vector2) -> float:
	var biome = get_biome(world_pos)
	if biome == Enums.BiomeType.MARSH:
		return 0.78
	return 1.0

func get_terrain_damage_per_second(world_pos: Vector2) -> float:
	var biome = get_biome(world_pos)
	if biome == Enums.BiomeType.LAVA:
		return 8.0
	return 0.0

func get_region_id(world_pos: Vector2) -> String:
	var grid_pos = world_to_grid(world_pos)
	var center = Vector2(MAP_WIDTH / 2.0, MAP_HEIGHT / 2.0)
	var rel = Vector2(grid_pos.x, grid_pos.y) - center
	var edge_margin = mini(
		mini(grid_pos.x, MAP_WIDTH - 1 - grid_pos.x),
		mini(grid_pos.y, MAP_HEIGHT - 1 - grid_pos.y)
	)
	if rel.length() < 26.0:
		return REGION_TAOYUAN
	if edge_margin < 24:
		return REGION_WASTELAND
	if rel.y < -36.0:
		return REGION_QINGQIU
	if rel.y > 44.0:
		return REGION_WATER
	return REGION_WILD

func get_region_name(region_id: String) -> String:
	if region_id == REGION_TAOYUAN:
		return "桃源村"
	if region_id == REGION_QINGQIU:
		return "青丘"
	if region_id == REGION_WATER:
		return "水域"
	if region_id == REGION_WASTELAND:
		return "荒野"
	return "郊野"

func get_region_color(region_id: String) -> Color:
	if region_id == REGION_TAOYUAN:
		return Color(0.24, 0.36, 0.18)
	if region_id == REGION_QINGQIU:
		return Color(0.12, 0.28, 0.18)
	if region_id == REGION_WATER:
		return Color(0.08, 0.18, 0.30)
	if region_id == REGION_WASTELAND:
		return Color(0.32, 0.25, 0.20)
	return Color(0.18, 0.26, 0.16)

func is_danger_region(region_id: String) -> bool:
	return region_id == REGION_WASTELAND

func get_biome_display_name(world_pos: Vector2) -> String:
	return Enums.biome_name(get_biome(world_pos))

func _debug_print_biome_counts():
	var counts: Dictionary = {}
	for gp in biome_grid:
		var biome = biome_grid[gp]
		counts[biome] = int(counts.get(biome, 0)) + 1
	var parts: Array[String] = []
	for biome in counts:
		parts.append("%s=%d" % [Enums.biome_name(biome), counts[biome]])
	print("[WorldGenerator] biome_counts %s" % ", ".join(parts))

func mark_explored_at(world_pos: Vector2, radius_tiles: int = 7):
	var center = world_to_grid(world_pos)
	ensure_region(center - Vector2i(radius_tiles, radius_tiles), center + Vector2i(radius_tiles, radius_tiles))
	for x in range(center.x - radius_tiles, center.x + radius_tiles + 1):
		for y in range(center.y - radius_tiles, center.y + radius_tiles + 1):
			var gp = Vector2i(x, y)
			explored_grid[gp] = true

func is_explored(grid_pos: Vector2i) -> bool:
	return explored_grid.has(grid_pos)

# ----- 实体管理 -----

func spawn_entity(entity_type: String, position: Vector2) -> Node:
	"""生成一个实体（生物/可采集物/结构）"""
	# 交给具体的场景管理器处理
	Signals.entity_spawned.emit("entity_%d" % spawned_entities.size(), entity_type, position)
	return null  # 后续 phase 实现

func despawn_entity(entity_id: String):
	for i in range(spawned_entities.size()):
		if spawned_entities[i].has("id") and spawned_entities[i]["id"] == entity_id:
			spawned_entities.remove_at(i)
			break

# ----- 时间事件 -----

func _on_time_of_day_changed(new_time: int):
	if new_time == Enums.TimeOfDay.NIGHT:
		# 夜晚刷新敌对生物
		_spawn_night_creatures()

func _spawn_night_creatures():
	"""夜晚在玩家周围刷蜘蛛"""
	# 后续 phase 实现具体逻辑
	pass

func _on_player_moved(pos: Vector2, _dir: Vector2):
	mark_explored_at(pos, 7)
	last_player_dir = _dir

func _respawn_pickables():
	"""定时刷新浆果、胡萝卜等可采集资源"""
	var player_node = _find_player()
	if player_node == null:
		return

	# 在玩家视角外围随机刷新
	var player_pos: Vector2 = player_node.global_position
	var spawn_radius: float = 600.0

	for i in range(5):  # 每次刷新 5 个
		var angle = randf() * TAU
		var distance = spawn_radius + randf() * 400.0
		var pos = player_pos + Vector2(cos(angle), sin(angle)) * distance

		if not is_passable(pos):
			continue

		# 根据地形选刷新内容
		var biome = get_biome(pos)
		var item = _get_random_pickable_for_biome(biome)
		if item != "":
			Signals.item_dropped_in_world.emit(item, randi_range(1, 3), pos)

func _get_random_pickable_for_biome(biome: int) -> String:
	var pool: Array = []
	if biome == Enums.BiomeType.FOREST:
		pool = ["berries", "twigs", "log", "spirit_grass"]
	elif biome == Enums.BiomeType.GRASSLAND:
		pool = ["carrot", "cut_grass", "berries"]
	elif biome == Enums.BiomeType.ROCKY:
		pool = ["rocks", "flint", "gold_nugget", "spirit_stone"]
	elif biome == Enums.BiomeType.MARSH:
		pool = ["cut_grass", "twigs"]
	elif biome == Enums.BiomeType.SAVANNA:
		pool = ["cut_grass", "carrot", "raw_meat", "spirit_grass"]
	else:
		pool = ["twigs", "cut_grass"]

	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]

func _find_player() -> Node:
	var tree = get_tree()
	if tree:
		var nodes = tree.root.find_children("*", "CharacterBody2D", true, false)
		if nodes.size() > 0:
			return nodes[0]
	return null

# ----- 序列化 -----
func serialize() -> Dictionary:
	return {
		"seed": map_generator.last_seed if map_generator else 0,
		"entities": [],
		"spawned_entities": spawned_entities
	}

func deserialize(data: Dictionary):
	if data.has("seed") and map_generator:
		generate_world(data["seed"])
