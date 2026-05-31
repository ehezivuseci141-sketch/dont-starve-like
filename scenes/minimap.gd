# Simple minimap (nearby tiles + player + resources)
extends Control

const SMALL_SIZE: Vector2 = Vector2(190, 190)
const LARGE_SIZE: Vector2 = Vector2(680, 680)
const PADDING: float = 12.0
const TILE_RANGE_MIN: int = 8
const TILE_RANGE_MAX: int = 40

var _open: bool = false
var _tile_range: int = 18
var _tile_range_small: int = 14
var _pan_grid: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_from: Vector2 = Vector2.ZERO
var _pan_from: Vector2 = Vector2.ZERO
var _dest_world: Vector2 = Vector2.ZERO
var _has_dest: bool = false
var _pressed_left: bool = false
var _press_pos: Vector2 = Vector2.ZERO
var _press_time_ms: int = 0
var _last_click_time_ms: int = 0
var _last_click_pos: Vector2 = Vector2.ZERO
const CLICK_MAX_MOVE: float = 6.0
const DRAG_START_MOVE: float = 8.0
const DOUBLE_CLICK_MS: int = 320

func _ready():
	_open = false
	visible = true
	Signals.map_open = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(_delta):
	queue_redraw()

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == KEY_M:
			_open = not _open
			Signals.map_open = _open
			mouse_filter = Control.MOUSE_FILTER_STOP if _open else Control.MOUSE_FILTER_IGNORE
			if _open:
				_pan_grid = Vector2.ZERO
			return
		if _open and code == KEY_ESCAPE:
			_open = false
			Signals.map_open = false
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			return
		if _open and (code == KEY_EQUAL or code == KEY_KP_ADD):
			_zoom_in()
			return
		if _open and (code == KEY_MINUS or code == KEY_KP_SUBTRACT):
			_zoom_out()
			return

	if _open and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_pan_grid = Vector2.ZERO
			_has_dest = false
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pressed_left = true
			_press_pos = event.position
			_dragging = false
			_drag_from = event.position
			_pan_from = _pan_grid
			_press_time_ms = Time.get_ticks_msec()
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_in()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_out()
			accept_event()
	elif _open and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _pressed_left:
			return
		_pressed_left = false
		# Click if we didn't drag.
		var moved = event.position.distance_to(_press_pos)
		if _dragging or moved > CLICK_MAX_MOVE:
			_dragging = false
			return

		var now_ms = Time.get_ticks_msec()
		var is_double = (now_ms - _last_click_time_ms) <= DOUBLE_CLICK_MS and event.position.distance_to(_last_click_pos) <= CLICK_MAX_MOVE
		_last_click_time_ms = now_ms
		_last_click_pos = event.position

		var wp = _map_click_to_world(event.position)
		if wp == null:
			return
		_dest_world = wp
		_has_dest = true
		if is_double:
			var p = _find_player()
			if p and p.has_method("set_move_target"):
				p.set_move_target(_dest_world)
		accept_event()

	if _open and event is InputEventMouseMotion and _pressed_left:
		# Start drag only after a small threshold; otherwise keep as click candidate.
		var moved = event.position.distance_to(_press_pos)
		if not _dragging and moved >= DRAG_START_MOVE:
			_dragging = true
		if _dragging:
			var viewport_size = get_viewport().get_visible_rect().size
			var map_size = _current_map_size(viewport_size)
			var draw_range = _tile_range
			var tiles = draw_range * 2 + 1
			var cell = map_size.x / float(tiles)
			if cell > 1.0:
				var delta = event.position - _drag_from
				_pan_grid = _pan_from - delta / cell
			accept_event()

func _zoom_in():
	_tile_range = maxi(TILE_RANGE_MIN, _tile_range - 2)

func _zoom_out():
	_tile_range = mini(TILE_RANGE_MAX, _tile_range + 2)

