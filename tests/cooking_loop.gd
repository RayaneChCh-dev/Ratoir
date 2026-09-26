extends Node
## Test de non-régression de la boucle de cuisine (bac → découpe → cuisson → livraison)
## et des collisions des meubles. Lancer : godot --headless --path . res://tests/cooking_loop.tscn

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func wait(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


func _run() -> void:
	var game = get_tree().root.get_node("GameState")
	var scene = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	var rat: Node = scene.get_node_or_null("Rat")
	if rat:
		rat.process_mode = Node.PROCESS_MODE_DISABLED  # pas de sabotage pendant ce test
	var player: Cook = scene.get_node("Player")
	var chop: Station = scene.get_node("Kitchen/ChopStation")
	var cook: Station = scene.get_node("Kitchen/CookStation")
	var spawn: Node3D = scene.get_node("Kitchen/IngredientSpawn")
	var delivery: Node3D = scene.get_node("Kitchen/DeliveryCounter")
	var start_score: int = game.score

	# Devant chaque meuble : 1,2 m vers le centre de la cuisine.
	player.global_position = _front_of(spawn)
	await wait(5)
	check(player.held_item != null and player.held_item.state == Item.State.RAW, "Bac : tomate crue en main")

	player.global_position = _front_of(chop)
	await wait(5)
	check(player.held_item == null, "Découpe : tomate posée")
	await wait(int(chop.duration * 60) + 10)
	check(player.held_item != null and player.held_item.state == Item.State.CHOPPED, "Découpe : tomate découpée reprise")

	player.global_position = _front_of(cook)
	await wait(5)
	check(player.held_item == null, "Cuisson : tranches posées sur la plaque")
	await wait(int(cook.duration * 60) + 10)
	check(player.held_item != null and player.held_item.state == Item.State.COOKED, "Cuisson : assiette reprise")

	player.global_position = _front_of(delivery)
	await wait(5)
	check(player.held_item == null and game.score == start_score + 1, "Livraison : +1 point")

	# Collision : on pousse le joueur vers la cuisinière, il doit s'arrêter devant.
	var toward := (cook.global_position - _front_of(cook, 2.5)).normalized()
	player.global_position = _front_of(cook, 2.5)
	for i in 90:
		player.velocity = toward * player.speed
		player.move_and_slide()
		await get_tree().physics_frame
	var distance := Vector2(player.global_position.x - cook.global_position.x,
		player.global_position.z - cook.global_position.z).length()
	check(distance > 0.9, "Collision : le joueur ne traverse pas la cuisinière (distance %.2f)" % distance)

	print("Boucle de cuisine : %d échec(s)" % failures)
	get_tree().quit(1 if failures else 0)


## Point au sol devant un meuble, du côté du centre de la cuisine.
func _front_of(node: Node3D, distance := 1.2) -> Vector3:
	var p := node.global_position
	var to_center := Vector3(-p.x, 0, -p.z).normalized()
	var axis := Vector3(signf(to_center.x), 0, 0) if absf(p.x) > absf(p.z) * 0.6 else Vector3(0, 0, signf(to_center.z))
	return Vector3(p.x, 0, p.z) + axis * distance
