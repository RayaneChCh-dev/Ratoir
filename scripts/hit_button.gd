extends TouchScreenButton

func _ready() -> void:
	get_viewport().size_changed.connect(_place)
	_place()

func _place() -> void:
	position = get_viewport_rect().size - Vector2(204, 220)
