# ============================================================
# shared/signals.gd — 全局信号总线
# 这是两个 Claude 系统之间的通信协议
#
# 规则：
#   你的 Claude 写 core/ 系统时 → 发出对应信号
#   伙伴的 Claude 写 world/ 系统时 → 监听这些信号，或发出自己的信号
#   双方都不直接调用对方模块的函数，只通过信号通信
#
# 用法：
#   Signals.player_died.emit("starvation")
#   Signals.player_died.connect(_on_player_died)
# ============================================================
extends Node

# UI state flags (kept tiny; avoids cross-module hard references)
var map_open: bool = false

# ---------- 玩家事件（core → world） ----------
signal player_moved(position: Vector2, direction: Vector2)
signal player_picked_up(item_id: String, amount: int)
signal player_dropped(item_id: String, amount: int, position: Vector2)
signal player_ate(item_id: String)
signal player_died(cause: String)
signal player_respawned(position: Vector2)

# ---------- 生存数值事件（core → world） ----------
signal hunger_changed(current: float, max_val: float)
signal health_changed(current: float, max_val: float)
signal sanity_changed(current: float, max_val: float)
signal player_starving()
signal player_insane()

# ---------- 世界事件（world → core） ----------
signal day_elapsed(day_count: int)
signal time_of_day_changed(new_time: int)  # Enums.TimeOfDay
signal season_changed(new_season: int)      # Enums.Season
signal weather_changed(new_weather: int)    # Enums.Weather

# ---------- 实体事件（world → core） ----------
signal entity_spawned(entity_id: String, entity_type: String, position: Vector2)
signal entity_died(entity_id: String, entity_type: String, position: Vector2, loot: Array)
signal entity_attacked_player(entity_id: String, damage: float)

# ---------- 物品世界事件 ----------
signal item_dropped_in_world(item_id: String, amount: int, position: Vector2)
signal item_collected_from_world(item_id: String, amount: int)

# ---------- 建造事件 ----------
signal structure_placed(structure_id: String, position: Vector2)
signal structure_destroyed(structure_id: String, position: Vector2)

# ---------- 游戏状态 ----------
signal game_saved()
signal game_loaded()
signal game_paused()
signal game_resumed()
