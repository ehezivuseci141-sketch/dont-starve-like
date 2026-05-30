# ============================================================
# shared/item_data.gd — 全游戏物品数据库（单一数据源）
# 两个系统都从这里读物品信息，不要各自硬编码
# 添加新物品：直接在这个文件里加，通知对方刷新
# ============================================================
extends Node

# 物品主表（key = item_id）
var items: Dictionary = {}

func _ready():
	_register_all_items()

func _register_all_items():
	# ===== 基础资源 =====
	_register({
		"id": "twigs", "name": "树枝", "name_en": "Twigs",
		"category": 0,  # RESOURCE
		"stack_max": 40,
		"fuel_value": 15.0,
		"eatable": false
	})
	_register({
		"id": "cut_grass", "name": "干草", "name_en": "Cut Grass",
		"category": 0,
		"stack_max": 40,
		"fuel_value": 15.0,
		"eatable": false
	})
	_register({
		"id": "log", "name": "原木", "name_en": "Log",
		"category": 0,
		"stack_max": 20,
		"fuel_value": 90.0,
		"eatable": false
	})
	_register({
		"id": "rocks", "name": "石头", "name_en": "Rocks",
		"category": 0,
		"stack_max": 40,
		"fuel_value": 0.0,
		"eatable": false
	})
	_register({
		"id": "flint", "name": "燧石", "name_en": "Flint",
		"category": 0,
		"stack_max": 40,
		"fuel_value": 0.0,
		"eatable": false
	})
	_register({
		"id": "gold_nugget", "name": "金块", "name_en": "Gold Nugget",
		"category": 0,
		"stack_max": 20,
		"fuel_value": 0.0,
		"eatable": false
	})

	# ===== 食物 =====
	_register({
		"id": "berries", "name": "浆果", "name_en": "Berries",
		"category": 1,  # FOOD
		"stack_max": 40,
		"hunger_restore": 9.0,
		"health_restore": 1.0,
		"sanity_restore": 0.0,
		"perish_time": 360.0,  # 6分钟
		"eatable": true,
		"cookable": true
	})
	_register({
		"id": "carrot", "name": "胡萝卜", "name_en": "Carrot",
		"category": 1,
		"stack_max": 40,
		"hunger_restore": 12.0,
		"health_restore": 3.0,
		"sanity_restore": 0.0,
		"perish_time": 480.0,  # 8分钟
		"eatable": true,
		"cookable": true
	})
	_register({
		"id": "raw_meat", "name": "生肉", "name_en": "Raw Meat",
		"category": 1,
		"stack_max": 20,
		"hunger_restore": 15.0,
		"health_restore": -5.0,
		"sanity_restore": -10.0,
		"perish_time": 180.0,
		"eatable": true,
		"cookable": true
	})
	_register({
		"id": "cooked_meat", "name": "熟肉", "name_en": "Cooked Meat",
		"category": 1,
		"stack_max": 20,
		"hunger_restore": 25.0,
		"health_restore": 3.0,
		"sanity_restore": 0.0,
		"perish_time": 300.0,
		"eatable": true,
		"cookable": false
	})

	# ===== 武器 =====
	_register({
		"id": "spear", "name": "矛", "name_en": "Spear",
		"category": 2,  # TOOL
		"stack_max": 1,
		"durability": 50.0,
		"damage": 15.0,
		"eatable": false
	})

	# ===== 工具 =====
	_register({
		"id": "axe", "name": "斧头", "name_en": "Axe",
		"category": 2,  # TOOL
		"stack_max": 1,
		"durability": 100.0,
		"tool_tier": 1,  # FLINT
		"tool_type": "chop",
		"damage": 5.0,
		"eatable": false
	})
	_register({
		"id": "pickaxe", "name": "镐子", "name_en": "Pickaxe",
		"category": 2,
		"stack_max": 1,
		"durability": 100.0,
		"tool_tier": 1,
		"tool_type": "mine",
		"damage": 5.0,
		"eatable": false
	})

	# ===== 可放置结构 =====
	_register({
		"id": "campfire", "name": "火堆", "name_en": "Campfire",
		"category": 4,  # PLACEABLE
		"stack_max": 1,
		"fuel_max": 120.0,
		"light_radius": 200.0,
		"eatable": false
	})

func _register(data: Dictionary):
	items[data["id"]] = data

# ---------- API：供两个系统查询物品 ----------
func get_item(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	push_warning("ItemDB: 未找到物品 '%s'" % item_id)
	return {}

func get_item_name(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("name", item_id)

func is_eatable(item_id: String) -> bool:
	var item = get_item(item_id)
	return item.get("eatable", false)

func get_category(item_id: String) -> int:
	var item = get_item(item_id)
	return item.get("category", -1)

func get_all_items() -> Array:
	return items.keys()

func get_items_by_category(category: int) -> Array:
	var result: Array = []
	for id in items:
		if items[id].get("category") == category:
			result.append(id)
	return result
