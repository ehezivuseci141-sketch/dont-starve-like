extends Node

var last_seed: int = 0
var _noise: FastNoiseLite
var _moisture_noise: FastNoiseLite

const REGION_MAP_WIDTH: int = 256
const REGION_MAP_HEIGHT: int = 256

func _init():
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.005
	_noise.fractal_octaves = 4
	_noise.fractal_lacunarity = 2.0
	_noise.fractal_gain = 0.5

	_moisture_noise = FastNoiseLite.new()
	_moisture_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_moisture_noise.frequency = 0.008
	_moisture_noise.fractal_octaves = 3

func generate(world: Node, _seed: int):
	last_seed = _seed
	_noise.seed = _seed
	_moisture_noise.seed = _seed + 999

	world.world_grid.clear()
	world.biome_grid.clear()

	for x in range(world.MAP_WIDTH):
		for y in range(world.MAP_HEIGHT):
			var grid_pos = Vector2i(x, y)
			generate_tile(world, grid_pos)

func generate_tile(world: Node, grid_pos: Vector2i):
	var elevation = _noise.get_noise_2d(grid_pos.x as float, grid_pos.y as float)
	var moisture = _moisture_noise.get_noise_2d(grid_pos.x as float, grid_pos.y as float)
	var biome = _determine_biome(grid_pos, elevation, moisture)
	var tile = _determine_tile(biome)
	world.biome_grid[grid_pos] = biome
	world.world_grid[grid_pos] = tile

func _determine_biome(grid_pos: Vector2i, elevation: float, moisture: float) -> int:
	var center = Vector2(REGION_MAP_WIDTH / 2.0, REGION_MAP_HEIGHT / 2.0)
	var rel = Vector2(grid_pos.x, grid_pos.y) - center
	var dist = rel.length()
	var edge_margin = mini(
		mini(grid_pos.x, REGION_MAP_WIDTH - 1 - grid_pos.x),
		mini(grid_pos.y, REGION_MAP_HEIGHT - 1 - grid_pos.y)
	)

	# Keep the spawn area safe, then push harsher biomes away from center.
	if dist < 26.0:
		return Enums.BiomeType.GRASSLAND
	if rel.x > 48.0 and rel.y < -34.0 and edge_margin > 18:
		return Enums.BiomeType.LAVA
	if edge_margin < 24:
		if rel.x > 20.0 and rel.y < -12.0:
			return Enums.BiomeType.LAVA
		return Enums.BiomeType.ROCKY
	if rel.y < -36.0:
		if rel.x < 28.0 and moisture > -0.12:
			return Enums.BiomeType.FOREST
		return Enums.BiomeType.ROCKY
	if rel.y > 44.0:
		return Enums.BiomeType.MARSH

	if elevation < -0.35:
		return Enums.BiomeType.OCEAN
	if elevation > 0.4:
		return Enums.BiomeType.ROCKY
	if elevation < -0.1 and moisture > 0.3:
		return Enums.BiomeType.MARSH
	if elevation > 0.15 and moisture < 0.2:
		return Enums.BiomeType.FOREST
	if elevation > 0.05 and moisture < -0.1:
		return Enums.BiomeType.SAVANNA
	return Enums.BiomeType.GRASSLAND

func _determine_tile(biome: int) -> int:
	match biome:
		Enums.BiomeType.OCEAN: return 5
		Enums.BiomeType.FOREST: return 0
		Enums.BiomeType.GRASSLAND: return 1
		Enums.BiomeType.ROCKY: return 2
		Enums.BiomeType.MARSH: return 3
		Enums.BiomeType.SAVANNA: return 4
		Enums.BiomeType.LAVA: return 6
	return 1

func get_spawn_point(world: Node) -> Vector2:
	var center = Vector2i(world.MAP_WIDTH / 2, world.MAP_HEIGHT / 2)
	for radius in range(20):
		for angle_step in range(max(1, radius * 6)):
			var angle = angle_step * TAU / max(1, radius * 6)
			var check_pos = Vector2i(
				center.x + int(cos(angle) * radius),
				center.y + int(sin(angle) * radius)
			)
			if check_pos.x < 0 or check_pos.x >= world.MAP_WIDTH:
				continue
			if check_pos.y < 0 or check_pos.y >= world.MAP_HEIGHT:
				continue
			var biome = world.biome_grid.get(check_pos, Enums.BiomeType.OCEAN)
			if biome != Enums.BiomeType.OCEAN:
				return world.grid_to_world(check_pos)
	return world.grid_to_world(center)
