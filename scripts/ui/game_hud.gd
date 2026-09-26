extends Control
## HUD de jeu : niveau, chrono et progression en étoiles vers l'objectif du niveau.

const CREAM := Color(1.0, 0.94, 0.82)
const BROWN := Color(0.24, 0.11, 0.06)
const RED := Color(1.0, 0.36, 0.3)

var _level_label: Label
var _time_label: Label
var _time_icon: HudIcon
var _star_icon: HudIcon
var _score_label: Label
var _progress_fill: Control
var _progress_back: Control
var _last_score := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	GameState.score_changed.connect(_refresh.unbind(1))
	GameState.level_changed.connect(_refresh.unbind(2))
	GameState.time_changed.connect(_refresh_time.unbind(1))
	GameState.round_state_changed.connect(_refresh.unbind(1))
	_refresh()
	_refresh_time()


func _refresh() -> void:
	_level_label.text = "NIV. %d" % GameState.level
	var target: int = GameState.target_score()
	_score_label.text = "%d / %d" % [GameState.score, target]
	if GameState.score > _last_score and _last_score != -1:
		_star_icon.pop()
	_last_score = GameState.score
	var ratio := clampf(float(GameState.score) / maxf(1.0, float(target)), 0.0, 1.0)
	_progress_fill.size.x = _progress_back.size.x * ratio


func _refresh_time() -> void:
	var seconds := int(ceil(GameState.time_left))
	_time_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
	var urgent := seconds <= 10 and GameState.round_state == GameState.RoundState.PLAYING
	_time_label.add_theme_color_override("font_color", RED if urgent else CREAM)
	if urgent and _time_icon.scale == Vector2.ONE:
		_time_icon.pop()


# --- Construction ---

func _build() -> void:
	# Chaque pastille est ancrée à sa place : elles ne peuvent pas déborder de l'écran.
	var level_pill := _pill()
	var level_row := _row(level_pill)
	level_row.add_child(_icon(HudIcon.Kind.HAT, 40))
	_level_label = _label(28)
	level_row.add_child(_level_label)
	_anchor(level_pill, Control.PRESET_TOP_LEFT, Vector2(14, 22))

	var time_pill := _pill()
	var time_row := _row(time_pill)
	_time_icon = _icon(HudIcon.Kind.TIMER, 44)
	time_row.add_child(_time_icon)
	_time_label = _label(38)
	time_row.add_child(_time_label)
	_anchor(time_pill, Control.PRESET_CENTER_TOP, Vector2(0, 18))

	# Objectif du niveau : étoile + « 3 / 5 » + barre de progression
	var goal_pill := _pill()
	var goal_row := _row(goal_pill)
	_star_icon = _icon(HudIcon.Kind.STAR, 36)
	goal_row.add_child(_star_icon)
	_score_label = _label(28)
	goal_row.add_child(_score_label)
	_progress_back = Panel.new()
	_progress_back.custom_minimum_size = Vector2(70, 14)
	_progress_back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress_back.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0.35), 8, 0))
	_progress_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_fill = Panel.new()
	_progress_fill.add_theme_stylebox_override("panel", _box(Color(1.0, 0.8, 0.2), 8, 0))
	_progress_fill.size = Vector2(0, 14)
	_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_back.add_child(_progress_fill)
	_progress_back.resized.connect(_refresh)
	goal_row.add_child(_progress_back)
	_anchor(goal_pill, Control.PRESET_TOP_RIGHT, Vector2(-14, 22))


## Ancre une pastille (taille = son contenu) sur un bord de l'écran, avec un décalage.
func _anchor(pill: Control, preset: Control.LayoutPreset, offset: Vector2) -> void:
	add_child(pill)
	pill.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE)
	pill.position += offset


func _pill() -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _box(Color(0.2, 0.09, 0.05, 0.78), 30, 3))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pill


func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	return row


func _icon(kind: HudIcon.Kind, px: int) -> HudIcon:
	var icon := HudIcon.new()
	icon.kind = kind
	icon.custom_minimum_size = Vector2(px, px)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_outline_color", BROWN)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _box(color: Color, radius: int, border: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border)
	box.border_color = Color(1.0, 0.86, 0.66, 0.9)
	box.content_margin_left = 12
	box.content_margin_right = 14
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
