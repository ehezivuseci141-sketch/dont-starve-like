extends CharacterBody2D

@export var move_speed: float = 200.0
var _last_direction: Vector2 = Vector2.DOWN
var _facing_right: bool = true
var _sprite: Sprite2D
var action_area: Area2D
var _attack_cooldown: float = 0.0
const ATTACK_CD: float = 0.4
var _attack_slash: float = 0.0

# Strategic mode
var _camera: Camera2D
var _move_target: Vector2
var _has_target: bool = false

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

	_sprite = Sprite2D.new(); _sprite.position = Vector2(0, -8)
	_sprite.scale = Vector2(0.7, 0.7); add_child(_sprite)
	_sprite_load("player_down.png")
	queue_redraw()

func _sprite_load(path: String):
	var full = "res://assets/sprites/" + path
	if ResourceLoader.exists(full):
		_sprite.texture = load(full)
		# Normalize scale based on texture size (target: ~64px)
		if _sprite.texture:
			var ts = _sprite.texture.get_size()
			var s = 64.0 / max(ts.x, ts.y)
			_sprite.scale.y = s
			_sprite.scale.x = -s if _facing_right else s

func _draw():
	if _sprite.texture == null:
		draw_circle(Vector2.ZERO, 24.0, Color(0.25, 0.70, 0.30))
	if _attack_slash > 0:
		var d = _last_direction; if d == Vector2.ZERO: d = Vector2(1 if _facing_right else -1, 0)
		d = d.normalized(); var a = _attack_slash / 0.15
		draw_arc(d * 18, 35.0, d.angle() - 0.5, d.angle() + 0.5, 8, Color(1,1,1,a*0.7), 3.0)

func _physics_process(delta: float):
	if _camera == null:
		var cams = get_tree().root.find_children("*", "Camera2D", true, false)
		if cams.size() > 0: _camera = cams[0]

	var is_strat = _camera != null and _camera.has_method("is_strategic") and _camera.is_strategic()

	if is_strat:
		if _has_target:
			var to = _move_target - global_position
			if to.length() < 15: _has_target = false; _moving = false; velocity = Vector2.ZERO
			else: _moving = true; velocity = to.normalized() * move_speed * 1.5; _last_direction = to.normalized(); if to.x != 0: _facing_right = to.x > 0
		else: _moving = false; velocity = Vector2.ZERO
	else:
		_has_target = false
		var dx = (1 if Input.is_action_pressed("move_right") else 0) - (1 if Input.is_action_pressed("move_left") else 0)
		var dy = (1 if Input.is_action_pressed("move_down") else 0) - (1 if Input.is_action_pressed("move_up") else 0)
		var dir = Vector2(dx, dy)
		_moving = dir != Vector2.ZERO
		if _moving: velocity = dir.normalized() * move_speed; _last_direction = dir.normalized(); if dir.x != 0: _facing_right = dir.x > 0
		else: velocity = Vector2.ZERO

	# Animation
	if _moving:
		var ax2 = abs(_last_direction.x); var ay2 = abs(_last_direction.y)
		if ay2 > ax2 * 2: _anim_dir = "up"
		elif ax2 > ay2 * 2: _anim_dir = "side"
		elif _last_direction.y < 0: _anim_dir = "up_side"
		else: _anim_dir = "down_side"
		_anim_timer += delta
		if _anim_timer > 0.25: _anim_timer = 0; _anim_frame = (_anim_frame + 1) % 3
		var p = "player_%s_walk%d.png" % [_anim_dir, _anim_frame + 1]
		if not ResourceLoader.exists("res://assets/sprites/" + p): p = "player_%s.png" % _anim_dir
		_sprite_load(p)
	else:
		_anim_timer = 0; _anim_frame = 0
		var p = "player_%s.png" % _anim_dir
		if not ResourceLoader.exists("res://assets/sprites/" + p): p = "player_down.png"
		_sprite_load(p)

	_attack_cooldown = maxf(0, _attack_cooldown - delta)
	if _attack_slash > 0: _attack_slash -= delta
	move_and_slide(); queue_redraw()

func _input(event: InputEvent):
	# Mouse: click-to-move (strategic) or attack (action)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _camera and _camera.has_method("is_strategic") and _camera.is_strategic():
			_move_target = get_global_mouse_position(); _has_target = true
		else: _do_attack()

	if event.is_action_pressed("interact"): _try_interact()
	if event.is_action_pressed("attack"): _do_attack()

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
			if area.is_in_group("Pickable") and area.has_method("pick_up"): area.pick_up(); break
