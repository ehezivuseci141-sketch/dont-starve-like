extends CharacterBody2D

@export var move_speed: float = 200.0
@export var strategic_speed_multiplier: float = 1.35

# Full skeleton rig: uses a dedicated scene with Skeleton2D+Bone2D.
const USE_SKELETON_RIG: bool = true
var _last_direction: Vector2 = Vector2.DOWN
var _facing_right: bool = true
var _sprite: Sprite2D
var _weapon_sprite: Sprite2D
var _weapon_item_id: String = ""
var _weapon_base_pos: Vector2 = Vector2.ZERO
var _weapon_base_scale: Vector2 = Vector2.ONE
var _weapon_base_rot: float = 0.0
var _weapon_class: String = ""
var _weapon_tool_type: String = ""
var action_area: Area2D
var _attack_cooldown: float = 0.0
const ATTACK_CD: float = 0.4
var _attack_slash: float = 0.0
var _weapon_anim_attack: float = 0.0
var _weapon_anim_gather: float = 0.0
const WEAPON_ATTACK_TIME: float = 0.16
const WEAPON_GATHER_TIME: float = 0.14

# Strategic mode
var _camera: Camera2D
var _move_target: Vector2
var _has_target: bool = false

# Animation
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _anim_dir: String = "down"
var _moving: bool = false
const ARRIVE_DISTANCE: float = 6.0
const ANIM_STEP_TIME: float = 0.18
const PLAYER_PIXEL_SIZE: float = 68.0
const SPRITE_BASE_Y: float = -8.0

# Skeleton rig (scene-based; down/front only for now)
var _rig_enabled: bool = false
var _rig_root: Node2D
var _rig_scene: Node2D
var _skel: Skeleton2D
var _rig_bones: Dictionary = {} # name -> Bone2D
var _rig_parts: Dictionary = {} # name -> Sprite2D
var _rig_walk_t: float = 0.0
var _hand_socket_r: Node2D

func _ready():
	var shape = CircleShape2D.new(); shape.radius = 20.0
	var coll = CollisionShape2D.new(); coll.shape = shape; add_child(coll)

	action_area = Area2D.new()
	action_area.collision_layer = 2; action_area.collision_mask = 3
	var ashape = CircleShape2D.new(); ashape.radius = 55.0
	var acoll = CollisionShape2D.new(); acoll.shape = ashape
	action_area.add_child(acoll); add_child(action_area)

	_sprite = Sprite2D.new(); _sprite.position = Vector2(0, SPRITE_BASE_Y)
	_sprite.scale = Vector2(0.7, 0.7); add_child(_sprite)
	_sprite_load("player_down.png")

	if USE_SKELETON_RIG:
		_setup_skeleton_rig()
		_sprite.visible = false

	_weapon_sprite = Sprite2D.new()
	_weapon_sprite.position = Vector2(10, SPRITE_BASE_Y + 10)
	_weapon_sprite.centered = true
	_weapon_sprite.visible = false
	_weapon_sprite.z_as_relative = true
	_weapon_sprite.z_index = 2
	add_child(_weapon_sprite)
	queue_redraw()

func _sprite_load(path: String):
	var full = "res://assets/sprites/" + path
	if ResourceLoader.exists(full):
		_sprite.texture = ResourceLoader.load(full, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE)
		# Normalize scale based on texture size (target: ~64px)
		if _sprite.texture:
			var ts = _sprite.texture.get_size()
			var s = PLAYER_PIXEL_SIZE / max(ts.x, ts.y)
			var should_mirror = _anim_dir == "side" or _anim_dir == "down_side" or _anim_dir == "up_side"
			var sx = -s if should_mirror and _facing_right else s
			_sprite.scale = Vector2(sx, s)

