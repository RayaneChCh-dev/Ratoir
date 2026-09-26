class_name FloorItem
extends Node3D
## Réessaie aussi si le joueur libère ses mains sans quitter la zone.

@onready var area: Area3D = $Area3D
var contained_item: Item
var _bounce: Tween

func setup(item: Item) -> void:
	contained_item = item
	item.reparent(self, false)
	item.position = Vector3(0, 0.1, 0)
	_bounce = create_tween()
	_bounce.tween_property(item, "position:y", 0.4, 0.15)
	_bounce.tween_property(item, "position:y", 0.1, 0.2)

func _physics_process(_delta: float) -> void:
	if contained_item == null:
		return
	for body in area.get_overlapping_bodies():
		if body is Cook and not body.has_item():
			if _bounce:
				_bounce.kill()
			var detail := contained_item.get_item_name()
			body.hold(contained_item)
			contained_item = null
			GameState.log_event("item_recovered", detail + " récupérée au sol")
			queue_free()
			return
