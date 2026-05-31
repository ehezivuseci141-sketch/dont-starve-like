# Inventory + crafting panel — Tab, click-to-move, sprites
extends CanvasLayer

var _visible: bool = false
var _all_ui: Array = []
var _slot_rects: Array = []
var _slot_sprites: Array = []
var _slot_labels: Array = []
var _slot_key_labels: Array = []
var _craft_labels: Array = []
var _craft_recipe_idx: Array = []
var _craft_icons: Array = []
var _craft_rows: Array = []
var _craft_scroll: ScrollContainer
var _craft_list: VBoxContainer
var _last_viewport_size: Vector2 = Vector2.ZERO
var _grabbed_slot: int = -1
var _grabbed_data: Dictionary = {}
var _border: Panel
var _tip_bg: Panel
var _tip_lbl: Label
var _drag_icon: TextureRect
var _drag_amount: Label

const PW: int = 720
const PH: int = 520
const SLOT: int = 52
const COLS: int = 5
const GAP: int = 6

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
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
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
	_build_ui()
	_last_viewport_size = get_viewport().get_visible_rect().size

func _build_ui():
	var viewport_size = get_viewport().get_visible_rect().size
	var cx = (viewport_size.x - PW) / 2
	var cy = (viewport_size.y - PH) / 2

	# Main background
	var bg = _make_panel(Vector2(cx, cy), Vector2(PW, PH), Color(0.032, 0.030, 0.028, 0.94), 14, Color(0.95, 0.78, 0.38, 0.26), 1)
	_all_ui.append(bg)

	var left_panel = _make_panel(Vector2(cx + 12, cy + 46), Vector2(292, 392), Color(0.055, 0.047, 0.038, 0.78), 12, Color(1, 1, 1, 0.08), 1)
	var right_panel = _make_panel(Vector2(cx + 318, cy + 46), Vector2(390, 392), Color(0.046, 0.045, 0.052, 0.80), 12, Color(1, 1, 1, 0.08), 1)
	_all_ui.append(left_panel)
	_all_ui.append(right_panel)

	_add_static("背包与合成", cx + 18, cy + 12, 20, Color(0.98, 0.82, 0.36))
	_add_static("快捷栏 / 背包", cx + 24, cy + 56, 14, Color(0.88, 0.78, 0.56))
	_add_static("配方", cx + 332, cy + 56, 14, Color(0.88, 0.78, 0.56))
	_add_static("点击拾起 / 放下    Tab 关闭", cx + 18, cy + PH - 32, 12, Color(0.58, 0.55, 0.48))

	_craft_scroll = ScrollContainer.new()
	_craft_scroll.position = Vector2(cx + 326, cy + 84)
	_craft_scroll.size = Vector2(370, 336)
	_craft_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_craft_scroll)
	_all_ui.append(_craft_scroll)

	_craft_list = VBoxContainer.new()
	_craft_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_craft_list.add_theme_constant_override("separation", 8)
	_craft_scroll.add_child(_craft_list)

	# Selection border
	_border = _make_panel(Vector2.ZERO, Vector2(SLOT + 6, SLOT + 6), Color(1, 0.85, 0.3, 0.14), 10, Color(1, 0.82, 0.26, 0.95), 2)
	_all_ui.append(_border)

	# Inventory slots
	var inv_x = cx + 24
	var inv_y = cy + 84
	for i in range(InventoryManager.max_slots):
		var row = i / COLS
		var col = i % COLS
		var x = inv_x + col * (SLOT + GAP)
		var y = inv_y + row * (SLOT + GAP)

		var rect = _make_panel(Vector2(x, y), Vector2(SLOT, SLOT), Color(0.105, 0.080, 0.055, 0.92), 9, Color(1, 1, 1, 0.10), 1)
		_slot_rects.append(rect)
		_all_ui.append(rect)

		var sprite = TextureRect.new()
		sprite.size = Vector2(SLOT - 8, SLOT - 8)
		sprite.position = Vector2(x + 4, y + 5)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_slot_sprites.append(sprite)
		_all_ui.append(sprite)

		var key = Label.new()
		key.text = str(i + 1) if i < 5 else ""
		key.position = Vector2(x + 5, y + 4)
		key.size = Vector2(18, 16)
		key.add_theme_font_size_override("font_size", 10)
		key.add_theme_color_override("font_color", Color(0.70, 0.64, 0.50))
		add_child(key)
		_slot_key_labels.append(key)
		_all_ui.append(key)

		var lbl = Label.new()
		lbl.position = Vector2(x + SLOT - 24, y + SLOT - 22)
		lbl.size = Vector2(20, 18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76))
		add_child(lbl)
		_slot_labels.append(lbl)
		_all_ui.append(lbl)

	_tip_bg = _make_panel(Vector2.ZERO, Vector2.ZERO, Color(0.035, 0.032, 0.030, 0.96), 10, Color(0.95, 0.78, 0.38, 0.28), 1)
	_tip_lbl = Label.new()
	_tip_lbl.add_theme_font_size_override("font_size", 12)
	_tip_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78))
	add_child(_tip_lbl)
	_all_ui.append(_tip_bg)
	_all_ui.append(_tip_lbl)

	_drag_icon = TextureRect.new()
	_drag_icon.size = Vector2(42, 42)
	_drag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_drag_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_drag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_icon.visible = false
	add_child(_drag_icon)

	_drag_amount = Label.new()
	_drag_amount.size = Vector2(28, 18)
	_drag_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_drag_amount.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_drag_amount.add_theme_font_size_override("font_size", 12)
	_drag_amount.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76))
	_drag_amount.visible = false
	add_child(_drag_amount)

	_hide_all()

