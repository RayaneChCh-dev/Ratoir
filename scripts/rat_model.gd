class_name RatModel
extends Node3D
## Visuel du rat : modèle animé (course) + version assommée.
## La logique reste dans scripts/rat/rat.gd, qui appelle seulement set_speed() et set_stunned().

## Vitesse (m/s) à laquelle l'animation « run » a sa cadence d'origine.
@export var run_anim_speed := 3.5

var _anim: AnimationPlayer
var _stunned := false

@onready var _running: Node3D = $Running
@onready var _stunned_model: Node3D = $Stunned


func _ready() -> void:
	var players := _running.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0]
		_anim.get_animation("run").loop_mode = Animation.LOOP_LINEAR
		_anim.play("run")
	set_stunned(false)


func _process(_delta: float) -> void:
	if _stunned:
		# Petit vacillement de la tête qui tourne.
		var t := Time.get_ticks_msec() / 1000.0
		_stunned_model.rotation.z = sin(t * 7.0) * 0.12
		_stunned_model.rotation.x = cos(t * 5.0) * 0.06


## À appeler à chaque image avec la vitesse au sol du rat : fige l'animation à l'arrêt.
func set_speed(speed: float) -> void:
	if _anim == null or _stunned:
		return
	if speed < 0.1:
		_anim.pause()
	else:
		if not _anim.is_playing():
			_anim.play("run")
		_anim.speed_scale = clampf(speed / run_anim_speed, 0.6, 2.0)


func set_stunned(stunned: bool) -> void:
	_stunned = stunned
	_running.visible = not stunned
	_stunned_model.visible = stunned
	if not stunned:
		_stunned_model.rotation = Vector3.ZERO