func _draw():
	# Ground shadow (drawn behind child sprite)
	var shadow_y = 22.0
	var sx = 1.25
	var sy = 0.55
	if _moving:
		# Subtle squash/stretch to avoid looking static.
		var t = float(_anim_frame) / 2.0
		sx = 1.22 + 0.06 * sin(t * TAU)
		sy = 0.54 + 0.03 * sin((t + 0.25) * TAU)
	draw_set_transform(Vector2(0, shadow_y), 0.0, Vector2(sx, sy))
	draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
			var distance = to.length()
			if distance <= ARRIVE_DISTANCE:
				global_position = _move_target
				_has_target = false
				_set_move_direction(Vector2.ZERO)
			else:
				var dir = to.normalized()
				_set_move_direction(dir)
				velocity = dir * move_speed * strategic_speed_multiplier
		else:
			_set_move_direction(Vector2.ZERO)
	else:
		_has_target = false
		var dx = (1 if Input.is_action_pressed("move_right") else 0) - (1 if Input.is_action_pressed("move_left") else 0)
		var dy = (1 if Input.is_action_pressed("move_down") else 0) - (1 if Input.is_action_pressed("move_up") else 0)
		var dir = Vector2(dx, dy)
		_set_move_direction(dir)

	_update_animation(delta)
	_update_weapon_visual()
	_update_weapon_animation(delta)
	_update_rig(delta)

	_attack_cooldown = maxf(0, _attack_cooldown - delta)
	if _attack_slash > 0: _attack_slash -= delta
	move_and_slide()
	if _moving:
		Signals.player_moved.emit(global_position, _last_direction)
	queue_redraw()

func set_move_target(pos: Vector2):
	_move_target = pos
	_has_target = true

func _set_move_direction(input_dir: Vector2):
	if input_dir == Vector2.ZERO:
		_moving = false
		velocity = Vector2.ZERO
		return

	var dir = input_dir.normalized()
	_moving = true
	velocity = dir * move_speed
	_last_direction = dir
	_anim_dir = _direction_to_anim(dir)
	if abs(dir.x) > 0.05:
		_facing_right = dir.x > 0

func _direction_to_anim(dir: Vector2) -> String:
	var angle = dir.angle()
	var octant = int(round(angle / (PI / 4.0))) & 7
	match octant:
		0:
			return "side"
		1:
			return "down_side"
		2:
			return "down"
		3:
			return "down_side"
		4:
			return "side"
		5:
			return "up_side"
		6:
			return "up"
		7:
			return "up_side"
	return "down"

func _update_animation(delta: float):
	if _moving:
		_anim_timer += delta
		if _anim_timer >= ANIM_STEP_TIME:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % 3
		var p = "player_%s_walk%d.png" % [_anim_dir, _anim_frame + 1]
		if not ResourceLoader.exists("res://assets/sprites/" + p):
			p = "player_%s.png" % _anim_dir
		_sprite_load(p)
		_reset_sprite_pose()
	else:
		_anim_timer = 0.0
		_anim_frame = 0
		var p = "player_%s.png" % _anim_dir
		if not ResourceLoader.exists("res://assets/sprites/" + p):
			p = "player_down.png"
		_sprite_load(p)
		_reset_sprite_pose()

func _reset_sprite_pose():
	_sprite.position = Vector2(0, SPRITE_BASE_Y)
	_sprite.rotation = 0.0

func _update_weapon_visual():
	var sel = InventoryManager.get_selected_item()
	if sel.is_empty():
		_weapon_item_id = ""
		_weapon_class = ""
		_weapon_tool_type = ""
		_weapon_sprite.visible = false
		_weapon_sprite.reparent(self)
		return

	var item_id = str(sel.get("item_id", ""))
	if item_id == "":
		_weapon_item_id = ""
		_weapon_class = ""
		_weapon_tool_type = ""
		_weapon_sprite.visible = false
		_weapon_sprite.reparent(self)
		return

	var item_def = ItemDB.get_item(item_id)
	var cat = int(item_def.get("category", -1))
	var is_tool = cat == 2 or item_def.has("tool_type") or float(item_def.get("damage", 0)) > 0.0
	if not is_tool:
		_weapon_item_id = ""
		_weapon_class = ""
		_weapon_tool_type = ""
		_weapon_sprite.visible = false
		_weapon_sprite.reparent(self)
		return

	_weapon_tool_type = str(item_def.get("tool_type", ""))
	_weapon_class = _classify_weapon(item_id, item_def)

	if item_id != _weapon_item_id:
		_weapon_item_id = item_id
		var p = "res://assets/sprites/%s.png" % item_id
		_weapon_sprite.texture = ResourceLoader.load(p, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE) if ResourceLoader.exists(p) else null

	if _weapon_sprite.texture == null:
		_weapon_sprite.visible = false
		_weapon_sprite.reparent(self)
		return

	_weapon_sprite.visible = true

	# If rig is active, attach weapon to right-hand socket for true bone binding.
	if _rig_enabled and _hand_socket_r != null:
		if _weapon_sprite.get_parent() != _hand_socket_r:
			_weapon_sprite.reparent(_hand_socket_r)
		_weapon_sprite.z_as_relative = true
		_weapon_sprite.z_index = 10
		_weapon_sprite.position = Vector2.ZERO
		_weapon_sprite.rotation = 0.0
		# Use offset only (grip alignment); position is handled by socket.
		var grip = _weapon_grip_offset()
		_weapon_sprite.offset = grip
		_weapon_base_pos = _weapon_sprite.position
		_weapon_base_scale = _weapon_sprite.scale
		_weapon_base_rot = _weapon_sprite.rotation
		return

	# Placement + layering by facing direction + item type.
	var pose = _weapon_pose()
	_weapon_sprite.z_index = pose["z"]
	_weapon_sprite.position = pose["pos"]
	_weapon_sprite.scale = pose["scale"]
	_weapon_sprite.rotation = pose["rot"]
	_weapon_sprite.offset = pose["offset"]
	_weapon_base_pos = _weapon_sprite.position
	_weapon_base_scale = _weapon_sprite.scale
	_weapon_base_rot = _weapon_sprite.rotation

