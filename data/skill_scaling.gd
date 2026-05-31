## Curvas de escalado por nivel de habilidad (1–3).
class_name SkillScaling
extends RefCounted

const MAX_SKILL_LEVEL: int = 3


static func clamp_level(level: int) -> int:
	return clampi(level, 1, MAX_SKILL_LEVEL)


static func get_cold_bolt_burst_count(level: int) -> int:
	return clamp_level(level)


static func get_cold_bolt_cooldown_multiplier(level: int) -> float:
	match clamp_level(level):
		2:
			return 0.88
		3:
			return 0.75
		_:
			return 1.0


static func get_thunderstorm_radius(level: int) -> float:
	return 72.0 + float(clamp_level(level) - 1) * 28.0


static func get_thunderstorm_pulse_damage(level: int, base_damage: int) -> int:
	return base_damage + (clamp_level(level) - 1) * 6


static func get_sight_orb_count(level: int) -> int:
	return 1 if clamp_level(level) < 3 else 2


static func get_sight_orbit_speed(level: int, base_speed: float) -> float:
	return base_speed + float(clamp_level(level) - 1) * 1.2


static func get_sight_tick_damage(level: int, base_damage: int) -> int:
	return base_damage + (clamp_level(level) - 1) * 2
