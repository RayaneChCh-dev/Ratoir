# scripts/rat/rat_profile.gd
class_name RatProfile
extends Resource

@export var display_name: String = "Gaston"
@export var intro_line: String = "Ce soir, c'est moi le chef."
@export_range(2.5, 5.5) var speed: float = 4.0               # Joueur = 6 m/s : le rat reste plus lent
@export_range(0.0, 1.0) var aggressiveness: float = 0.5       # Modifie l'intervalle entre les sorties
@export var hidden_time_range: Vector2 = Vector2(4.0, 8.0)

# Poids pour le tirage pondéré des sabotages
@export var weight_stove_off: float = 1.0
@export var weight_steal: float = 1.0
@export var weight_spill: float = 1.0

func get_next_hidden_delay() -> float:
	# Plus l'agressivité est haute, plus le délai d'attente est court
	var min_t = hidden_time_range.x * (1.0 - (aggressiveness * 0.4))
	var max_t = hidden_time_range.y * (1.0 - (aggressiveness * 0.4))
	return randf_range(min_t, max_t)