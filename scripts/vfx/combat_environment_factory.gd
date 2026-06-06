## Entorno de combate — tonemapping ACES sin glow (evita pantalla blanca por bloom).
extends RefCounted
class_name CombatEnvironmentFactory

const ENV_RESOURCE_PATH: String = "res://resources/vfx/combat_environment.tres"


static func build_environment() -> Environment:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_KEEP
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.0
	env.glow_enabled = false
	env.glow_intensity = 0.0
	env.glow_bloom = 0.0
	return env


static func apply_to(world_environment: WorldEnvironment, _map_id: String = "") -> void:
	if world_environment == null:
		return
	var env: Environment = null
	if ResourceLoader.exists(ENV_RESOURCE_PATH):
		env = load(ENV_RESOURCE_PATH) as Environment
	if env == null:
		env = build_environment()
	else:
		env.glow_enabled = false
		env.glow_intensity = 0.0
		env.glow_bloom = 0.0
	world_environment.environment = env
