## Curvas de combate del Swordman (niveles 1–5).
class_name SwordmanScaling
extends RefCounted

const MAX_LEVEL: int = 5

const MAGNUM_COOLDOWN: float = 3.5
const MAGNUM_KNOCKBACK: float = 150.0
const MAGNUM_FIRE_BUFF: float = 0.15
const MAGNUM_FIRE_BUFF_SEC: float = 2.0

const MOVING_RECOVERY_INTERVAL: float = 4.0
const MOVING_RECOVERY_MISSING_RATIO: float = 0.02

const INCREASE_HP_PER_LEVEL: float = 0.05
const INCREASE_FOOD_HEAL_PER_LEVEL: float = 0.25

const SPEAR_STAB_COOLDOWN: float = 2.5
const BERSERK_HP_VISUAL_THRESHOLD: float = 0.40
## Daño extra por cada 1% de HP faltante (nivel 1–5): 0.5%, 1%, 1.5%, 2%, 2.5%.
const BERSERK_BONUS_PER_MISSING_PERCENT: Array[float] = [0.005, 0.01, 0.015, 0.02, 0.025]
const SPEAR_STAB_DAMAGE_MULT: float = 1.5
const SPEAR_STAB_KNOCKBACK: float = 220.0

const ENDURE_COOLDOWN: float = 8.0
const ENDURE_DEFENSE_BONUS: float = 0.30
const ENDURE_DURATION: float = 4.0

const BOWLING_BASH_COOLDOWN: float = 5.0


static func clamp_level(level: int) -> int:
	return clampi(level, 1, MAX_LEVEL)


static func _lv(level: int) -> int:
	return clamp_level(level)


# --- Bash (básico automático) ---
static func get_bash_burst_interval(level: int) -> float:
	return maxf(2.0 - float(_lv(level) - 1) * 0.28, 0.88)


static func get_bash_damage_mult(level: int) -> float:
	return 1.0 + float(_lv(level) - 1) * 0.12


static func get_bash_radius(level: int) -> float:
	return 48.0 + float(_lv(level) - 1) * 10.0


static func get_bash_arc_angle(level: int) -> float:
	return 60.0 + float(_lv(level) - 1) * 10.0


static func get_bash_stun_chance(level: int) -> float:
	return 0.15 if _lv(level) >= 5 else 0.0


static func get_bash_stun_duration() -> float:
	return 1.0


# --- Magnum Break (autónoma) ---
static func get_magnum_radius(level: int) -> float:
	return 72.0 + float(_lv(level) - 1) * 8.0


static func get_magnum_damage_mult(level: int) -> float:
	return 1.0 + float(_lv(level) - 1) * 0.10


static func get_magnum_cooldown() -> float:
	return MAGNUM_COOLDOWN


static func get_magnum_knockback(_level: int = 1) -> float:
	return MAGNUM_KNOCKBACK


static func get_magnum_fire_buff(_level: int = 1) -> float:
	return MAGNUM_FIRE_BUFF


static func get_magnum_fire_buff_duration() -> float:
	return MAGNUM_FIRE_BUFF_SEC


# --- Moving Recovery ---
static func get_moving_recovery_interval(_level: int = 1) -> float:
	return MOVING_RECOVERY_INTERVAL


static func get_moving_recovery_missing_ratio(_level: int = 1) -> float:
	return MOVING_RECOVERY_MISSING_RATIO


# --- Increase HP Recovery ---
static func get_max_hp_bonus_per_level(_level: int = 1) -> float:
	return INCREASE_HP_PER_LEVEL


static func get_food_heal_bonus_per_level(level: int) -> float:
	return INCREASE_FOOD_HEAL_PER_LEVEL * float(clampi(level, 0, MAX_LEVEL))


# --- Auto Berserk (pasiva) ---
## Porcentaje de HP faltante en escala 0.0–1.0.
static func get_missing_hp_ratio(current_hp: int, max_hp: int) -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(1.0 - float(current_hp) / float(max_hp), 0.0, 1.0)


## Bonus por punto de HP faltante (ej. Nv.1 → 0.005 = +0.5% daño por cada 1% faltante).
static func get_auto_berserk_factor_per_missing_percent(level: int) -> float:
	var idx: int = clampi(_lv(level) - 1, 0, BERSERK_BONUS_PER_MISSING_PERCENT.size() - 1)
	return BERSERK_BONUS_PER_MISSING_PERCENT[idx]


## Multiplicador total: 1.0 + (missing% × factor). A 0 HP y Nv.5 → ×3.5 (+250%).
static func get_auto_berserk_damage_multiplier(level: int, missing_hp_ratio: float) -> float:
	if level <= 0:
		return 1.0
	var missing_percent: float = clampf(missing_hp_ratio, 0.0, 1.0) * 100.0
	var factor: float = get_auto_berserk_factor_per_missing_percent(level)
	var extra: float = missing_percent * factor
	return 1.0 + extra


static func get_auto_berserk_visual_hp_threshold() -> float:
	return BERSERK_HP_VISUAL_THRESHOLD


# --- Spear Stab ---
static func get_spear_stab_cooldown(_level: int = 1) -> float:
	return SPEAR_STAB_COOLDOWN


static func get_spear_stab_width(level: int) -> float:
	return 56.0 + float(_lv(level) - 1) * 8.0


static func get_spear_stab_length(level: int) -> float:
	return 88.0 + float(_lv(level) - 1) * 10.0


static func get_spear_stab_damage_mult(_level: int = 1) -> float:
	return SPEAR_STAB_DAMAGE_MULT


static func get_spear_stab_knockback(_level: int = 1) -> float:
	return SPEAR_STAB_KNOCKBACK


# --- Endure (activa) ---
static func get_endure_cooldown(_level: int = 1) -> float:
	return ENDURE_COOLDOWN


static func get_endure_defense_bonus(_level: int = 1) -> float:
	return ENDURE_DEFENSE_BONUS


static func get_endure_duration(_level: int = 1) -> float:
	return ENDURE_DURATION


# --- Bowling Bash (activa) ---
static func get_bowling_bash_cooldown(_level: int = 1) -> float:
	return BOWLING_BASH_COOLDOWN


static func get_bowling_bash_width(level: int) -> float:
	return 72.0 + float(_lv(level) - 1) * 10.0


static func get_bowling_bash_length(level: int) -> float:
	return 96.0 + float(_lv(level) - 1) * 12.0


static func get_bowling_bash_damage_mult(level: int) -> float:
	return 1.15 + float(_lv(level) - 1) * 0.10


static func get_bowling_bash_knockback(_level: int = 1) -> float:
	return 260.0