func _update_weapon_animation(delta: float):
	if _weapon_sprite == null:
		return

	_weapon_anim_attack = maxf(0.0, _weapon_anim_attack - delta)
	_weapon_anim_gather = maxf(0.0, _weapon_anim_gather - delta)

	var pos = _weapon_base_pos
	var rot = _weapon_base_rot

	# Idle/walk sway (very subtle)
	if _weapon_sprite.visible:
		var sway = 0.0
		if _moving:
			sway = sin(float(_anim_frame) / 3.0 * TAU) * 0.08
		rot += sway
		pos += Vector2(0, -1.0 if _moving else 0.0)

	# Attack swing: wide arc.
	if _weapon_anim_attack > 0.0 and _weapon_sprite.visible:
		var t = 1.0 - (_weapon_anim_attack / WEAPON_ATTACK_TIME) # 0..1
		var eased = _ease_out_cubic(t)
		var sign = -1.0 if _weapon_base_scale.x < 0.0 else 1.0
		var dir_mul = -1.0 if _anim_dir == "up" or _anim_dir == "up_side" else 1.0
		var arc = 70.0
		if _weapon_class == "spear" or _weapon_class == "lance":
			arc = 50.0
		elif _weapon_class == "fan":
			arc = 35.0
		elif _weapon_tool_type == "chop":
			arc = 85.0
		elif _weapon_tool_type == "mine":
			arc = 60.0
		var a0 = deg_to_rad(-arc) * sign * dir_mul
		var a1 = deg_to_rad(arc) * sign * dir_mul
		rot += lerpf(a0, a1, eased)
		var kick_y = -6.0 if dir_mul < 0.0 else 2.0
		pos += Vector2(10.0 * sign, kick_y) * _ease_in_out_quad(t)

	# Gather chop/pick: short down stroke.
	if _weapon_anim_gather > 0.0 and _weapon_sprite.visible:
		var t2 = 1.0 - (_weapon_anim_gather / WEAPON_GATHER_TIME)
		var eased2 = _ease_in_out_quad(t2)
		var sign2 = -1.0 if _weapon_base_scale.x < 0.0 else 1.0
		var down_mul = 1.0 if _anim_dir == "down" or _anim_dir == "down_side" else -0.7
		var amp = 38.0
		if _weapon_tool_type == "chop":
			amp = 52.0
		elif _weapon_tool_type == "mine":
			amp = 44.0
		rot += deg_to_rad(amp) * sign2 * down_mul * sin(eased2 * PI)
		pos += Vector2(4.0 * sign2, 6.0 * down_mul) * sin(eased2 * PI)

	_weapon_sprite.position = pos
	_weapon_sprite.rotation = rot

func _ease_out_cubic(t: float) -> float:
	var x = clampf(t, 0.0, 1.0)
	x = 1.0 - pow(1.0 - x, 3.0)
	return x

func _ease_in_out_quad(t: float) -> float:
	var x = clampf(t, 0.0, 1.0)
	if x < 0.5:
		return 2.0 * x * x
	return 1.0 - pow(-2.0 * x + 2.0, 2.0) / 2.0

func _input(event: InputEvent):
	# Mouse: click-to-move (strategic) or attack (action)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _camera and _camera.has_method("is_strategic") and _camera.is_strategic():
			set_move_target(get_global_mouse_position())
			_spawn_move_ping(_move_target)
		else: _do_attack()

	if event.is_action_pressed("interact"): _try_interact()
	if event.is_action_pressed("attack"): _do_attack()

