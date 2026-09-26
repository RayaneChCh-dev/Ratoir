extends Node
## Autoload : progression, santé, chrono et journal d'événements partagé.
## Le journal alimente le commentateur, le juge et le récap' final (voir docs/ARCHITECTURE.md).

enum RoundState { PLAYING, GAME_OVER, WON }

signal score_changed(score: int)
signal event_logged(entry: Dictionary)
signal level_changed(level: int, target_score: int)
signal time_changed(time_left: float)
signal round_state_changed(state: RoundState)
signal difficulty_changed(level: int, scale: float)
signal round_started
signal round_ended(level: int, score: int)

## Points nécessaires pour 1, 2 et 3 étoiles.
const STAR_THRESHOLDS: Array[int] = [5, 10, 15]
const LEVEL_COUNT := 3
const SCORE_PER_LEVEL := 5
const ROUND_DURATIONS: Array[float] = [90.0, 75.0, 60.0]
const RAT_SCALES: Array[float] = [1.0, 1.4, 1.8]
const PROTECTION_TIMES: Array[float] = [8.0, 5.0, 3.0]
const CHOP_DURATIONS: Array[float] = [1.5, 1.2, 1.0]
const COOK_DURATIONS: Array[float] = [2.5, 2.0, 1.6]

var score := 0
var level := 1
var time_left := 90.0
var round_state := RoundState.PLAYING
var events: Array[Dictionary] = []

var _round_start_ms := Time.get_ticks_msec()
var _milestone_30_logged := false
var _milestone_10_logged := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_round()


func _process(delta: float) -> void:
	if round_state != RoundState.PLAYING:
		return

	time_left = maxf(0.0, time_left - delta)
	time_changed.emit(time_left)
	if not _milestone_30_logged and time_left <= 30.0:
		_milestone_30_logged = true
		log_event("timer_milestone", "30 s restantes")
	if not _milestone_10_logged and time_left <= 10.0:
		_milestone_10_logged = true
		log_event("timer_milestone", "10 s restantes")
	if time_left <= 0.0:
		_finish_round()


func add_point() -> void:
	if round_state != RoundState.PLAYING:
		return
	score += 1
	score_changed.emit(score)
	if score >= target_score():
		_advance_level()


func stars() -> int:
	return STAR_THRESHOLDS.filter(func(threshold: int) -> bool: return score >= threshold).size()


func target_score() -> int:
	return level * SCORE_PER_LEVEL


func round_duration_for_level() -> float:
	return ROUND_DURATIONS[_level_index()]


## Le rat peut utiliser ce multiplicateur pour accélérer et sortir plus souvent.
func difficulty_scale() -> float:
	return RAT_SCALES[_level_index()]


func protection_time() -> float:
	return PROTECTION_TIMES[_level_index()]


## Vrai dès que le rat court plus vite que le chef : les pièges deviennent disponibles.
func traps_unlocked() -> bool:
	var rats := get_tree().get_nodes_in_group("rat")
	var chefs := get_tree().get_nodes_in_group("player")
	if rats.is_empty() or chefs.is_empty():
		return false
	return rats[0].travel_speed() > chefs[0].speed


func chop_duration() -> float:
	return CHOP_DURATIONS[_level_index()]


func cook_duration() -> float:
	return COOK_DURATIONS[_level_index()]


func _level_index() -> int:
	return clampi(level - 1, 0, LEVEL_COUNT - 1)


func start_round() -> void:
	if round_state == RoundState.GAME_OVER or round_state == RoundState.WON:
		return

	round_state = RoundState.PLAYING
	time_left = round_duration_for_level()
	_round_start_ms = Time.get_ticks_msec()
	_milestone_30_logged = false
	_milestone_10_logged = false
	round_state_changed.emit(round_state)
	time_changed.emit(time_left)
	log_event("round_start", "niveau %d, objectif %d plats, %d s" % [level, target_score(), int(time_left)])
	difficulty_changed.emit(level, difficulty_scale())
	round_started.emit()


func reset() -> void:
	get_tree().paused = false
	score = 0
	level = 1
	round_state = RoundState.PLAYING
	events.clear()
	score_changed.emit(score)
	level_changed.emit(level, target_score())
	start_round()


func _advance_level() -> void:
	log_event("round_end", "niveau %d terminé, score %d" % [level, score])
	round_ended.emit(level, score)
	if level >= LEVEL_COUNT:
		_win()
		return
	level += 1
	log_event("level_up", "niveau %d" % level)
	level_changed.emit(level, target_score())
	start_round()


func _win() -> void:
	if round_state == RoundState.WON:
		return
	round_state = RoundState.WON
	get_tree().paused = true
	round_state_changed.emit(round_state)


func _finish_round() -> void:
	log_event("round_end", "temps écoulé au niveau %d, score %d" % [level, score])
	round_ended.emit(level, score)
	_end_game()


func _end_game() -> void:
	if round_state == RoundState.GAME_OVER:
		return
	round_state = RoundState.GAME_OVER
	get_tree().paused = true
	round_state_changed.emit(round_state)


## Enregistre un événement structuré, ex. log_event("dish_delivered", "assiette de tomates").
## Les noms d'événements autorisés sont listés dans docs/ARCHITECTURE.md.
func log_event(event: String, detail := "") -> void:
	var entry := {
		"t": snappedf((Time.get_ticks_msec() - _round_start_ms) / 1000.0, 0.1),
		"event": event,
		"detail": detail,
	}
	events.append(entry)
	event_logged.emit(entry)
