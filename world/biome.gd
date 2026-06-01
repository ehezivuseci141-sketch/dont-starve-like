# ============================================================
# world/biome.gd — 生物群落配置
# 伙伴的 Claude 负责
# 定义每个群落的颜色、可采集物、生成规则等
# ============================================================
extends Node

# 群落配置表
var biome_configs: Dictionary = {}

func _ready():
	_register_biomes()

func _register_biomes():
	biome_configs[Enums.BiomeType.GRASSLAND] = {
		"color": Color(0.4, 0.7, 0.2),          # 草原绿
		"dark_color": Color(0.25, 0.45, 0.12),
		"ground_texture": "grassland",
		"pickables": ["cut_grass", "carrot", "twigs", "berries"],
		"creatures": ["rabbit", "butterfly"],
		"structures": [],
		"music": "grassland"
	}

	biome_configs[Enums.BiomeType.FOREST] = {
		"color": Color(0.15, 0.35, 0.10),        # 深绿
		"dark_color": Color(0.08, 0.20, 0.05),
		"ground_texture": "forest",
		"pickables": ["log", "twigs", "berries", "cut_grass", "spirit_grass"],
		"creatures": ["spider", "pigman"],
		"structures": ["spider_nest"],
		"music": "forest"
	}

	biome_configs[Enums.BiomeType.ROCKY] = {
		"color": Color(0.55, 0.55, 0.50),        # 灰色
		"dark_color": Color(0.35, 0.35, 0.30),
		"ground_texture": "rocky",
		"pickables": ["rocks", "flint", "gold_nugget", "spirit_stone"],
		"creatures": [],
		"structures": ["boulder"],
		"music": "rocky"
	}

	biome_configs[Enums.BiomeType.MARSH] = {
		"color": Color(0.30, 0.22, 0.32),        # 暗紫
		"dark_color": Color(0.18, 0.13, 0.20),
		"ground_texture": "marsh",
		"pickables": ["cut_grass", "twigs"],
		"creatures": ["tentacle", "mosquito"],
		"structures": [],
		"music": "marsh"
	}

	biome_configs[Enums.BiomeType.SAVANNA] = {
		"color": Color(0.70, 0.65, 0.30),        # 枯黄
		"dark_color": Color(0.45, 0.40, 0.18),
		"ground_texture": "savanna",
		"pickables": ["cut_grass", "carrot", "raw_meat", "spirit_grass"],
		"creatures": ["beefalo"],
		"structures": [],
		"music": "savanna"
	}

	biome_configs[Enums.BiomeType.OCEAN] = {
		"color": Color(0.12, 0.25, 0.55),        # 深蓝
		"dark_color": Color(0.06, 0.15, 0.35),
		"ground_texture": "ocean",
		"pickables": [],
		"creatures": [],
		"structures": [],
		"music": "ocean"
	}

	biome_configs[Enums.BiomeType.LAVA] = {
		"color": Color(0.22, 0.05, 0.035),
		"dark_color": Color(0.08, 0.015, 0.012),
		"ground_texture": "lava",
		"pickables": ["rocks", "flint"],
		"creatures": ["night_stalker"],
		"structures": ["lava_pool", "burnt_tree"],
		"music": "lava"
	}

# ----- API -----

func get_config(biome_type: int) -> Dictionary:
	return biome_configs.get(biome_type, {})

func get_color(biome_type: int, is_dark: bool = false) -> Color:
	var config = biome_configs.get(biome_type, {})
	if config.is_empty():
		return Color.MAGENTA  # 明显的错误色

	if is_dark:
		return config.get("dark_color", config.get("color", Color.MAGENTA))
	return config.get("color", Color.MAGENTA)

func get_pickables(biome_type: int) -> Array:
	var config = biome_configs.get(biome_type, {})
	return config.get("pickables", [])

func get_creatures(biome_type: int) -> Array:
	var config = biome_configs.get(biome_type, {})
	return config.get("creatures", [])

func get_structures(biome_type: int) -> Array:
	var config = biome_configs.get(biome_type, {})
	return config.get("structures", [])
