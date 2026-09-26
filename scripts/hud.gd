extends RichTextLabel
## Affichage du score en haut de l'écran.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.score_changed.connect(_refresh.unbind(1))
	GameState.level_changed.connect(_refresh.unbind(2))
	GameState.time_changed.connect(_refresh.unbind(1))
	GameState.round_state_changed.connect(_refresh.unbind(1))
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	var ended := GameState.round_state == GameState.RoundState.GAME_OVER or GameState.round_state == GameState.RoundState.WON
	if not ended:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		GameState.reset()
		get_tree().reload_current_scene()


func _refresh() -> void:
	if GameState.round_state == GameState.RoundState.GAME_OVER:
		text = "[center]PARTIE TERMINÉE | NIVEAU %d | SCORE %d | ESPACE POUR REJOUER[/center]" % [GameState.level, GameState.score]
		return
	if GameState.round_state == GameState.RoundState.WON:
		text = "[center]GAGNÉ | SCORE %d | ESPACE POUR REJOUER[/center]" % GameState.score
		return

	var seconds := int(ceil(GameState.time_left))
	var clock := "%d:%02d" % [int(seconds / 60.0), seconds % 60]
	if seconds <= 10:
		clock = "[color=red]%s[/color]" % clock
	var traps := " | PIÈGES" if GameState.traps_unlocked() else ""
	text = "[center]NIVEAU %d | SCORE %d/%d | %s%s[/center]" % [
		GameState.level,
		GameState.score,
		GameState.target_score(),
		clock,
		traps,
	]
