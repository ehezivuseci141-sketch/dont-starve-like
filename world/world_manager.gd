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

# 地图数据：world[Vector2i] = tile_type (int)
var world_grid: Dictionary = {}
var biome_grid: Dictionary = {}  # 每个格子的生物群系

# 已生成的实体列表
var spawned_entities: Array = []

# 可采集物刷新计时器
var _respawn_timer: float = 0.0
const RESPAWN_INTERVAL: float = 120.0  # 每 2 分钟刷新一波

@onready var map_generator: MapGenerator = $MapGenerator if has_node("MapGenerator") else null

func _ready():
	if map_generator == null:
		map_generator = MapGenerator.new()
		add_child(map_generator)

	# 生成世界地图
	generate_world()

	# 监听昼夜，晚上刷蜘蛛
	Signals.time_of_day_changed.connect(_on_time_of_day_changed)

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
	print("[世界] 地图生成完成，种子: %d" % seed)

func get_tile(world_pos: Vector2) -> int:
	"""获取某个世界坐标的地形类型"""
	var grid_pos = world_to_grid(world_pos)
	return world_grid.get(grid_pos, 0)

func get_biome(world_pos: Vector2) -> int:
	var grid_pos = world_to_grid(world_pos)
	return biome_grid.get(grid_pos, Enums.BiomeType.GRASSLAND)

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
	match biome:
		Enums.BiomeType.FOREST:
			pool = ["berries", "twigs", "log"]
		Enums.BiomeType.GRASSLAND:
			pool = ["carrot", "cut_grass", "berries"]
		Enums.BiomeType.ROCKY:
			pool = ["rocks", "flint", "gold_nugget"]
		Enums.BiomeType.MARSH:
			pool = ["cut_grass", "twigs"]
		Enums.BiomeType.SAVANNA:
			pool = ["cut_grass", "carrot", "raw_meat"]
		_:
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
