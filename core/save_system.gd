# ============================================================
# core/save_system.gd — 存档系统
# 你的 Claude 负责
# 负责把游戏状态序列化成 JSON，写入文件，以及反向操作
# ============================================================
extends Node

const SAVE_DIR: String = "user://saves/"
const SAVE_EXT: String = ".json"

func _ready():
	# 确保存档目录存在
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

# ----- 保存 -----

func save_game(slot_name: String = "auto"):
	var save_data: Dictionary = {
		"version": "0.1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"player": _save_player(),
		"survival": SurvivalManager.serialize(),
		"inventory": InventoryManager.serialize(),
		"world": WorldManager.serialize(),
		"day_night": DayNightCycle.serialize(),
		"weather": WeatherSystem.serialize()
	}

	var file_path = SAVE_DIR + slot_name + SAVE_EXT
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("存档失败: 无法写入 %s" % file_path)
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	Signals.game_saved.emit()
	print("存档成功: %s" % file_path)
	return true

# ----- 加载 -----

func load_game(slot_name: String = "auto") -> bool:
	var file_path = SAVE_DIR + slot_name + SAVE_EXT
	if not FileAccess.file_exists(file_path):
		push_warning("没有找到存档: %s" % file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("读档失败: 无法打开 %s" % file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("读档失败: JSON 解析错误")
		return false

	var data = json.get_data()

	# 恢复各系统
	_load_player(data.get("player", {}))
	SurvivalManager.deserialize(data.get("survival", {}))
	InventoryManager.deserialize(data.get("inventory", []))
	WorldManager.deserialize(data.get("world", {}))
	DayNightCycle.deserialize(data.get("day_night", {}))
	WeatherSystem.deserialize(data.get("weather", {}))

	Signals.game_loaded.emit()
	print("读档成功: %s" % file_path)
	return true

# ----- 列出存档 -----

func list_saves() -> Array:
	var result: Array = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(SAVE_EXT):
				result.append(file_name.trim_suffix(SAVE_EXT))
			file_name = dir.get_next()
		dir.list_dir_end()
	return result

# ----- 删除存档 -----

func delete_save(slot_name: String):
	var file_path = SAVE_DIR + slot_name + SAVE_EXT
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

# ----- 序列化子函数 -----

func _save_player() -> Dictionary:
	var player_node = _find_player()
	if player_node:
		return player_node.serialize()
	return {}

func _load_player(data: Dictionary):
	var player_node = _find_player()
	if player_node and not data.is_empty():
		player_node.deserialize(data)

func _find_player() -> Node:
	# 从场景树中寻找 Player 节点
	var tree = get_tree()
	if tree:
		var root = tree.root
		# 递归查找
		var nodes = root.find_children("Player", "", true, false)
		if nodes.size() > 0:
			return nodes[0]
		# 备用：按类型找
		nodes = root.find_children("*", "CharacterBody2D", true, false)
		if nodes.size() > 0:
			return nodes[0]
	return null
