extends Node
## Autoload : score de la manche, étoiles, et journal d'événements partagé.
## Le journal alimente le commentateur, le juge et le récap' final (voir docs/ARCHITECTURE.md).

signal score_changed(score: int)
signal event_logged(entry: Dictionary)

## Points nécessaires pour 1, 2 et 3 étoiles.
const STAR_THRESHOLDS: Array[int] = [5, 10, 15]

var score := 0
var events: Array[Dictionary] = []

var _round_start_ms := Time.get_ticks_msec()


func add_point() -> void:
	score += 1
	score_changed.emit(score)


func stars() -> int:
	return STAR_THRESHOLDS.filter(func(threshold: int) -> bool: return score >= threshold).size()


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
