## Sonidos retro estilo MMORPG coreano (tonos brillantes, arpegios cortos).
class_name ProceduralSfxFactory
extends RefCounted

const SAMPLE_RATE: int = 22050


static func build_sfx_only() -> Dictionary:
	return {
		"fire_bolt": _fire_bolt(),
		"hit": _hit(),
		"enemy_death": _enemy_death(),
		"player_hurt": _player_hurt(),
		"level_up": _level_up(),
		"zeny": _zeny(),
		"card": _card_sparkle(),
		"ui_click": _ui_click(),
	}


static func create_field_bgm() -> AudioStream:
	return _bgm_field()


static func _fire_bolt() -> AudioStream:
	var samples: PackedFloat32Array = _mix([
		_tone(880.0, 0.05, 0.22, true),
		_tone(1320.0, 0.07, 0.18, true),
		_noise_burst(0.04, 0.12),
	])
	return _to_wav(samples)


static func _hit() -> AudioStream:
	return _to_wav(_tone(520.0, 0.06, 0.35, true))


static func _enemy_death() -> AudioStream:
	return _to_wav(_mix([
		_tone(392.0, 0.08, 0.25, true),
		_tone(330.0, 0.1, 0.22, true),
		_tone(262.0, 0.14, 0.2, true),
	]))


static func _player_hurt() -> AudioStream:
	return _to_wav(_mix([
		_tone(180.0, 0.12, 0.35, false),
		_noise_burst(0.08, 0.15),
	]))


static func _level_up() -> AudioStream:
	# Arpegio ascendente estilo level-up retro
	return _to_wav(_concat([
		_tone(523.25, 0.09, 0.28, true),
		_tone(659.25, 0.09, 0.28, true),
		_tone(783.99, 0.1, 0.3, true),
		_tone(1046.5, 0.16, 0.32, true),
	]))


static func _zeny() -> AudioStream:
	return _to_wav(_mix([
		_tone(1174.7, 0.05, 0.25, true),
		_tone(1568.0, 0.08, 0.2, true),
	]))


static func _card_sparkle() -> AudioStream:
	return _to_wav(_mix([
		_tone(988.0, 0.06, 0.2, true),
		_tone(1318.5, 0.08, 0.22, true),
		_tone(1760.0, 0.1, 0.18, true),
	]))


static func _ui_click() -> AudioStream:
	return _to_wav(_tone(660.0, 0.04, 0.2, true))


static func _bgm_field() -> AudioStream:
	# Melodía simple en loop (más audible que acordes mezclados)
	var notes: Array[float] = [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 261.63]
	var parts: Array = []
	for freq: float in notes:
		parts.append(_tone(freq, 0.42, 0.14, false))
	var loop: PackedFloat32Array = _concat(parts)
	return _to_wav(loop, true)


static func _tone(freq: float, duration: float, volume: float, quick_decay: bool) -> PackedFloat32Array:
	var count: int = int(duration * SAMPLE_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	for i: int in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0
		if quick_decay:
			env = pow(1.0 - float(i) / float(count), 2.2)
		else:
			var attack: float = minf(float(i) / float(SAMPLE_RATE) * 8.0, 1.0)
			var release: float = 1.0 - maxf((t - duration * 0.75) / (duration * 0.25), 0.0)
			env = attack * release
		out[i] = sin(TAU * freq * t) * volume * env
	return out


static func _noise_burst(duration: float, volume: float) -> PackedFloat32Array:
	var count: int = int(duration * SAMPLE_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for i: int in count:
		var env: float = 1.0 - float(i) / float(count)
		out[i] = rng.randf_range(-1.0, 1.0) * volume * env
	return out


static func _concat(parts: Array) -> PackedFloat32Array:
	var total: int = 0
	for part: Variant in parts:
		if part is PackedFloat32Array:
			total += (part as PackedFloat32Array).size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total)
	var offset: int = 0
	for part: Variant in parts:
		if part is not PackedFloat32Array:
			continue
		var arr: PackedFloat32Array = part as PackedFloat32Array
		for i: int in arr.size():
			out[offset + i] = arr[i]
		offset += arr.size()
	return out


static func _mix(parts: Array) -> PackedFloat32Array:
	var max_len: int = 0
	for part: Variant in parts:
		if part is PackedFloat32Array:
			max_len = maxi(max_len, (part as PackedFloat32Array).size())
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(max_len)
	for i: int in max_len:
		var sum: float = 0.0
		for part: Variant in parts:
			if part is PackedFloat32Array:
				var arr: PackedFloat32Array = part as PackedFloat32Array
				if i < arr.size():
					sum += arr[i]
		out[i] = clampf(sum, -1.0, 1.0)
	return out


static func _to_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		var sample16: int = int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data[i * 2] = sample16 & 0xFF
		data[i * 2 + 1] = (sample16 >> 8) & 0xFF
	stream.data = data
	return stream
