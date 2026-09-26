extends Node3D
## Comptoir de livraison partagé : un plat cuit déposé au contact rapporte 1 point.

@onready var _area: Area3D = $Area3D


func _physics_process(_delta: float) -> void:
	for body in _area.get_overlapping_bodies():
		if body is Cook and body.held_item and body.held_item.state == Item.State.COOKED:
			body.take_item().queue_free()
			GameState.log_event("dish_delivered", "assiette de tomates cuites")
			GameState.add_point()
			_show_popup()


func _show_popup() -> void:
	var label := Label3D.new()
	label.text = "+1"
	label.pixel_size = 0.012
	label.font_size = 96
	label.outline_size = 24
	label.modulate = Color(0.3, 0.85, 0.4)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 1.8, 0)
	add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", 3.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)
