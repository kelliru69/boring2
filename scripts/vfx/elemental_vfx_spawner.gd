## Instancia escenas VFX editables (`scenes/vfx/particles/`).
extends RefCounted
class_name ElementalVfxSpawner

const _CameraShake = preload("res://scripts/vfx/camera_shake_controller.gd")
const _Registry = preload("res://scripts/vfx/vfx_scene_registry.gd")
const _VfxParticles = preload("res://scenes/vfx/particles/VfxParticles.gd")
const _Spawn = preload("res://scripts/vfx/vfx_spawn_helper.gd")
const _Budget = preload("res://scripts/vfx/combat_vfx_budget.gd")

const TRAIL_PRESET_SOUL: StringName = &"soul"
const TRAIL_PRESET_FIRE: StringName = &"fire"
const TRAIL_PRESET_ICE: StringName = &"ice"
const TRAIL_PRESET_LIGHTNING: StringName = &"lightning"
const TRAIL_PRESET_ENEMY: StringName = &"enemy"

const PROJECTILE_TRAILS_ENABLED: bool = false
const ENEMY_IMPACT_PARTICLES_ENABLED: bool = false


static func attach_projectile_trail(projectile: Node2D, preset: StringName = TRAIL_PRESET_FIRE) -> VfxParticles:
	if not PROJECTILE_TRAILS_ENABLED or projectile == null or not _Budget.allow_trail():
		return null
	var scene: PackedScene = _trail_scene_for(preset)
	var particles: VfxParticles = scene.instantiate() as VfxParticles
	if particles == null:
		return null
	particles.local_coords = true
	particles.position = Vector2.ZERO
	projectile.add_child(particles)
	particles.emitting = true
	return particles


static func spawn_attached_preset(parent: Node2D, preset: StringName) -> VfxParticles:
	if parent == null or preset.is_empty():
		return null
	var scene: PackedScene = _scene_for_preset(preset)
	if scene == null:
		return null
	var particles: VfxParticles = scene.instantiate() as VfxParticles
	if particles == null:
		return null
	parent.add_child(particles)
	particles.emitting = true
	return particles


static func spawn_ice_shatter(parent: Node, world_pos: Vector2, _amount: int = 28) -> void:
	if not ENEMY_IMPACT_PARTICLES_ENABLED:
		return
	_spawn_burst(_Registry.ICE_SHATTER, parent, world_pos)


static func spawn_frost_diver_burst(parent: Node, world_pos: Vector2) -> void:
	if not ENEMY_IMPACT_PARTICLES_ENABLED:
		return
	_spawn_burst(_Registry.FROST_SHATTER, parent, world_pos)


static func spawn_fire_impact(parent: Node, world_pos: Vector2) -> void:
	if not ENEMY_IMPACT_PARTICLES_ENABLED:
		return
	_spawn_burst(_Registry.FIRE_IMPACT, parent, world_pos)


static func spawn_soul_impact(parent: Node, world_pos: Vector2) -> void:
	if not ENEMY_IMPACT_PARTICLES_ENABLED:
		return
	_spawn_burst(_Registry.SOUL_IMPACT, parent, world_pos)


static func spawn_lightning_sparks(parent: Node, world_pos: Vector2) -> void:
	if not ENEMY_IMPACT_PARTICLES_ENABLED:
		return
	_spawn_burst(_Registry.LIGHTNING_SPARK, parent, world_pos)


static func spawn_lightning_hit_spark(parent: Node, world_pos: Vector2) -> void:
	if not ENEMY_IMPACT_PARTICLES_ENABLED:
		return
	_spawn_burst(_Registry.ELECTRIC_RING, parent, world_pos)


static func spawn_electric_ground_ring(parent: Node, world_pos: Vector2, radius: float) -> void:
	if parent == null or not _Budget.allow_burst():
		return
	var ring: VfxParticles = _Registry.ELECTRIC_RING.instantiate() as VfxParticles
	if ring == null:
		return
	_Spawn.add_child_at_world(parent, ring, world_pos)
	ring.configure_electric_outward(radius * 0.55)
	ring.play_burst_at(world_pos)


static func attach_firewall_ambient(wall: Node2D, radius: float) -> VfxParticles:
	var particles: VfxParticles = _Registry.FIREWALL_SMOKE.instantiate() as VfxParticles
	if particles == null:
		return null
	wall.add_child(particles)
	particles.position = Vector2.ZERO
	particles.configure_firewall_radius(radius)
	particles.emitting = true
	return particles


static func spawn_thunderstorm_strike(
	parent: Node,
	world_pos: Vector2,
	radius: float,
	with_camera_shake: bool = true
) -> void:
	if parent == null:
		return
	_spawn_lightning_zap(parent, world_pos, 120.0 + radius * 0.85)
	spawn_electric_ground_ring(parent, world_pos, radius)
	if with_camera_shake:
		_CameraShake.shake_active_scene(5.5 + radius * 0.04, 0.22)
	Audio.play_sfx_varied("thunder_storm", 0.88, 1.05)


static func spawn_lightning_bolt_hit(parent: Node, world_pos: Vector2, travel_radius: float) -> void:
	if parent == null:
		return
	_spawn_lightning_zap(parent, world_pos, 72.0 + travel_radius * 0.25)
	spawn_electric_ground_ring(parent, world_pos, maxf(travel_radius * 0.35, 14.0))
	spawn_lightning_hit_spark(parent, world_pos)


static func spawn_heavy_magic_shake(intensity: float = 3.0, duration: float = 0.12) -> void:
	_CameraShake.shake_active_scene(intensity, duration)


static func _spawn_lightning_zap(parent: Node, world_pos: Vector2, height: float) -> void:
	if not _Budget.allow_lightning_zap():
		return
	var zap: LightningZapFx = LightningZapFx.new()
	zap.setup_vertical_strike(world_pos, height)
	_Spawn.add_child_at_world(parent, zap, world_pos)


static func _spawn_burst(scene: PackedScene, parent: Node, world_pos: Vector2) -> void:
	if parent == null or scene == null or not _Budget.allow_burst():
		return
	var particles: VfxParticles = scene.instantiate() as VfxParticles
	if particles == null:
		return
	_Spawn.add_child_at_world(parent, particles, world_pos)
	particles.play_burst_at(world_pos)


static func _trail_scene_for(preset: StringName) -> PackedScene:
	match preset:
		TRAIL_PRESET_SOUL:
			return _Registry.SOUL_TRAIL
		TRAIL_PRESET_ICE:
			return _Registry.ICE_TRAIL
		TRAIL_PRESET_LIGHTNING:
			return _Registry.LIGHTNING_TRAIL
		TRAIL_PRESET_ENEMY:
			return _Registry.ENEMY_TRAIL
		_:
			return _Registry.FIRE_TRAIL


static func _scene_for_preset(preset: StringName) -> PackedScene:
	if preset == ElementalVfxConfig.PRESET_SIGHT_WISP:
		return _Registry.SIGHT_WISP
	return null