func _draw():
	var player = _find_player()
	if player == null:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var map_size = _current_map_size(viewport_size)
	var top_left = _current_map_pos(viewport_size, map_size)

	if _open:
		# Dim full screen background
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0, 0, 0, 0.35))

	# Background panel
	draw_rect(Rect2(top_left, map_size), Color(0.03, 0.03, 0.03, 0.82))
	draw_rect(Rect2(top_left, map_size), Color(1, 1, 1, 0.14), false, 1.0)

	var center_grid = WorldManager.world_to_grid(player.global_position)
	var draw_range = _tile_range if _open else _tile_range_small
	var center_offset = Vector2i(int(round(_pan_grid.x)), int(round(_pan_grid.y))) if _open else Vector2i.ZERO
	var map_center = center_grid + center_offset
	WorldManager.mark_explored_at(player.global_position, draw_range)
	var tiles = draw_range * 2 + 1
	var cell = map_size.x / float(tiles)

	# Tiles
	for dx in range(-draw_range, draw_range + 1):
		for dy in range(-draw_range, draw_range + 1):
			var gp = map_center + Vector2i(dx, dy)
			WorldManager.ensure_tile(gp)
			if not WorldManager.is_explored(gp):
				continue
			var biome = WorldManager.biome_grid.get(gp, Enums.BiomeType.GRASSLAND)
			var c = _biome_color(biome)
			var px = top_left.x + (dx + draw_range) * cell
			var py = top_left.y + (dy + draw_range) * cell
			draw_rect(Rect2(Vector2(px, py), Vector2(cell + 0.5, cell + 0.5)), c)

	# Resources (only in a small radius for perf)
	var res_nodes = get_tree().root.find_children("*", "Area2D", true, false)
	for n in res_nodes:
		if not n.is_in_group("Pickable"):
			continue
		if not (n is Node2D):
			continue
		var gp2 = WorldManager.world_to_grid(n.global_position)
		if not WorldManager.is_explored(gp2):
			continue
		var dd = gp2 - map_center
		if abs(dd.x) > draw_range or abs(dd.y) > draw_range:
			continue
		var p2 = top_left + Vector2((dd.x + draw_range) * cell + cell * 0.5, (dd.y + draw_range) * cell + cell * 0.5)
		draw_circle(p2, maxf(1.5, cell * 0.18), _resource_color(n))

	# Player marker
	var player_dd = center_grid - map_center
	var player_px: Variant = null
	if abs(player_dd.x) <= draw_range and abs(player_dd.y) <= draw_range:
		player_px = top_left + Vector2((player_dd.x + draw_range) * cell + cell * 0.5, (player_dd.y + draw_range) * cell + cell * 0.5)
		_draw_player_marker(player_px, cell)

	# Destination + route (fullscreen only)
	if _open and _has_dest and player_px != null:
		var dest_grid = WorldManager.world_to_grid(_dest_world)
		if WorldManager.is_explored(dest_grid):
			var dd2 = dest_grid - map_center
			if abs(dd2.x) <= draw_range and abs(dd2.y) <= draw_range:
				var dest_px = top_left + Vector2((dd2.x + draw_range) * cell + cell * 0.5, (dd2.y + draw_range) * cell + cell * 0.5)
				_draw_route_and_dest(player_px, dest_px, cell)

func _draw_player_marker(pos: Vector2, cell: float):
	var r = maxf(2.6, cell * 0.22)
	draw_circle(pos, r, Color(1.0, 0.92, 0.30))
	draw_circle(pos, maxf(1.4, cell * 0.10), Color(0.10, 0.08, 0.02))
	# Facing indicator (uses last known direction)
	var d = WorldManager.last_player_dir
	if d.length() < 0.01:
		d = Vector2.DOWN
	d = d.normalized()
	var tip = pos + d * (r + 4.0)
	draw_line(pos, tip, Color(1.0, 0.92, 0.30), 2.0)

