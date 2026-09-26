# scripts/rat/rat.gd
class_name Rat
extends CharacterBody3D

enum State { HIDDEN, EMERGING, GOING, SABOTAGING, RETURNING, FLEEING }

@export var profile: RatProfile

# Nœuds enfants
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var model: Node3D = $Model
@onready var hold_point: Marker3D = $Model/HoldPoint
@onready var contact_area: Area3D = $ContactArea
@onready var alert_label: Label3D = $Alert

# États et Timers
var current_state: State = State.HIDDEN
var hole_position: Vector3 = Vector3.ZERO
var carried_item: Item = null
var current_sabotage: Sabotage = null

var _state_timer: float = 0.0
var _protected_time: float = 5.0
var _anti_stuck_timer: float = 0.0
var _difficulty_scale: float = 1.0

const STUCK_LIMIT: float = 6.0
const HIT_FLEE_LONG_DELAY: float = 10.0

func _ready() -> void:
	add_to_group("rat")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	hole_position = global_position

	if not profile:
		profile = RatProfile.new()

	contact_area.body_entered.connect(_on_contact_area_body_entered)
	alert_label.visible = false

	GameState.difficulty_changed.connect(_on_difficulty_changed)
	GameState.round_started.connect(_on_round_started)
	_on_round_started()

func _on_difficulty_changed(_level: int, scale: float) -> void:
	_difficulty_scale = scale

func _on_round_started() -> void:
	_difficulty_scale = GameState.difficulty_scale()
	# Un objet volé reste récupérable lors du passage de niveau.
	if carried_item:
		_drop_item_on_floor()
	_protected_time = 5.0
	_anti_stuck_timer = 0.0
	model.scale = Vector3.ONE
	_enter_hidden(profile.get_next_hidden_delay() / _difficulty_scale)

func _physics_process(delta: float) -> void:
	if _protected_time > 0.0:
		_protected_time -= delta

	match current_state:
		State.HIDDEN:
			_state_timer -= delta
			if _state_timer <= 0.0 and _protected_time <= 0.0:
				_try_emerge()

		State.EMERGING:
			_state_timer -= delta
			var t = 1.0 - (_state_timer / 0.3)
			model.scale = Vector3.ONE * clamp(t, 0.1, 1.0)
			if _state_timer <= 0.0:
				_start_going()

		State.GOING:
			_anti_stuck_timer += delta
			var limit := Sabotage.SpillSabotage.MAX_PURSUIT_TIME if current_sabotage is Sabotage.SpillSabotage else STUCK_LIMIT
			if not current_sabotage.is_valid() or _anti_stuck_timer >= limit:
				_enter_returning()
				return

			var target = current_sabotage.target_position()
			var dist := global_position.distance_to(target)
			alert_label.global_position = target + Vector3.UP * 1.5
			if current_sabotage is Sabotage.SpillSabotage:
				# Le contact physique est la seule condition de renversement.
				for body in contact_area.get_overlapping_bodies():
					_on_contact_area_body_entered(body)
				if current_state == State.GOING:
					_move_towards(target, profile.speed)
			elif dist < 0.4:
				_enter_sabotaging()
			else:
				_move_towards(target, profile.speed)

		State.SABOTAGING:
			_state_timer -= delta
			if _state_timer <= 0.0:
				if current_sabotage and current_sabotage.is_valid():
					current_sabotage.apply(self)
				_enter_returning()

		State.RETURNING:
			_anti_stuck_timer += delta
			var dist = global_position.distance_to(hole_position)
			if dist < 0.3 or _anti_stuck_timer >= STUCK_LIMIT:
				# En secours, rendre l’objet récupérable plutôt que valider un vol.
				if dist >= 0.3 and carried_item:
					_drop_item_on_floor()
				_finish_returning()
			else:
				_move_towards(hole_position, profile.speed)

		State.FLEEING:
			_anti_stuck_timer += delta
			var dist = global_position.distance_to(hole_position)
			if dist < 0.3 or _anti_stuck_timer >= STUCK_LIMIT:
				GameState.log_event("rat_fled", "%s retourne dans son trou" % profile.display_name)
				_enter_hidden(HIT_FLEE_LONG_DELAY)
			else:
				_move_towards(hole_position, profile.speed * 1.5)