func _add_static(txt: String, x: float, y: float, sz: int, col: Color):
	var l = Label.new()
	l.text = txt
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	_all_ui.append(l)

func _add_icon(x: float, y: float, sz: float, tex_path: String) -> TextureRect:
	var t = TextureRect.new()
	if ResourceLoader.exists(tex_path):
		t.texture = load(tex_path)
	t.size = Vector2(sz, sz)
	t.position = Vector2(x, y)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.visible = _visible
	add_child(t)
	_craft_icons.append(t)
	return t

func _hide_all():
	for node in _all_ui: node.visible = false
	for node in _craft_labels: node.visible = false
	for node in _craft_icons: node.visible = false
	for node in _craft_rows: node.visible = false
	_drag_icon.visible = false
	_drag_amount.visible = false

func _show_all():
	for node in _all_ui: node.visible = true
	for node in _craft_labels: node.visible = true
	for node in _craft_icons: node.visible = true
	for node in _craft_rows: node.visible = true
	_tip_bg.visible = false
	_tip_lbl.visible = false

var _tab_was_down: bool = false

func _process(_delta):
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size != _last_viewport_size:
		_last_viewport_size = viewport_size
		_rebuild_ui_for_resize()

	# Tab toggle with debounce (bypass all keycode issues)
	var tab_now = Input.is_key_pressed(KEY_TAB) or Input.is_key_pressed(4194306)
	if tab_now and not _tab_was_down:
		_visible = not _visible
		if _visible: _show_all(); _refresh_crafting()
		else:
			_grabbed_slot = -1
			_grabbed_data = {}
			_hide_all()
			_clear_craft()
	_tab_was_down = tab_now

	if _visible:
		_refresh_slots()
		_refresh_tooltip()
		_refresh_drag_preview()

func _input(event: InputEvent):
	if not _visible:
		return
	if event is InputEventMouseButton and event.pressed and _visible:
		_handle_click(event.position)