func _draw_route_and_dest(from_px: Vector2, to_px: Vector2, cell: float):
	var w = maxf(2.0, cell * 0.10)
	draw_line(from_px, to_px, Color(1.0, 0.92, 0.30, 0.55), w)
	draw_circle(to_px, maxf(3.0, cell * 0.18), Color(1.0, 0.92, 0.30, 0.85))
	draw_circle(to_px, maxf(1.6, cell * 0.10), Color(0.10, 0.08, 0.02, 0.9))

func _current_map_size(viewport_size: Vector2) -> Vector2:
	if _open:
		var max_side = minf(viewport_size.x, viewport_size.y)
		var target = LARGE_SIZE.x
		var side = minf(target, max_side - PADDING * 2.0)
		side = maxf(320.0, side)
		return Vector2(side, side)
	return SMALL_SIZE

func _current_map_pos(viewport_size: Vector2, map_size: Vector2) -> Vector2:
	if _open:
		return Vector2((viewport_size.x - map_size.x) * 0.5, (viewport_size.y - map_size.y) * 0.5)
	return Vector2(viewport_size.x - map_size.x - PADDING, PADDING)

func _map_click_to_world(screen_pos: Vector2) -> Variant:
	if not _open:
		return null
	var player = _find_player()
	if player == null:
		return null
	var viewport_size = get_viewport().get_visible_rect().size
	var map_size = _current_map_size(viewport_size)
	var top_left = _current_map_pos(viewport_size, map_size)
	if not Rect2(top_left, map_size).has_point(screen_pos):
		return null

	var center_grid = WorldManager.world_to_grid(player.global_position)
	var center_offset = Vector2i(int(round(_pan_grid.x)), int(round(_pan_grid.y)))
	var map_center = center_grid + center_offset
	var draw_range = _tile_range
	var tiles = draw_range * 2 + 1
	var cell = map_size.x / float(tiles)
	if cell <= 0.5:
		return null
	var local = screen_pos - top_left
	var gx = int(floor(local.x / cell)) - draw_range
	var gy = int(floor(local.y / cell)) - draw_range
	var gp = map_center + Vector2i(gx, gy)
	if not WorldManager.is_explored(gp):
		return null
	return WorldManager.grid_to_world(gp)

func _resource_color(n: Node) -> Color:
	# resource_node.gd uses drop_item_id; simple_pickable.gd uses item_id
	var item_id = ""
	if n.has_method("get"):
		item_id = str(n.get("drop_item_id")) if n.get("drop_item_id") != null else ""
		if item_id == "":
			item_id = str(n.get("item_id")) if n.get("item_id") != null else ""
	match item_id:
		"log":
			return Color(0.40, 0.25, 0.12)
		"rocks", "flint":
			return Color(0.70, 0.70, 0.72)
		"gold_nugget":
			return Color(1.0, 0.85, 0.10)
		"berries":
			return Color(0.92, 0.20, 0.28)
		"carrot":
			return Color(1.0, 0.55, 0.15)
		"cut_grass", "twigs":
			return Color(0.65, 0.80, 0.35)
		_:
			return Color(0.85, 0.85, 0.85)

func _biome_color(biome: int) -> Color:
	match biome:
		Enums.BiomeType.GRASSLAND: return Color(0.22, 0.30, 0.18)
		Enums.BiomeType.FOREST: return Color(0.14, 0.20, 0.12)
		Enums.BiomeType.ROCKY: return Color(0.28, 0.27, 0.25)
		Enums.BiomeType.MARSH: return Color(0.14, 0.18, 0.14)
		Enums.BiomeType.SAVANNA: return Color(0.30, 0.29, 0.18)
		Enums.BiomeType.OCEAN: return Color(0.06, 0.09, 0.16)
	return Color(0.22, 0.30, 0.18)

func _find_player() -> Node:
	var p = get_tree().root.find_children("Player", "", true, false)
	if p.size() > 0:
		return p[0]
	return null