func _move_towards(target: Vector3, spd: float) -> void:
	var dir = (target - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
		model.rotation.y = atan2(dir.x, dir.z)
	velocity = dir * spd * _difficulty_scale
	move_and_slide()
	global_position.y = 0.0

# --- GESTION DES ÉTATS ---

func _enter_hidden(delay: float) -> void:
	current_state = State.HIDDEN
	global_position = hole_position
	velocity = Vector3.ZERO
	_state_timer = delay
	visible = false
	collision_shape.set_deferred("disabled", true)
	contact_area.set_deferred("monitoring", false)
	alert_label.visible = false
	current_sabotage = null

func _try_emerge() -> void:
	current_sabotage = _pick_best_sabotage()
	if current_sabotage == null:
		_state_timer = 2.0 # Réessaie dans 2s si aucun sabotage n'est possible
		return

	current_state = State.EMERGING
	_state_timer = 0.3
	global_position = hole_position
	visible = true
	model.scale = Vector3(0.1, 0.1, 0.1)
	collision_shape.set_deferred("disabled", false)
	contact_area.set_deferred("monitoring", true)

	GameState.log_event("rat_appeared", "%s sort de son trou" % profile.display_name)

func _start_going() -> void:
	current_state = State.GOING
	model.scale = Vector3.ONE
	_anti_stuck_timer = 0.0
	alert_label.visible = true
	alert_label.global_position = current_sabotage.target_position() + Vector3.UP * 1.5

func _enter_sabotaging() -> void:
	current_state = State.SABOTAGING
	_state_timer = current_sabotage.windup
	velocity = Vector3.ZERO
	alert_label.visible = false

func _enter_returning() -> void:
	current_state = State.RETURNING
	_anti_stuck_timer = 0.0
	alert_label.visible = false

func _finish_returning() -> void:
	if carried_item:
		# Vol validé uniquement à l’arrivée au trou.
		GameState.log_event("sabotage_steal", "le rat a volé " + carried_item.get_item_name())
		carried_item.queue_free()
		carried_item = null
	_enter_hidden(profile.get_next_hidden_delay() / _difficulty_scale)

# --- COUP REÇU (TAPER) ---

func hit() -> bool:
	if current_state == State.HIDDEN or current_state == State.FLEEING:
		return false

	# Lâcher l'objet au sol si le rat en portait un
	if carried_item:
		_drop_item_on_floor()

	alert_label.visible = false
	current_state = State.FLEEING
	_anti_stuck_timer = 0.0
	model.scale = Vector3.ONE
	_spawn_bonk_feedback()
	return true

func _drop_item_on_floor() -> void:
	var floor_item_scene = preload("res://scenes/floor_item.tscn")
	var floor_item = floor_item_scene.instantiate()
	get_parent().add_child(floor_item)
	floor_item.global_position = global_position

	# Transférer l'objet
	floor_item.setup(carried_item)
	carried_item = null

func carry(item: Item) -> void:
	item.reparent(hold_point, false)
	item.position = Vector3.ZERO
	carried_item = item

func _spawn_bonk_feedback() -> void:
	var label = Label3D.new()
	label.text = "BONK !"
	label.modulate = Color.YELLOW
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = global_position + Vector3.UP * 1.0
	get_parent().add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y + 0.8, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

# --- SÉLECTION PONDÉRÉE DU SABOTAGE ---

func _pick_best_sabotage() -> Sabotage:
	var candidates: Array[Sabotage] = []

	var s_off = Sabotage.StoveOffSabotage.new()
	s_off.weight = profile.weight_stove_off
	if s_off.weight > 0.0 and s_off.can_apply():
		candidates.append(s_off)

	var s_steal = Sabotage.StealSabotage.new()
	s_steal.weight = profile.weight_steal
	if s_steal.weight > 0.0 and s_steal.can_apply():
		candidates.append(s_steal)

	var s_spill = Sabotage.SpillSabotage.new()
	s_spill.weight = profile.weight_spill
	if s_spill.weight > 0.0 and s_spill.can_apply():
		candidates.append(s_spill)

	if candidates.is_empty():
		return null

	var total_w = 0.0
	for s in candidates:
		total_w += s.weight

	var roll = randf() * total_w
	var cur = 0.0
	for s in candidates:
		cur += s.weight
		if roll <= cur:
			return s

	return candidates[0]

# --- CONTACT AREA (RENVERSER AU TOUCHER) ---

func _on_contact_area_body_entered(body: Node3D) -> void:
	if current_state == State.GOING and current_sabotage is Sabotage.SpillSabotage:
		if body.is_in_group("player") and current_sabotage.is_valid():
			current_sabotage.apply(self)
			_enter_returning()
