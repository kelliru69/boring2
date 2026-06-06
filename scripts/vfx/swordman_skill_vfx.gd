## VFX Swordman — alto contraste (outline + núcleo additive) para Payon/Prontera.
extends RefCounted
class_name SwordmanSkillVfx

const Z_INDEX: int = 14
const OUTLINE_DARK: Color = Color(0.02, 0.03, 0.06, 0.98)
const OUTLINE_LIGHT: Color = Color(1.0, 0.98, 0.92, 0.85)
const PADDING: float = 1.12


## Efectos en el mundo (Area2D): top_level para ordenar sobre el mapa.
static func setup_world_vfx(item: CanvasItem) -> void:
	if item == null:
		return
	item.z_index = Z_INDEX
	item.z_as_relative = false
	if item is Node2D:
		var n2: Node2D = item as Node2D
		var keep_pos: Vector2 = n2.global_position
		n2.set_as_top_level(true)
		n2.global_position = keep_pos
	_apply_additive_material(item)


## Efectos pegados al jugador (Endure, Berserk): sin top_level → siguen al sprite.
static func setup_attached_vfx(item: CanvasItem) -> void:
	if item == null:
		return
	item.z_index = Z_INDEX
	item.z_as_relative = true
	if item is Node2D:
		(item as Node2D).top_level = false
		(item as Node2D).set_as_top_level(false)


static func _apply_additive_material(item: CanvasItem) -> void:
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	item.material = mat


static func flash_alpha(elapsed: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	var t: float = clampf(elapsed / duration, 0.0, 1.0)
	if t < 0.14:
		return lerpf(0.4, 1.0, t / 0.14)
	return lerpf(1.0, 0.0, pow((t - 0.14) / 0.86, 0.85))


static func make_arc_polygon(radius: float, half_angle_rad: float, segments: int = 28) -> PackedVector2Array:
	var points: PackedVector2Array = [Vector2.ZERO]
	var steps: int = maxi(segments, 8)
	for i: int in steps + 1:
		var ang: float = lerpf(-half_angle_rad, half_angle_rad, float(i) / float(steps))
		points.append(Vector2.from_angle(ang) * radius)
	return points


static func make_box_polygon(length: float, half_width: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -half_width),
		Vector2(length, -half_width),
		Vector2(length, half_width),
		Vector2(0.0, half_width),
	])


static func _draw_gradient_ring(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	inner: Color,
	outer: Color,
	alpha: float,
	segments: int = 40,
	width: float = 5.0
) -> void:
	var steps: int = maxi(segments, 12)
	for layer: int in 3:
		var t: float = float(layer) / 2.0
		var r: float = radius * lerpf(0.72, 1.08, t)
		var c: Color = inner.lerp(outer, t)
		c.a *= alpha * lerpf(0.95, 0.35, t)
		var pts: PackedVector2Array = []
		for i: int in steps + 1:
			var ang: float = TAU * float(i) / float(steps)
			pts.append(center + Vector2.from_angle(ang) * r)
		if pts.size() >= 3:
			canvas.draw_polyline(pts, c, width - float(layer) * 0.8, true)


static func draw_outlined_polygon(
	canvas: CanvasItem,
	points: PackedVector2Array,
	fill: Color,
	edge: Color,
	alpha: float = 1.0,
	outline_dark_w: float = 11.0,
	outline_light_w: float = 6.0,
	edge_w: float = 3.5
) -> void:
	if points.size() < 3:
		return
	var closed: PackedVector2Array = points.duplicate()
	closed.append(points[0])
	var fill_c: Color = fill
	fill_c.a *= alpha
	var edge_c: Color = edge
	edge_c.a *= alpha
	var dark: Color = OUTLINE_DARK
	dark.a *= alpha
	var light: Color = OUTLINE_LIGHT
	light.a *= alpha
	canvas.draw_colored_polygon(points, fill_c)
	canvas.draw_polyline(closed, dark, outline_dark_w, true)
	canvas.draw_polyline(closed, light, outline_light_w, true)
	canvas.draw_polyline(closed, edge_c, edge_w, true)


static func draw_bash_arc(
	canvas: CanvasItem,
	radius: float,
	half_angle_rad: float,
	fill: Color,
	edge: Color,
	alpha: float,
	slash_scale: float = 1.0
) -> void:
	var poly: PackedVector2Array = make_arc_polygon(radius * PADDING, half_angle_rad)
	draw_outlined_polygon(canvas, poly, fill, edge, alpha * 0.55, 12.0, 7.0, 4.0)
	var glow_fill: Color = fill
	glow_fill.a *= alpha * 0.42
	canvas.draw_colored_polygon(poly, glow_fill)
	var tip_len: float = radius * 1.08 * slash_scale
	var tip: Vector2 = Vector2(tip_len, 0.0)
	var dark: Color = OUTLINE_DARK
	dark.a *= alpha
	canvas.draw_line(Vector2.ZERO, tip, dark, 6.0, true)
	var slash_c: Color = edge
	slash_c.a *= alpha
	canvas.draw_line(Vector2.ZERO, tip, slash_c, 3.5, true)
	var slash_w: float = radius * 0.22 * slash_scale
	canvas.draw_line(
		Vector2(tip_len * 0.35, -slash_w),
		Vector2(tip_len * 0.92, slash_w * 0.35),
		slash_c,
		2.5,
		true
	)
	canvas.draw_line(
		Vector2(tip_len * 0.35, slash_w),
		Vector2(tip_len * 0.92, -slash_w * 0.35),
		slash_c.lightened(0.15),
		2.0,
		true
	)


