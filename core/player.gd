# Player controller — movement, animation, combat, interaction
extends CharacterBody2D
class_name Player

@export var move_speed: float = 200.0

var _last_direction: Vector2 = Vector2.DOWN
var _facing_right: bool = true
var _attack_cooldown: float = 0.0
var _attack_slash_timer: float = 0.0
const ATTACK_CD: float = 0.4
var _move_target: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _camera: Camera2D

var action_area: Area2D
var _sprite: Sprite2D
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _is_moving: bool = false
var _anim_dir: String = "down"

func _ready():
	add_to_group("Player")

	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -4)
	add_child(_sprite)
	_set_sprite_texture("player.png")

	var shape = CircleShape2D.new()
	shape.radius = 20.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)

	action_area = Area2D.new()
	action_area.collision_layer = 2
	action_area.collision_mask = 3
	var area_shape = CircleShape2D.new()
	area_shape.radius = 55.0
	var area_coll = CollisionShape2D.new()
	area_coll.shape = area_shape
	action_area.add_child(area_coll)
	add_child(action_area)

func _set_sprite_texture(path: String):
	if ResourceLoader.exists("res://assets/sprites/" + path):
		_sprite.texture = load("res://assets/sprites/" + path)
	elif ResourceLoader.exists("res://assets/sprites/player.png"):
		_sprite.texture = load("res://assets/sprites/player.png")

func _try_set_anim(base: String, frame: int = -1):
	if frame < 0:
		# Standing frame
		var path = base + ".png"
		if ResourceLoader.exists("res://assets/sprites/" + path):
			_set_sprite_texture(path)
			return true
	return false

func _get_anim(base: String, frame: int) -> bool:
	var path = base + "_walk%d.png" % (frame + 1)
	if ResourceLoader.exists("res://assets/sprites/" + path):
		_set_sprite_texture(path)
		return true
	return false

func _draw():
	# Direction indicator
	var d = _last_direction
	if d == Vector2.ZERO:
		d = Vector2(1 if _facing_right else -1, 0)
	d = d.normalized()
	var tip = d * 22 - Vector2(0, 16)
	var perp = Vector2(-d.y, d.x)
	var left = d * 12 + perp * 7 - Vector2(0, 16)
	var right = d * 12 - perp * 7 - Vector2(0, 16)
	var pts = PackedVector2Array([tip, left, right])
	draw_polygon(pts, PackedColorArray([Color(1,1,1,0.5), Color(1,1,1,0.5), Color(1,1,1,0.5)]))

	# Attack slash
	if _attack_slash_timer > 0:
		var alpha = _attack_slash_timer / 0.15
		draw_arc(d * 18, 35.0, d.angle() - 0.5, d.angle() + 0.5, 8, Color(1,1,1,alpha*0.7), 3.0)

func _physics_process(delta: float):
	# Find camera if not set
	if _camera == null:
		var cams = get_tree().root.find_children("*", "Camera2D", true, false)
		if cams.size() > 0: _camera = cams[0]

	var is_strategic = _camera != null and _camera.has_method("is_strategic") and _camera.is_strategic()

	if is_strategic:
		# === STRATEGIC MODE: click-to-move ===
		if _has_target:
			var to_target = _move_target - global_position
			var dist = to_target.length()
			if dist < 15:
				_has_target = false
				velocity = Vector2.ZERO
				_is_moving = false
			else:
				var dir = to_target.normalized()
				velocity = dir * move_speed * 1.5
				_is_moving = true
				_last_direction = dir
				if dir.x != 0: _facing_right = dir.x > 0
				if abs(dir.y) > abs(dir.x):
					_anim_dir = "up" if dir.y < 0 else "down"
				else:
					_anim_dir = "side"
				_anim_timer += delta
				if _anim_timer > 0.15:
					_anim_timer = 0.0
					_anim_frame = (_anim_frame + 1) % 3
					var prefix = "player_" + _anim_dir
					if not _get_anim(prefix, _anim_frame):
						_get_anim("player", _anim_frame)
		else:
			velocity = Vector2.ZERO
			_is_moving = false
	else:
		# === ACTION MODE: WASD ===
		var dir = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		_is_moving = dir != Vector2.ZERO
		_has_target = false  # clear strategic target

		if _is_moving:
			velocity = dir.normalized() * move_speed
			_last_direction = dir
			if dir.x != 0: _facing_right = dir.x > 0
			if abs(dir.y) > abs(dir.x):
				_anim_dir = "up" if dir.y < 0 else "down"
			else:
				_anim_dir = "side"
			_anim_timer += delta
			if _anim_timer > 0.15:
				_anim_timer = 0.0
				_anim_frame = (_anim_frame + 1) % 3
				var prefix = "player_" + _anim_dir
				if not _get_anim(prefix, _anim_frame):
					_get_anim("player", _anim_frame)
		else:
			velocity = Vector2.ZERO
			_anim_timer = 0.0
			_anim_frame = 0
			var prefix = "player_" + _anim_dir
			if not _try_set_anim(prefix):
				_try_set_anim("player")

	# Mirror sprite for left-facing
	if _sprite:
		_sprite.scale.x = 1 if _facing_right else -1

	move_and_slide()

	if _is_moving:
		Signals.player_moved.emit(global_position, dir)

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _attack_slash_timer > 0:
		_attack_slash_timer -= delta
	queue_redraw()

func _input(event: InputEvent):
	# Mouse click handling
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var is_strategic = _camera != null and _camera.has_method("is_strategic") and _camera.is_strategic()
			if is_strategic:
				# STRATEGIC: click to move
				_move_target = get_global_mouse_position()
				_has_target = true
			else:
				# ACTION: click to attack
				_do_attack()

	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("attack"):
		_do_attack()
	if event.is_action_pressed("place"):
		_place_item()

	if event is InputEventKey and event.pressed:
		var key_map = {
			KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3, KEY_5: 4,
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
	if _attack_cooldown > 0: return
	_attack_cooldown = ATTACK_CD
	_attack_slash_timer = 0.15

	# Flash attack frame
	_set_sprite_texture("player_attack.png")

	var dmg = 3.0
	var sel = InventoryManager.get_selected_item()
	if not sel.is_empty():
		var item = ItemDB.get_item(sel["item_id"])
		dmg = item.get("damage", 3.0)

	var atk_dir = _last_direction
	if atk_dir == Vector2.ZERO:
		atk_dir = Vector2(1 if _facing_right else -1, 0)

	var enemies = []
	if action_area:
		for body in action_area.get_overlapping_bodies():
			if body.is_in_group("Enemy"):
				var to_enemy = body.global_position - global_position
				if atk_dir.dot(to_enemy) > 0.6:
					if not enemies.has(body):
						enemies.append(body)

	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(dmg)
			if not sel.is_empty() and sel.has("dur"):
				sel["dur"] = sel.get("dur", 0) - 1
				if sel["dur"] <= 0:
					InventoryManager.slots[InventoryManager.selected_slot] = {}

func _place_item():
	var sel = InventoryManager.get_selected_item()
	if sel.is_empty(): return
	if sel["item_id"] == "campfire":
		var cf_script = load("res://scenes/campfire.gd")
		var cf = Node2D.new()
		cf.position = global_position + (_last_direction.normalized() * 50 if _last_direction != Vector2.ZERO else Vector2(50, 0))
		cf.set_script(cf_script)
		get_parent().add_child(cf)
		InventoryManager.remove_item("campfire", 1)

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
