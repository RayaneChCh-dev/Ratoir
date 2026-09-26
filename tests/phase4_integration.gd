extends Node

var failures := 0

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var game = get_tree().root.get_node("GameState")
	var scene = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	game.set_process(false)
	var rat = scene.get_node("Rat")
	var player = scene.get_node("Player")
	var joystick = scene.get_node("UI/TouchJoystick")
	check(rat.current_state == Rat.State.HIDDEN, "Rat caché au départ")
	for i in 5:
		game.add_point()
	check(game.level == 2 and game.time_left == 85.0, "Niveau 2 à cinq plats")
	check(is_equal_approx(rat._difficulty_scale, 1.15), "Difficulté transmise au rat")
	check(rat._protected_time == 5.0, "Protection au début de manche")
	var stolen := Item.new()
	scene.add_child(stolen)
	rat.carry(stolen)
	game.start_round()
	check(rat.carried_item == null and is_instance_valid(stolen), "Objet volé rendu récupérable")
	check(stolen.get_parent() is FloorItem, "Objet volé déposé au sol")
	player.hold(Item.new())
	var spill := Sabotage.SpillSabotage.new()
	spill.player = player
	rat.current_sabotage = spill
	rat.current_state = Rat.State.GOING
	rat._on_contact_area_body_entered(player)
	check(game.health == 2 and not player.has_item(), "Contact : perte du plat et d'une vie")
	rat._on_contact_area_body_entered(player)
	check(game.health == 2, "Pas de dégât répété après contact")
	game._process(100.0)
	check(game.health == 1 and game.time_left == 85.0, "Expiration : perte d'une vie et nouvelle manche")
	check(rat.current_state == Rat.State.HIDDEN, "Rat caché après expiration")
	joystick.output = Vector2.ONE
	game.take_damage()
	check(get_tree().paused and game.round_state == game.RoundState.GAME_OVER, "Pause à zéro vie")
	check(not rat.can_process() and not player.can_process(), "Rat et joueur figés")
	check(joystick.output == Vector2.ZERO, "Joystick relâché à la fin")
	check("PARTIE TERMINÉE" in scene.get_node("UI/Score").text, "HUD mis à jour malgré la pause")
	game.reset()
	check(not get_tree().paused and game.level == 1 and game.health == 3 and game.score == 0, "Reset de la progression")
	check(rat._difficulty_scale == 1.0 and rat.current_state == Rat.State.HIDDEN, "Reset du rat")
	game.level = 20
	game.start_round()
	check(rat._difficulty_scale == 2.0 and game.time_left == 60.0, "Plafonds difficulté et chrono")
	print("Phase 4 : %d échec(s)" % failures)
	get_tree().quit(1 if failures else 0)
