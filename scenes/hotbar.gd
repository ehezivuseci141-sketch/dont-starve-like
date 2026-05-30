# Hotbar — bottom-center 5 slots + tooltip
extends CanvasLayer

var _slot_bgs: Array = []
var _slot_sprites: Array = []
var _slot_labels: Array = []
var _border: ColorRect
var _tip_bg: ColorRect
var _tip_lbl: Label

const SLOTS: int = 5; const SIZE: int = 56; const GAP: int = 6

func _ready():
	var total_w = SLOTS * SIZE + (SLOTS + 1) * GAP
	var sx = (DisplayServer.window_get_size().x - total_w) / 2
	var sy = DisplayServer.window_get_size().y - SIZE - 18

	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.04, 0.6)
	bg.size = Vector2(total_w, SIZE + 12); bg.position = Vector2(sx - GAP, sy - 6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(bg)

	_border = ColorRect.new(); _border.color = Color(1, 0.85, 0.3, 0.5)
	_border.size = Vector2(SIZE + 4, SIZE + 4)
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(_border)

	for i in range(SLOTS):
		var x = sx + GAP + i * (SIZE + GAP)
		var rect = ColorRect.new(); rect.color = Color(0.10, 0.08, 0.06, 0.85)
		rect.size = Vector2(SIZE, SIZE); rect.position = Vector2(x, sy)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(rect); _slot_bgs.append(rect)

		var sprite = TextureRect.new(); sprite.size = Vector2(SIZE-6, SIZE-6); sprite.position = Vector2(x+3, sy+3)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(sprite); _slot_sprites.append(sprite)

		var lbl = Label.new(); lbl.position = Vector2(x+SIZE-16, sy+SIZE-16); lbl.size = Vector2(16,16)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_font_size_override("font_size", 9); lbl.add_theme_color_override("font_color", Color.WHITE)
		add_child(lbl); _slot_labels.append(lbl)

	# Tooltip
	_tip_bg = ColorRect.new(); _tip_bg.color = Color(0.05, 0.05, 0.08, 0.9)
	_tip_bg.visible = false; _tip_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(_tip_bg)
	_tip_lbl = Label.new(); _tip_lbl.add_theme_font_size_override("font_size", 11)
	_tip_lbl.add_theme_color_override("font_color", Color.WHITE); _tip_lbl.visible = false; add_child(_tip_lbl)

func _process(_delta):
	var sel = InventoryManager.selected_slot
	if sel < SLOTS: _border.position = _slot_bgs[sel].position - Vector2(2, 2)

	# Slots
	for i in range(SLOTS):
		if i >= InventoryManager.slots.size(): break
		var slot = InventoryManager.slots[i]
		if slot.is_empty():
			_slot_bgs[i].color = Color(0.10, 0.08, 0.06, 0.85)
			_slot_sprites[i].texture = null; _slot_labels[i].text = ""
		else:
			_slot_bgs[i].color = Color(0.14, 0.11, 0.08, 0.85)
			var p = "res://assets/sprites/%s.png" % slot["item_id"]
			_slot_sprites[i].texture = load(p) if ResourceLoader.exists(p) else null
			_slot_labels[i].text = str(slot["amount"]) if slot["amount"] > 1 else ""

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
					_tip_lbl.text = txt; _tip_lbl.position = mouse + Vector2(16, 16)
					_tip_bg.position = mouse + Vector2(12, 12)
					_tip_bg.size = _tip_lbl.get_minimum_size() + Vector2(8, 8)
					_tip_bg.visible = true; _tip_lbl.visible = true
					found = true
				break
	if not found: _tip_bg.visible = false; _tip_lbl.visible = false

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		for i in range(_slot_labels.size()):
			if i >= _slot_bgs.size(): break
			if Rect2(_slot_bgs[i].position, _slot_bgs[i].size).has_point(event.position):
				InventoryManager.select_slot(i); return
