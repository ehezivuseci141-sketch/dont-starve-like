# Crafting sidebar - appears on the LEFT side, press C
extends CanvasLayer

var _visible: bool = false
var _bg: ColorRect
var _labels: Array = []
var _title: Label

const PANEL_W: int = 220
const LINE_H: int = 18

func _ready():
	_bg = ColorRect.new()
	_bg.color = Color(0.06, 0.06, 0.08, 0.85)
	_bg.position = Vector2(0, 0)
	_bg.size = Vector2(PANEL_W, DisplayServer.window_get_size().y)
	_bg.visible = false
	add_child(_bg)

	_title = Label.new()
	_title.text = "Crafting [C]"
	_title.position = Vector2(8, 6)
	_title.add_theme_font_size_override("font_size", 15)
	_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	add_child(_title)

func _input(event: InputEvent):
	if event.is_action_pressed("open_crafting"):
		_visible = not _visible
		_bg.visible = _visible
		_title.visible = _visible
		for label in _labels:
			label.visible = _visible
		if _visible:
			_refresh()

	if not _visible:
		return

	# Craft with number keys
	var craft_keys = {KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3, KEY_5: 4}
	if event is InputEventKey and event.pressed:
		if event.keycode in craft_keys:
			var recipes = CraftingManager.get_all_recipes()
			var idx = craft_keys[event.keycode]
			if idx < recipes.size() and recipes[idx]["can_craft"]:
				CraftingManager.craft(recipes[idx]["id"])
				_refresh()

func _refresh():
	for label in _labels:
		label.queue_free()
	_labels.clear()

	var recipes = CraftingManager.get_all_recipes()
	var y = 32

	for i in range(recipes.size()):
		var r = recipes[i]
		var can = r["can_craft"]
		var line = "%d. %s" % [i + 1, r["name"]]
		var txt = "[Can] " + line if can else "[No  ] " + line

		var label = _make_label(txt, Vector2(8, y), 12,
			Color(0.3, 1.0, 0.3) if can else Color(0.5, 0.5, 0.5))
		add_child(label)
		_labels.append(label)
		y += LINE_H

		# Ingredient line
		var parts: Array = []
		for item_id in r["ingredients"]:
			var have = InventoryManager.count_item(item_id)
			var need = r["ingredients"][item_id]
			parts.append("%s:%d/%d" % [ItemDB.get_item_name(item_id), have, need])
		var ing = _make_label("    " + ", ".join(parts), Vector2(8, y), 10,
			Color(0.7, 0.7, 0.7))
		add_child(ing)
		_labels.append(ing)
		y += LINE_H

func _make_label(txt: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l = Label.new()
	l.text = txt
	l.position = pos
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l