func _handle_click(pos: Vector2):
	for i in range(_slot_rects.size()):
		var r = _slot_rects[i]
		if pos.x >= r.position.x and pos.x <= r.position.x + r.size.x:
			if pos.y >= r.position.y and pos.y <= r.position.y + r.size.y:
				if _grabbed_slot >= 0:
					_place_item(i)
				else:
					_grab_item(i)
				return

	var hotbar_idx = _hotbar_slot_at_pos(pos)
	if hotbar_idx >= 0:
		if _grabbed_slot >= 0:
			_place_item(hotbar_idx)
		else:
			_grab_item(hotbar_idx)
		return

	var recipes = CraftingManager.get_all_recipes()
	for j in range(_craft_labels.size()):
		var cl = _craft_labels[j]
		if pos.x >= cl.position.x and pos.y >= cl.position.y:
			if pos.y <= cl.position.y + 18:
				var ri = _craft_recipe_idx[j] if j < _craft_recipe_idx.size() else -1
				if ri >= 0 and ri < recipes.size() and recipes[ri]["can_craft"]:
					CraftingManager.craft(recipes[ri]["id"])
					_refresh_crafting()
				return

func _grab_item(slot_idx: int):
	var slot = InventoryManager.slots[slot_idx]
	if slot.is_empty(): return
	_grabbed_slot = slot_idx
	_grabbed_data = slot.duplicate()
	_refresh_drag_preview()

func _place_item(target_idx: int):
	if _grabbed_slot < 0: return
	if target_idx == _grabbed_slot:
		_grabbed_slot = -1
		_grabbed_data = {}
		_refresh_drag_preview()
		return
	var grabbed = _grabbed_data
	var target = InventoryManager.slots[target_idx]
	if target.is_empty():
		InventoryManager.slots[target_idx] = grabbed
		InventoryManager.slots[_grabbed_slot] = {}
	elif target["item_id"] == grabbed["item_id"]:
		var max_stack = ItemDB.get_item(grabbed["item_id"]).get("stack_max", 40)
		var space = max_stack - target["amount"]
		var to_move = mini(grabbed["amount"], space)
		if to_move > 0:
			target["amount"] += to_move
			grabbed["amount"] -= to_move
			if grabbed["amount"] <= 0:
				InventoryManager.slots[_grabbed_slot] = {}
			else:
				InventoryManager.slots[_grabbed_slot] = grabbed
	else:
		InventoryManager.slots[target_idx] = grabbed
		InventoryManager.slots[_grabbed_slot] = target
	_grabbed_slot = -1
	_grabbed_data = {}
	InventoryManager.select_slot(target_idx)
	_refresh_drag_preview()

func _hotbar_slot_at_pos(pos: Vector2) -> int:
	const HOTBAR_SLOTS: int = 5
	const HOTBAR_SIZE: int = 60
	const HOTBAR_GAP: int = 8
	var viewport_size = get_viewport().get_visible_rect().size
	var total_w = HOTBAR_SLOTS * HOTBAR_SIZE + (HOTBAR_SLOTS + 1) * HOTBAR_GAP
	var sx = (viewport_size.x - total_w) / 2
	var sy = viewport_size.y - HOTBAR_SIZE - 18
	for i in range(HOTBAR_SLOTS):
		var x = sx + HOTBAR_GAP + i * (HOTBAR_SIZE + HOTBAR_GAP)
		if Rect2(Vector2(x, sy), Vector2(HOTBAR_SIZE, HOTBAR_SIZE)).has_point(pos):
			return i
	return -1

func _rebuild_ui_for_resize():
	var was_visible = _visible
	_grabbed_slot = -1
	_grabbed_data = {}
	for child in get_children():
		if child is CanvasItem:
			child.visible = false
		child.queue_free()
	_all_ui.clear()
	_slot_rects.clear()
	_slot_sprites.clear()
	_slot_labels.clear()
	_slot_key_labels.clear()
	_craft_labels.clear()
	_craft_recipe_idx.clear()
	_craft_icons.clear()
	_craft_rows.clear()
	_build_ui()
	_visible = was_visible
	if _visible:
		_show_all()
		_refresh_crafting()
	else:
		_hide_all()

