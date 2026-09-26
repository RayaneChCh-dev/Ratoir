extends Cook
## Joueur : déplacement sur le plan horizontal uniquement, relatif à la caméra fixe.

@export var speed := 6.0
@export var acceleration := 40.0
@export var turn_speed := 14.0
@export var joystick: TouchJoystick

@onready var _model: Node3D = $Model
var _hit_cooldown: float = 0.0
const HIT_COOLDOWN_TIME: float = 0.8


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING


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

	if Input.is_action_just_pressed("hit") and _hit_cooldown <= 0.0:
		_try_hit_rat()

	if direction.length_squared() > 0.001:
		var target_yaw := atan2(direction.x, direction.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_speed * delta)


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
		rat.hit()
		GameState.log_event("rat_hit", "bonk ! le rat est assommé")
