extends Node
## Autoload : progression, santé, chrono et journal d'événements partagé.
## Le journal alimente le commentateur, le juge et le récap' final (voir docs/ARCHITECTURE.md).

enum RoundState { PLAYING, GAME_OVER }

signal score_changed(score: int)
signal event_logged(entry: Dictionary)
signal level_changed(level: int, target_score: int)
signal health_changed(health: int)
signal time_changed(time_left: float)
signal round_state_changed(state: RoundState)
signal difficulty_changed(level: int, scale: float)
signal round_started
signal round_ended(level: int, score: int, health: int)

## Points nécessaires pour 1, 2 et 3 étoiles.
const STAR_THRESHOLDS: Array[int] = [5, 10, 15]
const STARTING_HEALTH := 3
const BASE_ROUND_DURATION := 90.0
const ROUND_DURATION_STEP := 5.0
const MIN_ROUND_DURATION := 60.0
const SCORE_PER_LEVEL := 5

var score := 0
var level := 1
var health := STARTING_HEALTH
var time_left := BASE_ROUND_DURATION
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
	return maxf(MIN_ROUND_DURATION, BASE_ROUND_DURATION - (level - 1) * ROUND_DURATION_STEP)


## Le rat peut utiliser ce multiplicateur pour accélérer et sortir plus souvent.
func difficulty_scale() -> float:
	return minf(2.0, 1.0 + (level - 1) * 0.15)


## Appelé par un ennemi lorsqu'il touche directement le joueur.
func take_damage(amount := 1, reason := "rat") -> void:
	if round_state != RoundState.PLAYING or amount <= 0:
		return

	health = maxi(0, health - amount)
	health_changed.emit(health)
	log_event("player_damaged", reason)
	if health == 0:
		log_event("round_end", "partie terminée au niveau %d, score %d" % [level, score])
		round_ended.emit(level, score, health)
		_end_game()


func start_round() -> void:
	if round_state == RoundState.GAME_OVER:
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
	health = STARTING_HEALTH
	round_state = RoundState.PLAYING
	events.clear()
	score_changed.emit(score)
	level_changed.emit(level, target_score())
	health_changed.emit(health)
	start_round()


func _advance_level() -> void:
	log_event("round_end", "niveau %d terminé, score %d" % [level, score])
	level += 1
	log_event("level_up", "niveau %d" % level)
	health = mini(STARTING_HEALTH, health + 1)
	level_changed.emit(level, target_score())
	health_changed.emit(health)
	round_ended.emit(level - 1, score, health)
	start_round()


func _finish_round() -> void:
	log_event("round_end", "niveau %d, score %d, %d vie(s)" % [level, score, health])
	health = maxi(0, health - 1)
	health_changed.emit(health)
	round_ended.emit(level, score, health)
	if health == 0:
		_end_game()
	else:
		start_round()


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