func _refresh_slots():
	var sel = InventoryManager.selected_slot
	for i in range(InventoryManager.slots.size()):
		if i >= _slot_rects.size(): break
		var slot = InventoryManager.slots[i]
		var selected = i == sel
		if slot.is_empty():
			var bg_col = Color(0.17, 0.13, 0.075, 0.96) if selected else Color(0.105, 0.080, 0.055, 0.92)
			var border_col = Color(1.0, 0.86, 0.28, 0.85) if selected else Color(1, 1, 1, 0.10)
			var border_w = 2 if selected else 1
			_set_panel_color(_slot_rects[i], bg_col, 9, border_col, border_w)
			_slot_sprites[i].texture = null
			_slot_labels[i].text = ""
		else:
			var bg_col = Color(0.25, 0.18, 0.080, 0.98) if selected else Color(0.16, 0.12, 0.075, 0.94)
			var border_col = Color(1.0, 0.86, 0.28, 0.90) if selected else Color(1, 0.82, 0.35, 0.24)
			var border_w = 2 if selected else 1
			_set_panel_color(_slot_rects[i], bg_col, 9, border_col, border_w)
			var tex_path = "res://assets/sprites/%s.png" % slot["item_id"]
			if ResourceLoader.exists(tex_path):
				_slot_sprites[i].texture = load(tex_path)
			_slot_labels[i].text = str(slot["amount"]) if slot["amount"] > 1 else ""
		if i < _slot_key_labels.size():
			_slot_key_labels[i].add_theme_color_override("font_color", Color(1.0, 0.88, 0.28) if selected else Color(0.70, 0.64, 0.50))

	# Move border
	_border.visible = sel >= 0 and sel < _slot_rects.size()
	if _border.visible:
		_border.position = _slot_rects[sel].position - Vector2(3, 3)

	# Highlight grabbed slot
	if _grabbed_slot >= 0 and _grabbed_slot < _slot_rects.size():
		_set_panel_color(_slot_rects[_grabbed_slot], Color(0.48, 0.40, 0.10, 0.86), 9, Color(1, 0.9, 0.35, 0.95), 2)

func _refresh_drag_preview():
	if _grabbed_slot < 0 or _grabbed_data.is_empty():
		_drag_icon.visible = false
		_drag_amount.visible = false
		return

	var mouse = get_viewport().get_mouse_position()
	var tex_path = "res://assets/sprites/%s.png" % _grabbed_data["item_id"]
	_drag_icon.texture = load(tex_path) if ResourceLoader.exists(tex_path) else null
	_drag_icon.position = mouse + Vector2(18, 18)
	_drag_icon.visible = true
	_drag_amount.text = str(_grabbed_data.get("amount", 1)) if _grabbed_data.get("amount", 1) > 1 else ""
	_drag_amount.position = _drag_icon.position + Vector2(14, 22)
	_drag_amount.visible = _drag_amount.text != ""

func _refresh_tooltip():
	var mouse = get_viewport().get_mouse_position()
	var found = false
	for i in range(_slot_rects.size()):
		var r = _slot_rects[i]
		if Rect2(r.position, r.size).has_point(mouse) and i < InventoryManager.slots.size():
			var slot = InventoryManager.slots[i]
			if not slot.is_empty():
				_tip_lbl.text = _get_item_tooltip(slot)
				_tip_lbl.position = mouse + Vector2(22, 20)
				_tip_bg.position = mouse + Vector2(14, 12)
				_tip_bg.size = _tip_lbl.get_minimum_size() + Vector2(16, 16)
				_tip_bg.visible = true
				_tip_lbl.visible = true
				found = true
			break
	if not found:
		_tip_bg.visible = false
		_tip_lbl.visible = false

