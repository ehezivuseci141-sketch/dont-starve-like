# ============================================================
# world/day_night.gd — 昼夜循环系统
# 伙伴的 Claude 负责
# 控制游戏时间、日夜切换、季节更替
# ============================================================
extends Node

# 一天的长度（现实秒数）
const DAY_LENGTH: float = 120.0   # 2 分钟一天（测试用，正式版改回 480）
const DAY_SEGMENT: float = DAY_LENGTH / 3.0  # 白天/黄昏/夜晚各 1/3

# 季节长度（游戏天数）
const SEASON_LENGTH: int = 5   # 5 天一季（测试用，正式版改回 20）

# 当前游戏时间（累计秒数）
var game_time: float = 0.0
var current_day: int = 1
var current_season: int = Enums.Season.AUTUMN  # 从秋天开始（像饥荒一样）
var days_in_season: int = 0

# 当前时段
var current_time_of_day: int = Enums.TimeOfDay.DAY

func _process(delta: float):
	game_time += delta

	# 检测时段变化
	var time_in_day = fmod(game_time, DAY_LENGTH)
	var new_time_of_day = current_time_of_day

	if time_in_day < DAY_SEGMENT:
		new_time_of_day = Enums.TimeOfDay.DAY
	elif time_in_day < DAY_SEGMENT * 2:
		new_time_of_day = Enums.TimeOfDay.DUSK
	else:
		new_time_of_day = Enums.TimeOfDay.NIGHT

	if new_time_of_day != current_time_of_day:
		current_time_of_day = new_time_of_day
		Signals.time_of_day_changed.emit(current_time_of_day)

	# 检测新的一天
	var new_day = int(floor(game_time / DAY_LENGTH)) + 1
	if new_day != current_day:
		current_day = new_day
		Signals.day_elapsed.emit(current_day)
		_on_new_day()

# ----- 新的一天 -----

func _on_new_day():
	days_in_season += 1
	if days_in_season >= SEASON_LENGTH:
		days_in_season = 0
		_advance_season()

func _advance_season():
	current_season = (current_season + 1) % 4
	Signals.season_changed.emit(current_season)
	print("[季节] 进入了 %s" % Enums.season_name(current_season))

# ----- API -----

# 获取当前时段的比例（0.0=日出, 0.5=正午, 0.75=黄昏, 1.0=午夜）
func get_time_ratio() -> float:
	return fmod(game_time / DAY_LENGTH, 1.0)

# 是否是白天（可以安全活动）
func is_daytime() -> bool:
	return current_time_of_day == Enums.TimeOfDay.DAY

# 是否是夜晚（有危险）
func is_nighttime() -> bool:
	return current_time_of_day == Enums.TimeOfDay.NIGHT

# 是否是黄昏（过渡期）
func is_dusk() -> bool:
	return current_time_of_day == Enums.TimeOfDay.DUSK

# 根据时段获取环境光亮度（0.0=全黑, 1.0=全亮）
func get_ambient_light() -> float:
	match current_time_of_day:
		Enums.TimeOfDay.DAY: return 1.0
		Enums.TimeOfDay.DUSK: return 0.5
		Enums.TimeOfDay.NIGHT: return 0.15
	return 1.0

# 获取季节对环境的颜色修正
func get_season_color_modulate() -> Color:
	match current_season:
		Enums.Season.SPRING: return Color(0.85, 1.0, 0.85)  # 微绿
		Enums.Season.SUMMER: return Color(1.0, 1.0, 0.8)    # 微黄（热）
		Enums.Season.AUTUMN: return Color(1.0, 0.9, 0.75)   # 暖色调
		Enums.Season.WINTER: return Color(0.85, 0.9, 1.0)   # 冷色调
	return Color.WHITE

# ----- 序列化 -----
func serialize() -> Dictionary:
	return {
		"game_time": game_time,
		"current_day": current_day,
		"current_season": current_season,
		"days_in_season": days_in_season,
		"current_time_of_day": current_time_of_day
	}

func deserialize(data: Dictionary):
	game_time = data.get("game_time", 0.0)
	current_day = data.get("current_day", 1)
	current_season = data.get("current_season", Enums.Season.AUTUMN)
	days_in_season = data.get("days_in_season", 0)
	current_time_of_day = data.get("current_time_of_day", Enums.TimeOfDay.DAY)
	Signals.time_of_day_changed.emit(current_time_of_day)
	Signals.season_changed.emit(current_season)
