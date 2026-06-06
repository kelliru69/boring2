## Datos de presentación para selección de clase.
class_name MenuClassCatalog
extends RefCounted

const MAGE_PORTRAIT: String = "res://assets/skills/mage/soul_strike.png"
const SWORDMAN_PORTRAIT: String = "res://icon.svg"


static func get_mage_entry() -> Dictionary:
	return {
		"class_id": Game.CLASS_MAGE,
		"display_name": "MAGE",
		"portrait_path": MAGE_PORTRAIT,
		"tagline": "Maestro elemental a distancia",
		"skill_lines": [
			"• Ataque a distancia elemental (fuego, hielo, rayo)",
			"• Control de masas: ralentizar, congelar y empujar",
			"• Habilidades automáticas y manuales combinables",
			"• Alto daño en área con Tormenta y Frost Diver",
		],
		"available": true,
	}


static func get_swordman_entry() -> Dictionary:
	return {
		"class_id": Game.CLASS_SWORDMAN,
		"display_name": "SWORDMAN",
		"portrait_path": SWORDMAN_PORTRAIT,
		"tagline": "Espadachín cuerpo a cuerpo",
		"skill_lines": [
			"• Bash en arco hacia el cursor",
			"• Magnum Break, Auto Berserk y Spear Stab",
			"• Endure y Bowling Bash en ranuras manuales",
			"• Regeneración y tanqueo por posicionamiento",
		],
		"available": true,
	}
