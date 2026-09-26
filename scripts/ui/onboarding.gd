extends CanvasLayer
## Écran d'accueil (bouton PLAY) et de fin de partie (bouton REJOUER).
## Le jeu reste en pause derrière, flouté, tant que le joueur n'a pas appuyé.

const CREAM := Color(1.0, 0.94, 0.82)
const BROWN := Color(0.24, 0.11, 0.06)
const ORANGE := Color(0.96, 0.49, 0.16)
const ORANGE_DARK := Color(0.78, 0.33, 0.08)

const STEPS := [
	["res://assets/ui/icons/tomato.png", "Prends une tomate dans la caisse"],
	["res://assets/ui/icons/soup_tomate.png", "Découpe-la, puis fais-la cuire"],
	["res://assets/ui/icons/slot.png", "Livre l'assiette avant la fin du chrono"],
	["", "Attention : le rat sabote ta cuisine !"],
]

var _title: Label
var _subtitle: Label
var _steps_card: PanelContainer
var _button: Button
var _root: Control
var _pulse: Tween


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.round_state_changed.connect(_on_round_state_changed)
	_show_menu()


func _show_menu() -> void:
	_title.text = "TOMATO WARS"
	_title.add_theme_font_size_override("font_size", 100)
	_subtitle.text = "Cuisine vite… le rat rôde !"
	_steps_card.visible = true
	_button.text = "PLAY"
	_open()


func _show_game_over() -> void:
	_title.text = "PARTIE TERMINÉE"
	_title.add_theme_font_size_override("font_size", 72)
	_subtitle.text = "Niveau %d  ·  %d plat%s servi%s" % [
		GameState.level, GameState.score,
		"s" if GameState.score > 1 else "", "s" if GameState.score > 1 else ""]
	_steps_card.visible = false
	_button.text = "REJOUER"
	_open()


func _show_victory() -> void:
	_title.text = "VICTOIRE !"
	_title.add_theme_font_size_override("font_size", 96)
	_subtitle.text = "Les 3 manches sont réussies  ·  %d plat%s servi%s" % [
		GameState.score, "s" if GameState.score > 1 else "", "s" if GameState.score > 1 else ""]
	_steps_card.visible = false
	_button.text = "REJOUER"
	_open()


func _open() -> void:
	get_tree().paused = true
	visible = true
	_root.modulate.a = 1.0
	_button.disabled = false
	_button.grab_focus()
	_start_pulse()


func _on_play_pressed() -> void:
	_button.disabled = true
	var fade := create_tween()
	fade.tween_property(_root, "modulate:a", 0.0, 0.25)
	await fade.finished
	visible = false
	if _pulse:
		_pulse.kill()
	GameState.reset()  # relance une partie propre et enlève la pause


func _on_round_state_changed(state: int) -> void:
	if state == GameState.RoundState.GAME_OVER:
		_show_game_over()
	elif state == GameState.RoundState.WON:
		_show_victory()


func _start_pulse() -> void:
	if _pulse:
		_pulse.kill()
	_button.pivot_offset = _button.size / 2.0
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_button, "scale", Vector2(1.06, 1.06), 0.6).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(_button, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


# --- Construction de l'interface ---

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	var blur := ShaderMaterial.new()
	blur.shader = preload("res://shaders/screen_blur.gdshader")
	background.material = blur
	_root.add_child(background)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 48
	column.offset_right = -48
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 28)
	_root.add_child(column)

	_title = _label(120, CREAM, 28)
	column.add_child(_title)
	_subtitle = _label(38, CREAM, 12)
	column.add_child(_subtitle)
	column.add_child(_spacer(20))

	_steps_card = PanelContainer.new()
	_steps_card.custom_minimum_size.x = 580
	_steps_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_steps_card.add_theme_stylebox_override("panel", _box(Color(0.14, 0.06, 0.04, 0.55), 28, 0, Color.TRANSPARENT, 28))
	var steps := VBoxContainer.new()
	steps.add_theme_constant_override("separation", 18)
	_steps_card.add_child(steps)
	for step in STEPS:
		steps.add_child(_step_row(step[0], step[1]))
	column.add_child(_steps_card)
	column.add_child(_spacer(30))

	_button = Button.new()
	_button.custom_minimum_size = Vector2(440, 140)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.add_theme_font_size_override("font_size", 64)
	_button.add_theme_color_override("font_color", CREAM)
	_button.add_theme_color_override("font_hover_color", CREAM)
	_button.add_theme_color_override("font_pressed_color", CREAM)
	_button.add_theme_color_override("font_focus_color", CREAM)
	_button.add_theme_constant_override("outline_size", 14)
	_button.add_theme_color_override("font_outline_color", ORANGE_DARK)
	_button.add_theme_stylebox_override("normal", _box(ORANGE, 70, 6, CREAM, 0))
	_button.add_theme_stylebox_override("hover", _box(ORANGE.lightened(0.08), 70, 6, CREAM, 0))
	_button.add_theme_stylebox_override("pressed", _box(ORANGE_DARK, 70, 6, CREAM, 0))
	_button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, 70, 0, Color.TRANSPARENT, 0))
	_button.pressed.connect(_on_play_pressed)
	column.add_child(_button)

	var hint := _label(28, CREAM, 8)
	hint.text = "Glisse ton pouce n'importe où pour te déplacer"
	hint.modulate.a = 0.85
	column.add_child(hint)


func _step_row(icon_path: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon_path != "":
		icon.texture = load(icon_path)
	row.add_child(icon)
	var label := _label(32, CREAM, 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = text
	row.add_child(label)
	return row


func _label(size: int, color: Color, outline: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Retour à la ligne : un texte long ne doit jamais élargir la colonne au-delà de l'écran.
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 1
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", BROWN)
	return label


func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


func _box(color: Color, radius: int, border: int, border_color: Color, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border)
	box.border_color = border_color
	box.set_content_margin_all(padding)
	if border > 0:
		box.shadow_color = Color(0, 0, 0, 0.35)
		box.shadow_size = 10
		box.shadow_offset = Vector2(0, 6)
	return box
