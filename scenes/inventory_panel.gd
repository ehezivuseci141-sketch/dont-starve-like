# Inventory + crafting panel — Tab, click-to-move, sprites
extends CanvasLayer

var _visible: bool = false
var _all_ui: Array = []
var _slot_rects: Array = []
var _slot_sprites: Array = []
var _slot_labels: Array = []
var _craft_labels: Array = []
var _craft_recipe_idx: Array = []
var _craft_icons: Array = []
var _grabbed_slot: int = -1
var _grabbed_data: Dictionary = {}
var _border: ColorRect

const PW: int = 660
const PH: int = 500
const SLOT: int = 48
const COLS: int = 5
const GAP: int = 3

func _ready():
	var cx = (DisplayServer.window_get_size().x - PW) / 2
	var cy = (DisplayServer.window_get_size().y - PH) / 2

	# Main background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.92)
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(PW, PH)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_all_ui.append(bg)

	_add_static("Inventory & Crafting  [Tab]", cx + 12, cy + 8, 16, Color(1, 0.85, 0.3))
	_add_static("-- Backpack --  Click to pick up, click to place", cx + 12, cy + 28, 12, Color(0.7, 0.7, 0.7))
	_add_static("-- Crafting --  Click recipe to make", cx + 310, cy + 28, 12, Color(0.7, 0.7, 0.7))
	_add_static("[Click]Pick/Move  [F]Eat  [Q]Drop  [Tab]Close", cx + 12, cy + PH - 22, 11, Color(0.5, 0.5, 0.5))

	# Selection border
	_border = ColorRect.new()
	_border.color = Color(1, 0.85, 0.3, 0.5)
	_border.size = Vector2(SLOT + 4, SLOT + 4)
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_border)
	_all_ui.append(_border)

	# Inventory slots
	var inv_x = cx + 12
	var inv_y = cy + 48
	for i in range(InventoryManager.max_slots):
		var row = i / COLS
		var col = i % COLS
		var x = inv_x + col * (SLOT + GAP)
		var y = inv_y + row * (SLOT + GAP)

		var rect = ColorRect.new()
		rect.color = Color(0.12, 0.1, 0.07, 0.9)
		rect.size = Vector2(SLOT, SLOT)
		rect.position = Vector2(x, y)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_slot_rects.append(rect)
		_all_ui.append(rect)

		var sprite = TextureRect.new()
		sprite.size = Vector2(SLOT - 4, SLOT - 4)
		sprite.position = Vector2(x + 2, y + 2)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_slot_sprites.append(sprite)
		_all_ui.append(sprite)

		var lbl = Label.new()
		lbl.position = Vector2(x + SLOT - 16, y + SLOT - 16)
		lbl.size = Vector2(16, 16)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		add_child(lbl)
		_slot_labels.append(lbl)
		_all_ui.append(lbl)

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

func _show_all():
	for node in _all_ui: node.visible = true
	for node in _craft_labels: node.visible = true
	for node in _craft_icons: node.visible = true

var _tab_was_down: bool = false

func _process(_delta):
	# Tab toggle with debounce (bypass all keycode issues)
	var tab_now = Input.is_key_pressed(KEY_TAB) or Input.is_key_pressed(4194306)
	if tab_now and not _tab_was_down:
		_visible = not _visible
		if _visible: _show_all(); _refresh_crafting()
		else: _hide_all(); _clear_craft()
	_tab_was_down = tab_now

	if _visible:
		_refresh_slots()

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

func _place_item(target_idx: int):
	if _grabbed_slot < 0: return
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

func _refresh_slots():
	var sel = InventoryManager.selected_slot
	for i in range(InventoryManager.slots.size()):
		if i >= _slot_rects.size(): break
		var slot = InventoryManager.slots[i]
		if slot.is_empty():
			_slot_rects[i].color = Color(0.12, 0.1, 0.07, 0.9)
			_slot_sprites[i].texture = null
			_slot_labels[i].text = ""
		else:
			_slot_rects[i].color = Color(0.15, 0.12, 0.08, 0.9)
			var tex_path = "res://assets/sprites/%s.png" % slot["item_id"]
			if ResourceLoader.exists(tex_path):
				_slot_sprites[i].texture = load(tex_path)
			_slot_labels[i].text = str(slot["amount"]) if slot["amount"] > 1 else ""

	# Move border
	if sel >= 0 and sel < _slot_rects.size():
		_border.position = _slot_rects[sel].position - Vector2(2, 2)

	# Highlight grabbed slot
	if _grabbed_slot >= 0 and _grabbed_slot < _slot_rects.size():
		_slot_rects[_grabbed_slot].color = Color(0.5, 0.45, 0.1, 0.8)

func _refresh_crafting():
	_clear_craft()
	var cx = (DisplayServer.window_get_size().x - PW) / 2
	var cy = (DisplayServer.window_get_size().y - PH) / 2
	var rx = cx + 310
	var ry = cy + 50
	var recipes = CraftingManager.get_all_recipes()
	var ROW_H: int = 56

	for i in range(recipes.size()):
		var r = recipes[i]
		var can = r["can_craft"]
		var y = ry + i * ROW_H

		var result_id = r["result"]["item_id"]
		var tex_path = "res://assets/sprites/%s.png" % result_id
		_add_icon(rx, y + 2, 22, tex_path)

		var line = "%d. %s  x%d" % [i + 1, r["name"], r["result"]["amount"]]
		var name_color = Color(0.3, 1.0, 0.3) if can else Color(0.5, 0.5, 0.5)
		var nl = _craft_label(line, rx + 28, y, 14, name_color, i)
		_craft_recipe_idx.append(i)

		var badge_text = "[Can]" if can else "[No]"
		var badge_color = Color(0.2, 0.8, 0.2) if can else Color(0.6, 0.2, 0.2)
		_craft_label(badge_text, rx + 200, y, 12, badge_color, i)
		_craft_recipe_idx.append(i)

		var ing_text = ""
		for item_id in r["ingredients"]:
			var have = InventoryManager.count_item(item_id)
			var need = r["ingredients"][item_id]
			var ok = have >= need
			var dot = "[O]" if ok else "[X]"
			var name = ItemDB.get_item_name(item_id)
			if name == "": name = item_id
			ing_text += "%s%s:%d/%d  " % [dot, name, have, need]

		var ing_color = Color(0.7, 0.7, 0.7) if can else Color(0.4, 0.4, 0.4)
		_craft_label(ing_text, rx + 28, y + 20, 12, ing_color, i)
		_craft_recipe_idx.append(i)

		if i < recipes.size() - 1:
			var sep = _craft_label("----------------------------------------", rx, y + 42, 10, Color(0.2, 0.2, 0.25), i)
			_craft_recipe_idx.append(i)

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
	_craft_recipe_idx.clear()
