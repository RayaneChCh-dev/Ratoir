extends Cook
## Joueur : déplacement sur le plan horizontal uniquement, relatif à la caméra fixe.

@export var speed := 6.0
@export var acceleration := 40.0
@export var turn_speed := 14.0
@export var joystick: TouchJoystick
## Taper le rat (bouton TAPER / Espace). Désactivé pour l'instant : le chef ne peut rien contre le rat.
@export var can_hit_rat := false

## Vitesses (m/s) auxquelles les animations « walk » et « run » ont leur cadence d'origine.
@export var walk_anim_speed := 1.8
@export var run_anim_speed := 4.5
## Au-dessus de cette vitesse on court, en dessous de `idle_threshold` on s'arrête.
@export var run_threshold := 3.0
@export var idle_threshold := 0.3

var _anim: AnimationPlayer
var _anim_state := ""

@onready var _model: Node3D = $Model
var _hit_cooldown: float = 0.0
const HIT_COOLDOWN_TIME: float = 0.8


func _ready() -> void:
	add_to_group("player")
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

	if _hit_cooldown > 0.0:
		_hit_cooldown -= delta

	if can_hit_rat and Input.is_action_just_pressed("hit") and _hit_cooldown <= 0.0:
		_try_hit_rat()

	if direction.length_squared() > 0.001:
		var target_yaw := atan2(direction.x, direction.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_speed * delta)

	_update_animation()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("place_trap"):
		place_trap()


func place_trap() -> void:
	if held_trap == null:
		return
	clear_trap()
	var trap := preload("res://scenes/rat_trap.tscn").instantiate()
	get_parent().add_child(trap)
	var pos := global_position
	pos.y = 0.0
	pos.x = clampf(pos.x, -5.2, 5.2)
	pos.z = clampf(pos.z, -9.5, 9.5)
	trap.global_position = pos
	GameState.log_event("trap_placed", "piège posé")


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




func _try_hit_rat() -> void:
	_hit_cooldown = HIT_COOLDOWN_TIME

	var rats = get_tree().get_nodes_in_group("rat")
	if rats.is_empty():
		return

	var rat = rats[0]
	if rat.global_position.distance_to(global_position) <= 1.5:
		if rat.hit():
			GameState.log_event("rat_hit", "bonk ! le rat est assommé")
