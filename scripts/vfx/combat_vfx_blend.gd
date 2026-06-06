## Mezcla VFX anti-flashbang: Mix + HDR self-modulate + clamp en shader (sustituye Additive puro).
extends RefCounted
class_name CombatVfxBlend

enum Profile {
	TRAIL,
	IMPACT,
	MASSIVE,
	SPRITE,
	LINE,
}

const PARTICLE_SHADER_PATH: String = "res://shaders/vfx_particle_add.gdshader"
const SPRITE_SHADER_PATH: String = "res://shaders/vfx_hdr_clamp.gdshader"

const CLAMP_TRAIL: float = 0.78
const CLAMP_IMPACT: float = 1.05
const CLAMP_MASSIVE: float = 0.62
const CLAMP_SPRITE: float = 2.05
const CLAMP_LINE: float = 1.9

const HDR_TRAIL: Vector3 = Vector3(1.85, 1.55, 1.25)
const HDR_IMPACT: Vector3 = Vector3(2.05, 1.72, 1.38)
const HDR_MASSIVE: Vector3 = Vector3(1.62, 1.38, 1.15)
const HDR_SPRITE: Vector3 = Vector3(1.82, 1.58, 1.28)
const HDR_LINE: Vector3 = Vector3(1.75, 1.68, 1.55)

static var _sprite_shader: Shader
static var _particle_shader: Shader
static var _material_cache: Dictionary = {}


static func apply_particle_blend(particles: GPUParticles2D, profile: Profile) -> void:
	if particles == null:
		return
	var clamp_max: float = _clamp_for_profile(profile)
	var hdr: Vector3 = _hdr_for_profile(profile)
	particles.material = _get_shader_material(clamp_max, true)
	particles.self_modulate = Color(hdr.x, hdr.y, hdr.z, 1.0)
	VfxTextureFactory.apply_linear_filter(particles)


static func apply_sprite_glow(
	item: CanvasItem,
	profile: Profile = Profile.SPRITE,
	hdr_override: Vector3 = Vector3(-1.0, -1.0, -1.0)
) -> void:
	if item == null:
		return
	var clamp_max: float = _clamp_for_profile(profile)
	var hdr: Vector3 = _hdr_for_profile(profile)
	if hdr_override.x >= 0.0:
		hdr = hdr_override
	item.material = _get_shader_material(clamp_max)
	item.self_modulate = Color(hdr.x, hdr.y, hdr.z, 1.0)


static func apply_line_glow(line: Line2D, profile: Profile = Profile.LINE) -> void:
	if line == null:
		return
	apply_sprite_glow(line, profile)


static func _clamp_for_profile(profile: Profile) -> float:
	match profile:
		Profile.TRAIL:
			return CLAMP_TRAIL
		Profile.IMPACT:
			return CLAMP_IMPACT
		Profile.MASSIVE:
			return CLAMP_MASSIVE
		Profile.LINE:
			return CLAMP_LINE
		_:
			return CLAMP_SPRITE


static func _hdr_for_profile(profile: Profile) -> Vector3:
	match profile:
		Profile.TRAIL:
			return HDR_TRAIL
		Profile.IMPACT:
			return HDR_IMPACT
		Profile.MASSIVE:
			return HDR_MASSIVE
		Profile.LINE:
			return HDR_LINE
		_:
			return HDR_SPRITE


static func _get_shader_material(clamp_max: float, for_particles: bool = false) -> ShaderMaterial:
	var key: String = "%s_%.3f" % ["p" if for_particles else "s", clamp_max]
	if _material_cache.has(key):
		return _material_cache[key] as ShaderMaterial
	var mat: ShaderMaterial = ShaderMaterial.new()
	if for_particles:
		if _particle_shader == null:
			_particle_shader = load(PARTICLE_SHADER_PATH) as Shader
		mat.shader = _particle_shader
	else:
		if _sprite_shader == null:
			_sprite_shader = load(SPRITE_SHADER_PATH) as Shader
		mat.shader = _sprite_shader
	mat.set_shader_parameter(&"max_brightness", clamp_max)
	_material_cache[key] = mat
	return mat
