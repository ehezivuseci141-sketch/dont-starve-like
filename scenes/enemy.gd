# Spider enemy with sprite
extends CharacterBody2D

var hp: float = 15.0
var max_hp: float = 15.0
var speed: float = 80.0
var attack_damage: float = 8.0
var attack_cooldown: float = 1.5
var _attack_timer: float = 0.0
var _state: int = 0
var _wander_target: Vector2
var _wander_timer: float = 0.0
var _sprite: Sprite2D
var _hp_bar_bg: ColorRect
var _hp_bar_fill: ColorRect

func _ready():
	add_to_group("Enemy")
	collision_layer = 2

	var shape = CircleShape2D.new()
	shape.radius = 20.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)

	_sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/spider.png"):
		_sprite.texture = load("res://assets/sprites/spider.png")
	add_child(_sprite)

	_pick_new_wander()

func _physics_process(delta: float):
	var player = _find_player()
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)
	var is_night = DayNightCycle.is_nighttime()

	if dist > 500.0:
		var to_player = (player.global_position - global_position).normalized()
		global_position = player.global_position - to_player * 400.0

	_attack_timer -= delta

	if is_night:
		speed = 110.0
		if dist < 40.0 and _attack_timer <= 0.0:
			_state = 2
		elif dist < 250.0:
			_state = 1
		else:
			_state = 0
	else:
		speed = 40.0
		_state = 0

	match _state:
		0:
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_pick_new_wander(player.global_position)
			var dir = (_wander_target - global_position).normalized()
			velocity = dir * speed * 0.4
		1:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * speed
			# Flip sprite towards player
			if _sprite: _sprite.scale.x = -1 if dir.x < 0 else 1
		2:
			velocity = Vector2.ZERO
			if _attack_timer <= 0.0:
				SurvivalManager.take_damage(attack_damage)
				_attack_timer = attack_cooldown

	move_and_slide()

func _pick_new_wander(around: Vector2 = Vector2.ZERO):
	_wander_target = around + Vector2(randf_range(-200, 200), randf_range(-200, 200))
	_wander_timer = randf_range(2.0, 4.0)

func take_damage(amount: float):
	hp -= amount
	FX.show(get_parent(), global_position - Vector2(0, 30), str(int(amount)), Color(1, 0.3, 0.1))
	if _sprite: _sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if _sprite: _sprite.modulate = Color.WHITE
	if hp <= 0:
		die()

func die():
	var loot_scene = load("res://scenes/simple_pickable.gd")
	if loot_scene:
		var loot = Area2D.new()
		loot.position = global_position
		loot.collision_layer = 2
		loot.collision_mask = 2
		loot.set_script(loot_scene)
		loot.item_id = "raw_meat"
		loot.item_color = Color(0.8, 0.15, 0.2)
		get_parent().add_child(loot)
	queue_free()

func _find_player() -> Node:
	var players = get_tree().root.find_children("Player", "", true, false)
	if players.size() > 0:
		return players[0]
	return null
