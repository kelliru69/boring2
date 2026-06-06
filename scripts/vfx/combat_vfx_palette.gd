## Paleta Mage — colores legibles sin additive/bloom (fuego naranjo, hielo celeste, alma morada, sight verde).
extends RefCounted
class_name CombatVfxPalette

# --- Fuego: naranjo (50% saturación) ---
const PLAYER_FIRE_CORE: Color = Color(0.787, 0.577, 0.357, 1.0)
const PLAYER_FIRE_MID: Color = Color(0.752, 0.477, 0.282, 0.95)
const PLAYER_FIRE_EDGE: Color = Color(0.723, 0.397, 0.237, 0.75)
const PLAYER_FIRE_GLOW: Color = Color(0.773, 0.547, 0.347, 0.82)

# --- Hielo: celeste (50% saturación) ---
const PLAYER_ICE_CORE: Color = Color(0.687, 0.872, 0.912, 1.0)
const PLAYER_ICE_MID: Color = Color(0.527, 0.742, 0.842, 0.92)
const PLAYER_ICE_EDGE: Color = Color(0.4, 0.6, 0.74, 0.65)

# --- Rayo: amarillo pálido (50% saturación) ---
const PLAYER_LIGHTNING_CORE: Color = Color(0.904, 0.874, 0.644, 1.0)
const PLAYER_LIGHTNING_FLASH: Color = Color(0.872, 0.812, 0.547, 0.95)

# --- Alma: morado (50% saturación) ---
const PLAYER_SOUL_CORE: Color = Color(0.75, 0.55, 0.86, 0.98)
const PLAYER_SOUL_GLOW: Color = Color(0.577, 0.397, 0.747, 0.82)

# --- Sight: verde (50% saturación) ---
const PLAYER_SIGHT_CORE: Color = Color(0.549, 0.784, 0.519, 0.95)
const PLAYER_SIGHT_MID: Color = Color(0.37, 0.62, 0.39, 0.88)

# --- Enemigo: peligro ---
const ENEMY_THREAT_CORE: Color = Color(1.0, 0.12, 0.08, 0.95)
const ENEMY_THREAT_MID: Color = Color(0.95, 0.05, 0.12, 0.75)
const ENEMY_THREAT_FILL: Color = Color(0.88, 0.04, 0.06, 0.28)
const ENEMY_THREAT_RING: Color = Color(1.0, 0.22, 0.14, 0.72)
const ENEMY_OUTLINE: Color = Color(0.02, 0.02, 0.03, 0.96)


static func player_fire_modulate(pulse: float = 1.0) -> Color:
	var w: float = 0.5 + 0.5 * sin(pulse * 9.0)
	return PLAYER_FIRE_CORE.lerp(PLAYER_FIRE_MID, w * 0.35)


static func player_ice_modulate(pulse: float = 1.0) -> Color:
	return PLAYER_ICE_CORE.lerp(PLAYER_ICE_MID, 0.25 + 0.25 * sin(pulse * 7.0))


static func player_lightning_modulate(elapsed: float) -> Color:
	var flicker: float = 0.65 + 0.35 * absf(sin(elapsed * 42.0))
	return PLAYER_LIGHTNING_CORE.lerp(PLAYER_LIGHTNING_FLASH, flicker * 0.45)


static func player_sight_modulate(pulse: float = 1.0) -> Color:
	return PLAYER_SIGHT_CORE.lerp(PLAYER_SIGHT_MID, 0.2 + 0.2 * sin(pulse * 7.0))


static func enemy_threat_fill_alpha(elapsed: float, base: float = 0.22) -> float:
	return base + sin(elapsed * 10.0) * 0.1


static func desaturate(color: Color, saturation_keep: float = 0.5) -> Color:
	var gray: float = (color.r + color.g + color.b) / 3.0
	return Color(
		lerpf(gray, color.r, saturation_keep),
		lerpf(gray, color.g, saturation_keep),
		lerpf(gray, color.b, saturation_keep),
		color.a
	)


## Blend normal — sin additive ni HDR extra.
static func apply_soft_blend(item: CanvasItem) -> void:
	if item == null:
		return
	item.material = null
	item.self_modulate = Color.WHITE


static func apply_additive(item: CanvasItem) -> void:
	apply_soft_blend(item)


static func apply_line_glow(line: Line2D) -> void:
	if line == null:
		return
	line.material = null
	line.self_modulate = Color.WHITE
