# Floating text — damage numbers, pickup notifications
extends Node2D

@export var text: String = "0"
@export var color: Color = Color.RED
@export var duration: float = 0.8
@export var float_height: float = 40.0

var _elapsed: float = 0.0
var _label: Label

func _ready():
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_font_size_override("outline_size", 2)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)

func _process(delta: float):
	_elapsed += delta
	var t = _elapsed / duration
	position.y -= float_height * delta
	_label.modulate.a = 1.0 - t
	if _elapsed >= duration:
		queue_free()

# Helper to spawn in world
func spawn(world: Node, pos: Vector2, txt: String, col: Color = Color.WHITE):
	var node = Node2D.new()
	node.position = pos + Vector2(randf_range(-10, 10), -20)
	node.set_script(load("res://scenes/floating_text.gd"))
	node.text = txt
	node.color = col
	world.add_child(node)
