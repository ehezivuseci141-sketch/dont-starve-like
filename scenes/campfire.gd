# Campfire - placed in world, burns with fuel, protects at night
extends Node2D

var fuel: float = 60.0  # seconds of burn time
var lit: bool = true
var light_radius: float = 180.0
var _burn_timer: float = 0.0

func _ready():
	add_to_group("Campfire")
	queue_redraw()

func _draw():
	if not lit:
		return
	# Fire glow
	draw_circle(Vector2.ZERO, 30.0, Color(1.0, 0.5, 0.1, 0.3))
	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.6, 0.1, 0.6))
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.9, 0.3, 0.9))
	# Fuel bar
	var pct = fuel / 60.0
	draw_rect(Rect2(-20, -40, 40, 4), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(-20, -40, 40 * pct, 4), Color(1, 0.5, 0.1))

func _process(delta: float):
	if not lit: return
	fuel -= delta
	if fuel <= 0:
		_extinguish()
	queue_redraw()

	# Add fuel from nearby logs (simplified: player drops log near fire)
	if fuel < 30:
		for area in _find_nearby_logs():
			if area.is_in_group("Pickable") and area.has_method("pick_up"):
				if area.get("item_id") == "log":
					fuel += 30
					area.queue_free()
					break

func _extinguish():
	lit = false
	print("[Campfire] Burned out!")
	queue_redraw()
	# Remove after a moment
	await get_tree().create_timer(2.0).timeout
	queue_free()

func is_near(pos: Vector2) -> bool:
	return lit and global_position.distance_to(pos) < light_radius

func _find_nearby_logs() -> Array:
	var nearby = []
	for node in get_tree().root.find_children("*", "Area2D", true, false):
		if node.is_in_group("Pickable"):
			if global_position.distance_to(node.global_position) < 50:
				if node.get("item_id") == "log":
					nearby.append(node)
	return nearby
