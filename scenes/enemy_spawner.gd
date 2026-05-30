# Enemy spawner - spawns spiders at night
extends Node2D

var _enemy_script: Script
var _spider_count: int = 0
var _max_spiders: int = 4
var _spawned_tonight: bool = false

func _ready():
	_enemy_script = load("res://scenes/enemy.gd")
	Signals.time_of_day_changed.connect(_on_time_changed)
	# Initial spawn for testing
	_spawn_spiders()

func _on_time_changed(new_time: int):
	if new_time == Enums.TimeOfDay.NIGHT:
		_spawned_tonight = false
		_spawn_spiders()
	elif new_time == Enums.TimeOfDay.DAY:
		_spawned_tonight = false

func _spawn_spiders():
	if _spawned_tonight:
		return
	_spawned_tonight = true

	var player = _find_player()
	if player == null:
		return

	# Count existing spiders
	var existing = 0
	for child in get_parent().get_children():
		if child.is_in_group("Enemy"):
			existing += 1

	var to_spawn = _max_spiders - existing
	if to_spawn <= 0:
		return

	print("[Spawner] Night! %d spiders coming..." % to_spawn)
	for i in range(to_spawn):
		var spider = CharacterBody2D.new()
		var angle = randf() * TAU
		spider.position = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(250, 400)
		spider.set_script(_enemy_script)
		get_parent().add_child(spider)

func _find_player() -> Node:
	var players = get_tree().root.find_children("Player", "", true, false)
	if players.size() > 0:
		return players[0]
	return null
