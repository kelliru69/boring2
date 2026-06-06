## Materiales de partículas (código). Las escenas en `scenes/vfx/particles/` los aplican en _ready.
extends RefCounted
class_name ElementalVfxConfig

const BASE_ALPHA_SCALE: float = 1.0
const MAGE_PARTICLE_SIZE_SCALE: float = 0.5
const MAGE_PARTICLE_SATURATION: float = 0.5

const PRESET_ICE_SHATTER: StringName = &"ice_shatter"
const PRESET_FIRE_IMPACT: StringName = &"fire_impact"
const PRESET_ELECTRIC_RING: StringName = &"electric_ring"
const PRESET_SOUL_TRAIL: StringName = &"soul_trail"
const PRESET_SOUL_IMPACT: StringName = &"soul_impact"
const PRESET_FIRE_TRAIL: StringName = &"fire_trail"
const PRESET_ICE_TRAIL: StringName = &"ice_trail"
const PRESET_LIGHTNING_TRAIL: StringName = &"lightning_trail"
const PRESET_ENEMY_TRAIL: StringName = &"enemy_trail"
const PRESET_FIREWALL_SMOKE: StringName = &"firewall_smoke"
const PRESET_SIGHT_WISP: StringName = &"sight_wisp"
const PRESET_LIGHTNING_SPARK: StringName = &"lightning_spark"
const PRESET_FROST_SHATTER: StringName = &"frost_shatter"
const PRESET_ENEMY_HIT: StringName = &"enemy_hit"


static func apply_preset(particles: GPUParticles2D, preset: StringName, extra: float = 0.0) -> void:
	if particles == null:
		return
	if particles.process_material == null:
		particles.process_material = ParticleProcessMaterial.new()
	match preset:
		PRESET_ICE_SHATTER:
			apply_ice_shatter(particles)
		PRESET_FIRE_IMPACT:
			apply_fire_sparks_burst(particles)
		PRESET_ELECTRIC_RING:
			apply_electric_ring(particles, extra if extra > 0.0 else 18.0)
		PRESET_SOUL_TRAIL:
			apply_soul_trail(particles)
		PRESET_SOUL_IMPACT:
			apply_soul_impact_burst(particles)
		PRESET_FIRE_TRAIL:
			apply_fire_trail(particles)
		PRESET_ICE_TRAIL:
			apply_ice_trail(particles)
		PRESET_LIGHTNING_TRAIL:
			apply_lightning_trail(particles)
		PRESET_ENEMY_TRAIL:
			apply_enemy_trail(particles)
		PRESET_FIREWALL_SMOKE:
			apply_firewall_smoke(particles, extra if extra > 0.0 else 40.0)
		PRESET_SIGHT_WISP:
			apply_sight_wisp(particles)
		PRESET_LIGHTNING_SPARK:
			apply_lightning_spark_burst(particles)
		PRESET_FROST_SHATTER:
			apply_frost_shatter(particles)
		PRESET_ENEMY_HIT:
			apply_enemy_hit_spark(particles)
		_:
			pass
	apply_soft_particle_texture(particles)
	if preset == PRESET_LIGHTNING_SPARK:
		particles.texture = VfxTextureFactory.get_soft_radial(VfxTextureFactory.RadialProfile.SPARK_STREAK)
	elif preset == PRESET_FROST_SHATTER:
		particles.texture = VfxTextureFactory.get_soft_radial(VfxTextureFactory.RadialProfile.ICE_SHARD)
	if _is_burst_preset(preset):
		_configure_burst_safe(particles)


static func scale_alpha(color: Color, alpha_scale: float = BASE_ALPHA_SCALE) -> Color:
	var scaled: Color = color
	scaled.a = clampf(color.a * alpha_scale, 0.0, 1.0)
	return scaled


static func _mage_size(value: float) -> float:
	return value * MAGE_PARTICLE_SIZE_SCALE


static func _mage_color(color: Color) -> Color:
	return CombatVfxPalette.desaturate(color, MAGE_PARTICLE_SATURATION)


static func apply_trail_blend(p: GPUParticles2D) -> void:
	apply_additive_blend(p)


static func apply_impact_blend(p: GPUParticles2D) -> void:
	apply_additive_blend(p)


static func apply_massive_blend(p: GPUParticles2D) -> void:
	apply_additive_blend(p)


static func apply_additive_blend(p: GPUParticles2D) -> void:
	CombatVfxPalette.apply_soft_blend(p)


