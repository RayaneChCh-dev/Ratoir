class_name Cook
extends CharacterBody3D
## Cuisinier : gère l'objet tenu en main.

var held_item: Item = null

@onready var _hold_point: Node3D = $Model/HoldPoint


func hold(item: Item) -> void:
	held_item = item
	if item.get_parent():
		item.reparent(_hold_point, false)
	else:
		_hold_point.add_child(item)
	item.transform = Transform3D.IDENTITY


## Retire l'objet des mains ; l'appelant le re-parente ou le libère.
func take_item() -> Item:
	var item := held_item
	held_item = null
	return item