func _get_item_tooltip(slot: Dictionary) -> String:
	var item = ItemDB.get_item(slot["item_id"])
	var txt = item.get("name", slot["item_id"])
	txt += "\n数量: %d" % int(slot.get("amount", 1))
	if item.get("damage", 0) > 0: txt += "\n伤害: %d" % int(item.get("damage", 0))
	if item.get("hunger_restore", 0) != 0: txt += "\n饱食: %+d" % int(item.get("hunger_restore", 0))
	if item.get("health_restore", 0) != 0: txt += "\n生命: %+d" % int(item.get("health_restore", 0))
	if slot.has("dur"): txt += "\n耐久: %d/%d" % [slot["dur"], item.get("durability", 50)]
	return txt

func _refresh_crafting():
	_clear_craft()
	var recipes = CraftingManager.get_all_recipes()

	for i in range(recipes.size()):
		var r = recipes[i]
		var row = _make_craft_row(r, i)
		_craft_list.add_child(row)
		_craft_rows.append(row)

func _make_craft_row(recipe: Dictionary, index: int) -> Panel:
	var can = recipe["can_craft"]
	var row_col = Color(0.075, 0.080, 0.072, 0.92) if can else Color(0.058, 0.058, 0.062, 0.82)
	var row_border = Color(0.50, 0.95, 0.50, 0.28) if can else Color(1, 1, 1, 0.08)
	var row = Panel.new()
	row.custom_minimum_size = Vector2(344, 64)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can else Control.CURSOR_ARROW
	row.add_theme_stylebox_override("panel", _make_style(row_col, 9, row_border, 1))
	row.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if recipe["can_craft"] and CraftingManager.craft(recipe["id"]):
				_refresh_crafting()
	)

	var result_id = recipe["result"]["item_id"]
	var tex_path = "res://assets/sprites/%s.png" % result_id
	var icon = TextureRect.new()
	if ResourceLoader.exists(tex_path):
		icon.texture = load(tex_path)
	icon.position = Vector2(10, 12)
	icon.size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var title = Label.new()
	title.text = "%d. %s  x%d" % [index + 1, recipe["name"], recipe["result"]["amount"]]
	title.position = Vector2(58, 8)
	title.size = Vector2(180, 22)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.72, 1.0, 0.56) if can else Color(0.54, 0.54, 0.56))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)

	var badge = Label.new()
	badge.text = "可制作" if can else "材料不足"
	badge.position = Vector2(246, 8)
	badge.size = Vector2(84, 20)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color(0.45, 1.0, 0.45) if can else Color(0.95, 0.38, 0.32))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(badge)

	var ingredients = Label.new()
	ingredients.text = _craft_ingredients_text(recipe["ingredients"])
	ingredients.position = Vector2(58, 34)
	ingredients.size = Vector2(272, 20)
	ingredients.clip_text = true
	ingredients.add_theme_font_size_override("font_size", 11)
	ingredients.add_theme_color_override("font_color", Color(0.68, 0.66, 0.58) if can else Color(0.43, 0.42, 0.42))
	ingredients.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ingredients)

	return row

func _craft_ingredients_text(ingredients: Dictionary) -> String:
	var parts: Array = []
	for item_id in ingredients:
		var have = InventoryManager.count_item(item_id)
		var need = ingredients[item_id]
		var mark = "OK" if have >= need else "缺"
		var item_name = ItemDB.get_item_name(item_id)
		if item_name == "":
			item_name = item_id
		parts.append("%s %s:%d/%d" % [mark, item_name, have, need])
	return "  ".join(parts)

func _craft_label(txt: String, x: float, y: float, sz: int, col: Color, _ri: int) -> Label:
	var l = Label.new()
	l.text = txt
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.visible = _visible
	add_child(l)
	_craft_labels.append(l)
	return l

func _clear_craft():
	for label in _craft_labels:
		label.queue_free()
	_craft_labels.clear()
	for icon in _craft_icons:
		icon.queue_free()
	_craft_icons.clear()
	for row in _craft_rows:
		row.queue_free()
	_craft_rows.clear()
	_craft_recipe_idx.clear()