static func draw_slash_box(
	canvas: CanvasItem,
	length: float,
	half_width: float,
	fill: Color,
	edge: Color,
	chevron: Color,
	alpha: float,
	chevron_count: int = 4,
	slash_scale: float = 1.0
) -> void:
	var len_s: float = length * PADDING * slash_scale
	var hw_s: float = half_width * PADDING * slash_scale
	var poly: PackedVector2Array = make_box_polygon(len_s, hw_s)
	draw_outlined_polygon(canvas, poly, fill, edge, alpha * 0.5, 11.0, 6.5, 4.0)
	var glow: Color = fill
	glow.a *= alpha * 0.38
	canvas.draw_colored_polygon(poly, glow)
	draw_forward_chevrons(canvas, len_s, hw_s, chevron, alpha, chevron_count)


static func draw_forward_chevrons(
	canvas: CanvasItem,
	length: float,
	half_width: float,
	color: Color,
	alpha: float,
	count: int = 3
) -> void:
	var c: Color = color
	c.a *= alpha
	var n: int = maxi(count, 1)
	for i: int in n:
		var t: float = float(i + 1) / float(n + 1)
		var x: float = length * t
		var hw: float = half_width * 0.55
		var tip: Vector2 = Vector2(x + length * 0.06, 0.0)
		var top: Vector2 = Vector2(x - length * 0.04, -hw)
		var bot: Vector2 = Vector2(x - length * 0.04, hw)
		canvas.draw_line(top, tip, OUTLINE_DARK * Color(1, 1, 1, alpha * 0.7), 4.0, true)
		canvas.draw_line(bot, tip, OUTLINE_DARK * Color(1, 1, 1, alpha * 0.7), 4.0, true)
		canvas.draw_line(top, tip, c, 2.5, true)
		canvas.draw_line(bot, tip, c, 2.5, true)


static func draw_fire_shockwave(
	canvas: CanvasItem,
	radius: float,
	progress: float,
	alpha: float
) -> void:
	var expand: float = lerpf(0.35, 1.15, clampf(progress, 0.0, 1.0))
	var r: float = radius * expand * PADDING
	var fade: float = alpha * (1.0 - progress * 0.92)
	var core: Color = Color(1.0, 0.92, 0.55, 0.65)
	var mid: Color = Color(1.0, 0.45, 0.12, 0.45)
	var outer: Color = Color(1.0, 0.22, 0.04, 0.22)
	canvas.draw_circle(Vector2.ZERO, r * 0.35, core * Color(1, 1, 1, fade * 0.7))
	canvas.draw_circle(Vector2.ZERO, r * 0.72, mid * Color(1, 1, 1, fade * 0.5))
	canvas.draw_circle(Vector2.ZERO, r, outer * Color(1, 1, 1, fade * 0.35))
	_draw_gradient_ring(canvas, Vector2.ZERO, r, Color(1.0, 0.75, 0.3, 1.0), Color(1.0, 0.25, 0.05, 1.0), fade, 48, 5.5)
	var dark: Color = OUTLINE_DARK
	dark.a *= fade
	canvas.draw_arc(Vector2.ZERO, r, 0.0, TAU, 52, dark, 9.0, true)
	var light: Color = OUTLINE_LIGHT
	light.a *= fade * 0.85
	canvas.draw_arc(Vector2.ZERO, r, 0.0, TAU, 52, light, 4.5, true)


static func draw_magnum_burst(
	canvas: CanvasItem,
	radius: float,
	_inner: Color,
	_outer: Color,
	_ring: Color,
	alpha: float,
	ring_progress: float = 1.0
) -> void:
	draw_fire_shockwave(canvas, radius, ring_progress, alpha)


static func draw_endure_shield(
	canvas: CanvasItem,
	radius: float,
	pulse: float,
	alpha: float
) -> void:
	var r: float = radius * pulse
	_draw_gradient_ring(
		canvas,
		Vector2.ZERO,
		r,
		Color(0.55, 0.82, 1.0, 0.9),
		Color(0.2, 0.45, 0.95, 0.5),
		alpha,
		44,
		4.0
	)
	var dark: Color = OUTLINE_DARK
	dark.a *= alpha
	canvas.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, dark, 7.0, true)
