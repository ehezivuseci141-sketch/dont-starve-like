# ============================================================
# core/crafting.gd — 合成系统
# 你的 Claude 负责
# 包含所有合成配方，支持新增配方
# ============================================================
extends Node

# 所有配方
# 格式：recipe_id → {name, ingredients: {item_id: amount}, result: {item_id, amount}, station}
# station: "none" | "science_machine" | "alchemy_engine" | "shadow_manipulator"
var recipes: Dictionary = {}

func _ready():
	_register_all_recipes()

func _register_all_recipes():
	# ==== 基础合成（不需要科技站）====
	_register({
		"id": "craft_spear",
		"name": "矛",
		"ingredients": {"twigs": 2, "flint": 1, "cut_grass": 1},
		"result": {"item_id": "spear", "amount": 1},
		"station": "none"
	})
	_register({
		"id": "craft_axe",
		"name": "斧头",
		"ingredients": {"twigs": 1, "flint": 1},
		"result": {"item_id": "axe", "amount": 1},
		"station": "none"
	})
	_register({
		"id": "craft_pickaxe",
		"name": "镐子",
		"ingredients": {"twigs": 2, "flint": 2},
		"result": {"item_id": "pickaxe", "amount": 1},
		"station": "none"
	})
	_register({
		"id": "craft_campfire",
		"name": "火堆",
		"ingredients": {"cut_grass": 3, "log": 2},
		"result": {"item_id": "campfire", "amount": 1},
		"station": "none"
	})
	# ==== 需要科学机器 ====
	_register({
		"id": "craft_backpack",
		"name": "背包",
		"ingredients": {"cut_grass": 4, "twigs": 4},
		"result": {"item_id": "backpack", "amount": 1},
		"station": "science_machine"
	})

# 内部注册函数
func _register(data: Dictionary):
	recipes[data["id"]] = data

# ---------- API ----------

# 检查是否可以合成
func can_craft(recipe_id: String) -> bool:
	var recipe = recipes.get(recipe_id, {})
	if recipe.is_empty():
		return false

	var ingredients: Dictionary = recipe.get("ingredients", {})
	for item_id in ingredients:
		if not InventoryManager.has_item(item_id, ingredients[item_id]):
			return false
	return true

# 执行合成
func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false

	var recipe = recipes[recipe_id]

	# 扣材料
	var ingredients: Dictionary = recipe["ingredients"]
	for item_id in ingredients:
		InventoryManager.remove_item(item_id, ingredients[item_id])

	# 给成品
	var result = recipe["result"]
	InventoryManager.add_item(result["item_id"], result["amount"])

	print("合成完成: ", recipe["name"])
	return true

# 获取某个科技站可以制作的配方列表
func get_recipes_for_station(station: String) -> Array:
	var result: Array = []
	for recipe_id in recipes:
		var recipe = recipes[recipe_id]
		var required = recipe.get("station", "none")
		if _station_level(required) <= _station_level(station):
			result.append({
				"id": recipe_id,
				"name": recipe["name"],
				"ingredients": recipe["ingredients"],
				"result": recipe["result"],
				"can_craft": can_craft(recipe_id)
			})
	return result

func get_all_recipes() -> Array:
	return get_recipes_for_station("shadow_manipulator")  # 最高等级

# 科技站等级
func _station_level(station: String) -> int:
	match station:
		"shadow_manipulator": return 3
		"alchemy_engine": return 2
		"science_machine": return 1
		_: return 0  # "none"
