## Curvas de combate del Mage (niveles 1–5). Cada nivel mejora daño, alcance o cadencia sin retrocesos.
class_name MageSkillScaling
extends RefCounted

const MAX_LEVEL: int = 5


static func clamp_level(level: int) -> int:
	return clampi(level, 1, MAX_LEVEL)


static func _lv(level: int) -> int:
	return clamp_level(level)


# --- Soul Strike (auto, hacia cursor) ---
static func get_soul_strike_spirit_count(level: int) -> int:
	return _lv(level)


static func get_soul_strike_burst_interval(level: int) -> float:
	if _lv(level) >= 5:
		return 1.5
	return 2.0


static func get_soul_strike_stagger(level: int) -> float:
	return 0.12 if get_soul_strike_spirit_count(level) > 1 else 0.0


static func get_soul_strike_damage_mult(level: int) -> float:
	return 0.55 + float(_lv(level) - 1) * 0.07


# --- Sight (orbital) ---
const SIGHT_DAMAGE_SCALE: float = 2.0

static func get_sight_hit_radius(level: int) -> float:
	return 26.0 + float(_lv(level) - 1) * 6.5


static func get_sight_damage_mult(level: int) -> float:
	return SIGHT_DAMAGE_SCALE * (1.0 + float(_lv(level) - 1) * 0.12)


static func get_sight_knockback_force(level: int) -> float:
	if _lv(level) >= 4:
		return 80.0 + float(_lv(level) - 4) * 40.0
	return 0.0


static func get_sight_orb_count(level: int) -> int:
	return 2 if _lv(level) >= 5 else 1


static func get_sight_secondary_radius(level: int) -> float:
	if _lv(level) >= 5:
		return get_sight_hit_radius(level)
	return 0.0


static func get_sight_orbit_radius(level: int) -> float:
	return 52.0 + float(_lv(level) - 1) * 9.0


static func get_sight_orbit_speed(level: int) -> float:
	return 2.8 + float(_lv(level) - 1) * 0.42


# --- Cold Bolt (auto 2s) ---
static func get_cold_bolt_hit_count(level: int) -> int:
	match _lv(level):
		2, 3:
			return 2
		4, 5:
			return 3
		_:
			return 1


static func get_cold_bolt_slow_ratio(level: int) -> float:
	return minf(0.2 + float(_lv(level) - 1) * 0.075, 0.5)


static func get_cold_bolt_damage_mult(level: int) -> float:
	return 1.0 + float(_lv(level) - 1) * 0.1


static func get_cold_bolt_interval() -> float:
	return 2.0


# --- Fire Bolt (auto 2s) ---
static func get_fire_bolt_hit_count(level: int) -> int:
	match _lv(level):
		2, 3:
			return 2
		4, 5:
			return 3
		_:
			return 1


static func get_fire_bolt_damage_mult(level: int) -> float:
	return 1.0 + float(_lv(level) - 1) * 0.1


static func get_fire_bolt_interval() -> float:
	return 2.0


static func get_fire_bolt_stagger() -> float:
	return 0.08


# --- Fire Wall (auto 3.5s) ---
static func get_firewall_interval() -> float:
	return 3.5


static func get_firewall_barrier_count(level: int) -> int:
	return 2 if _lv(level) >= 5 else 1


static func get_firewall_offset_distance(level: int) -> float:
	return 72.0 + float(_lv(level) - 1) * 8.0


## Tiles verticales (1 en nv.1 → 5 en nv.5), siempre alineados al eje Y del mapa.
static func get_firewall_tile_count(level: int) -> int:
	return clampi(_lv(level), 1, 5)


static func get_firewall_line_length_px(level: int, tile_px: float) -> float:
	return float(get_firewall_tile_count(level)) * maxf(tile_px, 1.0)


static func get_firewall_radius(level: int) -> float:
	# Compatibilidad (p. ej. Meteor Storm): radio aprox. de la línea al máximo nivel.
	return get_firewall_line_length_px(level, 32.0) * 0.5


static func get_firewall_damage_mult(level: int) -> float:
	return (1.0 + float(_lv(level) - 1) * 0.1) * 1.2


static func snap_wall_anchor(anchor: Vector2, tile_px: float) -> Vector2:
	var px: float = maxf(tile_px, 1.0)
	return Vector2(
		floor(anchor.x / px) * px + px * 0.5,
		floor(anchor.y / px) * px + px * 0.5
	)


static func get_firewall_knockback(level: int) -> float:
	if _lv(level) < 2:
		return 0.0
	return 120.0 + float(_lv(level) - 1) * 20.0


static func get_firewall_duration() -> float:
	return 3.0


# --- Lightning Bolt (auto 2.2s) ---
static func get_lightning_travel_distance(level: int) -> float:
	return 140.0 + float(_lv(level) - 1) * 55.0


static func get_lightning_projectile_count(level: int) -> int:
	match _lv(level):
		3, 4:
			return 2
		5:
			return 3
		_:
			return 1


static func get_lightning_damage_mult(level: int) -> float:
	return 0.6 + float(_lv(level) - 1) * 0.1


static func get_lightning_interval() -> float:
	return 2.2


static func get_lightning_angle_spread(count: int) -> float:
	if count <= 1:
		return 0.0
	return PI * 0.35


# --- Frost Diver (activa) ---
static func get_frost_dive_radius(level: int) -> float:
	return 48.0 + float(_lv(level) - 1) * 10.0


static func get_frost_dive_stun_duration(level: int) -> float:
	if _lv(level) >= 5:
		return 2.0
	return 1.0 + float(_lv(level) - 1) * 0.25


static func get_frost_dive_line_length(level: int) -> float:
	if _lv(level) < 3:
		return 0.0
	return 110.0 + float(_lv(level) - 3) * 30.0


static func get_frost_dive_damage_mult(level: int) -> float:
	return 1.0 + float(_lv(level) - 1) * 0.12


static func get_frost_dive_cooldown() -> float:
	return 5.0


# --- Thunder Storm (activa) ---
static func get_thunderstorm_radius(level: int) -> float:
	return 68.0 + float(_lv(level) - 1) * 15.0


static func get_thunderstorm_damage_mult(level: int) -> float:
	return 1.0 + float(_lv(level) - 1) * 0.12


static func get_thunderstorm_duration(level: int) -> float:
	return 2.0 + float(_lv(level) - 1) * 0.2


static func get_thunderstorm_pulse_interval(level: int) -> float:
	return maxf(0.55 - float(_lv(level) - 1) * 0.04, 0.38)


static func get_thunderstorm_knockback(level: int) -> float:
	return 100.0 + float(_lv(level) - 1) * 15.0


static func get_thunderstorm_cast_delay(level: int = 1) -> float:
	return maxf(1.0 - float(_lv(level) - 1) * 0.05, 0.8)


static func get_thunderstorm_cooldown(level: int = 1) -> float:
	return maxf(6.0 - float(_lv(level) - 1) * 0.35, 4.5)
