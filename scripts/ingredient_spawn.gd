extends Node3D
## Bac à ingrédients partagé : donne une tomate brute à tout cuisinier qui arrive les mains vides.

@onready var _area: Area3D = $Area3D


func _physics_process(_delta: float) -> void:
	for body in _area.get_overlapping_bodies():
		if body is Cook and body.held_item == null:
			body.hold(Item.new())
			GameState.log_event("tomato_taken", "tomate crue")
