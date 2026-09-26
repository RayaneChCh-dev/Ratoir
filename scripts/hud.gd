extends RichTextLabel
## Affichage du score en haut de l'écran.


func _ready() -> void:
	GameState.score_changed.connect(_refresh.unbind(1))
	_refresh()


func _refresh() -> void:
	text = "[center]SCORE %d[/center]" % GameState.score
