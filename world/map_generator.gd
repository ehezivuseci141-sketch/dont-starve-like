extends Node
class_name MapGenerator

var last_seed: int = 0
var _noise: FastNoiseLite
var _moisture_noise: FastNoiseLite

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
	var biome = _determine_biome(elevation, moisture)
	var tile = _determine_tile(biome)
	world.biome_grid[grid_pos] = biome
	world.world_grid[grid_pos] = tile

func _determine_biome(elevation: float, moisture: float) -> int:
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
