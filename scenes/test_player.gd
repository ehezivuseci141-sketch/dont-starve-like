# Test player — green circle, WASD
extends CharacterBody2D

var speed: float = 300.0

func _ready():
	var shape = CircleShape2D.new()
	shape.radius = 32.0
	var coll = CollisionShape2D.new()
	coll.shape = shape
	add_child(coll)
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, 32.0, Color(0.2, 0.9, 0.3))
	draw_circle(Vector2(12, -8), 6.0, Color.WHITE)
	draw_circle(Vector2(14, -8), 3.0, Color.BLACK)

func _physics_process(_delta):
	var dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	velocity = dir * speed
	move_and_slide()
