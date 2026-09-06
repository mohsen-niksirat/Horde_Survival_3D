extends Node
## V8 procedural music: layered synth pads built from cached tone loops.
## Three intensity states cross-faded by game state (calm/tense/boss).
## All web-safe: zero audio assets, generated once and looped.

signal intensity_changed(state: int)

enum Intensity { CALM, TENSE, BOSS }

const LAYER_FADE := 1.5

var _players: Dictionary = {}   # Intensity -> AudioStreamPlayer
var _current: int = -1
var _built: bool = false

## Layer frequencies (dark-synth pads, A-minor family)
const CALM_NOTES := [110.0, 164.81, 220.0]
const TENSE_NOTES := [110.0, 146.83, 174.61, 220.0]
const BOSS_NOTES := [82.41, 110.0, 155.56, 207.65]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Build the three loop layers once. Called from Main after boot.
func build_music() -> void:
	if _built:
		return
	_built = true
	_players[Intensity.CALM] = _make_layer("music_calm", CALM_NOTES, 0.10)
	_players[Intensity.TENSE] = _make_layer("music_tense", TENSE_NOTES, 0.12)
	_players[Intensity.BOSS] = _make_layer("music_boss", BOSS_NOTES, 0.14)

func _make_layer(cache_id: String, notes: Array, gain: float) -> AudioStreamPlayer:
	# Layer a detuned stack of slow tones into one looped WAV
	var sample_rate := 22050
	var loop_len := int(sample_rate * 2.0)  # 2-second seamless pad loop
	var data := PackedByteArray()
	data.resize(loop_len * 2)
	for i in range(loop_len):
		var t := float(i) / sample_rate
		var value := 0.0
		for n in notes:
			value += sin(TAU * n * t)
			value += sin(TAU * n * 1.005 * t)  # detune shimmer
		value /= float(notes.size()) * 2.0
		var env := 0.6 + 0.4 * sin(TAU * t / 2.0)  # slow swell
		var s := int(clampf(value * env * gain, -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, s)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = loop_len
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -60.0
	add_child(p)
	return p

## Switch intensity with a short cross-fade.
func set_intensity(state: int) -> void:
	if not _built or state == _current:
		return
	_current = state
	for key in _players:
		var p: AudioStreamPlayer = _players[key]
		var target_db := -60.0
		if key == state:
			target_db = linear_to_db(1.0)
		var tween := create_tween()
		tween.tween_property(p, "volume_db", target_db, LAYER_FADE)
		if key == state and not p.playing:
			p.play()
	intensity_changed.emit(state)

func stop_music() -> void:
	for key in _players:
		_players[key].stop()
	_current = -1
