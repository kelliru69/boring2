## Reproduce golpes superpuestos (polyphony) desde un arreglo de streams.
## Inspector: Max Polyphony ≥ 6–10 para combates intensos.
class_name HitSoundPlayer
extends AudioStreamPlayer2D

## Rutas a archivos .wav / .ogg / .mp3 (arrastra en el Inspector o usa defaults).
@export var sound_paths: PackedStringArray = PackedStringArray([
	"res://audio/hit/hit_01.wav",
	"res://audio/hit/hit_02.wav",
	"res://audio/hit/hit_03.wav",
])

@export_range(1, 32) var max_polyphony_count: int = 10
@export var volume_db_offset: float = 0.0
@export var pitch_random_range: float = 0.08

var _streams: Array[AudioStream] = []


func _ready() -> void:
	max_polyphony = max_polyphony_count
	bus = &"Master"
	_load_streams()


func _load_streams() -> void:
	_streams.clear()
	for path: String in sound_paths:
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		var loaded_stream: AudioStream = load(path) as AudioStream
		if loaded_stream:
			_streams.append(loaded_stream)


func play_hit(at_position: Vector2 = Vector2.ZERO, pitch_scale_override: float = -1.0) -> void:
	if _streams.is_empty():
		return
	global_position = at_position
	stream = _streams[randi() % _streams.size()]
	pitch_scale = pitch_scale_override if pitch_scale_override > 0.0 else randf_range(1.0 - pitch_random_range, 1.0 + pitch_random_range)
	volume_db = volume_db_offset
	play()
