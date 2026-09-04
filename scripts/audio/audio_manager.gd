extends Node
## Audio playback: music + pooled SFX players, volume buses.
## Web-safe: playback only starts after user gesture (Click-to-Play) in the web shell.

var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 12

## Procedural tone cache (web-friendly, zero assets): id -> AudioStreamWAV
var _tone_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_apply_volumes()

## Simple procedural SFX: short synthesized tone, cached per sound id.
## No external audio assets needed for the MVP pass.
func play_tone(id: String, freq: float, duration: float, kind: String = "sine", volume_db_offset: float = 0.0) -> void:
	var stream: AudioStreamWAV = _get_tone(id, freq, duration, kind)
	play_sfx(stream, volume_db_offset, 1.0)

func _get_tone(id: String, freq: float, duration: float, kind: String) -> AudioStreamWAV:
	if _tone_cache.has(id):
		return _tone_cache[id]
	var sample_rate := 22050
	var count := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / sample_rate
		var progress := float(i) / count
		# Envelope: fast attack, exponential decay
		var envelope := minf(progress * 30.0, 1.0) * exp(-3.0 * progress)
		var sample := 0.0
		match kind:
			"sine":
				sample = sin(TAU * freq * t)
			"square":
				sample = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
			"saw":
				sample = 2.0 * fmod(t * freq, 1.0) - 1.0
			"noise":
				sample = randf_range(-1.0, 1.0)
		var value := int(clampf(sample * envelope, -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	_tone_cache[id] = stream
	return stream

func play_music(stream: AudioStream, loop: bool = true) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func play_sfx(stream: AudioStream, volume_db_offset: float = 0.0, pitch: float = 1.0) -> void:
	var player := _free_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = linear_to_db(clampf(sfx_volume, 0.001, 1.0)) + volume_db_offset
	player.pitch_scale = pitch
	player.play()

func _free_sfx_player() -> AudioStreamPlayer:
	if _sfx_players.is_empty():
		return null
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]

## Named SFX presets used across the game.
func play_game_sfx(id: String) -> void:
	match id:
		"weapon_fire":
			play_tone("shoot_fb", 220.0, 0.08, "saw", -6.0)
		"enemy_hit":
			play_tone("hit", 300.0, 0.05, "square", -10.0)
		"enemy_death":
			play_tone("death", 150.0, 0.12, "noise", -8.0)
		"xp_pickup":
			play_tone("xp", 1046.0, 0.06, "sine", -12.0)
		"level_up":
			play_tone("lvlup_a", 660.0, 0.15, "sine", -4.0)
			play_tone("lvlup_b", 880.0, 0.2, "sine", -4.0)
		"boss_warn":
			play_tone("boss_w", 110.0, 0.4, "square", -2.0)
		"boss_die":
			play_tone("boss_d", 90.0, 0.6, "saw", -2.0)
		"ui_click":
			play_tone("ui", 800.0, 0.04, "sine", -10.0)
		"player_hurt":
			play_tone("hurt", 180.0, 0.1, "square", -6.0)
		"ability":
			play_tone("abil", 440.0, 0.3, "saw", -4.0)
		"relic_pickup":
			play_tone("relic", 1320.0, 0.2, "sine", -8.0)

## Volume loading from save on demand.
func apply_saved_volumes() -> void:
	set_volumes(
		SaveManager.get_setting("master_volume", 0.8),
		SaveManager.get_setting("music_volume", 0.7),
		SaveManager.get_setting("sfx_volume", 0.8)
	)

func set_volumes(master: float, music: float, sfx: float) -> void:
	master_volume = master
	music_volume = music
	sfx_volume = sfx
	_apply_volumes()

func _apply_volumes() -> void:
	var music_db := linear_to_db(clampf(music_volume * master_volume, 0.001, 1.0))
	var sfx_db := linear_to_db(clampf(sfx_volume * master_volume, 0.001, 1.0))
	if _music_player:
		_music_player.volume_db = music_db
	for p in _sfx_players:
		p.volume_db = sfx_db
