# ARK-style inventory + crafting panel — Tab to open
extends CanvasLayer

var _visible: bool = false
var _all_ui: Array = []       # everything that should toggle
var _slot_rects: Array = []
var _slot_labels: Array = []
var _craft_labels: Array = []

const PW: int = 520
const PH: int = 420
const SLOT: int = 46
const COLS: int = 5
const GAP: int = 3

func _ready():
	var cx = (DisplayServer.window_get_size().x - PW) / 2
	var cy = (DisplayServer.window_get_size().y - PH) / 2

	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.92)
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(PW, PH)
	add_child(bg)
	_all_ui.append(bg)

	_add_static("Inventory & Crafting  [Tab] close", cx + 12, cy + 8, 15, Color(1, 0.85, 0.3))
	_add_static("—— Backpack ——", cx + 12, cy + 16, 12, Color(0.7, 0.7, 0.7))
	_add_static("—— Crafting ——  [Click] to make", cx + 280, cy + 16, 12, Color(0.7, 0.7, 0.7))
	_add_static("[Click]Select  [F]Eat  [Q]Drop", cx + 12, cy + PH - 22, 11, Color(0.5, 0.5, 0.5))

	var inv_x = cx + 12
	var inv_y = cy + 36
	for i in range(InventoryManager.max_slots):
		var row = i / COLS
		var col = i % COLS
		var x = inv_x + col * (SLOT + GAP)
		var y = inv_y + row * (SLOT + GAP)

		var rect = ColorRect.new()
		rect.color = Color(0.15, 0.12, 0.08, 0.9)
		rect.size = Vector2(SLOT, SLOT)
		rect.position = Vector2(x, y)
		add_child(rect)
		_slot_rects.append(rect)
		_all_ui.append(rect)

		var lbl = Label.new()
		lbl.size = Vector2(SLOT, SLOT)
		lbl.position = Vector2(x, y)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 9)
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

func _hide_all():
	for node in _all_ui:
		node.visible = false
	for node in _craft_labels:
		node.visible = false

func _show_all():
	for node in _all_ui:
		node.visible = true
	for node in _craft_labels:
		node.visible = true

func _unhandled_input(event: InputEvent):
	if not (event is InputEventKey and event.pressed):
		# Also handle mouse clicks
		if not _visible:
			return
		if event is InputEventMouseButton and event.pressed:
			for i in range(_slot_rects.size()):
				if Rect2(_slot_rects[i].position, _slot_rects[i].size).has_point(event.position):
					InventoryManager.select_slot(i)
					return
			var recipes = CraftingManager.get_all_recipes()
			for j in range(_craft_labels.size()):
				if Rect2(_craft_labels[j].position, Vector2(220, 16)).has_point(event.position):
					var ri = j / 2
					if ri < recipes.size() and recipes[ri]["can_craft"]:
						CraftingManager.craft(recipes[ri]["id"])
					return
		return

	# Keyboard handling
	print("[Panel] key:", event.keycode)
	if event.keycode == KEY_TAB:
		_visible = not _visible
		if _visible: _show_all()
		else: _hide_all(); _clear_craft()
	elif event.keycode == KEY_C:
		_visible = true
		_show_all()

func _process(_delta):
	if not _visible:
		return
	_refresh()

func _refresh():
	# Inventory
	var sel = InventoryManager.selected_slot
	for i in range(InventoryManager.slots.size()):
		if i >= _slot_rects.size(): break
		var slot = InventoryManager.slots[i]
		if slot.is_empty():
			_slot_rects[i].color = Color(0.15, 0.12, 0.08, 0.9)
			_slot_labels[i].text = ""
		else:
			var c = _item_color(slot["item_id"])
			if i == sel: c = c.lightened(0.4)
			_slot_rects[i].color = Color(c.r, c.g, c.b, 0.85)
			_slot_labels[i].text = str(slot["amount"])

	# Crafting
	_clear_craft()
	var cx = (DisplayServer.window_get_size().x - PW) / 2
	var cy = (DisplayServer.window_get_size().y - PH) / 2
	var rx = cx + 280
	var ry = cy + 36
	var recipes = CraftingManager.get_all_recipes()

	for i in range(recipes.size()):
		var r = recipes[i]
		var can = r["can_craft"]
		var y = ry + i * 38

		var line = "%d. " % (i + 1)
		line += "[Can] " if can else "[No ] "
		line += r["name"]
		var nl = _craft_label(line, rx, y, 12, Color(0.3,1.0,0.3) if can else Color(0.5,0.5,0.5))

		var parts: Array = []
		for item_id in r["ingredients"]:
			var have = InventoryManager.count_item(item_id)
			var need = r["ingredients"][item_id]
			parts.append("%s:%d/%d" % [ItemDB.get_item_name(item_id), have, need])
		_craft_label("    " + ", ".join(parts), rx, y+15, 10, Color(0.6,0.6,0.6) if can else Color(0.4,0.4,0.4))

func _craft_label(txt: String, x: float, y: float, sz: int, col: Color) -> Label:
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

func _item_color(item_id: String) -> Color:
	if item_id == "berries": return Color(0.9, 0.2, 0.2)
	if item_id == "carrot": return Color(1.0, 0.5, 0.1)
	if item_id == "twigs": return Color(0.5, 0.3, 0.15)
	if item_id == "cut_grass": return Color(0.3, 0.6, 0.2)
	if item_id == "log": return Color(0.4, 0.25, 0.1)
	if item_id == "rocks": return Color(0.6, 0.6, 0.6)
	if item_id == "flint": return Color(0.5, 0.5, 0.55)
	if item_id == "gold_nugget": return Color(1.0, 0.85, 0.1)
	if item_id == "raw_meat": return Color(0.8, 0.15, 0.2)
	if item_id == "spear": return Color(0.7, 0.7, 0.85)
	if item_id == "axe": return Color(0.8, 0.7, 0.5)
	if item_id == "pickaxe": return Color(0.6, 0.65, 0.7)
	return Color.GRAY
