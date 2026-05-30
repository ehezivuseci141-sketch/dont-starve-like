# Player — 8-dir animation, dual camera mode, combat, interaction
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
var _frame_count: int = 1  # cached count of available frames per direction

# ========= INIT =========
func _ready():
	add_to_group("Player")
	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)

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

	# Load initial standing sprite
	_try_anim_frame("player_down", -1)

# ========= SPRITE HELPERS =========
func _sprite_load(path: String) -> bool:
	var full = "res://assets/sprites/" + path
	if ResourceLoader.exists(full):
		_sprite.texture = load(full)
		return true
	return false

func _get_anim_dir(d: Vector2) -> String:
	var ax = abs(d.x); var ay = abs(d.y)
	if ay > ax * 2.0:      return "up"
	elif ax > ay * 2.0:    return "side"
	elif d.y < 0:          return "up_side"
	else:                  return "down_side"

func _try_anim_frame(base: String, frame: int) -> bool:
	var path: String
	if frame < 0:
		path = base + ".png"
	else:
		path = base + "_walk%d.png" % (frame + 1)
	return _sprite_load(path)

func _count_frames(base: String) -> int:
	for i in range(6):
		var path = base + "_walk%d.png" % (i + 1)
		if not ResourceLoader.exists("res://assets/sprites/" + path):
			return i
	return 0

func _update_anim(moving: bool, delta: float, dir_changed: bool):
	if dir_changed:
		_anim_frame = 0
		_anim_timer = 0.0
		_frame_count = _count_frames("player_" + _anim_dir)
		if _frame_count <= 0: _frame_count = 1

	if moving:
		_anim_timer += delta
		if _anim_timer > 0.25:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % _frame_count
		_try_anim_frame("player_" + _anim_dir, _anim_frame)
	else:
		_anim_timer = 0.0
		_anim_frame = 0
		_try_anim_frame("player_" + _anim_dir, -1)

# ========= DRAW (fallback + indicators) =========
func _draw():
	if _sprite.texture == null:
		draw_circle(Vector2.ZERO, 24.0, Color(0.25, 0.70, 0.30))
		draw_arc(Vector2.ZERO, 24.0, 0, TAU, 20, Color(0.1, 0.35, 0.12), 2.0)
		var ed = 1 if _facing_right else -1
		draw_circle(Vector2(ed * 6, -5), 4.0, Color.WHITE)
		draw_circle(Vector2(ed * 7, -5), 2.0, Color.BLACK)

	var d = _last_direction
	if d == Vector2.ZERO: d = Vector2(1 if _facing_right else -1, 0)
	d = d.normalized()
	var tip = d * 22 - Vector2(0, 16)
	var p = d * 12; var q = Vector2(-d.y, d.x) * 7; var r = Vector2(d.y, -d.x) * 7
	var pts = PackedVector2Array([tip, p+q - Vector2(0,16), p+r - Vector2(0,16)])
	draw_polygon(pts, PackedColorArray([Color(1,1,1,0.5), Color(1,1,1,0.5), Color(1,1,1,0.5)]))

	if _attack_slash_timer > 0:
		var a = _attack_slash_timer / 0.15
		draw_arc(d * 18, 35.0, d.angle() - 0.5, d.angle() + 0.5, 8, Color(1,1,1,a*0.7), 3.0)

