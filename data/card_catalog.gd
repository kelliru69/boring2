## Catálogo completo de cartas (álbum) — lore y rutas de arte.
class_name CardCatalog
extends RefCounted

const ALL_CARD_IDS: Array[String] = [
	"carta_poring",
	"carta_lunatic",
	"carta_fabre",
	"carta_zombie",
	"carta_skeleton",
	"carta_creamy",
	"carta_osiris",
]


static func get_definition(card_id: String) -> Dictionary:
	match card_id:
		"carta_poring":
			return _def("Poring", "Un slime gelatinoso de campos abiertos. Su carta otorga resistencia básica.", "Monstruo común de Prontera.")
		"carta_lunatic":
			return _def("Lunatic", "Conejo agresivo de pradera. Acelera tus reflejos en combate.", "Aparece en oleadas tempranas.")
		"carta_fabre":
			return _def("Fabre", "Insecto blindado. Endurece tu cuerpo contra golpes.", "Drop raro en Fabre.")
		"carta_zombie":
			return _def("Zombie", "No-muerto lento pero implacable. Absorbe parte del daño recibido.", "Payon y mapas oscuros.")
		"carta_skeleton":
			return _def("Esqueleto", "Guerrero óseo. Aumenta tu poder ofensivo y cadencia.", "Enemigo de dungeon.")
		"carta_creamy":
			return _def("Creamy", "Hadita errante. Velocidad y evasión mejoradas.", "Jefe de Prontera Fields.")
		"carta_osiris":
			return _def("Osiris", "Señor de la muerte. Bonificaciones élite a ATK, HP y DEF.", "Jefe final de Payon Dungeon.")
		_:
			return _def(card_id, "Carta misteriosa.", "")


static func _def(name: String, lore: String, subtitle: String) -> Dictionary:
	return {"name": name, "lore": lore, "subtitle": subtitle}
