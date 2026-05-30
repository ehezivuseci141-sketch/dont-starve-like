# Player controller - movement, interaction, combat
extends CharacterBody2D
class_name Player

@export var move_speed: float = 200.0

var current_action: int = 0
var _last_direction: Vector2 = Vector2.DOWN
var _facing_right: bool = true
var _attack_cooldown: float = 0.0
const ATTACK_CD: float = 0.4

var action_area: Area2D
var _attack_slash_timer: float = 0.0

func _ready():
	add_to_group("Player")

	var shape = CircleShape2D.new()
	shape.radius = 28.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)

	action_area = Area2D.new()
	action_area.collision_layer = 2
	action_area.collision_mask = 2
	var area_shape = CircleShape2D.new()
	area_shape.radius = 55.0
	var area_coll = CollisionShape2D.new()
	area_coll.shape = area_shape
	action_area.add_child(area_coll)
	add_child(action_area)

	queue_redraw()

func _draw():
	# Body
	draw_circle(Vector2.ZERO, 28.0, Color(0.25, 0.70, 0.30))
	draw_arc(Vector2.ZERO, 28.0, 0, TAU, 32, Color(0.1, 0.35, 0.12), 2.0)

	# Eyes
	var eye_dir = 1.0 if _facing_right else -1.0
	draw_circle(Vector2(eye_dir * 8, -6), 5.0, Color.WHITE)
	draw_circle(Vector2(eye_dir * 9, -6), 2.5, Color.BLACK)

	# Attack slash effect
	if _attack_slash_timer > 0:
		var alpha = _attack_slash_timer / 0.2
		var slash_color = Color(1.0, 1.0, 1.0, alpha * 0.7)
		draw_arc(Vector2.ZERO, 40.0, -0.5, 0.5, 8, slash_color, 4.0)

func _physics_process(delta: float):
	var dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		velocity = dir.normalized() * move_speed
		_last_direction = dir
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if dir != Vector2.ZERO:
		Signals.player_moved.emit(global_position, dir)

	if dir.x != 0:
		var new_facing = dir.x > 0
		if new_facing != _facing_right:
			_facing_right = new_facing
			queue_redraw()

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _attack_slash_timer > 0:
		_attack_slash_timer -= delta
		queue_redraw()

func _input(event: InputEvent):
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("open_inventory"):
		print("[Bag] items:", InventoryManager.get_all_item_ids())
	if event.is_action_pressed("open_crafting"):
		var recipes = CraftingManager.get_all_recipes()
		print("[Craft] recipes:", recipes.size())
	if event.is_action_pressed("attack"):
		_do_attack()

	if event is InputEventKey and event.pressed:
		var key_map = {
			KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3, KEY_5: 4,
			KEY_6: 5, KEY_7: 6, KEY_8: 7, KEY_9: 8, KEY_0: 9,
		}
		if event.keycode in key_map:
			InventoryManager.select_slot(key_map[event.keycode])
		if event.keycode == KEY_Q:
			InventoryManager.drop_item(InventoryManager.selected_slot, global_position)
		if event.keycode == KEY_F:
			var item = InventoryManager.get_selected_item()
			if not item.is_empty():
				if ItemDB.is_eatable(item["item_id"]):
					SurvivalManager.eat(item["item_id"])
					InventoryManager.remove_item(item["item_id"], 1)

func _do_attack():
	if _attack_cooldown > 0:
		return
	_attack_cooldown = ATTACK_CD
	_attack_slash_timer = 0.15
	queue_redraw()

	# Calculate damage
	var dmg = 3.0  # Fist damage
	var sel = InventoryManager.get_selected_item()
	if not sel.is_empty():
		var item = ItemDB.get_item(sel["item_id"])
		dmg = item.get("damage", 3.0)

	# Find enemies in pickup range
	var enemies = []
	if action_area:
		for area in action_area.get_overlapping_areas():
			var parent = area.get_parent()
			if parent and parent.is_in_group("Enemy"):
				if not enemies.has(parent):
					enemies.append(parent)

	# Attack them
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(dmg)
			print("[Combat] Hit enemy for %.0f damage!" % dmg)

	if enemies.is_empty():
		print("[Combat] Swung at nothing...")

func _try_interact():
	if action_area:
		for area in action_area.get_overlapping_areas():
			if area.is_in_group("Pickable") and area.has_method("pick_up"):
				area.pick_up()
				break

func serialize() -> Dictionary:
	return {"position_x": global_position.x, "position_y": global_position.y}

func deserialize(data: Dictionary):
	if data.has("position_x"):
		global_position = Vector2(data["position_x"], data["position_y"])
