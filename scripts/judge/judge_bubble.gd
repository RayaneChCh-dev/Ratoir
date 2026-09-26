class_name JudgeBubble
extends CanvasLayer
## Bulle de critique du juge : suit la tête du juge à l'écran (nom du plat, 5 étoiles, phrase).

const CREAM := Color(1.0, 0.95, 0.84)
const BROWN := Color(0.24, 0.11, 0.06)

## Point au-dessus duquel la bulle s'affiche (la tête du juge).
@export var anchor_height := 2.4

var _panel: PanelContainer
var _dish: Label
var _critique: Label
var _stars: Array[HudIcon] = []
var _hide_timer: SceneTreeTimer


func _ready() -> void:
	layer = 2
	_build()
	_panel.visible = false


func show_verdict(dish: String, stars: int, critique: String, duration: float) -> void:
	_dish.text = dish
	_critique.text = "« %s »" % critique
	for i in _stars.size():
		_stars[i].filled = i < stars
	_panel.visible = true
	_panel.modulate.a = 1.0
	_panel.scale = Vector2(0.6, 0.6)
	_place()
	var pop := create_tween()
	pop.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hide_timer = get_tree().create_timer(duration, false)
	var timer := _hide_timer
	await timer.timeout
	if timer == _hide_timer:  # une critique plus récente n'a pas pris la place
		var fade := create_tween()
		fade.tween_property(_panel, "modulate:a", 0.0, 0.3)
		await fade.finished
		_panel.visible = false


func _process(_delta: float) -> void:
	if _panel.visible:
		_place()


## Place la bulle au-dessus de la tête du juge, sans sortir de l'écran.
func _place() -> void:
	var camera := get_viewport().get_camera_3d()
	var judge := get_parent() as Node3D
	if camera == null or judge == null:
		return
	var head := camera.unproject_position(judge.global_position + Vector3(0, anchor_height, 0))
	var screen := get_viewport().get_visible_rect().size
	var size := _panel.get_combined_minimum_size()
	_panel.size = size
	_panel.pivot_offset = Vector2(size.x / 2.0, size.y)
	var pos := head - Vector2(size.x / 2.0, size.y)
	pos.x = clampf(pos.x, 10.0, screen.x - size.x - 10.0)
	pos.y = clampf(pos.y, 110.0, screen.y - size.y - 10.0)
	_panel.position = pos


func _build() -> void:
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = CREAM
	box.set_corner_radius_all(22)
	box.set_border_width_all(4)
	box.border_color = BROWN
	box.set_content_margin_all(14)
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 5)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(column)

	_dish = _label(26, BROWN)
	column.add_child(_dish)
	var stars_row := HBoxContainer.new()
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 4)
	stars_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 5:
		var star := HudIcon.new()
		star.kind = HudIcon.Kind.STAR
		star.custom_minimum_size = Vector2(32, 32)
		_stars.append(star)
		stars_row.add_child(star)
	column.add_child(stars_row)
	_critique = _label(21, Color(0.35, 0.2, 0.12))
	_critique.custom_minimum_size.x = 300
	_critique.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_critique)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
