class_name Judge
extends Node3D
## Le juge, assis à la table de la salle : à chaque livraison, l'assiette saute du comptoir
## jusqu'à lui, il goûte, réagit et affiche sa critique (nom du plat, note sur 5, phrase).
## Les textes viennent de data/judge_bank.json ; ne bloque jamais la partie.

signal verdict_given(dish_name: String, stars: int, critique: String)

const BANK_PATH := "res://data/judge_bank.json"
const PLATE_SCENE := preload("res://assets/models/food/plate_dish.glb")
const BUBBLE_TIME := 3.2

## Point de départ de l'assiette (le comptoir de livraison).
@export var delivery: Node3D
## Où l'assiette atterrit, relatif au juge (sur la table, devant lui).
@export var plate_offset := Vector3(0, 0.74, 1.15)

var _bank := {}
var _pending := 0
var _busy := false
var _last_delivery_ms := 0
var _sabotaged := false

@onready var _model: Node3D = $Model
@onready var _bubble: JudgeBubble = $Bubble


func _ready() -> void:
	_bank = JSON.parse_string(FileAccess.get_file_as_string(BANK_PATH))
	var players := _model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		# Pas d'animation assise pour l'instant : pose neutre figée, réactions animées par code.
		var anim: AnimationPlayer = players[0]
		anim.play("walk")
		anim.seek(0.0, true)
		anim.pause()
	GameState.event_logged.connect(_on_event)
	GameState.round_started.connect(_on_round_started)
	_on_round_started()


func _on_round_started() -> void:
	_last_delivery_ms = Time.get_ticks_msec()
	_sabotaged = false


func _on_event(entry: Dictionary) -> void:
	var event: String = entry["event"]
	if event == "dish_delivered":
		_pending += 1
		if not _busy:
			_judge_queue()
	elif event.begins_with("sabotage_"):
		_sabotaged = true


func _judge_queue() -> void:
	_busy = true
	while _pending > 0:
		_pending -= 1
		await _judge_one()
	_busy = false


func _judge_one() -> void:
	var seconds := (Time.get_ticks_msec() - _last_delivery_ms) / 1000.0
	_last_delivery_ms = Time.get_ticks_msec()
	var stars := _rate(seconds, _sabotaged)
	_sabotaged = false

	var plate := await _serve_plate()
	await _react(_model, "taste")
	var dish := "%s %s" % [_pick(_bank["prefixes"]), _pick(_bank["suffixes"])]
	var critique := _pick(_bank["critiques"][_bucket(stars)])
	_bubble.show_verdict(dish, stars, critique, BUBBLE_TIME)
	GameState.log_event("judge_verdict", "%s : %d/5, « %s »" % [dish, stars, critique])
	verdict_given.emit(dish, stars, critique)
	await _react(_model, "happy" if stars >= 4 else ("angry" if stars <= 2 else "ok"))
	await get_tree().create_timer(BUBBLE_TIME - 1.0, false).timeout
	var fade := plate.create_tween()
	fade.tween_property(plate, "scale", Vector3.ZERO, 0.3)
	await fade.finished
	plate.queue_free()


## Note sur 5 : rapide = +1, lent ou saboté = −1, un peu de hasard.
func _rate(seconds: float, sabotaged: bool) -> int:
	var stars := 4
	if seconds < 12.0:
		stars += 1
	elif seconds > 25.0:
		stars -= 1
	if sabotaged:
		stars -= 1
	var roll := randf()
	if roll < 0.2:
		stars -= 1
	elif roll > 0.9:
		stars += 1
	return clampi(stars, 1, 5)


func _bucket(stars: int) -> String:
	return "great" if stars == 5 else ("good" if stars == 4 else ("meh" if stars == 3 else "bad"))


func _pick(list: Array) -> String:
	return list[randi() % list.size()]


## L'assiette part du comptoir et atterrit sur la table en décrivant un arc.
func _serve_plate() -> Node3D:
	var plate: Node3D = PLATE_SCENE.instantiate()
	plate.scale = Vector3.ONE * 0.65
	get_parent().add_child(plate)
	var start := (delivery.global_position if delivery else global_position) + Vector3(0, 1.3, 0)
	var end := global_transform * plate_offset
	plate.global_position = start
	var flight := create_tween()
	flight.tween_method(func(t: float) -> void:
		plate.global_position = start.lerp(end, t) + Vector3(0, sin(t * PI) * 1.2, 0), 0.0, 1.0, 0.6)
	await flight.finished
	return plate


## Réactions animées par code sur le modèle (en attendant des animations Meshy dédiées).
func _react(model: Node3D, kind: String) -> void:
	var tween := create_tween()
	match kind:
		"taste":  # se penche vers l'assiette, deux bouchées
			for i in 2:
				tween.tween_property(model, "rotation:x", 0.35, 0.25)
				tween.tween_property(model, "rotation:x", 0.1, 0.2)
			tween.tween_property(model, "rotation:x", 0.0, 0.2)
		"happy":  # deux petits bonds
			for i in 2:
				tween.tween_property(model, "position:y", 0.35, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.tween_property(model, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		"angry":  # secoue la tête
			for i in 3:
				tween.tween_property(model, "rotation:y", 0.35, 0.08)
				tween.tween_property(model, "rotation:y", -0.35, 0.08)
			tween.tween_property(model, "rotation:y", 0.0, 0.08)
		_:  # hoche la tête
			tween.tween_property(model, "rotation:x", 0.18, 0.2)
			tween.tween_property(model, "rotation:x", 0.0, 0.2)
	await tween.finished
