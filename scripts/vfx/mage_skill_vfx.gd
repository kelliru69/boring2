## VFX Mage — additive, tweens orgánicos, paleta sin rojo en fuego.
extends RefCounted
class_name MageSkillVfx

const _Palette = preload("res://scripts/vfx/combat_vfx_palette.gd")
const _VfxConfig = preload("res://scripts/vfx/elemental_vfx_config.gd")
const _VfxSpawner = preload("res://scripts/vfx/elemental_vfx_spawner.gd")
const _ImpactFlash = preload("res://scripts/vfx/impact_flash.gd")
const _Spawn = preload("res://scripts/vfx/vfx_spawn_helper.gd")
const Z_PROJECTILE: int = 12


static func setup_player_projectile(item: CanvasItem, element: StringName) -> void:
	if item == null:
		return
	item.z_index = Z_PROJECTILE
	item.z_as_relative = false
	if item is Node2D:
		(item as Node2D).top_level = false
	match element:
		&"fire":
			item.modulate = _Palette.player_fire_modulate()
		&"ice":
			item.modulate = _Palette.player_ice_modulate()
		&"lightning":
			item.modulate = _Palette.player_lightning_modulate(0.0)
		&"soul":
			item.modulate = _Palette.PLAYER_SOUL_CORE
		_:
			pass
	_Palette.apply_soft_blend(item)
	if item is CanvasItem:
		# Hojas pixel-art 32→16: filtro Nearest en Inspector o aquí en runtime.
		item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


static func pulse_projectile_modulate(item: CanvasItem, element: StringName, elapsed: float) -> void:
	if item == null:
		return
	match element:
		&"fire":
			item.modulate = _Palette.player_fire_modulate(elapsed)
		&"ice":
			item.modulate = _Palette.player_ice_modulate(elapsed)
		&"lightning":
			item.modulate = _Palette.player_lightning_modulate(elapsed)
		&"soul":
			var w: float = 0.5 + 0.5 * sin(elapsed * 6.0)
			item.modulate = _Palette.PLAYER_SOUL_CORE.lerp(_Palette.PLAYER_SOUL_GLOW, w * 0.4)
		_:
			pass


static func attach_sight_wisp(orb: Node2D) -> VfxParticles:
	if orb == null:
		return null
	for child: Node in orb.get_children():
		if child is VfxParticles and (child as VfxParticles).vfx_preset == _VfxConfig.PRESET_SIGHT_WISP:
			return child as VfxParticles
	var particles: VfxParticles = _VfxSpawner.spawn_attached_preset(orb, _VfxConfig.PRESET_SIGHT_WISP)
	if particles != null:
		particles.name = &"SightWisp"
	return particles


static func draw_fire_barrier(canvas: CanvasItem, radius: float, elapsed: float, duration: float) -> void:
	draw_fire_barrier_line(canvas, radius * 2.0, maxi(int(round(radius / 16.0)), 1), elapsed, duration)


static func draw_fire_barrier_line(
	canvas: CanvasItem,
	tile_size_px: float,
	tiles: int,
	elapsed: float,
	duration: float
) -> void:
	if canvas == null or tiles <= 0:
		return
	var tile_px: float = maxf(tile_size_px, 1.0)
	var half_h: float = float(tiles) * tile_px * 0.5
	var half_w: float = tile_px * 0.5
	var life: float = clampf(elapsed / maxf(duration, 0.01), 0.0, 1.0)
	var pulse: float = 0.55 + 0.45 * sin(elapsed * 8.0)
	for i: int in tiles:
		var center_y: float = -half_h + tile_px * 0.5 + float(i) * tile_px
		var rect := Rect2(-half_w, center_y - tile_px * 0.5, tile_px, tile_px)
		var inner: Color = _Palette.PLAYER_FIRE_CORE
		inner.a = 0.28 * (1.0 - life * 0.35) * pulse
		var edge: Color = _Palette.PLAYER_FIRE_MID
		edge.a = 0.55 * (1.0 - life * 0.25) * pulse
		canvas.draw_rect(rect, inner, true)
		canvas.draw_rect(rect, edge, false, 2.0)
		var hot: Color = Color(1.0, 0.62, 0.18, 0.32 * pulse)
		canvas.draw_rect(rect.grow(-tile_px * 0.22), hot, true)


