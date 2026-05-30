# Hotbar — bottom-center 5 slots, simplified
extends CanvasLayer

var _slot_bgs: Array = []
var _slot_sprites: Array = []
var _slot_labels: Array = []
var _border: ColorRect

const SLOTS: int = 5
const SIZE: int = 56
const GAP: int = 6

func _ready():
	var total_w = SLOTS * SIZE + (SLOTS + 1) * GAP
	var sx = (DisplayServer.window_get_size().x - total_w) / 2
	var sy = DisplayServer.window_get_size().y - SIZE - 18

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.04, 0.6)
	bg.size = Vector2(total_w, SIZE + 12)
	bg.position = Vector2(sx - GAP, sy - 6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Selection border
	_border = ColorRect.new()
	_border.color = Color(1, 0.85, 0.3, 0.5)
	_border.size = Vector2(SIZE + 4, SIZE + 4)
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_border)

	for i in range(SLOTS):
		var x = sx + GAP + i * (SIZE + GAP)

		var bg_rect = ColorRect.new()
		bg_rect.color = Color(0.10, 0.08, 0.06, 0.85)
		bg_rect.size = Vector2(SIZE, SIZE)
		bg_rect.position = Vector2(x, sy)
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_rect)
		_slot_bgs.append(bg_rect)

		var sprite = TextureRect.new()
		sprite.size = Vector2(SIZE - 6, SIZE - 6)
		sprite.position = Vector2(x + 3, sy + 3)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_slot_sprites.append(sprite)

		var lbl = Label.new()
		lbl.position = Vector2(x + SIZE - 16, sy + SIZE - 16)
		lbl.size = Vector2(16, 16)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		add_child(lbl)
		_slot_labels.append(lbl)

func _process(_delta):
	var sel = InventoryManager.selected_slot

	# Move border
	if sel < SLOTS:
		var i = sel
		var x = _slot_bgs[i].position.x - 2
		var y = _slot_bgs[i].position.y - 2
		_border.position = Vector2(x, y)

	for i in range(SLOTS):
		if i >= InventoryManager.slots.size(): break
		var slot = InventoryManager.slots[i]
		if slot.is_empty():
			_slot_bgs[i].color = Color(0.10, 0.08, 0.06, 0.85)
			_slot_sprites[i].texture = null
			_slot_labels[i].text = ""
		else:
			_slot_bgs[i].color = Color(0.14, 0.11, 0.08, 0.85)
			var tex_path = "res://assets/sprites/%s.png" % slot["item_id"]
			if ResourceLoader.exists(tex_path):
				_slot_sprites[i].texture = load(tex_path)
			else:
				_slot_sprites[i].texture = null
			_slot_labels[i].text = str(slot["amount"]) if slot["amount"] > 1 else ""

func _get_mode_text() -> String:
	var cams = get_tree().root.find_children("*", "Camera2D", true, false)
	if cams.size() > 0 and cams[0].has_method("is_strategic"):
		return "[STRATEGIC]" if cams[0].is_strategic() else "[ACTION]"
	return ""

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		for i in range(_slot_labels.size()):
			if i >= _slot_bgs.size(): break
			if Rect2(_slot_bgs[i].position, _slot_bgs[i].size).has_point(event.position):
				InventoryManager.select_slot(i)
				return
