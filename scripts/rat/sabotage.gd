# scripts/rat/sabotage.gd
class_name Sabotage
extends RefCounted

var windup: float = 1.0
var weight: float = 1.0

func can_apply() -> bool:
	return false

func is_valid() -> bool:
	return false

func target_position() -> Vector3:
	return Vector3.ZERO

func apply(_rat: Node3D) -> void:
	pass

# -------------------------------------------------------------------
# 1. ÉTEINDRE LA PLAQUE
# -------------------------------------------------------------------
class StoveOffSabotage extends Sabotage:
	var target_station: Station = null

	func _init() -> void:
		windup = 1.0

	func can_apply() -> bool:
		var stations = Engine.get_main_loop().get_nodes_in_group("stations")
		for st in stations:
			if st.can_be_switched_off and not st.switched_off and st.is_transforming_item():
				target_station = st
				return true
		return false

	func is_valid() -> bool:
		return is_instance_valid(target_station) and target_station.can_be_switched_off and not target_station.switched_off and target_station.is_transforming_item()

	func target_position() -> Vector3:
		if is_instance_valid(target_station):
			return target_station.approach_point()
		return Vector3.ZERO

	func apply(_rat: Node3D) -> void:
		if is_instance_valid(target_station) and target_station.is_transforming_item() and not target_station.switched_off:
			target_station.switch_off()
			GameState.log_event("sabotage_stove_off", "le rat a éteint la plaque")

# -------------------------------------------------------------------
# 2. VOLER UN INGRÉDIENT SUR UNE STATION
# -------------------------------------------------------------------
class StealSabotage extends Sabotage:
	var target_station: Station = null

	func _init() -> void:
		windup = 0.8

	func can_apply() -> bool:
		var stations = Engine.get_main_loop().get_nodes_in_group("stations")
		var valid_stations: Array[Node3D] = []
		for st in stations:
			if st.has_item():
				valid_stations.append(st)

		if not valid_stations.is_empty():
			target_station = valid_stations.pick_random()
			return true
		return false

	func is_valid() -> bool:
		return is_instance_valid(target_station) and target_station.has_item()

	func target_position() -> Vector3:
		if is_instance_valid(target_station):
			return target_station.approach_point()
		return Vector3.ZERO

	func apply(rat: Node3D) -> void:
		if is_instance_valid(target_station) and target_station.has_item():
			var stolen_item = target_station.steal_item()
			if stolen_item:
				rat.carry(stolen_item)

# -------------------------------------------------------------------
# 3. RENVERSER LE PLAT DU JOUEUR
# -------------------------------------------------------------------
class SpillSabotage extends Sabotage:
	var player: Cook = null
	const MAX_PURSUIT_TIME: float = 4.0

	func _init() -> void:
		windup = 0.0 # Se déclenche au contact

	func can_apply() -> bool:
		var players = Engine.get_main_loop().get_nodes_in_group("player")
		if not players.is_empty() and players[0].has_item():
			player = players[0]
			return true
		return false

	func is_valid() -> bool:
		return is_instance_valid(player) and player.has_item()

	func target_position() -> Vector3:
		if is_instance_valid(player):
			return player.global_position
		return Vector3.ZERO

	func apply(_rat: Node3D) -> void:
		if is_instance_valid(player) and player.has_item():
			var item := player.take_item()
			var detail := item.get_item_name()
			if item:
				item.queue_free()
				_spawn_puddle(player.global_position)
				GameState.log_event("sabotage_spill", "le rat a renversé " + detail)
				GameState.take_damage(1, "rat : plat renversé")

	func _spawn_puddle(pos: Vector3) -> void:
		# Création d'une flaque temporaire au sol
		var puddle = CSGCylinder3D.new()
		puddle.radius = 0.6
		puddle.height = 0.02
		puddle.position = Vector3(pos.x, 0.01, pos.z)
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.4, 0.25, 0.1, 0.85) # Couleur soupe / sauce
		puddle.material = mat
		player.get_parent().add_child(puddle)

		# Disparaît après 4 secondes
		var tree = Engine.get_main_loop()
		tree.create_timer(4.0).timeout.connect(func(): puddle.queue_free())
