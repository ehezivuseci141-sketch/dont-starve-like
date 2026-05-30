# Survival stats (hunger/health/sanity)
extends Node

var hunger: float = 100.0
var health: float = 100.0
var sanity: float = 100.0

const HUNGER_MAX: float = 150.0
const HEALTH_MAX: float = 150.0
const SANITY_MAX: float = 200.0

const HUNGER_DRAIN: float = 0.3
const HUNGER_DRAIN_WINTER: float = 0.75
const NIGHT_SANITY_DRAIN: float = 1.5

var _current_hunger_drain: float = HUNGER_DRAIN

func _ready():
	Signals.season_changed.connect(_on_season_changed)

func _process(delta: float):
	# Hunger always decays
	modify_hunger(-_current_hunger_drain * delta)

	# At night: sanity drain (darkness is scary)
	if DayNightCycle.is_nighttime():
		modify_sanity(-NIGHT_SANITY_DRAIN * delta)
	# During day: slow sanity recovery
	elif DayNightCycle.is_daytime():
		modify_sanity(0.3 * delta)

	# Starvation damages health
	if hunger <= 0:
		modify_health(-3.0 * delta)

	# Death
	if health <= 0:
		Signals.player_died.emit("starvation" if hunger <= 0 else "damage")

func modify_hunger(amount: float):
	hunger = clampf(hunger + amount, 0.0, HUNGER_MAX)
	Signals.hunger_changed.emit(hunger, HUNGER_MAX)
	if hunger <= 0:
		Signals.player_starving.emit()

func modify_health(amount: float):
	health = clampf(health + amount, 0.0, HEALTH_MAX)
	Signals.health_changed.emit(health, HEALTH_MAX)

func modify_sanity(amount: float):
	sanity = clampf(sanity + amount, 0.0, SANITY_MAX)
	Signals.sanity_changed.emit(sanity, SANITY_MAX)
	if sanity <= 30:
		Signals.player_insane.emit()

func eat(item_id: String):
	var item = ItemDB.get_item(item_id)
	if not item.get("eatable", false):
		return
	modify_hunger(item.get("hunger_restore", 0.0))
	modify_health(item.get("health_restore", 0.0))
	modify_sanity(item.get("sanity_restore", 0.0))
	Signals.player_ate.emit(item_id)

func take_damage(amount: float):
	modify_health(-amount)

func full_restore():
	hunger = HUNGER_MAX
	health = HEALTH_MAX
	sanity = SANITY_MAX
	Signals.hunger_changed.emit(hunger, HUNGER_MAX)
	Signals.health_changed.emit(health, HEALTH_MAX)
	Signals.sanity_changed.emit(sanity, SANITY_MAX)

func _on_season_changed(new_season: int):
	if new_season == Enums.Season.WINTER:
		_current_hunger_drain = HUNGER_DRAIN_WINTER
	else:
		_current_hunger_drain = HUNGER_DRAIN

func serialize() -> Dictionary:
	return {"hunger": hunger, "health": health, "sanity": sanity, "current_hunger_drain": _current_hunger_drain}

func deserialize(data: Dictionary):
	hunger = data.get("hunger", HUNGER_MAX)
	health = data.get("health", HEALTH_MAX)
	sanity = data.get("sanity", SANITY_MAX)
	_current_hunger_drain = data.get("current_hunger_drain", HUNGER_DRAIN)
	Signals.hunger_changed.emit(hunger, HUNGER_MAX)
	Signals.health_changed.emit(health, HEALTH_MAX)
	Signals.sanity_changed.emit(sanity, SANITY_MAX)
