extends Node2D
class_name TerrainSystem

var _tile_size: int = 96
const EXTRA_TILE_MARGIN: int = 2
var _tex_variants: Dictionary = {} # biome:int -> Array[Texture2D]
var _tex_tile_size: int = -1
var _last_region_id: String = ""
var _region_banner: Label
var _zone_label: Label
var _danger_edges: Array[ColorRect] = []
var _region_flash_left: float = 0.0
var _danger_flash_left: float = 0.0

const REGION_FLASH_TIME: float = 1.6
const DANGER_FLASH_TIME: float = 1.1

func _ready():
	z_index = -10
	_setup_region_overlay()

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
				var tint = Color.WHITE.lerp(WorldManager.get_region_color(WorldManager.get_region_id(world_pos)).lightened(0.18), 0.18)
				draw_texture_rect(tex, Rect2(draw_pos - Vector2(_tile_size / 2.0, _tile_size / 2.0), Vector2(_tile_size, _tile_size)), false, tint)
			else:
				var color = _biome_color(biome, world_pos)
				draw_rect(Rect2(draw_pos - Vector2(_tile_size/2, _tile_size/2),
					Vector2(_tile_size, _tile_size)), color)

func _biome_color(biome: int, world_pos: Vector2 = Vector2.ZERO) -> Color:
	var base = Color(0.2, 0.22, 0.15)
	if biome == Enums.BiomeType.GRASSLAND:
		base = Color(0.25, 0.28, 0.18)
	elif biome == Enums.BiomeType.FOREST:
		base = Color(0.18, 0.2, 0.13)
	elif biome == Enums.BiomeType.ROCKY:
		base = Color(0.28, 0.26, 0.22)
	elif biome == Enums.BiomeType.MARSH:
		base = Color(0.15, 0.16, 0.12)
	elif biome == Enums.BiomeType.SAVANNA:
		base = Color(0.3, 0.3, 0.2)
	elif biome == Enums.BiomeType.OCEAN:
		base = Color(0.08, 0.1, 0.18)
	elif biome == Enums.BiomeType.LAVA:
		base = Color(0.25, 0.05, 0.03)
	if world_pos != Vector2.ZERO:
		base = base.lerp(WorldManager.get_region_color(WorldManager.get_region_id(world_pos)), 0.35)
	return base

func _process(delta):
	_update_region_overlay(delta)
	queue_redraw()

func _setup_region_overlay():
	var layer = CanvasLayer.new()
	layer.name = "RegionOverlay"
	add_child(layer)

	_region_banner = Label.new()
	_region_banner.visible = false
	_region_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_region_banner.add_theme_font_size_override("font_size", 30)
	_region_banner.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
	_region_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_region_banner.add_theme_constant_override("shadow_offset_x", 2)
	_region_banner.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(_region_banner)

	_zone_label = Label.new()
	_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_zone_label.add_theme_font_size_override("font_size", 18)
	_zone_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78))
	_zone_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_zone_label.add_theme_constant_override("shadow_offset_x", 2)
	_zone_label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(_zone_label)

	for i in range(4):
		var edge = ColorRect.new()
		edge.color = Color(1.0, 0.08, 0.04, 0.0)
		edge.visible = false
		layer.add_child(edge)
		_danger_edges.append(edge)

