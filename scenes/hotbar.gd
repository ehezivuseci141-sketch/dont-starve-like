# Hotbar — bottom-center 5 slots + tooltip
extends CanvasLayer

var _slot_bgs: Array = []
var _slot_sprites: Array = []
var _slot_labels: Array = []
var _key_labels: Array = []
var _bar_bg: Panel
var _border: Panel
var _tip_bg: Panel
var _tip_lbl: Label
var _last_viewport_size: Vector2 = Vector2.ZERO

const SLOTS: int = 5; const SIZE: int = 60; const GAP: int = 8

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
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style

func _make_panel(pos: Vector2, size: Vector2, color: Color, radius: int, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> Panel:
	var panel = Panel.new()
	panel.position = pos
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_style(color, radius, border_color, border_width))
	add_child(panel)
	return panel

func _set_panel_color(panel: Panel, color: Color, radius: int, border_color: Color = Color.TRANSPARENT, border_width: int = 0):
	panel.add_theme_stylebox_override("panel", _make_style(color, radius, border_color, border_width))

func _ready():
	var layout = _hotbar_layout()
	var sx = layout["sx"]
	var sy = layout["sy"]
	var total_w = layout["total_w"]

	_bar_bg = _make_panel(Vector2(sx - GAP, sy - 8), Vector2(total_w, SIZE + 16), Color(0.030, 0.028, 0.025, 0.78), 14, Color(0.95, 0.78, 0.38, 0.20), 1)
	_border = _make_panel(Vector2.ZERO, Vector2(SIZE + 6, SIZE + 6), Color(1, 0.85, 0.3, 0.16), 12, Color(1, 0.82, 0.25, 0.95), 2)

	for i in range(SLOTS):
		var x = sx + GAP + i * (SIZE + GAP)
		var rect = _make_panel(Vector2(x, sy), Vector2(SIZE, SIZE), Color(0.095, 0.075, 0.050, 0.90), 11, Color(1, 1, 1, 0.10), 1)
		_slot_bgs.append(rect)

		var key = Label.new(); key.text = str(i + 1)
		key.position = Vector2(x + 6, sy + 4); key.size = Vector2(18, 16)
		key.add_theme_font_size_override("font_size", 10)
		key.add_theme_color_override("font_color", Color(0.78, 0.70, 0.52))
		add_child(key); _key_labels.append(key)

		var sprite = TextureRect.new(); sprite.size = Vector2(SIZE-10, SIZE-10); sprite.position = Vector2(x+5, sy+7)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(sprite); _slot_sprites.append(sprite)

		var lbl = Label.new(); lbl.position = Vector2(x+SIZE-24, sy+SIZE-22); lbl.size = Vector2(20,18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_font_size_override("font_size", 12); lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76))
		add_child(lbl); _slot_labels.append(lbl)

	# Tooltip
	_tip_bg = _make_panel(Vector2.ZERO, Vector2.ZERO, Color(0.035, 0.032, 0.030, 0.96), 10, Color(0.95, 0.78, 0.38, 0.28), 1)
	_tip_bg.visible = false
	_tip_lbl = Label.new(); _tip_lbl.add_theme_font_size_override("font_size", 12)
	_tip_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78)); _tip_lbl.visible = false; add_child(_tip_lbl)
	_last_viewport_size = get_viewport().get_visible_rect().size

