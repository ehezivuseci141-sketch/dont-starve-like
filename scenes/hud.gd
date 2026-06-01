# HUD — Four-corner layout, using rounded Panel bars
extends CanvasLayer
class_name UIManager

# Top-left
var _health_bg: Panel
var _health_fill: Panel
var _hunger_bg: Panel
var _hunger_fill: Panel
var _health_lbl: Label
var _hunger_lbl: Label
const BAR_W = 180; const HEALTH_H = 18; const HUNGER_H = 14
var _health_max = 150.0; var _health_val = 100.0
var _hunger_max = 150.0; var _hunger_val = 100.0

# Top-right
var _realm_lbl: Label
var _qi_bg: Panel
var _qi_fill: Panel
var _qi_lbl: Label
var _time_lbl: Label
const QI_W = 200; const QI_H = 16
var _qi_max = 100.0; var _qi_val = 0.0

# Bottom-right
var _weapon_lbl: Label
var _dur_bg: Panel
var _dur_fill: Panel
const DUR_W = 200; const DUR_H = 10
var _dur_max = 50.0; var _dur_val = 0.0

# Bottom-left
var _weather_lbl: Label
var _last_viewport_size: Vector2 = Vector2.ZERO

func _ready():
	_rebuild_layout()
	_connect_signals()
	_last_viewport_size = get_viewport().get_visible_rect().size

func _connect_signals():
	Signals.hunger_changed.connect(_on_hunger)
	Signals.health_changed.connect(_on_health)
	Signals.day_elapsed.connect(_update_time)
	Signals.time_of_day_changed.connect(_on_time)
	Signals.season_changed.connect(_on_season)
	Signals.weather_changed.connect(_on_weather)

func _make_style(color: Color, radius: int, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style

func _make_panel(x: float, y: float, w: float, h: float, color: Color, radius: int, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> Panel:
	var panel = Panel.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(w, h)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_style(color, radius, border_color, border_width))
	add_child(panel)
	return panel

func _make_bar(x, y, w, h, bg_col, fill_col) -> Array:
	var bg = _make_panel(x, y, w, h, bg_col, 8, Color(1, 1, 1, 0.12), 1)
	var fill = _make_panel(x, y, w, h, fill_col, 8)
	return [bg, fill]

func _set_bar(fill: Panel, bg: Panel, val: float, max_v: float):
	var ratio = clampf(val / max_v, 0.0, 1.0)
	fill.size.x = bg.size.x * ratio

func _rebuild_layout():
	for child in get_children():
		if child is CanvasItem:
			child.visible = false
		child.queue_free()
	_create_top_left()
	_create_bottom_right()
	_create_bottom_left()
	_apply_cached_values()

func _apply_cached_values():
	if _health_lbl:
		_on_health(_health_val, _health_max)
	if _hunger_lbl:
		_on_hunger(_hunger_val, _hunger_max)
	_update_time_label()
	if _weather_lbl:
		_weather_lbl.text = WeatherSystem.get_weather_name()

# ===== TOP-LEFT =====
func _create_top_left():
	var m = 12
	_make_panel(m - 8, m - 8, 210, 160, Color(0.035, 0.033, 0.030, 0.78), 12, Color(0.92, 0.70, 0.30, 0.22), 1)
	# Avatar placeholder
	_make_panel(m, m, 48, 48, Color(0.18, 0.32, 0.20), 12, Color(0.95, 0.78, 0.38, 0.55), 2)
	var name_lbl = Label.new(); name_lbl.text = "旅人"; name_lbl.position = Vector2(m + 58, m + 5)
	name_lbl.size = Vector2(120, 22); name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62)); add_child(name_lbl)
	# Health
	var bars = _make_bar(m, m+54, BAR_W, HEALTH_H, Color(0.16, 0.035, 0.035), Color(0.82, 0.10, 0.10))
	_health_bg = bars[0]; _health_fill = bars[1]
	_health_lbl = Label.new(); _health_lbl.text = "生命 100/150"; _health_lbl.position = Vector2(m, m+54)
	_health_lbl.size = Vector2(BAR_W, HEALTH_H); _health_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_health_lbl.add_theme_font_size_override("font_size", 11)
	_health_lbl.add_theme_color_override("font_color", Color.WHITE); add_child(_health_lbl)
	# Hunger
	bars = _make_bar(m, m+78, BAR_W, HUNGER_H, Color(0.18, 0.10, 0.02), Color(0.92, 0.54, 0.12))
	_hunger_bg = bars[0]; _hunger_fill = bars[1]
	_hunger_lbl = Label.new(); _hunger_lbl.text = "饥饿 100/150"; _hunger_lbl.position = Vector2(m, m+78)
	_hunger_lbl.size = Vector2(BAR_W, HUNGER_H); _hunger_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hunger_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hunger_lbl.add_theme_font_size_override("font_size", 10)
	_hunger_lbl.add_theme_color_override("font_color", Color.WHITE); add_child(_hunger_lbl)

	# Realm + Qi moved here (was top-right) to avoid minimap overlap.
	_realm_lbl = Label.new()
	_realm_lbl.text = "凡人"
	_realm_lbl.position = Vector2(m, m + 98)
	_realm_lbl.size = Vector2(52, 18)
	_realm_lbl.add_theme_font_size_override("font_size", 12)
	_realm_lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	add_child(_realm_lbl)

	var qi_x = m + 56
	var qi_y = m + 98
	var qi_bars = _make_bar(qi_x, qi_y, 124, 14, Color(0.035, 0.045, 0.12), Color(0.20, 0.55, 1.0))
	_qi_bg = qi_bars[0]; _qi_fill = qi_bars[1]
	_qi_lbl = Label.new()
	_qi_lbl.text = "灵气 0/100"
	_qi_lbl.position = Vector2(qi_x, qi_y)
	_qi_lbl.size = Vector2(124, 14)
	_qi_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qi_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_qi_lbl.add_theme_font_size_override("font_size", 9)
	_qi_lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(_qi_lbl)

	_time_lbl = Label.new()
	_time_lbl.text = "第1天 白昼 秋"
	_time_lbl.position = Vector2(m, m + 118)
	_time_lbl.size = Vector2(180, 18)
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_time_lbl.add_theme_font_size_override("font_size", 10)
	_time_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(_time_lbl)

