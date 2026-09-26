# scripts/floor_item.gd
class_name FloorItem
extends Node3D

@onready var area: Area3D = $Area3D
var contained_item: Node3D = null

func _ready() -> void:
	area.collision_mask = 2 # Détecte uniquement le Joueur (Layer 2)
	area.body_entered.connect(_on_body_entered)

func setup(item: Node3D) -> void:
	contained_item = item
	add_child(item)
	item.position = Vector3(0, 0.1, 0)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Vérifie que le joueur a les mains libres
		if not body.has_item():
			remove_child(contained_item)
			body.hold(contained_item)
			GameState.log_event("item_recovered", "objet récupéré au sol")
			queue_free()