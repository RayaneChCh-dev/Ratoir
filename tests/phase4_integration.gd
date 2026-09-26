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
	check(game.level == 2 and game.time_left == 75.0, "Niveau 2 à cinq plats")
	check(is_equal_approx(rat._difficulty_scale, 1.4), "Difficulté transmise au rat")
	check(rat._protected_time == 5.0, "Protection au début de manche")
	var music = scene.get_node("Soundtrack")
	check(is_equal_approx(music.segment_start(), 60.0), "Musique manche 2 vise 60 s")
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
	check(not player.has_item() and game.round_state == game.RoundState.PLAYING, "Contact : perte du plat, la partie continue")
	rat._on_contact_area_body_entered(player)
	check(game.round_state == game.RoundState.PLAYING, "Un second contact ne termine pas la partie")
	joystick.output = Vector2.ONE
	game._process(100.0)
	check(get_tree().paused and game.round_state == game.RoundState.GAME_OVER, "Expiration : partie terminée")
	check(not rat.can_process() and not player.can_process(), "Rat et joueur figés")
	check(joystick.output == Vector2.ZERO, "Joystick relâché à la fin")
	check("PARTIE TERMINÉE" in scene.get_node("UI/Score").text, "HUD mis à jour malgré la pause")
	game.reset()
	check(not get_tree().paused and game.level == 1 and game.score == 0, "Reset de la progression")
	check(rat._difficulty_scale == 1.0 and rat.current_state == Rat.State.HIDDEN, "Reset du rat")
	for i in 15:
		game.add_point()
	check(game.level == 3 and game.round_state == game.RoundState.WON, "Victoire à 15 plats, sans niveau 4")
	check("GAGNÉ" in scene.get_node("UI/Score").text, "HUD de victoire")
	game.reset()
	game.level = 3
	game.start_round()
	check(is_equal_approx(rat._difficulty_scale, 1.8) and game.time_left == 60.0, "Plafonds de la manche 3")
	check(is_equal_approx(rat._protected_time, 3.0), "Protection de la manche 3")
	check(is_equal_approx(music.segment_start(), 120.0), "Musique manche 3 vise 120 s")
	var chop: Station = scene.get_node("Kitchen/ChopStation")
	var cook: Station = scene.get_node("Kitchen/CookStation")
	check(is_equal_approx(chop.duration, 1.0) and is_equal_approx(cook.duration, 1.6), "Recette de la manche 3")
	var trap_bin = scene.get_node("Kitchen/TrapBin")
	check(GameState.traps_unlocked() and trap_bin.visible and trap_bin.stock == 2, "Bac à pièges débloqué en manche 3")
	print("Phase 4 : %d échec(s)" % failures)
	get_tree().quit(1 if failures else 0)
