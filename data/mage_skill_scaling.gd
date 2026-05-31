## Curvas de combate del Mage (niveles 1–5). Fuente única para timers y daño.
class_name MageSkillScaling
extends RefCounted

const MAX_LEVEL: int = 5


static func clamp_level(level: int) -> int:
	return clampi(level, 1, MAX_LEVEL)


# --- Soul Strike (mouse): espíritus por ráfaga + intervalo entre ráfagas ---
static func get_soul_strike_spirit_count(level: int) -> int:
	return clamp_level(level)


static func get_soul_strike_burst_interval(level: int) -> float:
	if clamp_level(level) >= 5:
		return 1.5
	return 2.0


static func get_soul_strike_stagger(level: int) -> float:
	return 0.12 if get_soul_strike_spirit_count(level) > 1 else 0.0


static func get_soul_strike_damage_mult(level: int) -> float:
	return 0.55 + float(clamp_level(level) - 1) * 0.06


# --- Sight (orbital siempre activo) ---
static func get_sight_hit_radius(level: int) -> float:
	match clamp_level(level):
		2:
			return 38.0
		3, 4, 5:
			return 52.0
		_:
			return 26.0


static func get_sight_damage_mult(level: int) -> float:
	match clamp_level(level):
		2:
			return 1.15
		3:
			return 1.35
		4, 5:
			return 1.5
		_:
			return 1.0


static func get_sight_knockback_force(level: int) -> float:
	return 120.0 if clamp_level(level) >= 4 else 0.0


static func get_sight_orb_count(level: int) -> int:
	return 2 if clamp_level(level) >= 5 else 1


static func get_sight_secondary_radius(level: int) -> float:
	return 26.0 if clamp_level(level) >= 5 else 0.0


# --- Cold Bolt (auto 2s, enemigo al azar) ---
static func get_cold_bolt_hit_count(level: int) -> int:
	match clamp_level(level):
		3, 4:
			return 2
		5:
			return 3
		_:
			return 1


static func get_cold_bolt_slow_ratio(level: int) -> float:
	match clamp_level(level):
		2, 4, 5:
			return 0.5
		_:
			return 0.2


static func get_cold_bolt_damage_mult(level: int) -> float:
	match clamp_level(level):
		2, 4, 5:
			return 1.25
		_:
			return 1.0


static func get_cold_bolt_interval() -> float:
	return 2.0


# --- Fire Bolt (auto 2s, más cercano) ---
static func get_fire_bolt_hit_count(level: int) -> int:
	match clamp_level(level):
		3, 4:
			return 2
		5:
			return 3
		_:
			return 1


static func get_fire_bolt_damage_mult(level: int) -> float:
	match clamp_level(level):
		2, 4, 5:
			return 1.2
		_:
			return 1.0


static func get_fire_bolt_interval() -> float:
	return 2.0


static func get_fire_bolt_stagger() -> float:
	return 0.08


# --- Fire Wall (autónoma, barreras 3s) ---
static func get_firewall_interval() -> float:
	return 3.5


static func get_firewall_barrier_count(level: int) -> int:
	return 2 if clamp_level(level) >= 5 else 1


static func get_firewall_offset_distance(level: int) -> float:
	return 72.0 + float(clamp_level(level) - 1) * 6.0


static func get_firewall_radius(level: int) -> float:
	match clamp_level(level):
		4, 5:
			return 56.0
		_:
			return 40.0


static func get_firewall_damage_mult(level: int) -> float:
	match clamp_level(level):
		3, 4, 5:
			return 1.2 + float(clamp_level(level) - 3) * 0.08
		_:
			return 1.0


static func get_firewall_knockback(level: int) -> float:
	return 160.0 if clamp_level(level) >= 2 else 0.0


static func get_firewall_duration() -> float:
	return 3.0


# --- Lightning Bolt (boomerang) ---
static func get_lightning_travel_distance(level: int) -> float:
	match clamp_level(level):
		2:
			return 220.0
		4, 5:
			return 360.0
		_:
			return 140.0


static func get_lightning_projectile_count(level: int) -> int:
	match clamp_level(level):
		3:
			return 2
		5:
			return 3
		_:
			return 1


static func get_lightning_damage_mult(level: int) -> float:
	var mult: float = 1.0 if clamp_level(level) < 5 else 1.25
	return mult * 0.5


static func get_lightning_interval() -> float:
	return 2.2


static func get_lightning_angle_spread(count: int) -> float:
	if count <= 1:
		return 0.0
	return PI * 0.35


# --- Frost Diver (activa manual) ---
static func get_frost_dive_radius(level: int) -> float:
	return 48.0 + float(clamp_level(level) - 1) * 10.0


static func get_frost_dive_stun_duration(level: int) -> float:
	return 2.0 if clamp_level(level) >= 5 else 1.0


static func get_frost_dive_line_length(level: int) -> float:
	return 0.0 if clamp_level(level) < 3 else 120.0 + float(clamp_level(level) - 3) * 25.0


static func get_frost_dive_damage_mult(level: int) -> float:
	return 1.0 + float(clamp_level(level) - 1) * 0.12


static func get_frost_dive_cooldown() -> float:
	return 5.0


# --- Thunder Storm (activa manual, 1s cast) ---
static func get_thunderstorm_radius(level: int) -> float:
	match clamp_level(level):
		2:
			return 88.0
		4:
			return 120.0
		5:
			return 150.0
		_:
			return 64.0


static func get_thunderstorm_damage_mult(level: int) -> float:
	match clamp_level(level):
		3:
			return 1.15 * 1.2
		4, 5:
			return 1.35 * 1.2
		_:
			return 1.2


static func get_thunderstorm_duration() -> float:
	return 2.25


static func get_thunderstorm_pulse_interval() -> float:
	return 0.5


static func get_thunderstorm_cast_delay() -> float:
	return 1.0


static func get_thunderstorm_cooldown() -> float:
	return 6.0