# ===== TOP-RIGHT =====
func _create_top_right():
	var sw = get_viewport().get_visible_rect().size.x; var m = 12
	var x = sw - 200 - m; var y = m
	_make_panel(x - 10, y - 8, 220, 88, Color(0.030, 0.036, 0.050, 0.76), 12, Color(0.30, 0.74, 1.0, 0.18), 1)
	_realm_lbl = Label.new(); _realm_lbl.text = "凡人"; _realm_lbl.position = Vector2(x, y); _realm_lbl.size = Vector2(200, 24)
	_realm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_realm_lbl.add_theme_font_size_override("font_size", 18)
	_realm_lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0)); add_child(_realm_lbl)

	var bars = _make_bar(x, y+30, QI_W, QI_H, Color(0.035, 0.045, 0.12), Color(0.20, 0.55, 1.0))
	_qi_bg = bars[0]; _qi_fill = bars[1]
	_qi_lbl = Label.new(); _qi_lbl.text = "灵气 0/100"; _qi_lbl.position = Vector2(x, y+30); _qi_lbl.size = Vector2(QI_W, QI_H)
	_qi_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _qi_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_qi_lbl.add_theme_font_size_override("font_size", 10)
	_qi_lbl.add_theme_color_override("font_color", Color.WHITE); add_child(_qi_lbl)

	_time_lbl = Label.new(); _time_lbl.text = "第1天 白昼 秋"; _time_lbl.position = Vector2(x, y+48); _time_lbl.size = Vector2(200, 18)
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_lbl.add_theme_font_size_override("font_size", 11)
	_time_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7)); add_child(_time_lbl)

# ===== BOTTOM-RIGHT =====
func _create_bottom_right():
	var viewport_size = get_viewport().get_visible_rect().size
	var sw = viewport_size.x; var sh = viewport_size.y; var m = 12
	var x = sw - 200 - m; var y = sh - 48 - m
	_make_panel(x - 10, y - 8, 220, 62, Color(0.045, 0.038, 0.030, 0.74), 12, Color(0.95, 0.78, 0.38, 0.18), 1)
	_weapon_lbl = Label.new(); _weapon_lbl.text = "空手"; _weapon_lbl.position = Vector2(x, y); _weapon_lbl.size = Vector2(200, 20)
	_weapon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_weapon_lbl.add_theme_font_size_override("font_size", 14)
	_weapon_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5)); add_child(_weapon_lbl)

	var bars = _make_bar(x, y+26, DUR_W, DUR_H, Color(0.08, 0.075, 0.065), Color(0.72, 0.62, 0.36))
	_dur_bg = bars[0]; _dur_fill = bars[1]; _dur_bg.visible = false; _dur_fill.visible = false

# ===== BOTTOM-LEFT =====
func _create_bottom_left():
	var sh = get_viewport().get_visible_rect().size.y; var m = 12
	_make_panel(m - 8, sh - 40 - m, 96, 32, Color(0.035, 0.040, 0.036, 0.70), 10, Color(1, 1, 1, 0.10), 1)
	_weather_lbl = Label.new(); _weather_lbl.text = "晴天"; _weather_lbl.position = Vector2(m, sh - 34 - m)
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
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size != _last_viewport_size:
		_last_viewport_size = viewport_size
		_rebuild_layout()

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