func _process(_delta):
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size != _last_viewport_size:
		_last_viewport_size = viewport_size
		_layout_hotbar()

	var sel = InventoryManager.selected_slot
	_border.visible = sel >= 0 and sel < SLOTS
	if _border.visible:
		_border.position = _slot_bgs[sel].position - Vector2(3, 3)

	# Slots
	for i in range(SLOTS):
		if i >= InventoryManager.slots.size(): break
		var slot = InventoryManager.slots[i]
		var selected = i == sel
		if slot.is_empty():
			var bg_col = Color(0.17, 0.13, 0.075, 0.96) if selected else Color(0.095, 0.075, 0.050, 0.90)
			var border_col = Color(1.0, 0.86, 0.28, 0.85) if selected else Color(1, 1, 1, 0.10)
			var border_w = 2 if selected else 1
			_set_panel_color(_slot_bgs[i], bg_col, 11, border_col, border_w)
			_slot_sprites[i].texture = null; _slot_labels[i].text = ""
		else:
			var bg_col = Color(0.25, 0.18, 0.080, 0.98) if selected else Color(0.16, 0.12, 0.075, 0.94)
			var border_col = Color(1.0, 0.86, 0.28, 0.90) if selected else Color(1, 0.82, 0.35, 0.26)
			var border_w = 2 if selected else 1
			_set_panel_color(_slot_bgs[i], bg_col, 11, border_col, border_w)
			var p = "res://assets/sprites/%s.png" % slot["item_id"]
			_slot_sprites[i].texture = load(p) if ResourceLoader.exists(p) else null
			_slot_labels[i].text = str(slot["amount"]) if slot["amount"] > 1 else ""
		_key_labels[i].add_theme_color_override("font_color", Color(1.0, 0.88, 0.28) if selected else Color(0.78, 0.70, 0.52))

	# Tooltip
	var mouse = get_viewport().get_mouse_position()
	var found = false
	for i in range(_slot_bgs.size()):
		if Rect2(_slot_bgs[i].position, _slot_bgs[i].size).has_point(mouse):
			if i < InventoryManager.slots.size():
				var slot = InventoryManager.slots[i]
				if not slot.is_empty():
					var item = ItemDB.get_item(slot["item_id"])
					var txt = item.get("name", slot["item_id"])
					if item.get("damage", 0) > 0: txt += "\n伤害: %d" % int(item.get("damage", 0))
					if item.get("hunger_restore", 0) > 0: txt += "\n饱食: +%d" % int(item.get("hunger_restore", 0))
					if item.get("health_restore", 0) > 0: txt += "\n回血: +%d" % int(item.get("health_restore", 0))
					if slot.has("dur"): txt += "\n耐久: %d/%d" % [slot["dur"], item.get("durability", 50)]
					_tip_lbl.text = txt; _tip_lbl.position = mouse + Vector2(22, 20)
					_tip_bg.position = mouse + Vector2(14, 12)
					_tip_bg.size = _tip_lbl.get_minimum_size() + Vector2(16, 16)
					_tip_bg.visible = true; _tip_lbl.visible = true
					found = true
				break
	if not found: _tip_bg.visible = false; _tip_lbl.visible = false

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		var slot_idx = _number_key_to_slot(event)
		if slot_idx >= 0:
			InventoryManager.select_slot(slot_idx)
			return

	if event is InputEventMouseButton and event.pressed:
		for i in range(_slot_labels.size()):
			if i >= _slot_bgs.size(): break
			if Rect2(_slot_bgs[i].position, _slot_bgs[i].size).has_point(event.position):
				InventoryManager.select_slot(i); return

func _number_key_to_slot(event: InputEventKey) -> int:
	var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match code:
		KEY_1:
			return 0
		KEY_2:
			return 1
		KEY_3:
			return 2
		KEY_4:
			return 3
		KEY_5:
			return 4
	return -1

func _hotbar_layout() -> Dictionary:
	var viewport_size = get_viewport().get_visible_rect().size
	var total_w = SLOTS * SIZE + (SLOTS + 1) * GAP
	var sx = (viewport_size.x - total_w) / 2
	var sy = viewport_size.y - SIZE - 18
	return {"sx": sx, "sy": sy, "total_w": total_w}

func _layout_hotbar():
	var layout = _hotbar_layout()
	var sx = layout["sx"]
	var sy = layout["sy"]
	var total_w = layout["total_w"]
	if _bar_bg:
		_bar_bg.position = Vector2(sx - GAP, sy - 8)
		_bar_bg.size = Vector2(total_w, SIZE + 16)
	for i in range(SLOTS):
		var x = sx + GAP + i * (SIZE + GAP)
		if i < _slot_bgs.size():
			_slot_bgs[i].position = Vector2(x, sy)
		if i < _key_labels.size():
			_key_labels[i].position = Vector2(x + 6, sy + 4)
		if i < _slot_sprites.size():
			_slot_sprites[i].position = Vector2(x + 5, sy + 7)
		if i < _slot_labels.size():
			_slot_labels[i].position = Vector2(x + SIZE - 24, sy + SIZE - 22)
