## Base de datos de hojas VFX de combate (32×32 → escala 16×16 en runtime).
class_name SkillVfxRegistry
extends RefCounted

const _Cfg = preload("res://scripts/visual/skill_vfx_sheet_config.gd")

const BASE_PATH: String = "res://assets/sprites/skills/"
const DEFAULT_GRID_H: int = 6
const DEFAULT_GRID_V: int = 2
const DEFAULT_FRAME_COUNT: int = 12

## skill_id → { role_key → SkillVfxSheetConfig }
## role_key: "projectile" | "impact" | "slash" | "aura"
static var _entries: Dictionary = {}
static var _built: bool = false


static func get_config(skill_id: String, role_key: String = "projectile") -> SkillVfxSheetConfig:
	_ensure_built()
	var skill_entry: Variant = _entries.get(skill_id)
	if skill_entry == null:
		return null
	return skill_entry.get(role_key) as SkillVfxSheetConfig


static func has_config(skill_id: String, role_key: String = "projectile") -> bool:
	var cfg: SkillVfxSheetConfig = get_config(skill_id, role_key)
	return cfg != null and cfg.is_valid()


static func get_all_skill_ids() -> Array[String]:
	_ensure_built()
	var ids: Array[String] = []
	for key: Variant in _entries.keys():
		ids.append(String(key))
	return ids


static func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_register_defaults()


static func _register_defaults() -> void:
	# -------------------------------------------------------------------------
	# MAGE — cambia las rutas NUM.png por tus hojas definitivas.
	# Todas las hojas actuales miden 192×64 → grilla 6×2 (12 celdas de 32 px).
	# -------------------------------------------------------------------------

	_register_skill("soul_strike", {
		# Frames 1–6 en loop de ida; al llegar al 6 se congela (sin frames 7–12 de fade).
		"projectile": _Cfg.animated_play_then_hold(
			"soul_strike",
			BASE_PATH + "11.png",
			_Cfg.VisualRole.PROJECTILE,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 14.0, 6, 5.5
		),
		"impact": _Cfg.one_shot_burst(
			"soul_strike",
			BASE_PATH + "12.png",  # CAMBIA: impacto morado
			_Cfg.VisualRole.IMPACT,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 18.0, 9
		),
	})

	_register_skill("fire_bolt", {
		"projectile": _Cfg.animated_loop(
			"fire_bolt",
			BASE_PATH + "03.png",  # CAMBIA: naranjo / fuego
			_Cfg.VisualRole.PROJECTILE,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 12.0, DEFAULT_FRAME_COUNT
		),
		"impact": _Cfg.one_shot_burst(
			"fire_bolt",
			BASE_PATH + "04.png",  # CAMBIA: explosión fuego
			_Cfg.VisualRole.IMPACT,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 18.0, DEFAULT_FRAME_COUNT
		),
	})

	_register_skill("cold_bolt", {
		"projectile": _Cfg.animated_loop(
			"cold_bolt",
			BASE_PATH + "07.png",  # CAMBIA: celeste / hielo
			_Cfg.VisualRole.PROJECTILE,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 12.0, DEFAULT_FRAME_COUNT
		),
		"impact": _Cfg.one_shot_burst(
			"cold_bolt",
			BASE_PATH + "08.png",  # CAMBIA: impacto hielo
			_Cfg.VisualRole.IMPACT,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 16.0, DEFAULT_FRAME_COUNT
		),
	})

	_register_skill("sight", {
		"aura": _Cfg.animated_loop(
			"sight",
			BASE_PATH + "31.png",  # CAMBIA: verde / sight
			_Cfg.VisualRole.AURA,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 10.0, 8
		),
	})

	_register_skill("firewall", {
		# Barrera activa: loop mientras dura el muro.
		# 11 frames: el frame 12 de la grilla 6×2 está vacío y rompe el loop.
		"aura": _Cfg.animated_loop(
			"firewall",
			BASE_PATH + "05.png",  # CAMBIA: llamas / barrera circular
			_Cfg.VisualRole.AURA,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 10.0, 11
		),
		# Opcional: destello en cada pulso de daño.
		#"pulse": _Cfg.one_shot_burst(
			#"firewall",
			#BASE_PATH + "02.png",  # CAMBIA: chispa / pulso ígneo
			#_Cfg.VisualRole.IMPACT,
			#DEFAULT_GRID_H, DEFAULT_GRID_V, 16.0, 8
		#),
	})

	_register_skill("frost_diver", {
		# Cabeza del proyectil durante el vuelo en línea recta.
		"projectile": _Cfg.animated_loop(
			"frost_diver",
			BASE_PATH + "10.png",  # CAMBIA: cristal / hielo en movimiento
			_Cfg.VisualRole.PROJECTILE,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 14.0, DEFAULT_FRAME_COUNT
		),
		"impact": _Cfg.one_shot_burst(
			"frost_diver",
			BASE_PATH + "06.png",  # CAMBIA: explosión de escarcha
			_Cfg.VisualRole.IMPACT,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 18.0, DEFAULT_FRAME_COUNT
		),
	})

	_register_skill("lightning_bolt", {
		"projectile": _Cfg.animated_loop(
			"lightning_bolt",
			BASE_PATH + "18.png",  # CAMBIA: boomerang eléctrico
			_Cfg.VisualRole.PROJECTILE,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 14.0, DEFAULT_FRAME_COUNT
		),
		"impact": _Cfg.one_shot_burst(
			"lightning_bolt",
			BASE_PATH + "17.png",  # CAMBIA: chispa al impactar enemigo
			_Cfg.VisualRole.IMPACT,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 18.0, 10
		),
	})

	_register_skill("thunderstorm", {
		# Zona de tormenta persistente mientras dura el AoE.
		"aura": _Cfg.animated_loop(
			"thunderstorm",
			BASE_PATH + "20.png",  # CAMBIA: nube / anillo eléctrico
			_Cfg.VisualRole.AURA,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 12.0, DEFAULT_FRAME_COUNT
		),
		# Rayo inicial al aparecer la tormenta.
		"strike": _Cfg.one_shot_burst(
			"thunderstorm",
			BASE_PATH + "18.png",  # CAMBIA: rayo vertical / impacto inicial
			_Cfg.VisualRole.IMPACT,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 20.0, 10
		),
		# Opcional: destello en cada pulso de daño.
		"pulse": _Cfg.one_shot_burst(
			"thunderstorm",
			BASE_PATH + "16.png",  # CAMBIA: anillo eléctrico en el suelo
			_Cfg.VisualRole.IMPACT,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 16.0, 8
		),
	})

	# -------------------------------------------------------------------------
	# SWORDMAN
	# -------------------------------------------------------------------------

	_register_skill("bash", {
		"slash": _Cfg.one_shot_burst(
			"bash",
			BASE_PATH + "28.png",  # CAMBIA: arco / corte físico
			_Cfg.VisualRole.SLASH,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 20.0, 11
		),
	})

	_register_skill("magnum_break", {
		"impact": _Cfg.one_shot_burst(
			"magnum_break",
			BASE_PATH + "02.png",  # CAMBIA: onda de fuego / shockwave
			_Cfg.VisualRole.IMPACT,
			DEFAULT_GRID_H, DEFAULT_GRID_V, 16.0, DEFAULT_FRAME_COUNT
		),
	})


static func _register_skill(skill_id: String, roles: Dictionary) -> void:
	_entries[skill_id] = roles
