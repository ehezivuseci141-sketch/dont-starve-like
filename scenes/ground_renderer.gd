# Ground renderer - draws biome-colored background tiles
extends Node2D

var _tile_size: int = 64
var _view_range: int = 12  # tiles visible in each direction

func _draw():
	var player = _find_player()
	if player == null:
		return

	var player_grid = WorldManager.world_to_grid(player.global_position)
	var cx = player_grid.x
	var cy = player_grid.y

	for x in range(cx - _view_range, cx + _view_range + 1):
		for y in range(cy - _view_range, cy + _view_range + 1):
			var grid_pos = Vector2i(x, y)
			var biome = WorldManager.biome_grid.get(grid_pos, Enums.BiomeType.GRASSLAND)
			var world_pos = WorldManager.grid_to_world(grid_pos)

			# Adjust position relative to this node (which should be at 0,0 in world)
			var draw_pos = world_pos - global_position
			var color = _biome_color(biome)
			draw_rect(Rect2(draw_pos - Vector2(_tile_size/2, _tile_size/2),
				Vector2(_tile_size, _tile_size)), color)

func _biome_color(biome: int) -> Color:
	match biome:
		Enums.BiomeType.GRASSLAND: return Color(0.25, 0.28, 0.18)
		Enums.BiomeType.FOREST: return Color(0.18, 0.2, 0.13)
		Enums.BiomeType.ROCKY: return Color(0.28, 0.26, 0.22)
		Enums.BiomeType.MARSH: return Color(0.15, 0.16, 0.12)
		Enums.BiomeType.SAVANNA: return Color(0.3, 0.3, 0.2)
		Enums.BiomeType.OCEAN: return Color(0.08, 0.1, 0.18)
	return Color(0.2, 0.22, 0.15)

func _process(_delta):
	queue_redraw()

func _find_player() -> Node:
	var players = get_tree().root.find_children("Player", "", true, false)
	if players.size() > 0:
		return players[0]
	return null