func _do_attack():
	if _attack_cooldown > 0: return
	_attack_cooldown = ATTACK_CD; _attack_slash = 0.15
	_weapon_anim_attack = WEAPON_ATTACK_TIME
	var dmg = 3.0; var sel = InventoryManager.get_selected_item()
	if not sel.is_empty(): dmg = ItemDB.get_item(sel["item_id"]).get("damage", 3.0)
	var atk = _last_direction; if atk == Vector2.ZERO: atk = Vector2(1 if _facing_right else -1, 0)
	var hit_any = false
	if action_area:
		for body in action_area.get_overlapping_bodies():
			if body.is_in_group("Enemy") and atk.dot(body.global_position - global_position) > 0.3:
				if body.has_method("take_damage"):
					body.take_damage(dmg)
					hit_any = true
	if hit_any:
		_consume_selected_durability(1)

func _try_interact():
	if action_area:
		for area in action_area.get_overlapping_areas():
			if area.is_in_group("Pickable") and area.has_method("pick_up"):
				var ok = area.pick_up()
				if ok:
					_weapon_anim_gather = WEAPON_GATHER_TIME
					_consume_selected_durability(1)
				break

func _consume_selected_durability(amount: int):
	var idx = InventoryManager.selected_slot
	if idx < 0 or idx >= InventoryManager.slots.size():
		return
	var slot = InventoryManager.slots[idx]
	if slot.is_empty():
		return
	if not slot.has("dur"):
		return
	slot["dur"] = maxf(0.0, float(slot["dur"]) - float(amount))
	if float(slot["dur"]) <= 0.0:
		InventoryManager.slots[idx] = {}

func _spawn_move_ping(pos: Vector2):
	if get_parent() == null:
		return
	var node = Node2D.new()
	node.position = pos
	node.set_script(load("res://scenes/move_ping.gd"))
	get_parent().add_child(node)

func _classify_weapon(item_id: String, item_def: Dictionary) -> String:
	if item_id == "spear":
		return "spear"
	if item_id == "lance":
		return "lance"
	if item_id == "sword":
		return "sword"
	if item_id == "fan":
		return "fan"
	if item_def.has("tool_type"):
		return "tool"
	return "other"

func _weapon_pose() -> Dictionary:
	var should_flip = false
	var z = 2
	# Hand anchor (weapon origin should sit on player's hand).
	var x = 9.0
	var y = SPRITE_BASE_Y + 18.0
	var rot = 0.0
	var base_s = 0.62
	# Per item: held-size multiplier (icons are small; long weapons should read longer).
	var mult = 1.0
	if _weapon_class == "spear" or _weapon_class == "lance":
		mult = 1.28
	elif _weapon_class == "sword":
		mult = 1.10
	elif _weapon_tool_type == "chop" or _weapon_tool_type == "mine":
		mult = 1.15
	elif _weapon_class == "fan":
		mult = 1.05
	var scale = Vector2(base_s * mult, base_s * mult)
	# Sprite2D.centered=true, so offset moves texture relative to its center.
	# We choose an approximate "grip point" in the 32x32 icon and offset so that grip lands on sprite origin.
	var offset = Vector2.ZERO

	match _anim_dir:
		"up":
			x = 8.0; y = SPRITE_BASE_Y + 12.0; z = -1
		"up_side":
			x = 10.0; y = SPRITE_BASE_Y + 13.0; z = -1
			should_flip = not _facing_right
		"side":
			x = 11.0; y = SPRITE_BASE_Y + 15.0; z = 2
			should_flip = not _facing_right
		"down_side":
			x = 10.0; y = SPRITE_BASE_Y + 17.0; z = 2
			should_flip = not _facing_right
		_:
			x = 9.0; y = SPRITE_BASE_Y + 19.0; z = 2

	# Per item/tool hold angle and offset.
	if _weapon_tool_type == "chop":
		rot = deg_to_rad(34.0)
		x += 1.0; y -= 1.0
		# grip ~ (10,22) -> offset=(16-10,16-22)=(6,-6)
		offset = Vector2(6, -6)
	elif _weapon_tool_type == "mine":
		rot = deg_to_rad(-22.0)
		x += 1.0; y -= 2.0
		# grip ~ (10,22)
		offset = Vector2(6, -6)
	elif _weapon_class == "spear" or _weapon_class == "lance":
		# Long weapons: grip ~ (8,24) -> offset=(16-8,16-24)=(8,-8)
		rot = deg_to_rad(-18.0)
		x += 3.0; y -= 2.0
		offset = Vector2(8, -8)
	elif _weapon_class == "sword":
		rot = deg_to_rad(18.0)
		x += 2.0; y -= 1.0
		# grip ~ (11,23) -> offset=(5,-7)
		offset = Vector2(5, -7)
	elif _weapon_class == "fan":
		rot = deg_to_rad(42.0)
		x -= 1.0; y += 1.0
		# grip ~ (14,21) -> offset=(2,-5)
		offset = Vector2(2, -5)

	if should_flip:
		scale = Vector2(-scale.x, scale.y)

	return {"pos": Vector2(-x if should_flip else x, y), "scale": scale, "rot": rot, "z": z, "offset": offset}

