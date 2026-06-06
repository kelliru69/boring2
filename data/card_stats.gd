## Stats pasivos de cartas equipadas (hasta 5 ranuras).
class_name CardStats
extends RefCounted

const MAX_EQUIPPED: int = 5


static func get_passive_stats(card_id: String) -> Dictionary:
	match card_id:
		"carta_poring":
			return {"max_hp_flat": 15, "defense_pct": 0.02}
		"carta_lunatic":
			return {"attack_pct": 0.04, "move_speed_pct": 0.03}
		"carta_fabre":
			return {"max_hp_pct": 0.06, "defense_pct": 0.04}
		"carta_zombie":
			return {"max_hp_pct": 0.08, "lifesteal_pct": 0.01}
		"carta_skeleton":
			return {"attack_pct": 0.06, "cooldown_pct": -0.03}
		"carta_archer_skeleton":
			return {"attack_pct": 0.12, "cooldown_pct": -0.08}
		"carta_familiar":
			return {"attack_pct": 0.08, "move_speed_pct": 0.08, "cooldown_pct": -0.05}
		"carta_rocker":
			return {"max_hp_pct": 0.14, "defense_pct": 0.08, "attack_pct": 0.10}
		"carta_creamy":
			# Carta "rota": acelera muchísimo la run.
			return {
				"move_speed_pct": 0.30,
				"defense_pct": 0.20,
				"attack_pct": 0.22,
				"cooldown_pct": -0.30,
				"lifesteal_pct": 0.10,
				"max_hp_pct": 0.20
			}
		"carta_moonlight_flower":
			# Carta "ultrarota": pico de poder para recompensar el drop extremadamente raro.
			return {
				"attack_pct": 0.45,
				"max_hp_pct": 0.40,
				"defense_pct": 0.30,
				"move_speed_pct": 0.25,
				"cooldown_pct": -0.45,
				"lifesteal_pct": 0.22,
				"max_hp_flat": 220
			}
		"carta_orc_baby":
			return {"move_speed_pct": 0.08, "xp_gain_pct": 0.05}
		"carta_orc_warrior":
			return {"defense_pct": 0.10, "melee_attack_pct": 0.05}
		"carta_orc_lady":
			return {"move_speed_pct": 0.12, "crit_chance_pct": 0.04}
		"carta_orc_archer":
			return {"attack_range_pct": 0.10, "cooldown_pct": -0.05}
		"carta_high_orc":
			return {"max_hp_pct": 0.15, "projectile_damage_reduction_pct": 0.08}
		"carta_orc_hero":
			return {
				"attack_pct": 0.35,
				"max_hp_pct": 0.15,
				"max_hp_flat": 150,
				"terrain_slow_immunity": 1,
			}
		_:
			return {}


static func get_effect_description(card_id: String) -> String:
	var stats: Dictionary = get_passive_stats(card_id)
	var parts: PackedStringArray = PackedStringArray()
	if stats.get("max_hp_flat", 0) > 0:
		parts.append("+%d HP máximo" % stats.max_hp_flat)
	if float(stats.get("max_hp_pct", 0.0)) > 0.0:
		parts.append("+%d%% HP máximo" % int(float(stats.max_hp_pct) * 100.0))
	if float(stats.get("attack_pct", 0.0)) > 0.0:
		parts.append("+%d%% daño de ataque" % int(float(stats.attack_pct) * 100.0))
	if float(stats.get("defense_pct", 0.0)) > 0.0:
		parts.append("+%d%% defensa" % int(float(stats.defense_pct) * 100.0))
	if float(stats.get("move_speed_pct", 0.0)) > 0.0:
		parts.append("+%d%% velocidad de movimiento" % int(float(stats.move_speed_pct) * 100.0))
	if float(stats.get("cooldown_pct", 0.0)) != 0.0:
		var cd: float = float(stats.cooldown_pct)
		if cd < 0.0:
			parts.append("%d%% cooldown de habilidades" % int(absf(cd) * 100.0))
		else:
			parts.append("+%d%% cooldown de habilidades" % int(cd * 100.0))
	if float(stats.get("lifesteal_pct", 0.0)) > 0.0:
		parts.append("+%d%% robo de vida" % int(float(stats.lifesteal_pct) * 100.0))
	if parts.is_empty():
		return "Sin efectos pasivos conocidos."
	return "Efectos al equipar:\n• " + "\n• ".join(parts)


static func aggregate_equipped(card_ids: Array[String]) -> Dictionary:
	var total: Dictionary = {
		"max_hp_flat": 0,
		"max_hp_pct": 0.0,
		"attack_pct": 0.0,
		"melee_attack_pct": 0.0,
		"defense_pct": 0.0,
		"move_speed_pct": 0.0,
		"cooldown_pct": 0.0,
		"lifesteal_pct": 0.0,
		"crit_chance_pct": 0.0,
		"attack_range_pct": 0.0,
		"projectile_damage_reduction_pct": 0.0,
		"terrain_slow_immunity": 0,
		"xp_gain_pct": 0.0,
	}
	for card_id: String in card_ids:
		if card_id.is_empty():
			continue
		var stats: Dictionary = get_passive_stats(card_id)
		for key: String in stats:
			if key.ends_with("_pct"):
				total[key] = float(total.get(key, 0.0)) + float(stats[key])
			elif key == "terrain_slow_immunity":
				total[key] = maxi(int(total.get(key, 0)), int(stats[key]))
			else:
				total[key] = int(total.get(key, 0)) + int(stats[key])
	return total
