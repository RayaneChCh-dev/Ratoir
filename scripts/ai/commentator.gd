extends Node
## Critique affamé : toutes les quelques secondes, la phrase de l'action
## la plus fréquente dans la fenêtre. Le jeu n'attend jamais la voix.

const FALLBACK := "I'm hungry. The chef had better hurry."
const WINDOW_SECONDS := 4.0
const TEXT_ONLY_SECONDS := 2.5
const SAFETY_SECONDS := 12.0

const LINES := {
	"tomato_taken": [
		"Another tomato. I'm still hungry.",
		"He grabs a tomato. The plate is still empty.",
	],
	"chop_started": [
		"Chop, chop, chop. The knife is doing all the work.",
		"He's chopping again. Faster. I'm starving.",
	],
	"cook_started": [
		"On the stove. I can almost smell it.",
		"It's cooking. Don't let it sit there.",
	],
	"dish_delivered": [
		"A plate, finally. I'm still hungry.",
		"One more plate. The room wants another.",
	],
}

@export var proxy_url := "http://127.0.0.1:8787/speak"

var _busy := false
var _playing_voice := false
var _window: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _line_index := {}
var _http: HTTPRequest
var _player: AudioStreamPlayer
var _hide_timer: Timer
var _window_timer: Timer


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	_http.request_completed.connect(_on_response)
	add_child(_http)

	_player = AudioStreamPlayer.new()
	_player.finished.connect(_on_voice_finished)
	add_child(_player)

	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.timeout.connect(_on_line_done)
	add_child(_hide_timer)

	_window_timer = Timer.new()
	_window_timer.one_shot = true
	_window_timer.timeout.connect(_on_window)
	add_child(_window_timer)

	GameState.event_logged.connect(_on_event)
	# F5 seul doit produire une voix : F6 est déjà le raccourci Godot « jouer la scène ».
	get_tree().create_timer(0.8).timeout.connect(_speak_boot)


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		GameState.log_event("dish_delivered", "debug")
		_flush_window()


func _on_event(entry: Dictionary) -> void:
	var name := str(entry.get("event", ""))
	if not LINES.has(name):
		return
	_window.append(entry)
	if _window_timer.is_stopped():
		_window_timer.start(WINDOW_SECONDS)


func _on_window() -> void:
	_flush_window()


func _flush_window() -> void:
	if _window.is_empty():
		return
	var batch: Array[Dictionary] = _window.duplicate()
	_window.clear()
	_window_timer.stop()
	if _busy:
		_pending = batch
		return
	_speak_batch(batch)


func _speak_boot() -> void:
	if _busy:
		return
	_busy = true
	_request_voice(FALLBACK)


func _speak_batch(batch: Array[Dictionary]) -> void:
	_busy = true
	_request_voice(_line_for(_dominant(batch)))


func _request_voice(text: String) -> void:
	print("critic: ", text)
	if proxy_url.is_empty():
		_hide_timer.start(TEXT_ONLY_SECONDS)
		return
	var err := _http.request(
		proxy_url,
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		JSON.stringify({"text": text}),
	)
	if err != OK:
		_hide_timer.start(TEXT_ONLY_SECONDS)


func _dominant(batch: Array[Dictionary]) -> String:
	var counts := {}
	for entry in batch:
		var name := str(entry.get("event", ""))
		counts[name] = int(counts.get(name, 0)) + 1
	var best := ""
	var best_count := 0
	for entry in batch:
		var name := str(entry.get("event", ""))
		var count := int(counts.get(name, 0))
		if count >= best_count:
			best = name
			best_count = count
	return best


func _line_for(action: String) -> String:
	var lines: Array = LINES.get(action, [FALLBACK])
	var index := int(_line_index.get(action, 0))
	_line_index[action] = index + 1
	return str(lines[index % lines.size()])


func _on_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_hide_timer.start(TEXT_ONLY_SECONDS)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		_hide_timer.start(TEXT_ONLY_SECONDS)
		return
	var audio_b64 := str(parsed.get("audio_base64", "")).strip_edges()
	if audio_b64.is_empty():
		_hide_timer.start(TEXT_ONLY_SECONDS)
		return
	var stream := _wav_stream(Marshalls.base64_to_raw(audio_b64))
	if stream == null:
		_hide_timer.start(TEXT_ONLY_SECONDS)
		return
	_playing_voice = true
	_player.stream = stream
	_player.play()
	_hide_timer.start(SAFETY_SECONDS)


func _on_voice_finished() -> void:
	if not _playing_voice:
		return
	_playing_voice = false
	_on_line_done()


func _on_line_done() -> void:
	_busy = false
	_playing_voice = false
	_hide_timer.stop()
	if _pending.is_empty():
		return
	var batch: Array[Dictionary] = _pending.duplicate()
	_pending.clear()
	_speak_batch(batch)


func _wav_stream(bytes: PackedByteArray) -> AudioStreamWAV:
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	var offset := 12
	var channels := 1
	var sample_rate := 24000
	var bits := 16
	var audio_format := 1
	var pcm := PackedByteArray()
	while offset + 8 <= bytes.size():
		var chunk_id := bytes.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_size := bytes.decode_u32(offset + 4)
		var start := offset + 8
		# Gradium met 0xFFFFFFFF comme taille : le son va jusqu'à la fin du fichier.
		var unknown_size := chunk_size == 0xFFFFFFFF
		if not unknown_size and start + chunk_size > bytes.size():
			return null
		if chunk_id == "fmt " and chunk_size >= 16:
			audio_format = bytes.decode_u16(start)
			channels = bytes.decode_u16(start + 2)
			sample_rate = bytes.decode_u32(start + 4)
			bits = bytes.decode_u16(start + 14)
		elif chunk_id == "data":
			var end := bytes.size() if unknown_size else start + chunk_size
			pcm = bytes.slice(start, end)
			break
		var padded := chunk_size + (chunk_size % 2)
		offset = start + padded
	if pcm.is_empty() or audio_format != 1 or bits != 16 or channels < 1 or sample_rate <= 0:
		return null
	var frame := 2 * channels
	pcm = pcm.slice(0, pcm.size() - (pcm.size() % frame))
	if pcm.is_empty():
		return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = channels > 1
	stream.data = pcm
	return stream
