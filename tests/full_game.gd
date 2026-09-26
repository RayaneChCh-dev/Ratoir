extends Node
## Test de partie complète : un joueur automatique pilote le chef au joystick (comme un vrai joueur),
## avec le rat actif et le juge, sur les 3 manches. Vérifie que la partie se termine sans blocage.
## Lancer : godot --headless --path . res://tests/full_game.tscn

const TIME_SCALE := 3.0
const STUCK_LIMIT := 45.0  # secondes de jeu sans livraison = blocage

var failures := 0
var game
var scene: Node
var player: Cook
var joystick: TouchJoystick
var chop: Station
var cook: Station
var spawn: Node3D
var delivery: Node3D
var stats := {"livraisons": 0, "verdicts": 0, "sabotages": 0, "manches": 0, "rallumages": 0}
var _since_delivery := 0.0
var _game_time := 0.0
var _done := false


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start.call_deferred()  # la racine est occupée pendant _ready : on ajoute la cuisine juste après


func _start() -> void:
	Engine.time_scale = TIME_SCALE
	game = get_tree().root.get_node("GameState")
	scene = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	player = scene.get_node("Player")
	joystick = scene.get_node("UI/TouchJoystick")
	chop = scene.get_node("Kitchen/ChopStation")
	cook = scene.get_node("Kitchen/CookStation")
	spawn = scene.get_node("Kitchen/IngredientSpawn")
	delivery = scene.get_node("Kitchen/DeliveryCounter")
	game.event_logged.connect(_on_event)
	scene.get_node("Judge").verdict_given.connect(func(_d, _s, _c) -> void: stats["verdicts"] += 1)
	await get_tree().process_frame
	check(get_tree().paused, "L'écran d'accueil met le jeu en pause")
	scene.get_node("Onboarding")._button.pressed.emit()  # appui sur PLAY


func _on_event(entry: Dictionary) -> void:
	match entry["event"]:
		"dish_delivered":
			stats["livraisons"] += 1
			_since_delivery = 0.0
		"round_end":
			stats["manches"] += 1
		"stove_relit":
			stats["rallumages"] += 1
		_:
			if String(entry["event"]).begins_with("sabotage_"):
				stats["sabotages"] += 1


func _physics_process(delta: float) -> void:
	if _done or game == null:
		return
	var state: int = game.round_state
	if state != game.RoundState.PLAYING:
		if get_tree().paused and _game_time > 1.0:
			_finish(state)
		return
	_game_time += delta
	_since_delivery += delta
	if _since_delivery > STUCK_LIMIT:
		check(false, "Blocage : aucune livraison depuis %d s (niveau %d)" % [STUCK_LIMIT, game.level])
		_finish(state)
		return
	_drive(_choose_target())


## Même logique qu'un joueur : on va chercher ce qui est prêt, sinon on avance la recette en cours.
func _choose_target() -> Node3D:
	var held: Item = player.held_item
	if held == null:
		if cook._item and (cook._item.state == Item.State.COOKED or cook.switched_off):
			return cook
		if chop._item and chop._item.state == Item.State.CHOPPED:
			return chop
		if chop._item == null:
			return spawn
		return chop  # on attend la découpe
	match held.state:
		Item.State.RAW:
			return chop
		Item.State.CHOPPED:
			return cook
		_:
			return delivery


func _drive(target: Node3D) -> void:
	var goal := _front_of(target)
	var to_goal := goal - player.global_position
	to_goal.y = 0.0
	joystick.output = Vector2.ZERO if to_goal.length() < 0.25 else Vector2(to_goal.x, to_goal.z).normalized()


func _front_of(node: Node3D) -> Vector3:
	var marker := node.get_node_or_null("ApproachPoint")
	if marker:
		return Vector3(marker.global_position.x, 0, marker.global_position.z)
	# Le comptoir de livraison n'a pas de point d'approche : côté cuisine (−Z).
	return node.global_position + Vector3(0, 0, -1.2)


func _finish(state: int) -> void:
	_done = true
	Engine.time_scale = 1.0
	joystick.output = Vector2.ZERO
	# Laisse le juge finir sa dernière critique avant de compter.
	get_tree().paused = false
	await get_tree().create_timer(5.0).timeout
	var result: String = game.RoundState.keys()[state]
	print("Partie terminée : %s au niveau %d, score %d, %.0f s de jeu" % [result, game.level, game.score, _game_time])
	print("Statistiques : %s" % stats)
	check(stats["livraisons"] == game.score, "Chaque livraison compte un point")
	check(stats["verdicts"] >= stats["livraisons"] - 1, "Le juge note chaque plat (%d verdicts / %d plats)" % [stats["verdicts"], stats["livraisons"]])
	check(stats["livraisons"] >= 5, "Au moins la première manche est jouable (%d plats)" % stats["livraisons"])
	check(game.events.size() > 0, "Journal d'événements rempli")
	print("Partie complète : %d échec(s)" % failures)
	get_tree().quit(1 if failures else 0)
