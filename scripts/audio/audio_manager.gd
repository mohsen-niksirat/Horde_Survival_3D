extends Node
## Audio playback: music + pooled SFX players, volume buses.
## Web-safe: playback only starts after user gesture (Click-to-Play) in the web shell.

var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 12

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
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]

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
