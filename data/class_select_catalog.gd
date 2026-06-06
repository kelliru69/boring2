## Clases del Class Select (jugables + previews bloqueadas). Independientes del avatar.
class_name ClassSelectCatalog
extends RefCounted

const _Tex = preload("res://scripts/ui/menu/menu_texture_factory.gd")
const CLASSES_DIR: String = "res://resources/classes/"

const MAGE_ICON: String = "res://art/classes/mage/mage_icon.png"
const MAGE_BG: String = "res://art/classes/mage/mage_background.png"
const SWORDMAN_ICON: String = "res://art/classes/swordman/swordman_icon.png"
const SWORDMAN_BG: String = "res://art/classes/swordman/swordman_background.png"
const THIEF_ICON: String = "res://art/classes/thief/thief_icon.png"
const THIEF_BG: String = "res://art/classes/thief/thief_background.png"
const ARCHER_ICON: String = "res://art/classes/archer/archer_icon.png"
const ARCHER_BG: String = "res://art/classes/archer/archer_background.png"


static func get_starting_classes() -> Array[ClassData]:
	var loaded: Array[ClassData] = _load_from_directory()
	if not loaded.is_empty():
		return loaded
	return _build_builtin_classes()


static func get_selectable_classes() -> Array[ClassData]:
	var result: Array[ClassData] = []
	for class_data: ClassData in get_starting_classes():
		if class_data.is_selectable:
			result.append(class_data)
	return result


static func get_class_by_id(class_id: String) -> ClassData:
	for class_data: ClassData in get_starting_classes():
		if class_data.class_id == class_id:
			return class_data
	return null


static func _load_from_directory() -> Array[ClassData]:
	var result: Array[ClassData] = []
	if not DirAccess.dir_exists_absolute(CLASSES_DIR):
		return result
	var dir: DirAccess = DirAccess.open(CLASSES_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = load(CLASSES_DIR + file_name)
			if res is ClassData:
				result.append(res as ClassData)
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort_custom(func(a: ClassData, b: ClassData) -> bool:
		return _class_sort_order(a) < _class_sort_order(b)
	)
	return result


static func _class_sort_order(class_data: ClassData) -> int:
	match class_data.class_id:
		Game.CLASS_MAGE:
			return 0
		Game.CLASS_SWORDMAN:
			return 1
		Game.CLASS_THIEF:
			return 2
		Game.CLASS_ARCHER:
			return 3
		_:
			return 100


static func _build_builtin_classes() -> Array[ClassData]:
	return [
		_make_mage_class(),
		_make_swordman_class(),
		_make_thief_preview(),
		_make_archer_preview(),
	]


static func _make_mage_class() -> ClassData:
	var data: ClassData = ClassData.new()
	data.display_name = "Mage"
	data.class_id = Game.CLASS_MAGE
	data.description = (
		"Maestro elemental a distancia. Controla el campo con fuego, hielo y rayos. "
		+ "Tras Job Change puede evolucionar a Wizard o Sage."
	)
	data.class_background = _Tex.load_or_placeholder(
		MAGE_BG,
		Color(0.12, 0.18, 0.42, 1.0),
		Vector2i(1920, 1080)
	)
	data.icon_thumbnail = _Tex.load_or_placeholder(
		MAGE_ICON,
		Color(0.25, 0.45, 0.95, 1.0),
		Vector2i(128, 128)
	)
	data.is_selectable = true
	return data


static func _make_swordman_class() -> ClassData:
	var data: ClassData = ClassData.new()
	data.display_name = "Swordman"
	data.class_id = Game.CLASS_SWORDMAN
	data.description = (
		"Guerrero cuerpo a cuerpo. Tanqueo, embestidas y explosiones cercanas. "
		+ "Tras Job Change puede evolucionar a Knight o Crusader."
	)
	data.class_background = _Tex.load_or_placeholder(
		SWORDMAN_BG,
		Color(0.28, 0.12, 0.10, 1.0),
		Vector2i(1920, 1080)
	)
	data.icon_thumbnail = _Tex.load_or_placeholder(
		SWORDMAN_ICON,
		Color(0.85, 0.35, 0.25, 1.0),
		Vector2i(128, 128)
	)
	data.is_selectable = true
	return data


static func _make_thief_preview() -> ClassData:
	var data: ClassData = ClassData.new()
	data.display_name = "Thief"
	data.class_id = Game.CLASS_THIEF
	data.description = (
		"Asesino sigiloso y explosivo. Próxima clase en desarrollo: "
		+ "trampas, evasión y daño crítico desde las sombras."
	)
	data.class_background = _Tex.load_or_placeholder(
		THIEF_BG,
		Color(0.08, 0.10, 0.14, 1.0),
		Vector2i(1920, 1080)
	)
	data.icon_thumbnail = _Tex.load_or_placeholder(
		THIEF_ICON,
		Color(0.35, 0.32, 0.42, 1.0),
		Vector2i(128, 128)
	)
	data.is_selectable = false
	data.lock_reason = "Próximamente"
	return data


static func _make_archer_preview() -> ClassData:
	var data: ClassData = ClassData.new()
	data.display_name = "Archer"
	data.class_id = Game.CLASS_ARCHER
	data.description = (
		"Cazador a distancia con flechas y trampas. Próxima clase en desarrollo: "
		+ "disparos precisos, movilidad y control del campo."
	)
	data.class_background = _Tex.load_or_placeholder(
		ARCHER_BG,
		Color(0.10, 0.18, 0.12, 1.0),
		Vector2i(1920, 1080)
	)
	data.icon_thumbnail = _Tex.load_or_placeholder(
		ARCHER_ICON,
		Color(0.35, 0.55, 0.30, 1.0),
		Vector2i(128, 128)
	)
	data.is_selectable = false
	data.lock_reason = "Próximamente"
	return data
