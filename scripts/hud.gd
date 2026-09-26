extends RichTextLabel
## Affichage du score en haut de l'écran.


func _ready() -> void:
	GameState.score_changed.connect(_refresh.unbind(1))
	GameState.level_changed.connect(_refresh.unbind(2))
	GameState.health_changed.connect(_refresh.unbind(1))
	GameState.time_changed.connect(_refresh.unbind(1))
	GameState.round_state_changed.connect(_refresh.unbind(1))
	_refresh()


func _refresh() -> void:
	if GameState.round_state == GameState.RoundState.GAME_OVER:
		text = "[center]PARTIE TERMINÉE | NIVEAU %d | SCORE %d[/center]" % [GameState.level, GameState.score]
		return

	var seconds := int(ceil(GameState.time_left))
	text = "[center]NIVEAU %d | SCORE %d/%d | VIES %d | %d:%02d[/center]" % [
		GameState.level,
		GameState.score,
		GameState.target_score(),
		GameState.health,
		int(seconds / 60),
		seconds % 60,
	]
