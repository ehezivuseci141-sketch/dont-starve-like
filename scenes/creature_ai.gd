extends CharacterBody2D
class_name CreatureAI

enum State {IDLE, WANDER, FLEE, CHASE, ATTACK, RETURN, DEATH}

@export var creature_id: String = "moss_hopper"
@export var display_name: String = "Moss Hopper"
@export var max_hp: float = 8.0
@export var speed: float = 95.0
@export var attack_damage: float = 0.0
@export var attack_cooldown: float = 1.4
@export var sight_range: float = 190.0
@export var attack_range: float = 42.0
@export var home_radius: float = 360.0
@export var day_active: bool = true
@export var night_aggressive: bool = false
@export var drop_item_id: String = "raw_meat"
@export var drop_amount: int = 1

var hp: float
var state: int = State.IDLE
var home_position: Vector2
var _wander_target: Vector2
var _wander_timer: float = 0.0
var _attack_timer: float = 0.0
var _hurt_timer: float = 0.0
var _sprite: Sprite2D
var _hp_bg: ColorRect
var _hp_fill: ColorRect

func _ready():
	add_to_group("Creature")
	add_to_group("Enemy")
	collision_layer = 2
	collision_mask = 1
	hp = max_hp
	home_position = global_position

	var shape = CircleShape2D.new()
	shape.radius = 18.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)

	_sprite = Sprite2D.new()
	_sprite.texture = _load_texture()
	_sprite.scale = Vector2.ONE * _creature_scale()
	add_child(_sprite)

	_make_hp_bar()
	_pick_wander_target()

func configure(data: Dictionary):
	creature_id = str(data.get("creature_id", creature_id))
	display_name = str(data.get("display_name", display_name))
	max_hp = float(data.get("max_hp", max_hp))
	speed = float(data.get("speed", speed))
	attack_damage = float(data.get("attack_damage", attack_damage))
	attack_cooldown = float(data.get("attack_cooldown", attack_cooldown))
	sight_range = float(data.get("sight_range", sight_range))
	attack_range = float(data.get("attack_range", attack_range))
	home_radius = float(data.get("home_radius", home_radius))
	day_active = bool(data.get("day_active", day_active))
	night_aggressive = bool(data.get("night_aggressive", night_aggressive))
	drop_item_id = str(data.get("drop_item_id", drop_item_id))
	drop_amount = int(data.get("drop_amount", drop_amount))
	hp = max_hp

func _physics_process(delta: float):
	if state == State.DEATH:
		return
	var player = _find_player()
	if player == null:
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	_choose_state(player)
	_tick_state(delta, player)
	_update_visual()
	move_and_slide()

func _choose_state(player: Node2D):
	var dist = global_position.distance_to(player.global_position)
	var away_from_home = global_position.distance_to(home_position)
	var is_night = DayNightCycle.is_nighttime()
	if away_from_home > home_radius:
		state = State.RETURN
		return
	if creature_id == "moss_hopper":
		if dist < sight_range:
			state = State.FLEE
		elif day_active and not is_night:
			if state == State.IDLE:
				state = State.WANDER
		else:
			state = State.IDLE
		return
	if night_aggressive and is_night:
		if dist <= attack_range:
			state = State.ATTACK
		elif dist <= sight_range:
			state = State.CHASE
		else:
			state = State.WANDER
	else:
		state = State.WANDER

func _tick_state(delta: float, player: Node2D):
	if state == State.IDLE:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 5.0 * delta)
	elif state == State.WANDER:
		_wander_timer -= delta
		if _wander_timer <= 0.0 or global_position.distance_to(_wander_target) < 12.0:
			_pick_wander_target()
		_move_toward(_wander_target, speed * 0.45, delta)
	elif state == State.FLEE:
		var dir = (global_position - player.global_position).normalized()
		var target = global_position + dir * 140.0
		_move_toward(target, speed * 1.25, delta)
	elif state == State.CHASE:
		_move_toward(player.global_position, speed, delta)
	elif state == State.ATTACK:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 6.0 * delta)
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
			else:
				SurvivalManager.take_damage(attack_damage)
			Signals.entity_attacked_player.emit(creature_id, attack_damage)
	elif state == State.RETURN:
		_move_toward(home_position, speed * 0.9, delta)
		if global_position.distance_to(home_position) < 18.0:
			state = State.IDLE

