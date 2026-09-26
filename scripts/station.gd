class_name Station
extends Node3D
## Station de transformation (Découpe, Cuisson) : le cuisinier y pose un ingrédient
## au contact, il se transforme après `duration` secondes, puis il le reprend au contact.

@export var rug_color := Color(0.16, 0.42, 0.95, 0.35)
@export var accepts: Item.State = Item.State.RAW
@export var produces: Item.State = Item.State.CHOPPED
@export var duration := 1.5

# --- Phase 3 : Sabotage du Rat ---
@export var can_be_switched_off := false
var switched_off := false

var _item: Item = null
var _elapsed := 0.0

@onready var _area: Area3D = $Area3D
@onready var _slot: Node3D = $ItemSlot
@onready var _progress: ProgressBar3D = $Progress


func _ready() -> void:
	var rug_material := StandardMaterial3D.new()
	rug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rug_material.albedo_color = rug_color
	if has_node("Rug"):
		$Rug.material_override = rug_material


func _physics_process(delta: float) -> void:
	# Si la plaque est éteinte par le rat, la cuisson est en pause !
	if _item and _item.state == accepts and not switched_off:
		_elapsed += delta
		_progress.set_value(_elapsed / duration)
		if _elapsed >= duration:
			_item.state = produces
			_progress.hide()

	for body in _area.get_overlapping_bodies():
		if body is Cook:
			_interact(body)


func _interact(cook: Cook) -> void:
	# 1. Si la plaque a été éteinte par le rat, n'importe quel contact du joueur la rallume
	if switched_off:
		switched_off = false
		_set_visual_state(true)
		GameState.log_event("stove_relit", "le chef a rallumé la plaque")
		return # Règle d'or : une seule action par contact et par image

	# 2. Poser un ingrédient
	if _item == null:
		if cook.held_item and cook.held_item.state == accepts:
			_item = cook.take_item()
			_item.reparent(_slot, false)
			_item.transform = Transform3D.IDENTITY
			_elapsed = 0.0
			_progress.set_value(0.0)
			_progress.show()
	# 3. Récupérer l'ingrédient transformé
	elif _item.state == produces and cook.held_item == null:
		cook.hold(_item)
		_item = null


# --- Méthodes requises par le Rat (Phase 3) ---

func has_item() -> bool:
	return _item != null


func is_processing() -> bool:
	# Objet présent et encore en cours de transformation (ex: cuisson en cours)
	return _item != null and _item.state == accepts


func approach_point() -> Vector3:
	if has_node("ApproachPoint"):
		return get_node("ApproachPoint").global_position
	return global_position


func switch_off() -> void:
	switched_off = true
	_set_visual_state(false)


func steal_item() -> Item:
	if _item:
		var stolen = _item
		_item = null
		_elapsed = 0.0
		_progress.hide()
		return stolen
	return null


func _set_visual_state(is_on: bool) -> void:
	if has_node("StoveMesh"):
		var sm = get_node("StoveMesh")
		if sm.material_override:
			sm.material_override.albedo_color = Color.ORANGE if is_on else Color.GRAY