## Audio.gd — BGM (archivo propio o procedural) y SFX.
extends Node

signal volumes_changed(master: float, bgm: float, sfx: float)

const _SfxFactory = preload("res://scripts/audio/procedural_sfx_factory.gd")
const SETTINGS_PATH: String = "user://audio_settings.cfg"

## Arrastra tu canción aquí en el Inspector, o colócala en assets/audio/bgm_field.ogg
@export_file("*.ogg", "*.mp3", "*.wav") var custom_bgm_path: String = ""

@export_range(0.0, 1.0) var master_volume: float = 1.0
@export_range(0.0, 1.0) var bgm_volume: float = 0.55
@export_range(0.0, 1.0) var sfx_volume: float = 0.7

var _streams: Dictionary = {}
var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _zeny_sfx_cooldown: float = 0.0
var _bgm_started: bool = false
var _current_bgm_path: String = ""
const SFX_POOL_SIZE: int = 8

const _MapConfig = preload("res://data/map_config.gd")

const BGM_CANDIDATE_PATHS: Array[String] = [
	"res://assets/audio/bgm_field.ogg",
	"res://assets/audio/bgm_field.mp3",
	"res://assets/audio/bgm_field.wav",
]

const MENU_BGM_CANDIDATE_PATHS: Array[String] = [
	"res://assets/audio/bgm_menu.ogg",
	"res://assets/audio/bgm_menu.mp3",
	"res://assets/audio/bgm_menu.wav",
]

const PAYON_BGM_CANDIDATE_PATHS: Array[String] = [
	"res://assets/audio/bgm_payon.ogg",
	"res://assets/audio/bgm_payon.mp3",
	"res://assets/audio/bgm_payon.wav",
]

const LEVEL_UP_CANDIDATE_PATHS: Array[String] = [
	"res://audio/level_up.mp3",
	"res://audio/level_up.ogg",
	"res://audio/level_up.wav",
	"res://assets/audio/level_up.mp3",
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_load_volume_settings()
	_apply_bus_volumes_from_settings()
	_streams = _SfxFactory.build_sfx_only()
	_setup_players()
	_connect_game_signals()
	call_deferred("play_menu_bgm")


func _setup_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = &"Music"
	_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bgm_player)
	_apply_bgm_volume()
	for i: int in SFX_POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = &"SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_players.append(player)
	_apply_sfx_volume()


func _start_bgm_from_path(path: String, fallback_paths: Array[String] = []) -> void:
	var stream: AudioStream = _load_bgm_stream(path, fallback_paths)
	if stream == null:
		push_warning("Audio: no se pudo cargar BGM (%s)." % path)
		return
	if _bgm_player.stream == stream and _bgm_player.playing and path == _current_bgm_path:
		return
	_enable_stream_loop(stream)
	_current_bgm_path = path
	_bgm_player.stream = stream
	_bgm_player.play()
	_bgm_started = true
	if not _bgm_player.finished.is_connected(_on_bgm_finished):
		_bgm_player.finished.connect(_on_bgm_finished)


func _load_bgm_stream(primary_path: String, fallback_paths: Array[String]) -> AudioStream:
	if primary_path != "" and ResourceLoader.exists(primary_path):
		return load(primary_path) as AudioStream
	for candidate: String in fallback_paths:
		if ResourceLoader.exists(candidate):
			return load(candidate) as AudioStream
	return null


func _resolve_bgm_stream() -> AudioStream:
	if custom_bgm_path != "" and ResourceLoader.exists(custom_bgm_path):
		return load(custom_bgm_path) as AudioStream
	for path: String in BGM_CANDIDATE_PATHS:
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return _SfxFactory.create_field_bgm()


func play_menu_bgm() -> void:
	var path: String = _find_first_existing(MENU_BGM_CANDIDATE_PATHS)
	if path.is_empty():
		# Sin bgm_menu.*: usa la misma pista de campo como menú.
		path = _find_first_existing(BGM_CANDIDATE_PATHS)
	if path.is_empty():
		var stream: AudioStream = _SfxFactory.create_field_bgm()
		if stream == null:
			return
		_enable_stream_loop(stream)
		_current_bgm_path = ""
		_bgm_player.stream = stream
		_bgm_player.play()
		_bgm_started = true
		return
	_start_bgm_from_path(path, [])


func play_map_bgm(map_id: String) -> void:
	var path: String = _MapConfig.get_bgm_path(map_id)
	var fallbacks: Array[String] = BGM_CANDIDATE_PATHS
	if map_id == _MapConfig.MAP_PAYON:
		fallbacks = PAYON_BGM_CANDIDATE_PATHS + BGM_CANDIDATE_PATHS
	if path.is_empty() or not ResourceLoader.exists(path):
		path = _find_first_existing(fallbacks)
	_start_bgm_from_path(path, fallbacks)


