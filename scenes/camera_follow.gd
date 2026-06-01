# Camera follow + zoom system — ACTION / STRATEGIC modes
extends Camera2D
class_name CameraController

var target: Node2D
var _zoom_target: float = 1.5
const ZOOM_MIN: float = 0.4
const ZOOM_MAX: float = 2.5
const ZOOM_SPEED: float = 8.0
const ACTION_FOLLOW_SPEED: float = 26.0
const STRATEGIC_FOLLOW_SPEED: float = 14.0
const LOOK_AHEAD_DISTANCE: float = 36.0
const LOOK_AHEAD_SPEED: float = 10.0
var _look_ahead: Vector2 = Vector2.ZERO

func _ready():
	enabled = true
	make_current()
	position_smoothing_enabled = true
	position_smoothing_speed = 10.0
	var players = get_tree().root.find_children("Player", "", true, false)
	if players.size() > 0:
		target = players[0]

func _process(delta: float):
	if not target:
		return

	# Keep ACTION mode crisp; STRATEGIC mode can stay a little smoother.
	var follow_speed = STRATEGIC_FOLLOW_SPEED if is_strategic() else ACTION_FOLLOW_SPEED
	var desired_ahead = Vector2.ZERO
	var dir = WorldManager.last_player_dir
	if dir.length() > 0.01 and not is_strategic():
		desired_ahead = dir.normalized() * LOOK_AHEAD_DISTANCE
	_look_ahead = _look_ahead.lerp(desired_ahead, minf(1.0, LOOK_AHEAD_SPEED * delta))
	global_position = global_position.lerp(target.global_position + _look_ahead, minf(1.0, follow_speed * delta))

	# Smooth zoom
	zoom = zoom.lerp(Vector2(_zoom_target, _zoom_target), ZOOM_SPEED * delta)

func _input(event: InputEvent):
	# When fullscreen map is open, ignore zoom inputs.
	if Signals.map_open:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_target = minf(ZOOM_MAX, _zoom_target + 0.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_target = maxf(ZOOM_MIN, _zoom_target - 0.15)

func is_strategic() -> bool:
	return _zoom_target < 0.9

func zoom_level() -> float:
	return _zoom_target
