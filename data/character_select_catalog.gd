## Avatares jugables para Character Select (Maga / Gato azul). No confundir con clases.
class_name CharacterSelectCatalog
extends RefCounted

const CHARACTERS_DIR: String = "res://resources/characters/"
const _Tex = preload("res://scripts/ui/menu/menu_texture_factory.gd")
const _SkinCatalog = preload("res://data/player_skin_catalog.gd")
const _SpriteFrames = preload("res://scripts/visual/player_directional_sprite_frames.gd")

const MAGE_GIRL_ICON: String = "res://art/characters/mage_girl/mage_girl_icon.png"
const MAGE_GIRL_SPLASH: String = "res://art/characters/mage_girl/mage_girl_splash.png"
const BLUE_CAT_ICON: String = "res://art/characters/blue_cat/blue_cat_icon.png"
const BLUE_CAT_SPLASH: String = "res://art/characters/blue_cat/blue_cat_splash.png"

const ROSTER_COLUMNS: int = 2
const ROSTER_ROWS: int = 4
const ROSTER_SIZE: int = ROSTER_COLUMNS * ROSTER_ROWS


static func get_roster_entries() -> Array:
	var playable: Array[CharacterData] = get_all_characters()
	var roster: Array = []
	for character: CharacterData in playable:
		roster.append(character)
	while roster.size() < ROSTER_SIZE:
		roster.append(null)
	return roster.slice(0, ROSTER_SIZE)


static func get_all_characters() -> Array[CharacterData]:
	var loaded: Array[CharacterData] = _load_from_directory()
	if not loaded.is_empty():
		return loaded
	return _build_builtin_characters()


static func get_character_by_id(character_id: String) -> CharacterData:
	for character: CharacterData in get_all_characters():
		if character.character_id == character_id:
			return character
	return null


static func get_character_by_skin_id(skin_id: String) -> CharacterData:
	for character: CharacterData in get_all_characters():
		if character.default_skin_id == skin_id:
			return character
	return null


static func _load_from_directory() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	if not DirAccess.dir_exists_absolute(CHARACTERS_DIR):
		return result
	var dir: DirAccess = DirAccess.open(CHARACTERS_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = CHARACTERS_DIR + file_name
			var res: Resource = load(path)
			if res is CharacterData:
				result.append(res as CharacterData)
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
		return a.character_name < b.character_name
	)
	return result


static func _build_builtin_characters() -> Array[CharacterData]:
	return [_make_mage_girl_character(), _make_blue_cat_character()]


static func _make_mage_girl_character() -> CharacterData:
	var data: CharacterData = CharacterData.new()
	data.character_id = "char_mage_girl"
	data.character_name = "Maga"
	data.default_skin_id = _SkinCatalog.SKIN_MAGE_GIRL
	data.icon_thumbnail = _Tex.load_or_placeholder(
		MAGE_GIRL_ICON,
		Color(0.25, 0.45, 0.95, 1.0),
		Vector2i(128, 128)
	)
	data.large_splash = _Tex.load_or_placeholder(
		MAGE_GIRL_SPLASH,
		Color(0.08, 0.12, 0.28, 1.0),
		Vector2i(480, 720)
	)
	data.menu_sprite_frames = _Tex.build_menu_sprite_frames_from_skin(_SkinCatalog.SKIN_MAGE_GIRL)
	return data


static func _make_blue_cat_character() -> CharacterData:
	var data: CharacterData = CharacterData.new()
	data.character_id = "char_blue_cat"
	data.character_name = "Gato azul"
	data.default_skin_id = _SkinCatalog.SKIN_BLUE_CAT
	data.icon_thumbnail = _Tex.load_or_placeholder(
		BLUE_CAT_ICON,
		Color(0.35, 0.75, 1.0, 1.0),
		Vector2i(128, 128)
	)
	data.large_splash = _Tex.load_or_placeholder(
		BLUE_CAT_SPLASH,
		Color(0.18, 0.10, 0.08, 1.0),
		Vector2i(480, 720)
	)
	data.menu_sprite_frames = _Tex.build_menu_sprite_frames_from_skin(_SkinCatalog.SKIN_BLUE_CAT)
	return data


static func _skin_preview_icon(skin_id: String) -> Texture2D:
	var skin_def: Dictionary = _SkinCatalog.get_skin(skin_id)
	var preview: Texture2D = _SpriteFrames.get_preview_texture(skin_def)
	if preview != null:
		return preview
	return _Tex.load_or_placeholder("", Color(0.35, 0.75, 1.0, 1.0), Vector2i(128, 128))
