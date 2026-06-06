## Genera trayectorias zig-zag para rayos (Line2D).
extends RefCounted
class_name LightningPathBuilder


static func build_zigzag(
	from_pos: Vector2,
	to_pos: Vector2,
	segment_count: int = 8,
	jitter: float = 18.0,
	noise_seed: int = 0
) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var delta: Vector2 = to_pos - from_pos
	var length: float = delta.length()
	if length < 1.0:
		return PackedVector2Array([from_pos, to_pos])
	var dir: Vector2 = delta / length
	var normal: Vector2 = Vector2(-dir.y, dir.x)
	var steps: int = maxi(segment_count, 2)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = noise_seed if noise_seed != 0 else int(hash(from_pos) ^ hash(to_pos))
	for i: int in steps + 1:
		var t: float = float(i) / float(steps)
		var base: Vector2 = from_pos.lerp(to_pos, t)
		var falloff: float = sin(t * PI)
		var offset: float = 0.0
		if i > 0 and i < steps:
			offset = rng.randf_range(-jitter, jitter) * falloff
		points.append(base + normal * offset)
	return points


static func build_branch(
	anchor: Vector2,
	direction: Vector2,
	length: float,
	noise_seed: int = 0
) -> PackedVector2Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = noise_seed
	var dir: Vector2 = direction.normalized()
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	var mid: Vector2 = anchor + dir * length * 0.55
	var normal: Vector2 = Vector2(-dir.y, dir.x)
	mid += normal * rng.randf_range(-length * 0.35, length * 0.35)
	return PackedVector2Array([anchor, mid, anchor + dir * length])
