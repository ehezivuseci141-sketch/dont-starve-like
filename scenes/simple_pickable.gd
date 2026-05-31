# Pickable item with sprite texture
extends Area2D

var item_id: String = "twigs"
var item_color: Color = Color.BROWN
var _picked: bool = false
var _sprite: Sprite2D
var _label: Label
var _near_player: bool = false
const HINT_DISTANCE: float = 78.0

func _ready():
	add_to_group("Pickable")

	# Collision
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)

	# Sprite
	_sprite = Sprite2D.new()
	var tex_path = "res://assets/sprites/%s.png" % item_id
	if ResourceLoader.exists(tex_path):
		_sprite.texture = load(tex_path)
	# Loose drops should read smaller than the player.
	_sprite.scale = Vector2(0.75, 0.75)
	add_child(_sprite)

	# Name label (use a Label node)
	_label = Label.new()
	_label.text = ""
	_label.position = Vector2(-42, -34)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.72))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(84, 16)
	_label.visible = false
	add_child(_label)
	queue_redraw()

func _draw():
	if _picked:
		return
	draw_circle(Vector2(0, 15), 13.0, Color(0, 0, 0, 0.20))

func _process(_delta):
	if _picked:
		return
	var player = _find_player()
	var was_near = _near_player
	_near_player = player != null and global_position.distance_to(player.global_position) <= HINT_DISTANCE
	if _near_player != was_near:
		_update_focus_visual()

func _update_focus_visual():
	var item_name = ItemDB.get_item_name(item_id)
	if _near_player:
		_label.text = "E 采集  " + item_name
		_label.visible = true
		if _sprite:
			_sprite.modulate = Color(1.18, 1.12, 0.92, 1.0)
			_sprite.scale = Vector2(1.08, 1.08)
	else:
		_label.visible = false
		if _sprite:
			_sprite.modulate = Color.WHITE
			_sprite.scale = Vector2.ONE

func pick_up():
	if _picked: return
	var p = InventoryManager.add_item(item_id, 1)
	if p > 0:
		FX.show(get_parent(), global_position, "+1 %s" % ItemDB.get_item_name(item_id), Color(1, 1, 1))
		_picked = true
		collision_layer = 0
		collision_mask = 0
		if _label:
			_label.text = "+1"
			_label.visible = true
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "position", position + Vector2(0, -18), 0.18)
		tween.tween_property(self, "scale", Vector2(0.35, 0.35), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "modulate:a", 0.0, 0.18)
		tween.finished.connect(func(): queue_free())
		return true
	else:
		FX.show(get_parent(), global_position, "背包已满", Color(1.0, 0.35, 0.25))
		return false

func set_item(item: String, count: int = 1):
	item_id = item
	# Reload sprite
	if _sprite:
		var tex_path = "res://assets/sprites/%s.png" % item_id
		if ResourceLoader.exists(tex_path):
			_sprite.texture = load(tex_path)
	_update_focus_visual()

func _find_player() -> Node:
	var p = get_tree().root.find_children("Player", "", true, false)
	if p.size() > 0:
		return p[0]
	return null