func _move_toward(target: Vector2, move_speed: float, delta: float):
	var dir = (target - global_position).normalized()
	if dir.length() < 0.01:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 4.0 * delta)
		return
	velocity = velocity.move_toward(dir * move_speed, move_speed * 5.0 * delta)

func _pick_wander_target():
	var r = randf_range(60.0, 180.0)
	var a = randf() * TAU
	_wander_target = home_position + Vector2(cos(a), sin(a)) * r
	_wander_timer = randf_range(1.2, 3.0)

func take_damage(amount: float):
	if state == State.DEATH:
		return
	hp = maxf(0.0, hp - amount)
	_hurt_timer = 0.16
	FX.show(get_parent(), global_position - Vector2(0, 28), str(int(amount)), Color(1.0, 0.35, 0.15))
	if hp <= 0.0:
		die()

func die():
	state = State.DEATH
	Signals.entity_died.emit(creature_id, creature_id, global_position, [{"item_id": drop_item_id, "amount": drop_amount}])
	_drop_loot()
	queue_free()

func _drop_loot():
	var pickable_script = load("res://scenes/simple_pickable.gd")
	for i in range(drop_amount):
		var loot = Area2D.new()
		loot.position = global_position + Vector2(randf_range(-18, 18), randf_range(-18, 18))
		loot.collision_layer = 2
		loot.collision_mask = 2
		loot.set_script(pickable_script)
		loot.item_id = drop_item_id
		get_parent().add_child(loot)

func _update_visual():
	if _sprite == null:
		return
	if abs(velocity.x) > 4.0:
		_sprite.scale.x = -abs(_creature_scale()) if velocity.x < 0.0 else abs(_creature_scale())
	_sprite.modulate = Color(1.0, 0.45, 0.35) if _hurt_timer > 0.0 else Color.WHITE
	if _hp_bg != null:
		var show_bar = hp < max_hp
		_hp_bg.visible = show_bar
		_hp_fill.visible = show_bar
		_hp_fill.size.x = 34.0 * clampf(hp / max_hp, 0.0, 1.0)

func _make_hp_bar():
	_hp_bg = ColorRect.new()
	_hp_bg.position = Vector2(-17, -34)
	_hp_bg.size = Vector2(34, 4)
	_hp_bg.color = Color(0, 0, 0, 0.55)
	_hp_bg.visible = false
	add_child(_hp_bg)
	_hp_fill = ColorRect.new()
	_hp_fill.position = Vector2(-17, -34)
	_hp_fill.size = Vector2(34, 4)
	_hp_fill.color = Color(0.85, 0.12, 0.08, 0.95)
	_hp_fill.visible = false
	add_child(_hp_fill)

func _load_texture() -> Texture2D:
	var path = "res://assets/sprites/%s.png" % creature_id
	if ResourceLoader.exists(path):
		return load(path)
	return _make_fallback_texture()

func _make_fallback_texture() -> Texture2D:
	var img = Image.create(48, 40, false, Image.FORMAT_RGBA8)
	var body = Color(0.72, 0.80, 0.62, 1.0) if creature_id == "moss_hopper" else Color(0.18, 0.18, 0.20, 1.0)
	var ear = body.lightened(0.14)
	for y in range(40):
		for x in range(48):
			var p = Vector2(x, y)
			var alpha = 0.0
			var c = body
			if p.distance_to(Vector2(24, 24)) < 13.0:
				alpha = 1.0
			if p.distance_to(Vector2(17, 12)) < 7.5 or p.distance_to(Vector2(31, 12)) < 7.5:
				alpha = 1.0
				c = ear
			if p.distance_to(Vector2(19, 23)) < 2.0 or p.distance_to(Vector2(29, 23)) < 2.0:
				c = Color(0.05, 0.04, 0.03, 1.0)
				alpha = 1.0
			img.set_pixel(x, y, Color(c.r, c.g, c.b, alpha))
	return ImageTexture.create_from_image(img)

func _creature_scale() -> float:
	if creature_id == "moss_hopper":
		return 1.0
	return 1.12

func _find_player() -> Node2D:
	var p = get_tree().root.find_children("Player", "", true, false)
	if p.size() > 0:
		return p[0] as Node2D
	return null
