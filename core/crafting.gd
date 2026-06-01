# ============================================================
# core/crafting.gd — 合成系统
# 你的 Claude 负责
# 包含所有合成配方，支持新增配方
# ============================================================
extends Node
class_name CraftingSystem

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
		"id": "craft_sword",
		"name": "剑",
		"ingredients": {"twigs": 1, "flint": 2, "gold_nugget": 1},
		"result": {"item_id": "sword", "amount": 1},
		"station": "none"
	})
	_register({
		"id": "craft_lance",
		"name": "长枪",
		"ingredients": {"twigs": 3, "flint": 2, "cut_grass": 1},
		"result": {"item_id": "lance", "amount": 1},
		"station": "none"
	})
	_register({
		"id": "craft_fan",
		"name": "折扇",
		"ingredients": {"twigs": 2, "cut_grass": 4},
		"result": {"item_id": "fan", "amount": 1},
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
	_register({
		"id": "craft_torch",
		"name": "火把",
		"ingredients": {"cut_grass": 2, "twigs": 1},
		"result": {"item_id": "torch", "amount": 1},
		"station": "none"
	})
	_register({
		"id": "craft_snare_trap",
		"name": "捕兽夹",
		"ingredients": {"twigs": 3, "cut_grass": 2},
		"result": {"item_id": "snare_trap", "amount": 1},
		"station": "none"
	})
	# ==== 烹饪（需要火堆）====
	_register({
		"id": "cook_meat",
		"name": "熟肉",
		"ingredients": {"raw_meat": 1},
		"result": {"item_id": "cooked_meat", "amount": 1},
		"station": "campfire"
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

	# 给成品 — 优先放进选中的槽位或快捷栏
	var result = recipe["result"]
	var item_id = result["item_id"]
	var amount = result["amount"]

	# Build slot data (add durability for tools/weapons)
	var slot_data = {"item_id": item_id, "amount": amount}
	var item_def = ItemDB.get_item(item_id)
	if item_def.has("durability"):
		slot_data["dur"] = item_def["durability"]

	# Try selected slot first
	var sel = InventoryManager.selected_slot
	if sel >= 0 and sel < InventoryManager.slots.size():
		var slot = InventoryManager.slots[sel]
		if slot.is_empty():
			InventoryManager.slots[sel] = slot_data
			print("合成完成: %s → 槽位 %d" % [recipe["name"], sel])
			return true
		elif slot["item_id"] == item_id:
			var max_stack = item_def.get("stack_max", 40)
			if slot["amount"] + amount <= max_stack:
				slot["amount"] += amount
				print("合成完成: %s → 槽位 %d (堆叠)" % [recipe["name"], sel])
				return true

	# Try first empty hotbar slot (0-4)
	for i in range(5):
		if InventoryManager.slots[i].is_empty():
			InventoryManager.slots[i] = slot_data
			print("合成完成: %s → 槽位 %d" % [recipe["name"], i])
			return true

	# Fallback: normal add
	InventoryManager.add_item(item_id, amount)
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
