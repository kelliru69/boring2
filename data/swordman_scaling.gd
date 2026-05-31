## Curvas de combate del Swordman (niveles 1–5).
class_name SwordmanScaling
extends RefCounted

const MAX_LEVEL: int = 5


static func clamp_level(level: int) -> int:
	return clampi(level, 1, MAX_LEVEL)


# --- Bash (básico automático hacia adelante) ---
static func get_bash_burst_interval(level: int) -> float:
	match clamp_level(level):
		2:
			return 1.0
		3:
			return 2.0
		4:
			return 1.0
		5:
			return 1.4
		_:
			return 2.0


static func get_bash_hit_count(level: int) -> int:
	match clamp_level(level):
		3, 4:
			return 2
		5:
			return 3
		_:
			return 1


static func get_bash_damage_mult(level: int) -> float:
	return 1.0 + float(clamp_level(level) - 1) * 0.1


static func get_bash_radius(level: int) -> float:
	return 48.0 + float(clamp_level(level) - 1) * 8.0


static func get_bash_arc_angle(level: int) -> float:
	return 65.0 + float(clamp_level(level) - 1) * 8.0


static func get_bash_stun_chance(level: int) -> float:
	return 0.35 if clamp_level(level) >= 4 else 0.15 if clamp_level(level) >= 2 else 0.0


# --- HP Recovery (regen automático) ---
static func get_hp_recovery_interval(level: int) -> float:
	return maxf(2.2 - float(clamp_level(level)) * 0.22, 0.9)


static func get_hp_recovery_amount(level: int) -> int:
	return 1 + int(float(clamp_level(level)) / 2.0)


# --- Sword Mastery (daño pasivo %) ---
static func get_sword_mastery_attack_bonus(level: int) -> float:
	return float(clamp_level(level)) * 0.05


# --- Endure (mitigación automática al recibir golpe) ---
static func get_endure_damage_reduction(level: int) -> float:
	return 0.12 + float(clamp_level(level) - 1) * 0.06


static func get_endure_duration(level: int) -> float:
	return 2.0 + float(clamp_level(level) - 1) * 0.5


# --- Magnum Break (activa manual) ---
static func get_magnum_radius(level: int) -> float:
	return 80.0 + float(clamp_level(level) - 1) * 14.0


static func get_magnum_damage_mult(level: int) -> float:
	return 1.0 + float(clamp_level(level) - 1) * 0.14


static func get_magnum_knockback(level: int) -> float:
	return 180.0 + float(clamp_level(level) - 1) * 25.0


static func get_magnum_fire_buff(level: int) -> float:
	return 0.08 * float(clamp_level(level))


static func get_magnum_cooldown() -> float:
	return 5.0


# --- Provoke (activa manual, debuff área) ---
static func get_provoke_radius(level: int) -> float:
	return 100.0 + float(clamp_level(level) - 1) * 18.0


static func get_provoke_slow_ratio(level: int) -> float:
	return 0.35 + float(clamp_level(level) - 1) * 0.05


static func get_provoke_defense_shred(level: int) -> float:
	return 0.08 * float(clamp_level(level))


static func get_provoke_duration(level: int) -> float:
	return 2.0 + float(clamp_level(level) - 1) * 0.4


static func get_provoke_cooldown() -> float:
	return 6.0
