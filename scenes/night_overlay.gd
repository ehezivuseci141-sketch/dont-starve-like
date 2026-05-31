# Night overlay - darkens screen at night
extends CanvasLayer

var _color_rect: ColorRect

func _ready():
	_color_rect = ColorRect.new()
	_color_rect.size = get_viewport().get_visible_rect().size
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_color_rect)
	Signals.time_of_day_changed.connect(_on_time_changed)

func _process(_delta):
	if _color_rect == null:
		return
	_color_rect.size = get_viewport().get_visible_rect().size
	match DayNightCycle.current_time_of_day:
		Enums.TimeOfDay.DAY:
			_color_rect.color = Color(0, 0, 0, 0)
		Enums.TimeOfDay.DUSK:
			_color_rect.color = Color(0.5, 0.25, 0.1, 0.2)
		Enums.TimeOfDay.NIGHT:
			_color_rect.color = Color(0.03, 0.03, 0.15, 0.5)

func _on_time_changed(_t: int):
	pass