func _update_region_overlay(delta: float):
	var player = _find_player()
	if player == null or _region_banner == null:
		return

	var region_id = WorldManager.get_region_id(player.global_position)
	_zone_label.text = WorldManager.get_biome_display_name(player.global_position)
	if region_id != _last_region_id:
		_last_region_id = region_id
		_region_flash_left = REGION_FLASH_TIME
		_region_banner.text = WorldManager.get_region_name(region_id)
		_region_banner.visible = true
		if WorldManager.is_danger_region(region_id):
			_danger_flash_left = DANGER_FLASH_TIME

	var vp = get_viewport_rect().size
	_zone_label.position = Vector2(vp.x - 230.0, vp.y - 54.0)
	_zone_label.size = Vector2(210.0, 28.0)
	_region_banner.position = Vector2(vp.x * 0.5 - 160.0, vp.y * 0.34)
	_region_banner.size = Vector2(320.0, 42.0)

	if _region_flash_left > 0.0:
		_region_flash_left = maxf(0.0, _region_flash_left - delta)
		var banner_modulate = _region_banner.modulate
		banner_modulate.a = minf(1.0, _region_flash_left / 0.35)
		_region_banner.modulate = banner_modulate
	else:
		_region_banner.visible = false

	if _danger_flash_left > 0.0:
		_danger_flash_left = maxf(0.0, _danger_flash_left - delta)
		_layout_danger_edges(vp, _danger_flash_left / DANGER_FLASH_TIME)
	else:
		for edge in _danger_edges:
			edge.visible = false

func _layout_danger_edges(vp: Vector2, strength: float):
	var thick = 18.0
	var alpha = 0.32 * clampf(strength, 0.0, 1.0)
	var rects = [
		Rect2(0, 0, vp.x, thick),
		Rect2(0, vp.y - thick, vp.x, thick),
		Rect2(0, 0, thick, vp.y),
		Rect2(vp.x - thick, 0, thick, vp.y)
	]
	for i in range(_danger_edges.size()):
		var edge = _danger_edges[i]
		edge.visible = true
		edge.position = rects[i].position
		edge.size = rects[i].size
		edge.color = Color(1.0, 0.08, 0.04, alpha)

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

	_load_terrain_texture(Enums.BiomeType.GRASSLAND, "grass.png", Color(0.18, 0.30, 0.16), Color(0.10, 0.20, 0.10))
	_load_terrain_texture(Enums.BiomeType.FOREST, "forest_ground.png", Color(0.10, 0.20, 0.10), Color(0.06, 0.12, 0.06))
	_load_terrain_texture(Enums.BiomeType.ROCKY, "rocky_ground.png", Color(0.26, 0.25, 0.23), Color(0.14, 0.14, 0.15))
	_load_terrain_texture(Enums.BiomeType.MARSH, "swamp_ground.png", Color(0.12, 0.16, 0.12), Color(0.07, 0.10, 0.07))
	_load_terrain_texture(Enums.BiomeType.LAVA, "lava_ground.png", Color(0.20, 0.04, 0.03), Color(0.95, 0.20, 0.05))
	_tex_variants[Enums.BiomeType.SAVANNA] = _make_variants(Color(0.30, 0.30, 0.18), Color(0.20, 0.18, 0.08), 3, 0.18)
	_tex_variants[Enums.BiomeType.OCEAN] = _make_variants(Color(0.06, 0.10, 0.18), Color(0.03, 0.06, 0.12), 3, 0.16)

func _load_terrain_texture(biome: int, file_name: String, base_col: Color, accent_col: Color):
	var path = "res://assets/terrain/%s" % file_name
	var tex = _load_png_texture(path)
	if tex == null:
		print("[TerrainSystem] missing terrain texture: %s; generating fallback PNG" % path)
		_save_fallback_png(path, base_col, accent_col)
		tex = _load_png_texture(path)
	if tex:
		_tex_variants[biome] = [tex]
		print("Loaded terrain texture: %s" % file_name)
	else:
		print("[TerrainSystem] failed to load terrain texture: %s" % path)
		_tex_variants[biome] = _make_variants(base_col, accent_col, 1, 0.22)

func _load_png_texture(path: String) -> Texture2D:
	var img = Image.new()
	var err = img.load(path)
	if err != OK:
		return null
	return ImageTexture.create_from_image(img)

func _save_fallback_png(path: String, base_col: Color, accent_col: Color):
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var h = _hash2i(x * 19 + y * 7, y * 31 + x)
			var n = _rand01(h)
			var c = base_col.lerp(accent_col, n)
			if (x + y + int(n * 10.0)) % 17 < 2:
				c = accent_col
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	img.save_png(path)

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
