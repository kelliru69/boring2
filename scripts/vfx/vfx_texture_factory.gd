## Texturas procedurales suaves para VFX (sin bordes cuadrados en modo Additive).
extends RefCounted
class_name VfxTextureFactory

enum RadialProfile { PARTICLE, GLOW_ORB, SPARK_STREAK, ICE_SHARD }

static var _cache: Dictionary = {}


static func get_soft_radial(profile: RadialProfile = RadialProfile.PARTICLE) -> Texture2D:
	var key: String = "radial_%d" % profile
	if _cache.has(key):
		return _cache[key] as Texture2D
	var tex: Texture2D
	match profile:
		RadialProfile.GLOW_ORB:
			tex = _build_radial_image(96, 0.08, 0.55, 1.0)
		RadialProfile.SPARK_STREAK:
			tex = _build_streak_image(32, 8)
		RadialProfile.ICE_SHARD:
			tex = _build_ice_shard_image(20, 36)
		_:
			tex = _build_radial_image(80, 0.06, 0.48, 0.92)
	_cache[key] = tex
	return tex


static func apply_linear_filter(item: CanvasItem) -> void:
	if item == null:
		return
	item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


static func _build_radial_image(
	size: int,
	core_stop: float,
	mid_stop: float,
	edge_alpha: float
) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center: Vector2 = Vector2(float(size) * 0.5, float(size) * 0.5)
	var radius: float = float(size) * 0.5 - 0.5
	for y: int in size:
		for x: int in size:
			var dist: float = Vector2(float(x), float(y)).distance_to(center) / radius
			if dist > 1.0:
				continue
			var alpha: float = _radial_alpha(dist, core_stop, mid_stop, edge_alpha)
			if alpha <= 0.001:
				continue
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


static func _radial_alpha(dist: float, core_stop: float, mid_stop: float, edge_alpha: float) -> float:
	if dist <= core_stop:
		return 1.0
	if dist <= mid_stop:
		var t: float = (dist - core_stop) / maxf(mid_stop - core_stop, 0.001)
		return lerpf(1.0, 0.55, smoothstep(0.0, 1.0, t))
	var t2: float = (dist - mid_stop) / maxf(1.0 - mid_stop, 0.001)
	return lerpf(0.55, edge_alpha, smoothstep(0.0, 1.0, t2)) * (1.0 - smoothstep(0.82, 1.0, dist))


static func _build_streak_image(length: int, thickness: int) -> ImageTexture:
	var image: Image = Image.create(length, thickness, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var mid_y: float = float(thickness) * 0.5
	var half_h: float = float(thickness) * 0.5 - 0.5
	for x: int in length:
		var along: float = float(x) / float(maxi(length - 1, 1))
		var length_fade: float = 1.0 - smoothstep(0.55, 1.0, along)
		for y: int in thickness:
			var dy: float = absf(float(y) - mid_y) / maxf(half_h, 0.001)
			if dy > 1.0:
				continue
			var alpha: float = (1.0 - smoothstep(0.25, 1.0, dy)) * length_fade
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


static func _build_ice_shard_image(width: int, height: int) -> ImageTexture:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cx: float = float(width) * 0.5
	var cy: float = float(height) * 0.5
	for y: int in height:
		for x: int in width:
			var nx: float = absf(float(x) - cx) / maxf(cx, 0.001)
			var ny: float = absf(float(y) - cy) / maxf(cy, 0.001)
			var diamond: float = nx + ny * 0.65
			if diamond > 1.0:
				continue
			var alpha: float = (1.0 - smoothstep(0.35, 1.0, diamond)) * (1.0 - smoothstep(0.0, 0.15, ny))
			if alpha <= 0.002:
				continue
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)
