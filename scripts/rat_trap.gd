extends Area3D
## Piège posé au sol : une seule frappe sur le rat, puis disparaît.

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("rat"):
		return
	# hit() renvoie false si le rat est caché ou déjà en fuite : on ne consomme pas le piège.
	if not body.hit():
		return
	GameState.log_event("rat_hit", "piège ! le rat est assommé")
	queue_free()
