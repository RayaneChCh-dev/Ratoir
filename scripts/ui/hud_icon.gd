class_name HudIcon
extends Control
## Icône du HUD. Utilise l'image assets/ui/icons/<nom>.png si elle existe,
## sinon dessine une version vectorielle simple (cœur, chrono, étoile, toque).

enum Kind { HEART, TIMER, STAR, HAT }

const FILES := {
	Kind.HEART: "res://assets/ui/icons/heart.png",
	Kind.TIMER: "res://assets/ui/icons/timer.png",
	Kind.STAR: "res://assets/ui/icons/star.png",
	Kind.HAT: "res://assets/ui/icons/chef_hat.png",
}
const OUTLINE := Color(0.24, 0.11, 0.06)

@export var kind := Kind.HEART
## false = version « vide » (cœur perdu, étoile pas encore gagnée) : grisée.
@export var filled := true:
	set(value):
		filled = value
		queue_redraw()

var _texture: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size / 2.0
	if ResourceLoader.exists(FILES[kind]):
		_texture = load(FILES[kind])
	resized.connect(func() -> void: pivot_offset = size / 2.0)


func pop() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _draw() -> void:
	var tint := Color.WHITE if filled else Color(0.35, 0.3, 0.3, 0.8)
	if _texture:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false, tint)
		return
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 * 0.9
	match kind:
		Kind.HEART:
			var pts := PackedVector2Array()
			for i in 48:
				var t := TAU * i / 48.0
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				pts.append(c + Vector2(x, y + 2.0) * r / 17.0)
			_shape(pts, Color(0.93, 0.25, 0.27) * tint)
		Kind.STAR:
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + PI * i / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
			_shape(pts, Color(1.0, 0.8, 0.2) * tint)
		Kind.TIMER:
			draw_circle(c, r, OUTLINE)
			draw_circle(c, r - 3.0, Color(0.9, 0.27, 0.22) * tint)
			draw_circle(c, r * 0.68, Color(1.0, 0.96, 0.88) * tint)
			draw_line(c, c + Vector2(0, -r * 0.5), OUTLINE, 4.0, true)
			draw_line(c, c + Vector2(r * 0.35, 0), OUTLINE, 4.0, true)
			draw_rect(Rect2(c + Vector2(-r * 0.15, -r - 4.0), Vector2(r * 0.3, 7.0)), Color(0.3, 0.65, 0.3) * tint)
		Kind.HAT:
			var white := Color(1.0, 0.98, 0.94) * tint
			var band := Rect2(c + Vector2(-r * 0.55, r * 0.15), Vector2(r * 1.1, r * 0.6))
			for p in [Vector2(-0.45, -0.2), Vector2(0.45, -0.2), Vector2(0, -0.45)]:
				draw_circle(c + p * r, r * 0.46, OUTLINE)
			draw_rect(band.grow(3.0), OUTLINE)
			for p in [Vector2(-0.45, -0.2), Vector2(0.45, -0.2), Vector2(0, -0.45)]:
				draw_circle(c + p * r, r * 0.46 - 3.0, white)
			draw_rect(band, white)


func _shape(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE, 4.0, true)
