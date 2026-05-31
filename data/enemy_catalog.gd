## Definiciones de monstruos, pesos por mapa/tiempo y drops de curación.
class_name EnemyCatalog
extends RefCounted

const _MapConfig = preload("res://data/map_config.gd")

const TYPE_PORING: String = "poring"
const TYPE_LUNATIC: String = "lunatic"
const TYPE_FABRE: String = "fabre"
const TYPE_ZOMBIE: String = "zombie"
const TYPE_SKELETON: String = "skeleton"
const TYPE_CREAMY: String = "creamy"
const TYPE_OSIRIS: String = "osiris"

const HEAL_APPLE_CHANCE_PORING: float = 0.01
const HEAL_CARROT_CHANCE_LUNATIC: float = 0.01


static func get_definition(type_id: String) -> Dictionary:
	match type_id:
		TYPE_CREAMY:
			return {
				"id": TYPE_CREAMY,
				"display_name": "Creamy",
				"sprite_path": "res://assets/sprites/monsters/creamy.png",
				"walk_frames_folder": "res://assets/sprites/monsters/creamy/",
				"sprite_height": 36.0,
				"anim_fps": 8.0,
				"color": Color(1.0, 0.92, 0.45, 1.0),
				"max_hp": 20000,
				"move_speed": 410.0,
				"contact_damage": 260,
				"zeny_reward": 180,
				"xp_reward": 400,
				"card_id": "carta_creamy",
				"card_name": "Carta Creamy",
			}
		TYPE_OSIRIS:
			return {
				"id": TYPE_OSIRIS,
				"display_name": "Osiris",
				"sprite_path": "res://assets/sprites/monsters/osiris.png",
				"walk_frames_folder": "res://assets/sprites/monsters/osiris/",
				"sprite_height": 48.0,
				"anim_fps": 8.0,
				"color": Color(0.55, 0.85, 0.35, 1.0),
				"max_hp": 2000,
				"move_speed": 130.0,
				"contact_damage": 22,
				"zeny_reward": 250,
				"xp_reward": 600,
				"card_id": "carta_osiris",
				"card_name": "Carta Osiris",
			}
		TYPE_ZOMBIE:
			return {
				"id": TYPE_ZOMBIE,
				"display_name": "Zombie",
				"sprite_path": "res://assets/sprites/monsters/zombie.png",
				"walk_frames_folder": "res://assets/sprites/monsters/zombie/",
				"sprite_height": 32.0,
				"anim_fps": 6.0,
				"color": Color(0.45, 0.55, 0.38, 1.0),
				"max_hp": 55,
				"move_speed": 70.0,
				"contact_damage": 16,
				"zeny_reward": 10,
				"xp_reward": 16,
				"card_id": "carta_zombie",
				"card_name": "Carta Zombie",
			}
		TYPE_SKELETON:
			return {
				"id": TYPE_SKELETON,
				"display_name": "Skeleton",
				"sprite_path": "res://assets/sprites/monsters/skeleton.png",
				"walk_frames_folder": "res://assets/sprites/monsters/skeleton/",
				"sprite_height": 30.0,
				"anim_fps": 8.0,
				"color": Color(0.85, 0.82, 0.75, 1.0),
				"max_hp": 40,
				"move_speed": 105.0,
				"contact_damage": 18,
				"zeny_reward": 12,
				"xp_reward": 18,
				"card_id": "carta_skeleton",
				"card_name": "Carta Skeleton",
			}
		TYPE_LUNATIC:
			return {
				"id": TYPE_LUNATIC,
				"display_name": "Lunatic",
				"sprite_path": "res://assets/sprites/monsters/lunatic.png",
				"sprite_height": 28.0,
				"anim_fps": 8.0,
				"color": Color(0.35, 0.9, 0.45, 1.0),
				"max_hp": 13,
				"move_speed": 125.0,
				"contact_damage": 8,
				"zeny_reward": 7,
				"xp_reward": 12,
				"card_id": "carta_lunatic",
				"card_name": "Carta Lunatic",
				"heal_drop": "carrot",
				"heal_drop_chance": HEAL_CARROT_CHANCE_LUNATIC,
			}
		TYPE_FABRE:
			return {
				"id": TYPE_FABRE,
				"display_name": "Fabre",
				"sprite_path": "res://assets/sprites/monsters/fabre.png",
				"sprite_height": 26.0,
				"anim_fps": 6.0,
				"color": Color(0.95, 0.82, 0.25, 1.0),
				"max_hp": 45,
				"move_speed": 36.0,
				"contact_damage": 20,
				"zeny_reward": 9,
				"xp_reward": 14,
				"card_id": "carta_fabre",
				"card_name": "Carta Fabre",
			}
		_:
			return {
				"id": TYPE_PORING,
				"display_name": "Poring",
				"sprite_path": "res://assets/sprites/monsters/poring.png",
				"sprite_height": 30.0,
				"anim_fps": 8.0,
				"color": Color(1.0, 0.55, 0.75, 1.0),
				"max_hp": 30,
				"move_speed": 88.0,
				"contact_damage": 10,
				"zeny_reward": 5,
				"xp_reward": 10,
				"card_id": "carta_poring",
				"card_name": "Carta Poring",
				"heal_drop": "apple",
				"heal_drop_chance": HEAL_APPLE_CHANCE_PORING,
			}


static func pick_random_for_time(elapsed_seconds: float, map_id: String = _MapConfig.MAP_PRONTERA) -> String:
	if map_id == _MapConfig.MAP_PAYON:
		return pick_random_payon(elapsed_seconds)
	var weights: Dictionary = {
		TYPE_PORING: 70.0,
		TYPE_LUNATIC: 20.0,
		TYPE_FABRE: 10.0,
	}
	if elapsed_seconds >= 60.0:
		weights[TYPE_PORING] = 45.0
		weights[TYPE_LUNATIC] = 35.0
		weights[TYPE_FABRE] = 20.0
	if elapsed_seconds >= 180.0:
		weights[TYPE_PORING] = 30.0
		weights[TYPE_LUNATIC] = 40.0
		weights[TYPE_FABRE] = 30.0
	return _weighted_pick(weights)


static func pick_random_payon(elapsed_seconds: float) -> String:
	var weights: Dictionary = {
		TYPE_ZOMBIE: 55.0,
		TYPE_SKELETON: 45.0,
	}
	if elapsed_seconds >= 120.0:
		weights[TYPE_ZOMBIE] = 40.0
		weights[TYPE_SKELETON] = 60.0
	return _weighted_pick(weights)


static func _weighted_pick(weights: Dictionary) -> String:
	var total: float = 0.0
	for type_id: String in weights:
		total += float(weights[type_id])
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for type_id: String in weights:
		cumulative += float(weights[type_id])
		if roll <= cumulative:
			return type_id
	return TYPE_PORING
