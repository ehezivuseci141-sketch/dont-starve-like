# FX Spawner — global utility for floating text
extends Node

func show(world: Node, pos: Vector2, txt: String, col: Color = Color.WHITE):
	var node = Node2D.new()
	node.position = pos + Vector2(randf_range(-10, 10), -20)
	node.set_script(load("res://scenes/floating_text.gd"))
	node.text = txt
	node.color = col
	world.add_child(node)
