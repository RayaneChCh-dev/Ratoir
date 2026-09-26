class_name Item
extends Node3D
## Ingrédient : brut → découpé → cuit. Le visuel change avec l'état.

enum State { RAW, CHOPPED, COOKED }

const TOMATO_COLOR := Color(0.9, 0.2, 0.15)
const COOKED_COLOR := Color(0.72, 0.32, 0.12)
const PLATE_COLOR := Color(0.97, 0.97, 0.95)

## Modèles 3D par état (échelle, hauteur du centre). Un état absent garde sa forme simple.
const MODELS := {
	State.COOKED: [preload("res://assets/models/food/plate_dish.glb"), 0.65, 0.11],
}

var state := State.RAW:
	set(value):
		state = value
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	if MODELS.has(state):
		var entry: Array = MODELS[state]
		var model: Node3D = entry[0].instantiate()
		model.scale = Vector3.ONE * entry[1]
		model.position.y = entry[2]
		add_child(model)
		return
	match state:
		State.RAW:
			_add_sphere(TOMATO_COLOR, 0.22, Vector3(0, 0.22, 0))
		State.CHOPPED:
			for i in 3:
				_add_cylinder(TOMATO_COLOR, 0.14, 0.06, Vector3((i - 1) * 0.2, 0.03, 0))
		State.COOKED:
			_add_cylinder(PLATE_COLOR, 0.34, 0.05, Vector3(0, 0.025, 0))
			_add_sphere(COOKED_COLOR, 0.22, Vector3(0, 0.1, 0)).scale = Vector3(1, 0.5, 1)


func _add_sphere(color: Color, radius: float, pos: Vector3) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add_mesh(mesh, color, pos)


func _add_cylinder(color: Color, radius: float, height: float, pos: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _add_mesh(mesh, color, pos)


func _add_mesh(mesh: PrimitiveMesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	add_child(instance)
	return instance


func get_item_name() -> String:
	return ["une tomate crue", "une tomate découpée", "une assiette de tomates cuites"][state]
