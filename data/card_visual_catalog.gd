## Rutas de arte de cartas.
##
## - Álbum / menú: `{mob}_card.png` (ilustración completa).
## - Drop en suelo: `carta_{mob}.png` (sprite pequeño; nunca el arte de álbum).
class_name CardVisualCatalog
extends RefCounted

const ART_BASE: String = "res://art/cards/"
const ASSETS_CARD_BASE: String = "res://assets/"
const PICKUP_BASE: String = "res://assets/sprites/cards/"


static func _mob_id(card_id: String) -> String:
	return card_id.replace("carta_", "")


static func get_album_art_paths(card_id: String) -> Array[String]:
	var mob: String = _mob_id(card_id)
	return [
		ART_BASE + mob + "_card.png",
		ASSETS_CARD_BASE + mob + "_card.png",
		ART_BASE + card_id + ".png",
	]


static func get_pickup_sprite_paths(card_id: String) -> Array[String]:
	var mob: String = _mob_id(card_id)
	return [
		ART_BASE + card_id + ".png",
		PICKUP_BASE + card_id + ".png",
		# Fallback: usar arte de álbum si no hay sprite pequeño de drop.
		ASSETS_CARD_BASE + mob + "_card.png",
		ART_BASE + mob + "_card.png",
	]


static func load_album_texture(card_id: String) -> Texture2D:
	for path: String in get_album_art_paths(card_id):
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


static func load_pickup_texture(card_id: String) -> Texture2D:
	for path: String in get_pickup_sprite_paths(card_id):
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


## Compatibilidad: álbum usa arte completo.
static func get_art_paths(card_id: String) -> Array[String]:
	return get_album_art_paths(card_id)


static func get_sprite_path(card_id: String) -> String:
	for path: String in get_pickup_sprite_paths(card_id):
		if ResourceLoader.exists(path):
			return path
	return ART_BASE + card_id + ".png"


static func load_texture(card_id: String) -> Texture2D:
	return load_album_texture(card_id)
