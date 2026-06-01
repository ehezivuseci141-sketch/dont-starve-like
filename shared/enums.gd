# ============================================================
# shared/enums.gd — 全局枚举定义
# 两个 Claude 共享，所有系统都引用这里的枚举
# 修改前两人商量，改了要通知对方
# ============================================================
extends Node

# ---------- 季节 ----------
enum Season {
	SPRING = 0,
	SUMMER = 1,
	AUTUMN = 2,
	WINTER = 3
}

# ---------- 生物群落 ----------
enum BiomeType {
	FOREST = 0,
	GRASSLAND = 1,
	ROCKY = 2,
	MARSH = 3,
	SAVANNA = 4,
	OCEAN = 5,
	LAVA = 6
}

# ---------- 一天中的时段 ----------
enum TimeOfDay {
	DAY = 0,
	DUSK = 1,
	NIGHT = 2
}

# ---------- 天气 ----------
enum Weather {
	CLEAR = 0,
	RAIN = 1,
	SNOW = 2,
	FOG = 3,
	STORM = 4
}

# ---------- 物品分类 ----------
enum ItemCategory {
	RESOURCE = 0,   # 基础资源（木头、石头、草）
	FOOD = 1,        # 食物（浆果、胡萝卜、肉）
	TOOL = 2,        # 工具（斧头、镐子）
	EQUIPMENT = 3,   # 装备（护甲、背包）
	PLACEABLE = 4,   # 可放置（火堆、科学机器）
	CONSUMABLE = 5   # 消耗品（药膏）
}

# ---------- 工具等级 ----------
enum ToolTier {
	NONE = 0,
	FLINT = 1,
	GOLD = 2,
	SHADOW = 3
}

# ---------- 生物行为状态 ----------
enum EntityState {
	IDLE = 0,
	WANDER = 1,
	FLEE = 2,
	ATTACK = 3,
	SLEEP = 4,
	EAT = 5
}

# ---------- 玩家动作 ----------
enum PlayerAction {
	NONE = 0,
	PICK_UP = 1,
	CHOP = 2,
	MINE = 3,
	DIG = 4,
	ATTACK = 5,
	PLACE = 6,
	EAT = 7
}

# ---------- 季节名称映射 ----------
static func season_name(s: Season) -> String:
	match s:
		Season.SPRING: return "春"
		Season.SUMMER: return "夏"
		Season.AUTUMN: return "秋"
		Season.WINTER: return "冬"
	return "未知"

# ---------- 生物群系名称映射 ----------
static func biome_name(b: BiomeType) -> String:
	match b:
		BiomeType.FOREST: return "森林"
		BiomeType.GRASSLAND: return "草原"
		BiomeType.ROCKY: return "岩石地"
		BiomeType.MARSH: return "沼泽"
		BiomeType.SAVANNA: return "稀树草原"
		BiomeType.OCEAN: return "海洋"
		BiomeType.LAVA: return "岩浆区"
	return "未知"
