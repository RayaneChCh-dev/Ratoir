class_name TouchJoystick
extends Control
## Joystick flottant plein écran : il apparaît là où le doigt touche l'écran.
## `output` est un Vector2 (x droite, y bas) de longueur 0..1.

@export var radius := 90.0
@export var dead_zone := 0.15
@export var base_color := Color(0, 0, 0, 0.18)
@export var knob_color := Color(1, 1, 1, 0.85)
@export var outline_color := Color(0.1, 0.1, 0.15, 0.6)

var output := Vector2.ZERO

var _touch_index := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO

@export var ignore_zones: Array[TouchScreenButton] = []

func _is_in_ignore_zone(pos: Vector2) -> bool:
	for button in ignore_zones:
		if button and button.is_visible_in_tree():
			var size = button.texture_normal.get_size() * button.global_scale
			if Rect2(button.global_position, size).has_point(pos):
				return true
	return false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if _is_in_ignore_zone(event.position):
			return # On ignore ce doigt s'il touche le bouton TAPER

	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_origin = event.position
			_update_knob(event.position)
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)

func _notification(what: int) -> void:
	# Évite un joueur qui continue d'avancer si l'app perd le focus en plein glissé.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release()

func _update_knob(pos: Vector2) -> void:
	var offset := (pos - _origin).limit_length(radius)
	_knob = _origin + offset
	var strength := offset.length() / radius
	if strength < dead_zone:
		output = Vector2.ZERO
	else:
		# Remappe dead_zone..1 vers 0..1 pour un démarrage progressif.
		output = offset.normalized() * inverse_lerp(dead_zone, 1.0, strength)
	queue_redraw()

func _release() -> void:
	_touch_index = -1
	output = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_origin, radius, base_color)
	draw_arc(_origin, radius, 0.0, TAU, 48, outline_color, 3.0, true)
	draw_circle(_knob, radius * 0.4, knob_color)
	draw_arc(_knob, radius * 0.4, 0.0, TAU, 32, outline_color, 3.0, true)