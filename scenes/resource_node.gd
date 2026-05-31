# Resource node (berry bush, grass patch, rock node, etc.)
extends Area2D

@export var node_id: String = "berry_bush" # sprite id in assets/sprites
@export var drop_item_id: String = "berries"
@export var drop_min: int = 1
@export var drop_max: int = 2
@export var respawn_time: float = 45.0
@export var required_tool_type: String = "" # "", "chop", "mine"
@export var required_tool_tier: int = 0

var _picked: bool = false
var _sprite: Sprite2D
var _label: Label
var _near_player: bool = false
var _respawn_left: float = 0.0

const HINT_DISTANCE: float = 90.0

func _ready():
	add_to_group("Pickable")

	var shape = CircleShape2D.new()
	shape.radius = 18.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)

	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.texture = _load_tex(node_id)
	_sprite.scale = Vector2.ONE * _node_scale(node_id)
	add_child(_sprite)

	_label = Label.new()
	_label.text = ""
	_label.position = Vector2(-56, -46)
	_label.size = Vector2(112, 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.72))
	_label.visible = false
	add_child(_label)

	queue_redraw()

func _process(delta: float):
	if _picked:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_respawn()
		return

	var player = _find_player()
	var was_near = _near_player
	_near_player = player != null and global_position.distance_to(player.global_position) <= HINT_DISTANCE
	if _near_player != was_near:
		_update_focus_visual()

func _update_focus_visual():
	if _picked:
		_label.visible = false
		return
	if _near_player:
		_label.text = "E 采集"
		_label.visible = true
		if _sprite:
			_sprite.modulate = Color(1.18, 1.12, 0.92, 1.0)
			_sprite.scale = Vector2(1.04, 1.04)
	else:
		_label.visible = false
		if _sprite:
			_sprite.modulate = Color.WHITE
			_sprite.scale = Vector2.ONE

func pick_up():
	if _picked:
		return false
	if not _can_harvest():
		FX.show(get_parent(), global_position, _need_tool_text(), Color(1.0, 0.35, 0.25))
		return false
	var count = randi_range(drop_min, drop_max)
	var added = InventoryManager.add_item(drop_item_id, count)
	if added <= 0:
		FX.show(get_parent(), global_position, "背包已满", Color(1.0, 0.35, 0.25))
		return false

	FX.show(get_parent(), global_position, "+%d %s" % [added, ItemDB.get_item_name(drop_item_id)], Color(1, 1, 1))
	_set_depleted()
	return true

func _set_depleted():
	_picked = true
	_respawn_left = respawn_time
	_label.visible = false
	collision_layer = 0
	collision_mask = 0
	if _sprite:
		_sprite.modulate = Color(0.55, 0.55, 0.55, 1.0)
		_sprite.scale = Vector2(0.98, 0.98)

func _respawn():
	_picked = false
	_respawn_left = 0.0
	_near_player = false
	collision_layer = 2
	collision_mask = 2
	if _sprite:
		_sprite.texture = _load_tex(node_id)
		_sprite.modulate = Color.WHITE
		_sprite.scale = Vector2.ONE * _node_scale(node_id)
	_update_focus_visual()

func _load_tex(id: String) -> Texture2D:
	var p = "res://assets/sprites/%s.png" % id
	return load(p) if ResourceLoader.exists(p) else null

func _can_harvest() -> bool:
	if required_tool_type == "":
		return true
	var sel = InventoryManager.get_selected_item()
	if sel.is_empty():
		return false
	var item_id = str(sel.get("item_id", ""))
	if item_id == "":
		return false
	var item = ItemDB.get_item(item_id)
	if str(item.get("tool_type", "")) != required_tool_type:
		return false
	var tier = int(item.get("tool_tier", 0))
	return tier >= required_tool_tier

func _need_tool_text() -> String:
	if required_tool_type == "chop":
		return "需要斧头"
	if required_tool_type == "mine":
		return "需要镐子"
	return "需要工具"

func _node_scale(id: String) -> float:
	match id:
		"tree":
			return 1.35
		"rock_node", "flint_node", "gold_node":
			return 1.15
		"berry_bush", "carrot_patch", "grass_patch", "sapling":
			return 1.05
		_:
			return 1.0

func _find_player() -> Node:
	var p = get_tree().root.find_children("Player", "", true, false)
	if p.size() > 0:
		return p[0]
	return null
