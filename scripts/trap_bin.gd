extends Node3D
## Bac à pièges : visible seulement quand le rat est plus rapide que le chef.

const MAX_STOCK := 2

var stock := 0

@onready var _area: Area3D = $Area3D
@onready var _label: Label3D = $Label3D


func _ready() -> void:
	GameState.round_started.connect(_on_round_started)
	_on_round_started()


func _physics_process(_delta: float) -> void:
	if stock <= 0 or not visible:
		return
	for body in _area.get_overlapping_bodies():
		if body is Cook and body.held_item == null and body.held_trap == null:
			body.hold_trap()
			stock -= 1
			_refresh_label()
			return


func _on_round_started() -> void:
	if GameState.traps_unlocked():
		stock = MAX_STOCK
		visible = true
		_area.monitoring = true
		_area.monitorable = true
		_set_collision_enabled(true)
	else:
		stock = 0
		visible = false
		_area.monitoring = false
		_area.monitorable = false
		_set_collision_enabled(false)
	_refresh_label()


func _refresh_label() -> void:
	_label.text = "Pièges (%d)" % stock


func _set_collision_enabled(enabled: bool) -> void:
	for child in _area.get_children():
		if child is CollisionShape3D:
			child.disabled = not enabled
