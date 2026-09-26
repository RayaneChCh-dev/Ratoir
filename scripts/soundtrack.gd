extends AudioStreamPlayer
## Musique de fond : une tranche de 60 s par manche, bouclée tant que la manche dure.

const SEGMENT_SECONDS := 60.0
## Sous la voix du critique pour ne pas la couvrir.
const MUSIC_VOLUME_DB := -8.0
const STREAM_PATH := "res://assets/audio/sizzling_bistro_panic.mp3"


func _ready() -> void:
	stream = load(STREAM_PATH)
	volume_db = MUSIC_VOLUME_DB
	bus = "Master"
	GameState.round_started.connect(_on_round_started)
	GameState.round_state_changed.connect(_on_round_state_changed)
	# GameState a déjà démarré la manche 1 avant que Main soit prêt.
	if GameState.round_state == GameState.RoundState.PLAYING:
		_play_segment_for_level(GameState.level)


func _process(_delta: float) -> void:
	if not playing:
		return
	var start := segment_start()
	if get_playback_position() >= start + SEGMENT_SECONDS:
		seek(start)


func segment_start() -> float:
	return float(clampi(GameState.level, 1, 3) - 1) * SEGMENT_SECONDS


func _on_round_started() -> void:
	_play_segment_for_level(GameState.level)


func _on_round_state_changed(state: int) -> void:
	if state == GameState.RoundState.GAME_OVER or state == GameState.RoundState.WON:
		stop()


func _play_segment_for_level(_level: int) -> void:
	if stream == null:
		return
	var start := segment_start()
	play(start)
