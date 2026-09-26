extends TouchScreenButton
## Bouton tactile POSER : visible seulement quand le chef tient un piège.


func _ready() -> void:
	get_viewport().size_changed.connect(_place)
	_place()


func _process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	visible = not players.is_empty() and players[0].held_trap != null


func _place() -> void:
	position = get_viewport_rect().size - Vector2(204, 220)
