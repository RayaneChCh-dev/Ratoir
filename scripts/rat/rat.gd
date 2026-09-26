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
var carried_item: Node3D = null
var current_sabotage: Sabotage = null

var _state_timer: float = 0.0
var _protected_time: float = 5.0
var _anti_stuck_timer: float = 0.0

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
	
	_enter_hidden(profile.get_next_hidden_delay())

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
			if _anti_stuck_timer >= STUCK_LIMIT:
				_enter_returning()
				return

			var target = current_sabotage.target_position()
			var dist = global_position.distance_to(target)
			
			if dist < 0.4:
				_enter_sabotaging()
			else:
				_move_towards(target, profile.speed)

		State.SABOTAGING:
			_state_timer -= delta
			if _state_timer <= 0.0:
				if current_sabotage:
					current_sabotage.apply(self)
				_enter_returning()

		State.RETURNING:
			var dist = global_position.distance_to(hole_position)
			if dist < 0.3:
				_finish_returning()
			else:
				_move_towards(hole_position, profile.speed)

		State.FLEEING:
			var dist = global_position.distance_to(hole_position)
			if dist < 0.3:
				GameState.log_event("rat_fled", "%s retourne dans son trou" % profile.display_name)
				_enter_hidden(HIT_FLEE_LONG_DELAY)
			else:
				_move_towards(hole_position, profile.speed * 1.5)

func _move_towards(target: Vector3, spd: float) -> void:
	var dir = (target - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
		look_at(global_position + dir, Vector3.UP)
	velocity = dir * spd
	move_and_slide()

# --- GESTION DES ÉTATS ---

func _enter_hidden(delay: float) -> void:
	current_state = State.HIDDEN
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
	alert_label.visible = false

func _finish_returning() -> void:
	if carried_item:
		# Vol validé
		carried_item.queue_free()
		carried_item = null
	_enter_hidden(profile.get_next_hidden_delay())

# --- COUP REÇU (TAPER) ---

func hit() -> void:
	if current_state == State.HIDDEN or current_state == State.FLEEING:
		return
	
	# Lâcher l'objet au sol si le rat en portait un
	if carried_item:
		_drop_item_on_floor()

	alert_label.visible = false
	current_state = State.FLEEING
	_spawn_bonk_feedback()

func _drop_item_on_floor() -> void:
	var floor_item_scene = preload("res://scenes/floor_item.tscn")
	var floor_item = floor_item_scene.instantiate()
	get_parent().add_child(floor_item)
	floor_item.global_position = global_position
	
	# Transférer l'objet
	carried_item.get_parent().remove_child(carried_item)
	floor_item.setup(carried_item)
	carried_item = null

func carry(item: Node3D) -> void:
	if item.get_parent():
		item.get_parent().remove_child(item)
	hold_point.add_child(item)
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
	if s_off.can_apply():
		candidates.append(s_off)

	var s_steal = Sabotage.StealSabotage.new()
	s_steal.weight = profile.weight_steal
	if s_steal.can_apply():
		candidates.append(s_steal)

	var s_spill = Sabotage.SpillSabotage.new()
	s_spill.weight = profile.weight_spill
	if s_spill.can_apply():
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
		if body.is_in_group("player"):
			current_sabotage.apply(self)
			_enter_returning()