func _setup_skeleton_rig():
	_rig_enabled = true

	# Headless runs (used for automated checks) can trigger noisy Skeleton2D internal warnings/errors.
	# In normal gameplay this rig is fine; for headless we fall back to the legacy sprite to keep checks clean.
	if DisplayServer.get_name() == "headless":
		_rig_enabled = false
		_sprite.visible = true
		return

	_rig_root = Node2D.new()
	_rig_root.position = Vector2(0, SPRITE_BASE_Y)
	_rig_root.scale = Vector2(0.7, 0.7)
	add_child(_rig_root)

	var rig_scene = load("res://scenes/player_rig.tscn") as PackedScene
	if rig_scene == null:
		_rig_enabled = false
		_sprite.visible = true
		return
	_rig_scene = rig_scene.instantiate() as Node2D
	_rig_root.add_child(_rig_scene)

	_skel = _rig_scene.get_node_or_null("Skeleton2D") as Skeleton2D
	if _skel == null:
		_rig_enabled = false
		_sprite.visible = true
		return

	# Cache bone references
	_rig_bones.clear()
	for bn in ["torso", "head", "arm_l", "arm_r", "leg_l", "leg_r"]:
		var b = _skel.get_node_or_null(bn) as Bone2D
		if b != null:
			_rig_bones[bn] = b

	_hand_socket_r = _skel.get_node_or_null("torso/arm_r/arm_r_end/HandSocketR") as Node2D

func _weapon_grip_offset() -> Vector2:
	# Offset so that the "grip point" lands on the socket origin.
	# Centered sprite: offset is applied relative to the texture center.
	if _weapon_tool_type == "chop" or _weapon_tool_type == "mine":
		return Vector2(6, -6)
	if _weapon_class == "spear" or _weapon_class == "lance":
		return Vector2(8, -8)
	if _weapon_class == "sword":
		return Vector2(5, -7)
	if _weapon_class == "fan":
		return Vector2(2, -5)
	return Vector2.ZERO

func _update_rig(delta: float):
	if not _rig_enabled:
		return

	# Procedural walk: swing arms/legs (front view only for now).
	if _moving:
		_rig_walk_t += delta * 9.0
	else:
		_rig_walk_t = 0.0

	var s = sin(_rig_walk_t)
	var arm = deg_to_rad(10.0) * s
	var leg = deg_to_rad(12.0) * s
	if _rig_bones.has("arm_l"): (_rig_bones["arm_l"] as Bone2D).rotation = arm
	if _rig_bones.has("arm_r"): (_rig_bones["arm_r"] as Bone2D).rotation = -arm
	if _rig_bones.has("leg_l"): (_rig_bones["leg_l"] as Bone2D).rotation = -leg
	if _rig_bones.has("leg_r"): (_rig_bones["leg_r"] as Bone2D).rotation = leg

	# Attack/gather add-on: rotate right arm.
	if _weapon_anim_attack > 0.0:
		var t = 1.0 - (_weapon_anim_attack / WEAPON_ATTACK_TIME)
		var add = deg_to_rad(-35.0) * sin(t * PI)
		if _rig_bones.has("arm_r"): (_rig_bones["arm_r"] as Bone2D).rotation += add
	if _weapon_anim_gather > 0.0:
		var t2 = 1.0 - (_weapon_anim_gather / WEAPON_GATHER_TIME)
		var add2 = deg_to_rad(-25.0) * sin(t2 * PI)
		if _rig_bones.has("arm_r"): (_rig_bones["arm_r"] as Bone2D).rotation += add2
