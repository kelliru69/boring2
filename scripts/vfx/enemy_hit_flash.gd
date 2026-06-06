## Colores de hit flash por elemento (modulate HDR > 1.0 = blanco brillante).
class_name EnemyHitFlash
extends RefCounted

const ELEMENT_DEFAULT: StringName = &""
const ELEMENT_FIRE: StringName = &"fire"
const ELEMENT_ICE: StringName = &"ice"
const ELEMENT_LIGHTNING: StringName = &"lightning"
const ELEMENT_SOUL: StringName = &"soul"
const ELEMENT_WIND: StringName = &"wind"

const FLASH_DURATION: float = 0.07


static func peak_color(element: StringName) -> Color:
	match element:
		ELEMENT_FIRE:
			return Color(3.0, 1.45, 0.55, 1.0)
		ELEMENT_ICE:
			return Color(1.35, 2.6, 3.0, 1.0)
		ELEMENT_LIGHTNING, ELEMENT_WIND:
			return Color(1.6, 2.1, 3.0, 1.0)
		ELEMENT_SOUL:
			return Color(2.2, 1.1, 3.0, 1.0)
		_:
			return Color(3.0, 3.0, 3.0, 1.0)
