class_name Cook
extends CharacterBody3D
## Cuisinier : gère l'objet tenu en main.

var held_item: Item = null
var held_trap: Node3D = null

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


func has_item() -> bool:
	return held_item != null


func hold_trap() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.28, 0.1, 0.28)
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.16, 0.14)
	mesh.material_override = material
	held_trap = mesh
	_hold_point.add_child(mesh)
	mesh.position = Vector3.ZERO


func clear_trap() -> void:
	if held_trap:
		held_trap.queue_free()
	held_trap = null
