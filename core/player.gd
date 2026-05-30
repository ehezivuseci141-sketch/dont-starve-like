extends CharacterBody2D

@export var move_speed: float = 200.0
var _last_direction: Vector2 = Vector2.DOWN
var _facing_right: bool = true
var _sprite: Sprite2D
var action_area: Area2D
var _attack_cooldown: float = 0.0
const ATTACK_CD: float = 0.4
var _attack_slash: float = 0.0

# Animation
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _anim_dir: String = "down"
var _moving: bool = false

func _ready():
	var shape = CircleShape2D.new(); shape.radius = 20.0
	var coll = CollisionShape2D.new(); coll.shape = shape; add_child(coll)

	action_area = Area2D.new()
	action_area.collision_layer = 2; action_area.collision_mask = 3
	var ashape = CircleShape2D.new(); ashape.radius = 55.0
	var acoll = CollisionShape2D.new(); acoll.shape = ashape
	action_area.add_child(acoll); add_child(action_area)

	_sprite = Sprite2D.new(); _sprite.position = Vector2(0, -8); add_child(_sprite)
	_sprite_load("player_down.png")
	queue_redraw()

func _sprite_load(path: String):
	var full = "res://assets/sprites/" + path
	if ResourceLoader.exists(full): _sprite.texture = load(full)

func _draw():
	if _sprite.texture == null:
		draw_circle(Vector2.ZERO, 24.0, Color(0.25, 0.70, 0.30))
	if _attack_slash > 0:
		var d = _last_direction; if d == Vector2.ZERO: d = Vector2(1 if _facing_right else -1, 0)
		d = d.normalized()
		var a = _attack_slash / 0.15
		draw_arc(d * 18, 35.0, d.angle() - 0.5, d.angle() + 0.5, 8, Color(1,1,1,a*0.7), 3.0)

func _physics_process(delta: float):
	var dir = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	_moving = dir != Vector2.ZERO

	if _moving:
		velocity = dir.normalized() * move_speed; _last_direction = dir
		if dir.x != 0: _facing_right = dir.x > 0
		# Animation direction
		var ax = abs(dir.x); var ay = abs(dir.y)
		if ay > ax * 2: _anim_dir = "up"
		elif ax > ay * 2: _anim_dir = "side"
		elif dir.y < 0: _anim_dir = "up_side"
		else: _anim_dir = "down_side"
		# Cycle frames
		_anim_timer += delta
		if _anim_timer > 0.25: _anim_timer = 0; _anim_frame = (_anim_frame + 1) % 4
		_try_walk_frame()
	else:
		velocity = Vector2.ZERO
		_anim_timer = 0; _anim_frame = 0
		_try_stand_frame()

	if _sprite: _sprite.scale.x = -1 if _facing_right else 1
	_attack_cooldown = maxf(0, _attack_cooldown - delta)
	if _attack_slash > 0: _attack_slash -= delta
	move_and_slide(); queue_redraw()

func _try_walk_frame():
	var path = "player_%s_walk%d.png" % [_anim_dir, _anim_frame + 1]
	if not ResourceLoader.exists("res://assets/sprites/" + path):
		path = "player_%s.png" % _anim_dir  # fallback: standing
	_sprite_load(path)

func _try_stand_frame():
	var path = "player_%s.png" % _anim_dir
	if not ResourceLoader.exists("res://assets/sprites/" + path):
		path = "player_down.png"
	_sprite_load(path)

func _input(event: InputEvent):
	if event.is_action_pressed("interact"): _try_interact()
	if event.is_action_pressed("attack"): _do_attack()
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		SurvivalManager.eat(InventoryManager.get_selected_item()["item_id"])
		InventoryManager.remove_item(InventoryManager.get_selected_item()["item_id"], 1)

func _do_attack():
	if _attack_cooldown > 0: return
	_attack_cooldown = ATTACK_CD; _attack_slash = 0.15
	var dmg = 3.0; var sel = InventoryManager.get_selected_item()
	if not sel.is_empty(): dmg = ItemDB.get_item(sel["item_id"]).get("damage", 3.0)
	var atk = _last_direction; if atk == Vector2.ZERO: atk = Vector2(1 if _facing_right else -1, 0)
	if action_area:
		for body in action_area.get_overlapping_bodies():
			if body.is_in_group("Enemy") and atk.dot(body.global_position - global_position) > 0.3:
				if body.has_method("take_damage"): body.take_damage(dmg)

func _try_interact():
	if action_area:
		for area in action_area.get_overlapping_areas():
			if area.is_in_group("Pickable") and area.has_method("pick_up"):
				area.pick_up(); break