static func apply_soft_particle_texture(p: GPUParticles2D) -> void:
	if p == null:
		return
	p.texture = VfxTextureFactory.get_soft_radial(VfxTextureFactory.RadialProfile.PARTICLE)
	VfxTextureFactory.apply_linear_filter(p)


static func apply_soul_trail(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 28.0
	mat.initial_velocity_min = 8.0
	mat.initial_velocity_max = 28.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 40.0
	mat.damping_max = 80.0
	mat.scale_min = _mage_size(0.58)
	mat.scale_max = _mage_size(1.38)
	mat.scale_curve = curve_shrink_to_zero()
	mat.color = _mage_color(Color(0.72, 0.32, 0.98, 0.88))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(0.88, 0.48, 1.0, 0.92)],
		[0.5, Color(0.62, 0.22, 0.95, 0.62)],
		[1.0, Color(0.42, 0.12, 0.78, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_trail_blend(p)


static func apply_fire_trail(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 35.0
	mat.initial_velocity_min = 12.0
	mat.initial_velocity_max = 45.0
	mat.gravity = Vector3(0.0, -40.0, 0.0)
	mat.damping_min = 20.0
	mat.damping_max = 50.0
	mat.scale_min = _mage_size(0.55)
	mat.scale_max = _mage_size(1.32)
	mat.scale_curve = curve_shrink_to_zero()
	mat.color = _mage_color(Color(1.0, 0.52, 0.12, 0.92))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(1.0, 0.62, 0.18, 0.95)],
		[0.4, Color(1.0, 0.48, 0.08, 0.78)],
		[1.0, Color(0.85, 0.28, 0.04, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_trail_blend(p)


static func apply_ice_trail(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(0.0, 0.0, 0.0)
	mat.spread = 40.0
	mat.initial_velocity_min = 6.0
	mat.initial_velocity_max = 22.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 30.0
	mat.damping_max = 60.0
	mat.scale_min = _mage_size(0.48)
	mat.scale_max = _mage_size(1.15)
	mat.scale_curve = curve_shrink_to_zero()
	mat.color = _mage_color(Color(0.48, 0.9, 1.0, 0.9))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(0.62, 0.96, 1.0, 0.92)],
		[0.35, Color(0.38, 0.82, 0.98, 0.78)],
		[1.0, Color(0.22, 0.65, 0.92, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_trail_blend(p)


static func apply_lightning_trail(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(0.0, 0.0, 0.0)
	mat.spread = 55.0
	mat.initial_velocity_min = 15.0
	mat.initial_velocity_max = 55.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 25.0
	mat.damping_max = 70.0
	mat.scale_min = _mage_size(0.42)
	mat.scale_max = _mage_size(1.05)
	mat.color = _mage_color(Color(1.0, 0.92, 0.45, 0.9))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(1.0, 0.96, 0.55, 0.92)],
		[1.0, Color(0.85, 0.78, 0.28, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_trail_blend(p)


static func apply_ice_shatter(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 5.0
	mat.direction = Vector3(0.0, 0.0, 0.0)
	mat.spread = 180.0
	mat.initial_velocity_min = 90.0
	mat.initial_velocity_max = 220.0
	mat.gravity = Vector3(0.0, 80.0, 0.0)
	mat.damping_min = 180.0
	mat.damping_max = 320.0
	mat.angular_velocity_min = -14.0
	mat.angular_velocity_max = 14.0
	mat.scale_min = _mage_size(0.16)
	mat.scale_max = _mage_size(0.98)
	mat.scale_curve = curve_burst_pop()
	mat.color = _mage_color(Color(0.5, 0.9, 1.0, 0.9))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(0.65, 0.96, 1.0, 0.9)],
		[0.35, Color(0.4, 0.82, 0.98, 0.72)],
		[1.0, Color(0.22, 0.62, 0.9, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_impact_blend(p)


static func apply_frost_shatter(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 10.0
	mat.direction = Vector3(0.0, -0.2, 0.0)
	mat.spread = 180.0
	mat.initial_velocity_min = 140.0
	mat.initial_velocity_max = 320.0
	mat.gravity = Vector3(0.0, 40.0, 0.0)
	mat.damping_min = 120.0
	mat.damping_max = 260.0
	mat.angular_velocity_min = -22.0
	mat.angular_velocity_max = 22.0
	mat.orbit_velocity_min = -0.4
	mat.orbit_velocity_max = 0.4
	mat.scale_min = _mage_size(0.14)
	mat.scale_max = _mage_size(0.88)
	mat.scale_curve = curve_burst_pop()
	mat.color = _mage_color(Color(0.52, 0.9, 1.0, 0.9))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(0.68, 0.96, 1.0, 0.88)],
		[0.2, Color(0.45, 0.84, 0.98, 0.78)],
		[0.55, Color(0.32, 0.72, 0.92, 0.45)],
		[1.0, Color(0.22, 0.58, 0.88, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_impact_blend(p)


static func apply_fire_sparks_burst(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 10.0
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 75.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 140.0
	mat.gravity = Vector3(0.0, -60.0, 0.0)
	mat.damping_min = 35.0
	mat.damping_max = 90.0
	mat.scale_min = _mage_size(0.18)
	mat.scale_max = _mage_size(1.05)
	mat.scale_curve = curve_burst_pop()
	mat.color = _mage_color(Color(1.0, 0.55, 0.14, 0.92))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(1.0, 0.62, 0.2, 0.9)],
		[0.35, Color(1.0, 0.48, 0.1, 0.72)],
		[0.7, Color(0.92, 0.35, 0.06, 0.38)],
		[1.0, Color(0.72, 0.25, 0.04, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_impact_blend(p)


static func apply_firewall_smoke(p: GPUParticles2D, radius: float) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = radius * 0.55
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 28.0
	mat.initial_velocity_min = 18.0
	mat.initial_velocity_max = 55.0
	mat.gravity = Vector3(0.0, -35.0, 0.0)
	mat.damping_min = 15.0
	mat.damping_max = 40.0
	mat.scale_min = 0.35
	mat.scale_max = 1.1
	mat.scale_curve = curve_dissolve()
	mat.color = Color(1.0, 0.62, 0.14, 0.78)
	mat.color_ramp = gradient_ramp([
		[0.0, Color(1.0, 0.88, 0.35, 0.9)],
		[0.45, Color(1.0, 0.58, 0.1, 0.55)],
		[1.0, Color(0.35, 0.22, 0.08, 0.0)],
	])
	apply_massive_blend(p)


static func apply_electric_ring(p: GPUParticles2D, outward_bias: float = 18.0) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_radius = 4.0
	mat.emission_ring_inner_radius = 2.0
	mat.emission_ring_height = 1.0
	mat.direction = Vector3(1.0, 0.0, 0.0)
	mat.spread = 0.0
	mat.initial_velocity_min = outward_bias
	mat.initial_velocity_max = outward_bias * 2.2
	mat.gravity = Vector3.ZERO
	mat.damping_min = 60.0
	mat.damping_max = 120.0
	mat.scale_min = _mage_size(0.28)
	mat.scale_max = _mage_size(0.82)
	mat.scale_curve = curve_shrink_to_zero()
	mat.color = _mage_color(Color(1.0, 0.92, 0.42, 0.88))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(1.0, 0.96, 0.55, 0.88)],
		[0.6, Color(0.92, 0.82, 0.32, 0.48)],
		[1.0, Color(0.78, 0.68, 0.22, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_massive_blend(p)


static func apply_enemy_hit_spark(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 4.0
	mat.spread = 180.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 90.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 80.0
	mat.damping_max = 140.0
	mat.scale_min = 0.15
	mat.scale_max = 0.4
	mat.scale_curve = curve_shrink_to_zero()
	mat.color = Color(1.0, 1.0, 1.0, 1.0)
	mat.color_ramp = gradient_ramp([
		[0.0, Color(1.1, 1.1, 1.1, 0.95)],
		[1.0, Color(0.85, 0.85, 0.9, 0.0)],
	])
	apply_impact_blend(p)


static func apply_soul_impact_burst(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 8.0
	mat.spread = 180.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 200.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 90.0
	mat.damping_max = 160.0
	mat.scale_min = _mage_size(0.16)
	mat.scale_max = _mage_size(0.95)
	mat.scale_curve = curve_burst_pop()
	mat.color = _mage_color(Color(0.82, 0.42, 1.0, 0.92))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(0.92, 0.55, 1.0, 0.9)],
		[0.4, Color(0.65, 0.28, 0.95, 0.68)],
		[1.0, Color(0.42, 0.12, 0.78, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_impact_blend(p)


static func apply_enemy_trail(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(0.0, 0.0, 0.0)
	mat.spread = 22.0
	mat.initial_velocity_min = 6.0
	mat.initial_velocity_max = 28.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 35.0
	mat.damping_max = 75.0
	mat.scale_min = 0.25
	mat.scale_max = 0.65
	mat.scale_curve = curve_shrink_to_zero()
	mat.color = Color(1.0, 0.15, 0.1, 0.9)
	mat.color_ramp = gradient_ramp([
		[0.0, Color(1.0, 0.35, 0.2, 0.95)],
		[0.5, Color(0.95, 0.08, 0.12, 0.55)],
		[1.0, Color(0.6, 0.02, 0.05, 0.0)],
	])
	apply_trail_blend(p)


static func apply_sight_wisp(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 10.0
	mat.direction = Vector3(0.0, -0.4, 0.0)
	mat.spread = 180.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 18.0
	mat.gravity = Vector3(0.0, -18.0, 0.0)
	mat.damping_min = 8.0
	mat.damping_max = 25.0
	mat.scale_min = _mage_size(0.42)
	mat.scale_max = _mage_size(1.08)
	mat.scale_curve = curve_shrink_to_zero()
	mat.color = _mage_color(Color(0.45, 0.92, 0.4, 0.85))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(0.58, 0.98, 0.48, 0.9)],
		[0.5, Color(0.32, 0.78, 0.34, 0.58)],
		[1.0, Color(0.18, 0.58, 0.22, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_massive_blend(p)


static func apply_lightning_spark_burst(p: GPUParticles2D) -> void:
	var mat: ParticleProcessMaterial = _mat(p)
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(1.0, 0.0, 0.0)
	mat.spread = 180.0
	mat.initial_velocity_min = 180.0
	mat.initial_velocity_max = 420.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 120.0
	mat.damping_max = 220.0
	mat.angular_velocity_min = -18.0
	mat.angular_velocity_max = 18.0
	mat.scale_min = _mage_size(0.18)
	mat.scale_max = _mage_size(1.15)
	mat.scale_curve = curve_burst_pop()
	mat.color = _mage_color(Color(1.0, 0.92, 0.42, 0.9))
	mat.color_ramp = gradient_ramp([
		[0.0, Color(1.0, 0.96, 0.55, 0.88)],
		[0.25, Color(0.95, 0.85, 0.35, 0.72)],
		[1.0, Color(0.82, 0.72, 0.22, 0.0)],
	], BASE_ALPHA_SCALE, MAGE_PARTICLE_SATURATION)
	apply_impact_blend(p)


static func _is_massive_preset(preset: StringName) -> bool:
	return preset == PRESET_FIREWALL_SMOKE or preset == PRESET_SIGHT_WISP


static func _mat(p: GPUParticles2D) -> ParticleProcessMaterial:
	return p.process_material as ParticleProcessMaterial


static func _is_burst_preset(preset: StringName) -> bool:
	return preset == PRESET_ICE_SHATTER \
		or preset == PRESET_FROST_SHATTER \
		or preset == PRESET_FIRE_IMPACT \
		or preset == PRESET_SOUL_IMPACT \
		or preset == PRESET_LIGHTNING_SPARK \
		or preset == PRESET_ELECTRIC_RING \
		or preset == PRESET_ENEMY_HIT


static func _configure_burst_safe(p: GPUParticles2D) -> void:
	p.preprocess = 0.05
	p.interpolate = true


static func curve_burst_pop() -> CurveTexture:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.06))
	curve.add_point(Vector2(0.1, 0.95))
	curve.add_point(Vector2(0.45, 0.7))
	curve.add_point(Vector2(1.0, 0.0))
	var tex: CurveTexture = CurveTexture.new()
	tex.curve = curve
	return tex


static func curve_shrink_to_zero() -> CurveTexture:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.35, 0.75))
	curve.add_point(Vector2(1.0, 0.0))
	var tex: CurveTexture = CurveTexture.new()
	tex.curve = curve
	return tex


static func curve_dissolve() -> CurveTexture:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.2))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(0.7, 0.55))
	curve.add_point(Vector2(1.0, 0.0))
	var tex: CurveTexture = CurveTexture.new()
	tex.curve = curve
	return tex


static func gradient_ramp(stops: Array, alpha_scale: float = BASE_ALPHA_SCALE, saturation_keep: float = 1.0) -> GradientTexture1D:
	var grad: Gradient = Gradient.new()
	for stop: Variant in stops:
		if stop is Array and stop.size() >= 2:
			var c: Color = stop[1] as Color
			if saturation_keep < 1.0:
				c = CombatVfxPalette.desaturate(c, saturation_keep)
			grad.add_point(float(stop[0]), scale_alpha(c, alpha_scale))
	var tex: GradientTexture1D = GradientTexture1D.new()
	tex.gradient = grad
	return tex


