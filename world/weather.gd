extends Node

var current_weather: int = Enums.Weather.CLEAR
var weather_timer: float = 0.0
var weather_duration: float = 0.0
var wetness: float = 0.0

const WETNESS_MAX: float = 100.0
const WETNESS_DRY_RATE: float = 2.0

func _ready():
	Signals.season_changed.connect(_on_season_changed)
	_pick_new_weather()

func _process(delta: float):
	weather_timer -= delta
	if weather_timer <= 0.0:
		_pick_new_weather()

	if current_weather == Enums.Weather.RAIN or current_weather == Enums.Weather.STORM:
		wetness = minf(wetness + 5.0 * delta, WETNESS_MAX)
		if wetness > 50:
			SurvivalManager.modify_sanity(-1.0 * delta)
	else:
		wetness = maxf(wetness - WETNESS_DRY_RATE * delta, 0.0)

func _pick_new_weather():
	var pool = _get_weather_pool(DayNightCycle.current_season)
	if pool.is_empty():
		pool = [Enums.Weather.CLEAR]
	current_weather = pool[randi() % pool.size()]
	weather_duration = randf_range(60.0, 180.0)
	weather_timer = weather_duration
	Signals.weather_changed.emit(current_weather)

func _get_weather_pool(season: int) -> Array:
	match season:
		Enums.Season.SPRING:
			return [Enums.Weather.CLEAR, Enums.Weather.CLEAR, Enums.Weather.RAIN, Enums.Weather.RAIN, Enums.Weather.FOG]
		Enums.Season.SUMMER:
			return [Enums.Weather.CLEAR, Enums.Weather.CLEAR, Enums.Weather.CLEAR, Enums.Weather.RAIN, Enums.Weather.FOG]
		Enums.Season.AUTUMN:
			return [Enums.Weather.CLEAR, Enums.Weather.CLEAR, Enums.Weather.CLEAR, Enums.Weather.RAIN, Enums.Weather.FOG]
		Enums.Season.WINTER:
			return [Enums.Weather.CLEAR, Enums.Weather.CLEAR, Enums.Weather.SNOW, Enums.Weather.SNOW, Enums.Weather.FOG]
	return [Enums.Weather.CLEAR]

func _on_season_changed(_new_season: int):
	_pick_new_weather()

func is_raining() -> bool:
	return current_weather == Enums.Weather.RAIN or current_weather == Enums.Weather.STORM

func is_snowing() -> bool:
	return current_weather == Enums.Weather.SNOW

func get_weather_name() -> String:
	match current_weather:
		Enums.Weather.CLEAR: return "Sunny"
		Enums.Weather.RAIN: return "Rain"
		Enums.Weather.SNOW: return "Snow"
		Enums.Weather.FOG: return "Fog"
		Enums.Weather.STORM: return "Storm"
	return "Unknown"

func get_movement_penalty() -> float:
	if current_weather == Enums.Weather.STORM:
		return 0.7
	if current_weather == Enums.Weather.SNOW:
		return 0.85
	return 1.0

func serialize() -> Dictionary:
	return {"current_weather": current_weather, "wetness": wetness}

func deserialize(data: Dictionary):
	current_weather = data.get("current_weather", Enums.Weather.CLEAR)
	wetness = data.get("wetness", 0.0)
	Signals.weather_changed.emit(current_weather)