static func draw_ice_zone(canvas: CanvasItem, radius: float, elapsed: float, alpha_scale: float = 1.0) -> void:
	var core: Color = _Palette.PLAYER_ICE_CORE
	core.a = 0.18 * alpha_scale
	var ring: Color = _Palette.PLAYER_ICE_MID
	ring.a = 0.35 * alpha_scale * (0.7 + 0.3 * sin(elapsed * 11.0))
	canvas.draw_circle(Vector2.ZERO, radius, core)
	canvas.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, ring, 3.0, true)
	_draw_ice_spikes(canvas, radius, elapsed, alpha_scale)


static func spawn_fire_impact(parent: Node, world_pos: Vector2) -> void:
	_VfxSpawner.spawn_fire_impact(parent, world_pos)
	_ImpactFlash.spawn(parent, world_pos, _Palette.PLAYER_FIRE_GLOW, 0.75, 0.08, 2.0)


static func spawn_soul_impact(parent: Node, world_pos: Vector2) -> void:
	_VfxSpawner.spawn_soul_impact(parent, world_pos)
	_ImpactFlash.spawn(parent, world_pos, _Palette.PLAYER_SOUL_CORE, 0.72, 0.1, 1.9)


static func draw_frost_diver_head(canvas: CanvasItem, radius: float, elapsed: float) -> void:
	var pulse: float = 0.7 + 0.3 * sin(elapsed * 16.0)
	var core: Color = Color(0.58, 0.92, 1.0, 0.42 * pulse)
	var ring: Color = Color(0.42, 0.82, 0.98, 0.5 * pulse)
	canvas.draw_circle(Vector2.ZERO, radius * 0.55, core)
	canvas.draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 24, ring, 2.5, true)
	_draw_ice_spikes(canvas, radius * 0.85, elapsed, 0.85)


static func draw_frost_explosion_ring(canvas: CanvasItem, radius: float, elapsed: float, alpha: float = 1.0) -> void:
	var expand: float = lerpf(0.25, 1.0, clampf(elapsed * 3.5, 0.0, 1.0))
	var r: float = radius * expand
	var inner: Color = Color(0.95, 1.0, 1.0, 0.35 * alpha * (1.0 - expand * 0.5))
	var outer: Color = Color(0.5, 0.85, 1.0, 0.28 * alpha)
	canvas.draw_circle(Vector2.ZERO, r * 0.55, inner)
	canvas.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, outer, 3.5, true)
	_draw_ice_spikes(canvas, r * 0.92, elapsed * 2.0, alpha * 0.7)


static func spawn_frost_diver_impact(parent: Node, world_pos: Vector2, blast_radius: float) -> void:
	_VfxSpawner.spawn_frost_diver_burst(parent, world_pos)
	_VfxSpawner.spawn_ice_shatter(parent, world_pos)
	_ImpactFlash.spawn(parent, world_pos, _Palette.PLAYER_ICE_CORE, 0.68, 0.1, 2.0)
	var ring: FrostExplosionRingFx = FrostExplosionRingFx.new()
	ring.setup(blast_radius, 0.35)
	_Spawn.add_child_at_world(parent, ring, world_pos)


static func spawn_ice_impact(parent: Node, world_pos: Vector2) -> void:
	_VfxSpawner.spawn_ice_shatter(parent, world_pos)
	_ImpactFlash.spawn(parent, world_pos, _Palette.PLAYER_ICE_CORE, 0.7, 0.1, 2.0)


static func spawn_lightning_ground_wave(parent: Node, world_pos: Vector2, radius: float) -> void:
	_VfxSpawner.spawn_electric_ground_ring(parent, world_pos, radius)


static func spawn_lightning_impact(parent: Node, world_pos: Vector2, travel_radius: float) -> void:
	_VfxSpawner.spawn_lightning_sparks(parent, world_pos)
	_VfxSpawner.spawn_lightning_bolt_hit(parent, world_pos, travel_radius)
	_ImpactFlash.spawn(parent, world_pos, _Palette.PLAYER_LIGHTNING_CORE, 0.72, 0.08, 1.85)


static func _draw_ice_spikes(canvas: CanvasItem, radius: float, elapsed: float, alpha_scale: float) -> void:
	var spikes: int = 8
	for i: int in spikes:
		var ang: float = TAU * float(i) / float(spikes) + elapsed * 0.6
		var tip: Vector2 = Vector2.from_angle(ang) * radius * 0.78
		var base: Vector2 = Vector2.from_angle(ang) * radius * 0.5
		var c: Color = Color(0.72, 0.94, 1.0, 0.5 * alpha_scale)
		canvas.draw_line(base, tip, c, 2.0)
