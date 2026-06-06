## Catálogo completo de cartas (álbum) — lore y rutas de arte.
class_name CardCatalog
extends RefCounted

const ALL_CARD_IDS: Array[String] = [
	"carta_poring",
	"carta_lunatic",
	"carta_fabre",
	"carta_zombie",
	"carta_skeleton",
	"carta_archer_skeleton",
	"carta_familiar",
	"carta_rocker",
	"carta_creamy",
	"carta_moonlight_flower",
	"carta_orc_baby",
	"carta_orc_warrior",
	"carta_orc_lady",
	"carta_orc_archer",
	"carta_high_orc",
	"carta_orc_hero",
]


static func get_definition(card_id: String) -> Dictionary:
	if card_id.ends_with("_plus"):
		var base_id: String = card_id.trim_suffix("_plus")
		var base_def: Dictionary = get_definition(base_id)
		return {
			"name": "%s+" % String(base_def.get("name", base_id)),
			"lore": "%s\n\nVariante evolucionada (+): efectos pasivos duplicados." % String(base_def.get("lore", "")),
			"subtitle": "Carta evolucionada (+)",
		}
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
		"carta_archer_skeleton":
			return _def("Archer Skeleton", "Arquero no-muerto de precisión mortal. Potencia daño y alcance efectivo.", "Aparece en Payon (5:00+).")
		"carta_familiar":
			return _def("Familiar", "Espíritu veloz de Payon. Potencia movilidad y presión ofensiva.", "Aparece en el segundo mapa.")
		"carta_rocker":
			return _def("Rocker", "Bestia saltarina de impacto brutal. Mejora burst y control de espacio.", "Aparece en Prontera (5:00+).")
		"carta_creamy":
			return _def("Creamy", "Hadita errante legendaria. Buff extremo para runs avanzadas.", "Drop ultrarraro de jefe.")
		"carta_moonlight_flower":
			return _def("Moonlight Flower", "Aura mística abrumadora. Poder descomunal en ofensiva y supervivencia.", "Drop ultrarraro del jefe final de Payon.")
		"carta_orc_baby":
			return _def("Orc Baby", "Cría orca ágil. Impulso temprano de velocidad y EXP en la run.", "Orc Village — horda inicial — drop 0.05%.")
		"carta_orc_warrior":
			return _def("Orc Warrior", "Guerrero orco resistente. Mejora defensa y daño cuerpo a cuerpo.", "Orc Village — drop 0.05%.")
		"carta_orc_lady":
			return _def("Orc Lady", "Velocidad de horda. Más movimiento y críticos.", "Orc Village — drop 0.05%.")
		"carta_orc_archer":
			return _def("Orc Archer", "Precisión a distancia. Alcance y recarga.", "Orc Village — drop 0.05%.")
		"carta_high_orc":
			return _def("High Orc", "Tanque de élite. HP y resistencia a proyectiles.", "Orc Village (5:00+) — drop 0.05%.")
		"carta_orc_hero":
			return _def("Orc Hero", "Carta MVP legendaria. Poder absoluto y dominio del terreno.", "Jefe Orc Hero — máx. 1 por run.")
		_:
			return _def(card_id, "Carta misteriosa.", "")


static func _def(name: String, lore: String, subtitle: String) -> Dictionary:
	return {"name": name, "lore": lore, "subtitle": subtitle}


## IDs del álbum: cartas base + variantes plus (solo visibles si están desbloqueadas).
static func get_all_album_card_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.append_array(ALL_CARD_IDS)
	for base_id: String in ALL_CARD_IDS:
		var plus_id: String = "%s_plus" % base_id
		if not ids.has(plus_id):
			ids.append(plus_id)
	return ids
