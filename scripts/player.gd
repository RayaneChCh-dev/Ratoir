extends Cook
## Joueur : déplacement sur le plan horizontal uniquement, relatif à la caméra fixe.

@export var speed := 6.0
@export var acceleration := 40.0
@export var turn_speed := 14.0
@export var joystick: TouchJoystick

## Vitesses (m/s) auxquelles les animations « walk » et « run » ont leur cadence d'origine.
@export var walk_anim_speed := 1.8
@export var run_anim_speed := 4.5
## Au-dessus de cette vitesse on court, en dessous de `idle_threshold` on s'arrête.
@export var run_threshold := 3.0
@export var idle_threshold := 0.3

var _anim: AnimationPlayer
var _anim_state := ""

@onready var _model: Node3D = $Model


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var players := _model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0]
		for anim_name in _anim.get_animation_list():
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


func _physics_process(delta: float) -> void:
	var input := _read_input()
	var direction := _to_world(input)

	var target := direction * speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, acceleration * delta)
	velocity = horizontal  # y toujours à 0 : aucun mouvement vertical
	move_and_slide()
	global_position.y = 0.0

	if direction.length_squared() > 0.001:
		var target_yaw := atan2(direction.x, direction.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_speed * delta)

	_update_animation()


## Choisit idle / walk / run selon la vitesse, et cale la cadence des pas sur la vitesse réelle.
func _update_animation() -> void:
	if _anim == null:
		return
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	if ground_speed < idle_threshold:
		if _anim_state != "idle":
			_anim_state = "idle"
			if _anim.has_animation("idle"):
				_anim.play("idle", 0.2)
			else:
				# Pas encore d'animation « idle » : on fige la pose neutre du début de la marche.
				_anim.play("walk")
				_anim.seek(0.0, true)
				_anim.pause()
		return
	var running := ground_speed > run_threshold and _anim.has_animation("run")
	var wanted := "run" if running else "walk"
	if _anim_state != wanted or not _anim.is_playing():
		_anim_state = wanted
		_anim.play(wanted, 0.15)
	var reference := run_anim_speed if running else walk_anim_speed
	_anim.speed_scale = clampf(ground_speed / reference, 0.5, 1.6)


func _read_input() -> Vector2:
	var input := Vector2.ZERO
	if joystick:
		input = joystick.output
	if input == Vector2.ZERO:
		# Clavier pour tester sur ordinateur.
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return input


## Convertit l'entrée écran (x droite, y bas) en direction monde, alignée sur la caméra.
func _to_world(input: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null or input == Vector2.ZERO:
		return Vector3.ZERO
	var right := camera.global_basis.x
	var forward := -camera.global_basis.z
	right.y = 0.0
	forward.y = 0.0
	return (right.normalized() * input.x + forward.normalized() * -input.y).limit_length(1.0)
