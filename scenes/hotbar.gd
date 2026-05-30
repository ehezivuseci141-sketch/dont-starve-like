# Hotbar - bottom inventory bar showing 5 slots
extends CanvasLayer

var _slot_bgs: Array = []
var _slot_labels: Array = []
const VISIBLE_SLOTS: int = 5
const SLOT_SIZE: int = 56

func _ready():
	# Create hotbar background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05, 0.7)
	var total_w = VISIBLE_SLOTS * SLOT_SIZE + (VISIBLE_SLOTS + 1) * 6
	bg.size = Vector2(total_w, SLOT_SIZE + 12)
	bg.position = Vector2(
		(DisplayServer.window_get_size().x - total_w) / 2,
		DisplayServer.window_get_size().y - SLOT_SIZE - 22
	)
	add_child(bg)

	# Create slot backgrounds
	for i in range(VISIBLE_SLOTS):
		var slot_bg = ColorRect.new()
		slot_bg.color = Color(0.15, 0.12, 0.08, 0.9)
		slot_bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_bg.position = bg.position + Vector2(6 + i * (SLOT_SIZE + 6), 6)
		add_child(slot_bg)
		_slot_bgs.append(slot_bg)

		# Item count label
		var label = Label.new()
		label.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		label.position = slot_bg.position
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		add_child(label)
		_slot_labels.append(label)

	# Selection highlight
	var highlight = ColorRect.new()
	highlight.color = Color(1.0, 0.85, 0.3, 0.5)
	highlight.size = Vector2(SLOT_SIZE + 4, SLOT_SIZE + 4)
	highlight.position = bg.position + Vector2(4, 4)
	highlight.name = "Highlight"
	add_child(highlight)

	# Selected slot indicator text
	var sel_label = Label.new()
	sel_label.position = bg.position + Vector2(0, -18)
	sel_label.size = Vector2(total_w, 16)
	sel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sel_label.add_theme_font_size_override("font_size", 12)
	sel_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	sel_label.name = "SelLabel"
	add_child(sel_label)

func _process(_delta):
	var highlight = get_node_or_null("Highlight")
	var sel_label = get_node_or_null("SelLabel")

	var sel = InventoryManager.selected_slot

	# Update highlight position
	if highlight and sel < VISIBLE_SLOTS:
		var slot_bg = _slot_bgs[sel]
		highlight.position = slot_bg.position - Vector2(2, 2)

	# Update each slot
	for i in range(VISIBLE_SLOTS):
		if i >= _slot_labels.size():
			break
		var slot_data = {}
		if i < InventoryManager.slots.size():
			slot_data = InventoryManager.slots[i]

		if slot_data.is_empty():
			_slot_bgs[i].color = Color(0.15, 0.12, 0.08, 0.9)
			_slot_labels[i].text = ""
		else:
			# Color the slot by item type
			var item = ItemDB.get_item(slot_data["item_id"])
			var c = _item_color(slot_data["item_id"])
			_slot_bgs[i].color = Color(c.r, c.g, c.b, 0.7)
			_slot_labels[i].text = str(slot_data["amount"])

	# Selected item name
	if sel_label and sel >= 0 and sel < InventoryManager.slots.size():
		var slot = InventoryManager.slots[sel]
		if not slot.is_empty():
			sel_label.text = "%s x%d  [F]Eat  [Q]Drop" % [
				ItemDB.get_item_name(slot["item_id"]),
				slot["amount"]
			]
		else:
			sel_label.text = "Empty  [E]Interact"

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
	return Color.GRAY