# ========= PHYSICS =========
func _physics_process(delta: float):
	if _camera == null:
		var cams = get_tree().root.find_children("*", "Camera2D", true, false)
		if cams.size() > 0: _camera = cams[0]

	var is_strat = _camera != null and _camera.has_method("is_strategic") and _camera.is_strategic()
	var last_dir = _anim_dir

	if is_strat:
		if _has_target:
			var to = _move_target - global_position
			if to.length() < 15:
				_has_target = false; velocity = Vector2.ZERO; _is_moving = false
			else:
				var nd = to.normalized()
				velocity = nd * move_speed * 1.5; _is_moving = true
				_last_direction = nd
				if nd.x != 0: _facing_right = nd.x > 0
				_anim_dir = _get_anim_dir(nd)
		else:
			velocity = Vector2.ZERO; _is_moving = false
	else:
		var nd = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
		_has_target = false
		if nd != Vector2.ZERO:
			velocity = nd.normalized() * move_speed; _is_moving = true
			_last_direction = nd
			if nd.x != 0: _facing_right = nd.x > 0
			_anim_dir = _get_anim_dir(nd)
		else:
			velocity = Vector2.ZERO; _is_moving = false

	if _sprite: _sprite.scale.x = -1 if _facing_right else 1

	move_and_slide()
	if _is_moving: Signals.player_moved.emit(global_position, _last_direction)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _attack_slash_timer > 0: _attack_slash_timer -= delta
	_update_anim(_is_moving, delta, _anim_dir != last_dir)
	queue_redraw()

# ========= INPUT =========
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var is_strat = _camera != null and _camera.has_method("is_strategic") and _camera.is_strategic()
			if is_strat: _move_target = get_global_mouse_position(); _has_target = true
			else: _do_attack()

	if event.is_action_pressed("interact"): _try_interact()
	if event.is_action_pressed("attack"): _do_attack()
	if event.is_action_pressed("place"): _place_item()

	if event is InputEventKey and event.pressed:
		if event.keycode in {KEY_1:0, KEY_2:1, KEY_3:2, KEY_4:3, KEY_5:4}:
			InventoryManager.select_slot({KEY_1:0, KEY_2:1, KEY_3:2, KEY_4:3, KEY_5:4}[event.keycode])
		if event.keycode == KEY_Q: InventoryManager.drop_item(InventoryManager.selected_slot, global_position)
		if event.keycode == KEY_F:
			var item = InventoryManager.get_selected_item()
			if not item.is_empty() and ItemDB.is_eatable(item["item_id"]):
				SurvivalManager.eat(item["item_id"])
				InventoryManager.remove_item(item["item_id"], 1)

# ========= COMBAT =========
func _do_attack():
	if _attack_cooldown > 0: return
	_attack_cooldown = ATTACK_CD; _attack_slash_timer = 0.15
	_sprite_load("player_attack.png")

	var dmg = 3.0
	var sel = InventoryManager.get_selected_item()
	if not sel.is_empty(): dmg = ItemDB.get_item(sel["item_id"]).get("damage", 3.0)

	var atk = _last_direction if _last_direction != Vector2.ZERO else Vector2(1 if _facing_right else -1, 0)
	var enemies = []
	if action_area:
		for body in action_area.get_overlapping_bodies():
			if body.is_in_group("Enemy") and atk.dot(body.global_position - global_position) > 0.6:
				if not enemies.has(body): enemies.append(body)

	for e in enemies:
		if e.has_method("take_damage"):
			e.take_damage(dmg)
			if not sel.is_empty() and sel.has("dur"):
				sel["dur"] = sel.get("dur", 0) - 1
				if sel["dur"] <= 0: InventoryManager.slots[InventoryManager.selected_slot] = {}

# ========= PLACE / INTERACT =========
func _place_item():
	var sel = InventoryManager.get_selected_item()
	if sel.is_empty() or sel["item_id"] != "campfire": return
	var cf = Node2D.new()
	cf.position = global_position + (_last_direction.normalized() * 50 if _last_direction != Vector2.ZERO else Vector2(50, 0))
	cf.set_script(load("res://scenes/campfire.gd"))
	get_parent().add_child(cf)
	InventoryManager.remove_item("campfire", 1)

func _try_interact():
	if action_area:
		for area in action_area.get_overlapping_areas():
			if area.is_in_group("Pickable") and area.has_method("pick_up"):
				area.pick_up(); break

func serialize() -> Dictionary:
	return {"position_x": global_position.x, "position_y": global_position.y}

func deserialize(data: Dictionary):
	if data.has("position_x"): global_position = Vector2(data["position_x"], data["position_y"])
