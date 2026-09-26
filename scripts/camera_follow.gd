extends Camera3D
## Caméra en plongée qui suit la cible sur X/Z (jamais de rotation) :
## elle ne bouge que si la cible sort d'une zone morte au centre de l'écran,
## et reste bornée pour ne jamais montrer l'extérieur de la cuisine.

@export var target: Node3D
## Emprise au sol de la cuisine, murs compris (x, z, largeur, profondeur).
@export var bounds := Rect2(-6.5, -13.8, 13, 25.3)
## Demi-taille de la zone morte, en unités monde.
@export var dead_zone := Vector2(1.2, 2.0)
@export var follow_speed := 5.0
@export var distance := 20.0

var _focus := Vector3.ZERO


func _ready() -> void:
	if target:
		_focus = _clamp_focus(target.global_position)
	_apply()


func _process(delta: float) -> void:
	if target == null:
		return
	var desired := _focus
	var offset := target.global_position - _focus
	if absf(offset.x) > dead_zone.x:
		desired.x = target.global_position.x - signf(offset.x) * dead_zone.x
	if absf(offset.z) > dead_zone.y:
		desired.z = target.global_position.z - signf(offset.z) * dead_zone.y
	desired = _clamp_focus(desired)
	_focus = _focus.lerp(desired, 1.0 - exp(-follow_speed * delta))
	_apply()


func _apply() -> void:
	global_position = _focus + global_basis.z * distance


## Borne le point visé au sol pour que les bords de l'écran restent dans `bounds`.
func _clamp_focus(point: Vector3) -> Vector3:
	var screen := get_viewport().get_visible_rect()
	var half_width := (_ground_at(Vector2(screen.end.x, screen.get_center().y)).x
		- _ground_at(Vector2(screen.position.x, screen.get_center().y)).x) * 0.5
	var half_depth := (_ground_at(Vector2(screen.get_center().x, screen.end.y)).z
		- _ground_at(Vector2(screen.get_center().x, screen.position.y)).z) * 0.5
	point.x = _clamp_axis(point.x, bounds.position.x + half_width, bounds.end.x - half_width)
	point.z = _clamp_axis(point.z, bounds.position.y + half_depth, bounds.end.y - half_depth)
	point.y = 0.0
	return point


## Point du sol (y = 0) visible à cette position de l'écran.
func _ground_at(screen_point: Vector2) -> Vector3:
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(
		project_ray_origin(screen_point), project_ray_normal(screen_point))
	return hit if hit != null else Vector3.ZERO


func _clamp_axis(value: float, low: float, high: float) -> float:
	# Cuisine plus petite que l'écran sur cet axe : on centre.
	return (low + high) * 0.5 if low > high else clampf(value, low, high)
