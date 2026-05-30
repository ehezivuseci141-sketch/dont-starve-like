# HUD — Four-corner layout, using ColorRect for bars
extends CanvasLayer

# Top-left
var _health_bg: ColorRect
var _health_fill: ColorRect
var _hunger_bg: ColorRect
var _hunger_fill: ColorRect
var _health_lbl: Label
var _hunger_lbl: Label
const BAR_W = 180; const HEALTH_H = 18; const HUNGER_H = 14
var _health_max = 150.0; var _health_val = 100.0
var _hunger_max = 150.0; var _hunger_val = 100.0

# Top-right
var _realm_lbl: Label
var _qi_bg: ColorRect
var _qi_fill: ColorRect
var _qi_lbl: Label
var _time_lbl: Label
const QI_W = 200; const QI_H = 16
var _qi_max = 100.0; var _qi_val = 0.0

# Bottom-right
var _weapon_lbl: Label
var _dur_bg: ColorRect
var _dur_fill: ColorRect
const DUR_W = 200; const DUR_H = 10
var _dur_max = 50.0; var _dur_val = 0.0

# Bottom-left
var _weather_lbl: Label

func _ready():
	_create_top_left()
	_create_top_right()
	_create_bottom_right()
	_create_bottom_left()
	_connect_signals()

func _connect_signals():
	Signals.hunger_changed.connect(_on_hunger)
	Signals.health_changed.connect(_on_health)
	Signals.day_elapsed.connect(_update_time)
	Signals.time_of_day_changed.connect(_on_time)
	Signals.season_changed.connect(_on_season)
	Signals.weather_changed.connect(_on_weather)

func _make_bar(x, y, w, h, bg_col, fill_col) -> Array:
	var bg = ColorRect.new(); bg.color = bg_col; bg.size = Vector2(w, h); bg.position = Vector2(x, y)
	add_child(bg)
	var fill = ColorRect.new(); fill.color = fill_col; fill.size = Vector2(w, h); fill.position = Vector2(x, y)
	add_child(fill)
	return [bg, fill]

func _set_bar(fill: ColorRect, bg: ColorRect, val: float, max_v: float):
	var ratio = clampf(val / max_v, 0.0, 1.0)
	fill.size.x = bg.size.x * ratio

# ===== TOP-LEFT =====
func _create_top_left():
	var m = 12
	# Avatar placeholder
	var av = ColorRect.new(); av.color = Color(0.3, 0.5, 0.3); av.size = Vector2(48, 48); av.position = Vector2(m, m)
	add_child(av)
	# Health
	var bars = _make_bar(m, m+54, BAR_W, HEALTH_H, Color(0.2, 0.03, 0.03), Color(0.85, 0.15, 0.15))
	_health_bg = bars[0]; _health_fill = bars[1]
	_health_lbl = Label.new(); _health_lbl.text = "生命 100/150"; _health_lbl.position = Vector2(m, m+54)
	_health_lbl.size = Vector2(BAR_W, HEALTH_H); _health_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_health_lbl.add_theme_font_size_override("font_size", 11)
	_health_lbl.add_theme_color_override("font_color", Color.WHITE); add_child(_health_lbl)
	# Hunger
	bars = _make_bar(m, m+76, BAR_W, HUNGER_H, Color(0.2, 0.1, 0.01), Color(0.9, 0.55, 0.15))
	_hunger_bg = bars[0]; _hunger_fill = bars[1]
	_hunger_lbl = Label.new(); _hunger_lbl.text = "饥饿 100/150"; _hunger_lbl.position = Vector2(m, m+76)
	_hunger_lbl.size = Vector2(BAR_W, HUNGER_H); _hunger_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hunger_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hunger_lbl.add_theme_font_size_override("font_size", 10)
	_hunger_lbl.add_theme_color_override("font_color", Color.WHITE); add_child(_hunger_lbl)

