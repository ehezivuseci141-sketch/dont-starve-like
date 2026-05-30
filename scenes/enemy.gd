# Spider enemy - wanders, chases at night, attacks
extends CharacterBody2D

var hp: float = 30.0
var max_hp: float = 30.0
var speed: float = 80.0
var attack_damage: float = 8.0
var attack_cooldown: float = 1.5
var _attack_timer: float = 0.0
var _state: int = 0
var _wander_target: Vector2
var _wander_timer: float = 0.0

func _ready():
	add_to_group("Enemy")
	var shape = CircleShape2D.new()
	shape.radius = 24.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)
	_pick_new_wander()
	queue_redraw()

func _draw():
	var body_c = Color(0.15, 0.08, 0.12)
	if hp / max_hp < 0.5:
		body_c = Color(0.35, 0.1, 0.1)
	draw_circle(Vector2.ZERO, 22.0, body_c)
	draw_arc(Vector2.ZERO, 22.0, 0, TAU, 16, Color.BLACK, 2.0)
	draw_circle(Vector2(-8, -6), 4.0, Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(8, -6), 4.0, Color(0.9, 0.1, 0.1))
	if hp < max_hp:
		var bar_w = 40.0 * hp / max_hp
		draw_rect(Rect2(-20, -30, 40, 4), Color.BLACK)
		draw_rect(Rect2(-20, -30, bar_w, 4), Color.RED)

func _physics_process(delta: float):
	var player = _find_player()
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)
	var is_night = DayNightCycle.is_nighttime()

	# Leash: never go too far from player
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
		2:
			velocity = Vector2.ZERO
			if _attack_timer <= 0.0:
				SurvivalManager.take_damage(attack_damage)
				_attack_timer = attack_cooldown
				print("[Spider] Hit! -8 HP")

	move_and_slide()

func _pick_new_wander(around: Vector2 = Vector2.ZERO):
	_wander_target = around + Vector2(randf_range(-200, 200), randf_range(-200, 200))
	_wander_timer = randf_range(2.0, 4.0)

func take_damage(amount: float):
	hp -= amount
	queue_redraw()
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
	print("[Spider] Dead! Dropped raw meat")
	queue_free()

func _find_player() -> Node:
	var players = get_tree().root.find_children("Player", "", true, false)
	if players.size() > 0:
		return players[0]
	return null