func _find_first_existing(paths: Array[String]) -> String:
	for p: String in paths:
		if ResourceLoader.exists(p):
			return p
	return ""


func _start_field_bgm() -> void:
	play_map_bgm(_MapConfig.MAP_PRONTERA)


func _enable_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func _on_bgm_finished() -> void:
	# Respaldo si el archivo importado no tiene loop activado.
	if _bgm_player and _bgm_player.stream != null:
		_bgm_player.play()


func play_bgm(_stream_name: String = "") -> void:
	play_map_bgm(_MapConfig.MAP_PRONTERA)


func stop_bgm() -> void:
	if _bgm_player:
		_bgm_player.stop()
	_bgm_started = false


func resume_bgm_if_needed() -> void:
	if _bgm_player == null:
		return
	if not _bgm_started or _bgm_player.stream == null:
		play_map_bgm(Game.selected_map_id)
		return
	if not _bgm_player.playing:
		_bgm_player.play()


func play_sfx(stream_name: String, pitch_scale: float = 1.0) -> void:
	if not _streams.has(stream_name):
		return
	var player: AudioStreamPlayer = _get_free_sfx_player()
	if player == null:
		return
	player.stream = _streams[stream_name]
	player.pitch_scale = pitch_scale
	player.volume_db = 0.0
	player.play()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bgm_volume()
	_apply_sfx_volume()
	_emit_volumes()


func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes_from_settings()
	_emit_volumes()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes_from_settings()
	_emit_volumes()


func get_volume_settings() -> Dictionary:
	return {
		"master": master_volume,
		"bgm": bgm_volume,
		"sfx": sfx_volume,
	}


func save_volume_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "bgm", bgm_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SETTINGS_PATH)


func _load_volume_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	bgm_volume = float(cfg.get_value("audio", "bgm", bgm_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))


func _apply_bgm_volume() -> void:
	_apply_bus_volumes_from_settings()


func _apply_sfx_volume() -> void:
	_apply_bus_volumes_from_settings()


func _ensure_audio_buses() -> void:
	if not _has_bus(&"Music"):
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "Music")
		AudioServer.set_bus_send(1, &"Master")
	if not _has_bus(&"SFX"):
		var idx: int = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, &"Master")


func _has_bus(bus_name: StringName) -> bool:
	for i: int in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == bus_name:
			return true
	return false


func _apply_bus_volumes_from_settings() -> void:
	var music_idx: int = AudioServer.get_bus_index(&"Music")
	var sfx_idx: int = AudioServer.get_bus_index(&"SFX")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, _linear_to_db(bgm_volume))
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, _linear_to_db(sfx_volume))
	if _bgm_player:
		_bgm_player.volume_db = 0.0
	for player: AudioStreamPlayer in _sfx_players:
		if player.playing:
			player.volume_db = 0.0


func _linear_to_db(linear: float) -> float:
	if linear <= 0.001:
		return -80.0
	return linear_to_db(linear)


func _bgm_volume_db() -> float:
	if master_volume <= 0.0 or bgm_volume <= 0.0:
		return -80.0
	return linear_to_db(master_volume * bgm_volume)


func _sfx_volume_db() -> float:
	if master_volume <= 0.0 or sfx_volume <= 0.0:
		return -80.0
	return linear_to_db(master_volume * sfx_volume)


func _emit_volumes() -> void:
	volumes_changed.emit(master_volume, bgm_volume, sfx_volume)


func _process(delta: float) -> void:
	_zeny_sfx_cooldown = maxf(_zeny_sfx_cooldown - delta, 0.0)


func _connect_game_signals() -> void:
	if not Global.level_up.is_connected(_on_level_up):
		Global.level_up.connect(_on_level_up)
	if not Global.zeny_gained.is_connected(_on_zeny_gained):
		Global.zeny_gained.connect(_on_zeny_gained)
	if not Global.card_collected.is_connected(_on_card_collected):
		Global.card_collected.connect(_on_card_collected)


func _get_free_sfx_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]


func _on_level_up(_new_level: int) -> void:
	var path: String = _find_first_existing(LEVEL_UP_CANDIDATE_PATHS)
	if path.is_empty():
		play_sfx("level_up")
		return
	var player: AudioStreamPlayer = _get_free_sfx_player()
	if player == null:
		return
	player.stream = load(path) as AudioStream
	player.pitch_scale = 1.0
	player.volume_db = 0.0
	player.play()


func _on_zeny_gained(_amount: int, _total: int) -> void:
	if _zeny_sfx_cooldown > 0.0:
		return
	_zeny_sfx_cooldown = 0.07
	play_sfx("zeny", randf_range(0.95, 1.08))


func _on_card_collected(_card_id: String, _data: Dictionary) -> void:
	play_sfx("card")


func play_ui_click() -> void:
	play_sfx("ui_click")


func play_ui_hover() -> void:
	play_sfx("ui_click", randf_range(1.18, 1.28))
