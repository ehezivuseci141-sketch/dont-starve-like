# Pickable world item
extends Area2D
class_name PickableItem

@export var item_id: String = "twigs"
@export var amount: int = 1

var _picked_up: bool = false

func _ready():
	add_to_group("Pickable")
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)
	queue_redraw()

func _draw():
	var color = _get_item_color()
	draw_circle(Vector2.ZERO, 16.0, color)
	draw_arc(Vector2.ZERO, 16.0, 0, TAU, 16, color.darkened(0.3), 1.5)

func _get_item_color() -> Color:
	if item_id == "berries": return Color(0.85, 0.1, 0.2)
	if item_id == "carrot": return Color(1.0, 0.5, 0.1)
	if item_id == "twigs": return Color(0.4, 0.25, 0.1)
	if item_id == "cut_grass": return Color(0.3, 0.7, 0.2)
	if item_id == "log": return Color(0.35, 0.2, 0.05)
	if item_id == "rocks": return Color(0.55, 0.55, 0.5)
	if item_id == "flint": return Color(0.4, 0.4, 0.45)
	if item_id == "gold_nugget": return Color(1.0, 0.85, 0.1)
	if item_id == "raw_meat": return Color(0.7, 0.15, 0.2)
	return Color.MAGENTA

func pick_up():
	if _picked_up:
		return
	var picked = InventoryManager.add_item(item_id, amount)
	if picked > 0:
		print("[Pickup] +%d %s" % [picked, ItemDB.get_item_name(item_id)])
		_picked_up = true
		queue_free()

func set_item(item: String, count: int = 1):
	item_id = item
	amount = count
	queue_redraw()
