# HUD controller
extends Node

@onready var hunger_bar = get_node("../StatBars/HungerBar")
@onready var health_bar = get_node("../StatBars/HealthBar")
@onready var time_label = get_node("../StatBars/TimeLabel")
@onready var weather_label = get_node("../StatBars/WeatherLabel")

func _ready():
	Signals.hunger_changed.connect(_on_hunger_changed)
	Signals.health_changed.connect(_on_health_changed)
	Signals.day_elapsed.connect(_on_day_elapsed)
	Signals.time_of_day_changed.connect(_on_time_changed)
	Signals.season_changed.connect(_on_season_changed)
	Signals.weather_changed.connect(_on_weather_changed)
	_update_all_labels()

func _on_hunger_changed(current: float, max_val: float):
	if hunger_bar:
		hunger_bar.max_value = max_val
		hunger_bar.value = current

func _on_health_changed(current: float, max_val: float):
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current

func _on_day_elapsed(_day: int):
	_update_all_labels()

func _on_time_changed(_new_time: int):
	_update_all_labels()

func _on_season_changed(_new_season: int):
	_update_all_labels()

func _on_weather_changed(_new_weather: int):
	_update_all_labels()

func _update_all_labels():
	if time_label:
		var time_name = "Day"
		match DayNightCycle.current_time_of_day:
			Enums.TimeOfDay.DAY: time_name = "Day"
			Enums.TimeOfDay.DUSK: time_name = "Dusk"
			Enums.TimeOfDay.NIGHT: time_name = "Night"
		time_label.text = "Day %d | %s | %s" % [
			DayNightCycle.current_day, time_name,
			Enums.season_name(DayNightCycle.current_season)
		]
	if weather_label:
		weather_label.text = "%s | Wet: %.0f%%" % [
			WeatherSystem.get_weather_name(), WeatherSystem.wetness
		]
