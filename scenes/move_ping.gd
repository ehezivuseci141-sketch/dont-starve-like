# Click-to-move marker (LoL-like ping, no route)
extends Node2D

var _t: float = 0.0
const LIFE: float = 0.65

func _ready():
	z_index = 200
	z_as_relative = true
	queue_redraw()

func _process(delta: float):
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()

func _draw():
	var a = 1.0 - (_t / LIFE)
	a = clampf(a, 0.0, 1.0)
	var r0 = 10.0 + 26.0 * (1.0 - a)
	var col = Color(1.0, 0.92, 0.30, 0.65 * a)
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.92, 0.30, 0.9 * a))
	draw_arc(Vector2.ZERO, r0, 0.0, TAU, 28, col, 2.0)
