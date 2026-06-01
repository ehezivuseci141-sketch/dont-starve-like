# ============================================================
# core/inventory.gd — 背包系统
# 你的 Claude 负责
# 支持：添加/移除/堆叠/选择/丢弃
# ============================================================
extends Node
class_name InventorySystem

# 背包槽位数量
const DEFAULT_SLOTS: int = 15
const BACKPACK_BONUS: int = 8

var max_slots: int = DEFAULT_SLOTS

# 背包数据：[{item_id, amount}, ...]
# 空槽位 = {}
var slots: Array = []

# 当前选中的槽位索引
var selected_slot: int = 0

func _ready():
	# 初始化空槽位
	for i in range(max_slots):
		slots.append({})

# ----- 基础操作 -----

# 添加物品，返回实际放入的数量
func add_item(item_id: String, amount: int) -> int:
	var item = ItemDB.get_item(item_id)
	if item.is_empty():
		push_warning("Inventory: 未知物品 '%s'" % item_id)
		return 0

	var stack_max = item.get("stack_max", 40)
	var remaining = amount

	# 先尝试堆叠到已有的同类槽位
	for i in range(slots.size()):
		if remaining <= 0:
			break
		var slot = slots[i]
		if slot.is_empty():
			continue
		if slot["item_id"] == item_id and slot["amount"] < stack_max:
			var space = stack_max - slot["amount"]
			var to_add = mini(space, remaining)
			slot["amount"] += to_add
			remaining -= to_add

	# 剩余的开新槽位
	if remaining > 0:
		for i in range(slots.size()):
			if remaining <= 0:
				break
			var slot = slots[i]
			if slot.is_empty():
				var to_add = mini(stack_max, remaining)
				slots[i] = {"item_id": item_id, "amount": to_add}
				remaining -= to_add

	var added = amount - remaining
	Signals.player_picked_up.emit(item_id, added)
	return added

# 移除物品，返回实际移除的数量
func remove_item(item_id: String, amount: int) -> int:
	var remaining = amount

	for i in range(slots.size()):
		if remaining <= 0:
			break
		var slot = slots[i]
		if slot.is_empty():
			continue
		if slot["item_id"] == item_id:
			var to_remove = mini(slot["amount"], remaining)
			slot["amount"] -= to_remove
			remaining -= to_remove
			if slot["amount"] <= 0:
				slots[i] = {}

	return amount - remaining

# 丢弃物品到地面
func drop_item(slot_index: int, position: Vector2, amount: int = -1):
	if slot_index < 0 or slot_index >= slots.size():
		return
	var slot = slots[slot_index]
	if slot.is_empty():
		return

	if amount < 0 or amount >= slot["amount"]:
		amount = slot["amount"]
		slots[slot_index] = {}
	else:
		slot["amount"] -= amount

	Signals.player_dropped.emit(slot["item_id"], amount, position)
	Signals.item_dropped_in_world.emit(slot["item_id"], amount, position)

# 选择槽位
func select_slot(index: int):
	if index >= 0 and index < slots.size():
		selected_slot = index

# 获取当前选中的物品
func get_selected_item() -> Dictionary:
	if selected_slot < 0 or selected_slot >= slots.size():
		return {}
	return slots[selected_slot]

# 查询某个物品的总数量
func count_item(item_id: String) -> int:
	var total = 0
	for slot in slots:
		if not slot.is_empty() and slot["item_id"] == item_id:
			total += slot["amount"]
	return total

# 是否有足够的物品
func has_item(item_id: String, amount: int) -> bool:
	return count_item(item_id) >= amount

# 获取所有物品列表（去重）
func get_all_item_ids() -> Array:
	var ids: Array = []
	for slot in slots:
		if not slot.is_empty() and not ids.has(slot["item_id"]):
			ids.append(slot["item_id"])
	return ids

# 装备背包（增加槽位）
func equip_backpack():
	max_slots = DEFAULT_SLOTS + BACKPACK_BONUS
	for i in range(BACKPACK_BONUS):
		slots.append({})

# ----- 序列化 -----
func serialize() -> Array:
	var result: Array = []
	for slot in slots:
		if slot.is_empty():
			result.append({})
		else:
			result.append({"item_id": slot["item_id"], "amount": slot["amount"]})
	return result

func deserialize(data: Array):
	slots.clear()
	for item in data:
		if item.is_empty():
			slots.append({})
		else:
			slots.append({"item_id": item["item_id"], "amount": item["amount"]})
	# 补齐空槽位
	while slots.size() < max_slots:
		slots.append({})
