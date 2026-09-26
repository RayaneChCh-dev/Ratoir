class_name Station
extends Node3D
## Station de transformation (Découpe, Cuisson) : le cuisinier y pose un ingrédient
## au contact, il se transforme après `duration` secondes, puis il le reprend au contact.

@export var rug_color := Color(0.16, 0.42, 0.95, 0.35)
@export var accepts: Item.State = Item.State.RAW
@export var produces: Item.State = Item.State.CHOPPED
@export var duration := 1.5

var _item: Item = null
var _elapsed := 0.0

@onready var _area: Area3D = $Area3D
@onready var _slot: Node3D = $ItemSlot
@onready var _progress: ProgressBar3D = $Progress


func _ready() -> void:
	var rug_material := StandardMaterial3D.new()
	rug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rug_material.albedo_color = rug_color
	$Rug.material_override = rug_material


func _physics_process(delta: float) -> void:
	if _item and _item.state == accepts:
		_elapsed += delta
		_progress.set_value(_elapsed / duration)
		if _elapsed >= duration:
			_item.state = produces
			_progress.hide()

	for body in _area.get_overlapping_bodies():
		if body is Cook:
			_interact(body)


func _interact(cook: Cook) -> void:
	if _item == null:
		if cook.held_item and cook.held_item.state == accepts:
			_item = cook.take_item()
			_item.reparent(_slot, false)
			_item.transform = Transform3D.IDENTITY
			_elapsed = 0.0
			_progress.set_value(0.0)
			_progress.show()
	elif _item.state == produces and cook.held_item == null:
		cook.hold(_item)
		_item = null
