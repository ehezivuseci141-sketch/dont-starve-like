# Ground renderer - draws biome-colored background tiles
extends Node2D

var _tile_size: int = 96
const EXTRA_TILE_MARGIN: int = 2
var _tex_variants: Dictionary = {} # biome:int -> Array[Texture2D]
var _tex_tile_size: int = -1

func _draw():
	var player = _find_player()
	var camera = get_viewport().get_camera_2d()
	if player == null and camera == null:
		return

	_tile_size = WorldManager.TILE_SIZE
	_ensure_textures()
	var center = camera.global_position if camera != null else player.global_position
	var viewport_size = get_viewport_rect().size
	var zoom_x = maxf(0.05, camera.zoom.x if camera != null else 1.0)
	var zoom_y = maxf(0.05, camera.zoom.y if camera != null else 1.0)
	var half_world = Vector2(viewport_size.x / zoom_x, viewport_size.y / zoom_y) * 0.5
	half_world += Vector2(_tile_size * EXTRA_TILE_MARGIN, _tile_size * EXTRA_TILE_MARGIN)

	var min_grid = WorldManager.world_to_grid(center - half_world)
	var max_grid = WorldManager.world_to_grid(center + half_world)
	WorldManager.ensure_region(min_grid, max_grid)

	for x in range(min_grid.x, max_grid.x + 1):
		for y in range(min_grid.y, max_grid.y + 1):
			var grid_pos = Vector2i(x, y)
			var biome = WorldManager.biome_grid.get(grid_pos, Enums.BiomeType.GRASSLAND)
			var world_pos = WorldManager.grid_to_world(grid_pos)

			# Adjust position relative to this node (which should be at 0,0 in world)
			var draw_pos = world_pos - global_position
			var tex = _pick_tile_texture(biome, grid_pos)
			if tex:
				draw_texture_rect(tex, Rect2(draw_pos - Vector2(_tile_size / 2.0, _tile_size / 2.0), Vector2(_tile_size, _tile_size)), false)
			else:
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

func _ensure_textures():
	if _tex_tile_size == _tile_size and not _tex_variants.is_empty():
		return
	_tex_tile_size = _tile_size
	_tex_variants.clear()

	# 3 variants per biome to reduce repetition.
	_tex_variants[Enums.BiomeType.GRASSLAND] = _make_variants(Color(0.18, 0.30, 0.16), Color(0.10, 0.20, 0.10), 3, 0.22)
	_tex_variants[Enums.BiomeType.FOREST] = _make_variants(Color(0.10, 0.20, 0.10), Color(0.06, 0.12, 0.06), 3, 0.20)
	_tex_variants[Enums.BiomeType.ROCKY] = _make_variants(Color(0.26, 0.25, 0.23), Color(0.14, 0.14, 0.15), 3, 0.18)
	_tex_variants[Enums.BiomeType.MARSH] = _make_variants(Color(0.12, 0.16, 0.12), Color(0.07, 0.10, 0.07), 3, 0.20)
	_tex_variants[Enums.BiomeType.SAVANNA] = _make_variants(Color(0.30, 0.30, 0.18), Color(0.20, 0.18, 0.08), 3, 0.18)
	_tex_variants[Enums.BiomeType.OCEAN] = _make_variants(Color(0.06, 0.10, 0.18), Color(0.03, 0.06, 0.12), 3, 0.16)

func _pick_tile_texture(biome: int, grid_pos: Vector2i) -> Texture2D:
	var arr = _tex_variants.get(biome, null)
	if arr == null or arr.is_empty():
		return null
	var idx = int(_hash2i(grid_pos.x, grid_pos.y) % arr.size())
	return arr[idx]

func _make_variants(base_col: Color, accent_col: Color, count: int, noise_amount: float) -> Array:
	var out: Array = []
	for i in range(count):
		out.append(_make_tile_tex(base_col, accent_col, noise_amount, i * 977))
	return out

func _make_tile_tex(base_col: Color, accent_col: Color, noise_amount: float, salt: int) -> Texture2D:
	var img = Image.create(_tile_size, _tile_size, false, Image.FORMAT_RGBA8)

	var seed = 1337
	if WorldManager.map_generator != null:
		seed = int(WorldManager.map_generator.last_seed)
	var local_seed = _hash2i(seed + salt, _tile_size * 17 + salt * 3)

	for y in range(_tile_size):
		for x in range(_tile_size):
			var n = _rand01(_hash2i(local_seed, _hash2i(x, y)))
			# Two-layer noise: soft base + sparse accent specks.
			var c = base_col.lerp(accent_col, (n - 0.5) * noise_amount + noise_amount * 0.5)
			var speck = _rand01(_hash2i(local_seed + 91, _hash2i(x * 3, y * 3)))
			if speck > 0.985:
				c = c.lerp(Color(1, 1, 1), 0.10)
			elif speck < 0.015:
				c = c.lerp(Color(0, 0, 0), 0.10)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))

	# Subtle edge variation to break perfect grid seams.
	var edge_dark = base_col.darkened(0.12)
	for i in range(_tile_size):
		if i % 2 == 0:
			img.set_pixel(i, 0, Color(edge_dark.r, edge_dark.g, edge_dark.b, 1.0))
			img.set_pixel(0, i, Color(edge_dark.r, edge_dark.g, edge_dark.b, 1.0))

	var tex = ImageTexture.create_from_image(img)
	return tex

func _hash2i(a: int, b: int) -> int:
	# Deterministic 32-bit-ish mixing.
	var x = int(a) * 374761393 + int(b) * 668265263
	x = (x ^ (x >> 13)) * 1274126177
	return x ^ (x >> 16)

func _rand01(h: int) -> float:
	# Map hash to [0,1).
	var v = float(h & 0x7fffffff) / 2147483648.0
	return v
