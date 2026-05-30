# Pickable item with sprite texture
extends Area2D

var item_id: String = "twigs"
var item_color: Color = Color.BROWN
var _picked: bool = false

func _ready():
	add_to_group("Pickable")

	# Collision
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)

	# Sprite
	var sprite = Sprite2D.new()
	var tex_path = "res://assets/sprites/%s.png" % item_id
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	sprite.scale = Vector2(1.0, 1.0)
	add_child(sprite)

	# Name label (use a Label node)
	var label = Label.new()
	label.text = ItemDB.get_item_name(item_id)
	label.position = Vector2(-16, -24)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(32, 14)
	add_child(label)

func pick_up():
	if _picked: return
	var p = InventoryManager.add_item(item_id, 1)
	if p > 0:
		FX.show(get_parent(), global_position, "+1 %s" % ItemDB.get_item_name(item_id), Color(1, 1, 1))
		_picked = true
		queue_free()

func set_item(item: String, count: int = 1):
	item_id = item
	# Reload sprite
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		var tex_path = "res://assets/sprites/%s.png" % item_id
		if ResourceLoader.exists(tex_path):
			sprite.texture = load(tex_path)