# ===== TOP-RIGHT =====
func _create_top_right():
	var sw = DisplayServer.window_get_size().x; var m = 12
	var x = sw - 200 - m; var y = m
	_realm_lbl = Label.new(); _realm_lbl.text = "凡人"; _realm_lbl.position = Vector2(x, y); _realm_lbl.size = Vector2(200, 24)
	_realm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_realm_lbl.add_theme_font_size_override("font_size", 18)
	_realm_lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0)); add_child(_realm_lbl)

	var bars = _make_bar(x, y+28, QI_W, QI_H, Color(0.05, 0.05, 0.15), Color(0.3, 0.5, 1.0))
	_qi_bg = bars[0]; _qi_fill = bars[1]
	_qi_lbl = Label.new(); _qi_lbl.text = "灵气 0/100"; _qi_lbl.position = Vector2(x, y+28); _qi_lbl.size = Vector2(QI_W, QI_H)
	_qi_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _qi_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_qi_lbl.add_theme_font_size_override("font_size", 10)
	_qi_lbl.add_theme_color_override("font_color", Color.WHITE); add_child(_qi_lbl)

	_time_lbl = Label.new(); _time_lbl.text = "第1天 白昼 秋"; _time_lbl.position = Vector2(x, y+48); _time_lbl.size = Vector2(200, 18)
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_lbl.add_theme_font_size_override("font_size", 11)
	_time_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7)); add_child(_time_lbl)

# ===== BOTTOM-RIGHT =====
func _create_bottom_right():
	var sw = DisplayServer.window_get_size().x; var sh = DisplayServer.window_get_size().y; var m = 12
	var x = sw - 200 - m; var y = sh - 40 - m
	_weapon_lbl = Label.new(); _weapon_lbl.text = "空手"; _weapon_lbl.position = Vector2(x, y); _weapon_lbl.size = Vector2(200, 20)
	_weapon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_weapon_lbl.add_theme_font_size_override("font_size", 14)
	_weapon_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5)); add_child(_weapon_lbl)

	var bars = _make_bar(x, y+22, DUR_W, DUR_H, Color(0.08, 0.08, 0.08), Color(0.5, 0.45, 0.3))
	_dur_bg = bars[0]; _dur_fill = bars[1]; _dur_bg.visible = false; _dur_fill.visible = false

# ===== BOTTOM-LEFT =====
func _create_bottom_left():
	var sh = DisplayServer.window_get_size().y; var m = 12
	_weather_lbl = Label.new(); _weather_lbl.text = "晴天"; _weather_lbl.position = Vector2(m, sh - 24 - m)
	_weather_lbl.add_theme_font_size_override("font_size", 11)
	_weather_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7)); add_child(_weather_lbl)

# ===== UPDATES =====
func _on_health(cur: float, max_v: float):
	_health_val = cur; _health_max = max_v
	_set_bar(_health_fill, _health_bg, cur, max_v)
	_health_lbl.text = "生命 %d/%d" % [int(cur), int(max_v)]

func _on_hunger(cur: float, max_v: float):
	_hunger_val = cur; _hunger_max = max_v
	_set_bar(_hunger_fill, _hunger_bg, cur, max_v)
	_hunger_lbl.text = "饥饿 %d/%d" % [int(cur), int(max_v)]

func _update_time(_day: int): _update_time_label()
func _on_time(_t: int): _update_time_label()
func _on_season(_s: int): _update_time_label()
func _on_weather(_w: int):
	if _weather_lbl: _weather_lbl.text = WeatherSystem.get_weather_name()

func _update_time_label():
	if not _time_lbl: return
	var tn = "白昼"
	match DayNightCycle.current_time_of_day:
		Enums.TimeOfDay.DAY: tn = "白昼"
		Enums.TimeOfDay.DUSK: tn = "黄昏"
		Enums.TimeOfDay.NIGHT: tn = "黑夜"
	_time_lbl.text = "第%d天  %s  %s" % [DayNightCycle.current_day, tn, Enums.season_name(DayNightCycle.current_season)]

func _process(_delta):
	var sel = InventoryManager.get_selected_item()
	if not sel.is_empty():
		var name = ItemDB.get_item_name(sel["item_id"])
		var dur = sel.get("dur", -1)
		if dur > 0:
			_weapon_lbl.text = "%s  [%d]" % [name, dur]
			_set_bar(_dur_fill, _dur_bg, dur, ItemDB.get_item(sel["item_id"]).get("durability", 50))
			_dur_bg.visible = true; _dur_fill.visible = true
		else:
			_weapon_lbl.text = name
			_dur_bg.visible = false; _dur_fill.visible = false
	else:
		_weapon_lbl.text = "空手"
		_dur_bg.visible = false; _dur_fill.visible = false
