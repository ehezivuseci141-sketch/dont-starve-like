# Hotbar - bottom bar with item sprites + selection border
extends CanvasLayer

var _slot_bgs: Array = []
var _slot_sprites: Array = []
var _slot_labels: Array = []
var _border: ColorRect
var _sel_label: Label

const SLOTS: int = 5
const SIZE: int = 56
const GAP: int = 6

func _ready():
	var total_w = SLOTS * SIZE + (SLOTS + 1) * GAP
	var sx = (DisplayServer.window_get_size().x - total_w) / 2
	var sy = DisplayServer.window_get_size().y - SIZE - 24

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05, 0.7)
	bg.size = Vector2(total_w, SIZE + 16)
	bg.position = Vector2(sx - GAP, sy - 8)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Selection border
	_border = ColorRect.new()
	_border.color = Color(1, 0.85, 0.3, 0.6)
	_border.size = Vector2(SIZE + 4, SIZE + 4)
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_border)

	for i in range(SLOTS):
		var x = sx + GAP + i * (SIZE + GAP)

		var bg_rect = ColorRect.new()
		bg_rect.color = Color(0.12, 0.1, 0.07, 0.9)
		bg_rect.size = Vector2(SIZE, SIZE)
		bg_rect.position = Vector2(x, sy)
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_rect)
		_slot_bgs.append(bg_rect)

		var sprite = TextureRect.new()
		sprite.size = Vector2(SIZE - 8, SIZE - 8)
		sprite.position = Vector2(x + 4, sy + 4)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_slot_sprites.append(sprite)

		var label = Label.new()
		label.position = Vector2(x + SIZE - 16, sy + SIZE - 16)
		label.size = Vector2(16, 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", Color.WHITE)
		add_child(label)
		_slot_labels.append(label)

	# Selected item name
	_sel_label = Label.new()
	_sel_label.position = Vector2(sx, sy - 20)
	_sel_label.size = Vector2(total_w, 16)
	_sel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sel_label.add_theme_font_size_override("font_size", 12)
	_sel_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	add_child(_sel_label)

func _process(_delta):
	var sel = InventoryManager.selected_slot

	# Move border
	if sel < SLOTS:
		var i = sel
		var x = _slot_bgs[i].position.x - 2
		var y = _slot_bgs[i].position.y - 2
		_border.position = Vector2(x, y)

	# Update slots
	for i in range(SLOTS):
		if i >= InventoryManager.slots.size():
			break
		var slot = InventoryManager.slots[i]
		if slot.is_empty():
			_slot_bgs[i].color = Color(0.12, 0.1, 0.07, 0.9)
			_slot_sprites[i].texture = null
			_slot_labels[i].text = ""
		else:
			_slot_bgs[i].color = Color(0.18, 0.15, 0.1, 0.9)
			var tex_path = "res://assets/sprites/%s.png" % slot["item_id"]
			if ResourceLoader.exists(tex_path):
				_slot_sprites[i].texture = load(tex_path)
			else:
				_slot_sprites[i].texture = null
			_slot_labels[i].text = str(slot["amount"]) if slot["amount"] > 1 else ""

	# Label
	if sel < InventoryManager.slots.size():
		var s = InventoryManager.slots[sel]
		if not s.is_empty():
			var dur_text = ""
			if s.has("dur"):
				dur_text = "  Dur:%d" % s["dur"]
			_sel_label.text = "%s x%d%s  [F]Eat  [Q]Drop  [B]Place  %s" % [ItemDB.get_item_name(s["item_id"]), s["amount"], dur_text, _get_mode_text()]
		else:
			var mode = _get_mode_text()
			_sel_label.text = "Empty  [E]Interact  [B]Place  " + mode

func _get_mode_text() -> String:
	var cams = get_tree().root.find_children("*", "Camera2D", true, false)
	if cams.size() > 0 and cams[0].has_method("is_strategic"):
		return "[STRATEGIC]" if cams[0].is_strategic() else "[ACTION]"
	return ""

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		for i in range(_slot_labels.size()):
			if i >= _slot_bgs.size(): break
			var r = Rect2(_slot_bgs[i].position, _slot_bgs[i].size)
			if r.has_point(event.position):
				InventoryManager.select_slot(i)
				return
