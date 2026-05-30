# Simple pickable - draws colored circle, E to pick up
extends Area2D

var item_id: String = "twigs"
var item_color: Color = Color.BROWN
var _picked: bool = false

func _ready():
	add_to_group("Pickable")
	var shape = CircleShape2D.new()
	shape.radius = 25.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, 20.0, item_color)
	draw_arc(Vector2.ZERO, 20.0, 0, TAU, 16, item_color.darkened(0.4), 2.0)
	# Draw item name above
	draw_string(ThemeDB.fallback_font, Vector2(-20, -28), ItemDB.get_item_name(item_id),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func pick_up():
	if _picked:
		return
	var p = InventoryManager.add_item(item_id, 1)
	if p > 0:
		print("[Pickup] +1 %s" % ItemDB.get_item_name(item_id))
		_picked = true
		queue_free()
