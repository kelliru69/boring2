## Definiciones de monstruos, pesos por mapa/tiempo y drops de curación.
class_name EnemyCatalog
extends RefCounted

const _MapConfig = preload("res://data/map_config.gd")

const TYPE_PORING: String = "poring"
const TYPE_LUNATIC: String = "lunatic"
const TYPE_FABRE: String = "fabre"
const TYPE_ZOMBIE: String = "zombie"
const TYPE_SKELETON: String = "skeleton"
const TYPE_FAMILIAR: String = "familiar"
const TYPE_CREAMY: String = "creamy"
const TYPE_OSIRIS: String = "osiris"
const TYPE_MOONLIGHT_FLOWER: String = "moonlight_flower"
const TYPE_ROCKER: String = "rocker"
const TYPE_ARCHER_SKELETON: String = "archer_skeleton"
const TYPE_ORC_BABY: String = "orc_baby"
const TYPE_ORC_WARRIOR: String = "orc_warrior"
const TYPE_ORC_LADY: String = "orc_lady"
const TYPE_ORC_ARCHER: String = "orc_archer"
const TYPE_HIGH_ORC: String = "high_orc"
const TYPE_ORC_HERO: String = "orc_hero"

const SIZE_SMALL: String = "small"
const SIZE_MEDIUM: String = "medium"
const SIZE_LARGE: String = "large"

const HEAL_DROP_BASE_CHANCE: float = 0.04
const HEAL_APPLE_CHANCE_PORING: float = HEAL_DROP_BASE_CHANCE
const HEAL_CARROT_CHANCE_LUNATIC: float = HEAL_DROP_BASE_CHANCE


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
		TYPE_MOONLIGHT_FLOWER:
			return {
				"id": TYPE_MOONLIGHT_FLOWER,
				"display_name": "Moonlight Flower",
				"sprite_path": "res://assets/sprites/monsters/moonlight_flower/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/moonlight_flower/",
				"sprite_height": 52.0,
				"anim_fps": 9.0,
				"color": Color(0.95, 0.75, 1.0, 1.0),
				"max_hp": 20000,
				"move_speed": 145.0,
				"contact_damage": 32,
				"zeny_reward": 420,
				"xp_reward": 900,
				"card_id": "carta_moonlight_flower",
				"card_name": "Carta Moonlight Flower",
			}
		TYPE_ZOMBIE:
			return {
				"id": TYPE_ZOMBIE,
				"display_name": "Zombie",
				"sprite_path": "res://assets/sprites/monsters/zombie.png",
				"walk_frames_folder": "res://assets/sprites/monsters/zombie/",
				"sprite_height": 80.0,
				"sprite_width_scale": 0.9,
				"collision_radius": 30.0,
				"anim_fps": 6.0,
				"color": Color(0.45, 0.55, 0.38, 1.0),
				"max_hp": 55,
				"move_speed": 38.5,
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
				"sprite_height": 80.0,
				"sprite_width_scale": 0.9,
				"collision_radius": 30.0,
				"anim_fps": 8.0,
				"color": Color(0.85, 0.82, 0.75, 1.0),
				"max_hp": 40,
				"move_speed": 105.0,
				"contact_damage": 18,
				"zeny_reward": 12,
				"xp_reward": 18,
				"card_id": "carta_skeleton",
				"card_name": "Carta Skeleton",
				"heal_drop": "apple",
				"heal_drop_chance": HEAL_APPLE_CHANCE_PORING,
			}
		TYPE_FAMILIAR:
			return {
				"id": TYPE_FAMILIAR,
				"display_name": "Familiar",
				"sprite_path": "res://assets/sprites/monsters/familiar/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/familiar/",
				"sprite_height": 27.0,
				"anim_fps": 11.0,
				"color": Color(0.72, 0.55, 1.0, 1.0),
				"max_hp": 74,
				"move_speed": 130.0,
				"contact_damage": 24,
				"zeny_reward": 16,
				"xp_reward": 28,
				"card_id": "carta_familiar",
				"card_name": "Carta Familiar",
			}
		TYPE_LUNATIC:
			return {
				"id": TYPE_LUNATIC,
				"display_name": "Lunatic",
				"sprite_path": "res://assets/sprites/monsters/lunatic.png",
				"sprite_height": 28.0,
				"anim_fps": 8.0,
				"color": Color(0.35, 0.9, 0.45, 1.0),
				# Inicio dinámico: debe caer de 1 golpe del daño base típico.
				"max_hp": 8,
				"move_speed": 125.0,
				"contact_damage": 8,
				"zeny_reward": 7,
				"xp_reward": 12,
				"card_id": "carta_lunatic",
				"card_name": "Carta Lunatic",
				"heal_drop": "carrot",
				"heal_drop_chance": HEAL_CARROT_CHANCE_LUNATIC,
			}
		TYPE_ROCKER:
			return {
				"id": TYPE_ROCKER,
				"display_name": "Rocker",
				"sprite_path": "res://assets/sprites/monsters/rocker/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/rocker/",
				# 3 tiles alto (3×32 = 96px). Ancho depende del sprite.
				"sprite_height": 96.0,
				"anim_fps": 8.0,
				"color": Color(0.95, 0.65, 0.25, 1.0),
				"max_hp": 280,
				"move_speed": 0.0,
				# Rocker no hace daño por contacto; solo por su impacto de salto.
				"contact_damage": 0,
				"impact_damage": 36,
				"impact_radius": 64.0,
				"zeny_reward": 30,
				"xp_reward": 65,
				"collision_radius": 28.0,
				"scene_path": "res://scenes/enemy/RockerEnemy.tscn",
				"card_id": "carta_rocker",
				"card_name": "Carta Rocker",
			}
		TYPE_ORC_BABY:
			return {
				"id": TYPE_ORC_BABY,
				"display_name": "Orc Baby",
				"sprite_path": "res://assets/sprites/monsters/orc_baby/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/orc_baby/",
				"sprite_height": 42.0,
				"collision_radius": 18.0,
				"anim_fps": 11.0,
				"size_tier": SIZE_SMALL,
				"max_hp": 20,
				"move_speed": 158.0,
				"contact_damage": 9,
				"zeny_reward": 6,
				"xp_reward": 11,
				"card_id": "carta_orc_baby",
				"card_name": "Carta Orc Baby",
			}
		TYPE_ORC_WARRIOR:
			return {
				"id": TYPE_ORC_WARRIOR,
				"display_name": "Orc Warrior",
				"sprite_path": "res://assets/sprites/monsters/orc_warrior/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/orc_warrior/",
				"sprite_height": 88.0,
				"sprite_width_scale": 1.0,
				"collision_radius": 30.0,
				"anim_fps": 8.0,
				"max_hp": 88,
				"move_speed": 74.0,
				"contact_damage": 21,
				"zeny_reward": 14,
				"xp_reward": 23,
				"card_id": "carta_orc_warrior",
				"card_name": "Carta Orc Warrior",
			}
		TYPE_ORC_LADY:
			return {
				"id": TYPE_ORC_LADY,
				"display_name": "Orc Lady",
				"sprite_path": "res://assets/sprites/monsters/orc_lady/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/orc_lady/",
				"sprite_height": 72.0,
				"collision_radius": 22.0,
				"anim_fps": 11.0,
				"max_hp": 44,
				"move_speed": 152.0,
				"contact_damage": 13,
				"zeny_reward": 10,
				"xp_reward": 15,
				"card_id": "carta_orc_lady",
				"card_name": "Carta Orc Lady",
			}
		TYPE_ORC_ARCHER:
			return {
				"id": TYPE_ORC_ARCHER,
				"display_name": "Orc Archer",
				"sprite_path": "res://assets/sprites/monsters/orc_archer/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/orc_archer/",
				"sprite_height": 84.0,
				"anim_fps": 9.0,
				"max_hp": 66,
				"move_speed": 96.0,
				"contact_damage": 10,
				"ranged_damage": 54,
				"ranged_range_tiles": 12.0,
				"zeny_reward": 17,
				"xp_reward": 28,
				"collision_radius": 24.0,
				"scene_path": "res://scenes/enemy/OrcArcherEnemy.tscn",
				"card_id": "carta_orc_archer",
				"card_name": "Carta Orc Archer",
			}
		TYPE_HIGH_ORC:
			return {
				"id": TYPE_HIGH_ORC,
				"display_name": "High Orc",
				"sprite_path": "res://assets/sprites/monsters/high_orc/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/high_orc/",
				"sprite_height": 96.0,
				"sprite_width_scale": 1.05,
				"anim_fps": 7.0,
				"max_hp": 395,
				"move_speed": 56.0,
				"contact_damage": 36,
				"axe_damage": 68,
				"axe_radius": 70.0,
				"frontal_block_pct": 0.30,
				"zeny_reward": 36,
				"xp_reward": 78,
				"collision_radius": 32.0,
				"scene_path": "res://scenes/enemy/HighOrcEnemy.tscn",
				"card_id": "carta_high_orc",
				"card_name": "Carta High Orc",
			}
		TYPE_ORC_HERO:
			return {
				"id": TYPE_ORC_HERO,
				"display_name": "Orc Hero",
				"sprite_path": "res://assets/sprites/monsters/orc_hero/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/orc_hero/",
				"sprite_height": 108.0,
				"sprite_width_scale": 1.1,
				"anim_fps": 8.0,
				"max_hp": 44000,
				"move_speed": 102.0,
				"contact_damage": 40,
				"zeny_reward": 640,
				"xp_reward": 1500,
				"card_id": "carta_orc_hero",
				"card_name": "Carta Orc Hero",
			}
		TYPE_ARCHER_SKELETON:
			return {
				"id": TYPE_ARCHER_SKELETON,
				"display_name": "Archer Skeleton",
				"sprite_path": "res://assets/sprites/monsters/archer_skeleton/00.png",
				"walk_frames_folder": "res://assets/sprites/monsters/archer_skeleton/",
				"sprite_height": 96.0,
				"anim_fps": 8.0,
				"color": Color(0.85, 0.82, 0.75, 1.0),
				"max_hp": 190,
				"move_speed": 105.0,
				"contact_damage": 12,
				"ranged_damage": 52,
				"ranged_range_tiles": 11.0,
				"zeny_reward": 26,
				"xp_reward": 58,
				"collision_radius": 28.0,
				"scene_path": "res://scenes/enemy/ArcherSkeletonEnemy.tscn",
				"card_id": "carta_archer_skeleton",
				"card_name": "Carta Archer Skeleton",
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
				"size_tier": SIZE_SMALL,
				"heal_drop": "apple",
				"heal_drop_chance": HEAL_APPLE_CHANCE_PORING,
			}


static func pick_random_for_time(elapsed_seconds: float, map_id: String = _MapConfig.MAP_PRONTERA) -> String:
	if map_id == _MapConfig.MAP_ORC_VILLAGE:
		return pick_random_orc_village(elapsed_seconds)
	if map_id == _MapConfig.MAP_PAYON:
		return pick_random_payon(elapsed_seconds)
	var weights: Dictionary = {
		TYPE_PORING: 20.0,
		TYPE_LUNATIC: 65.0,
		TYPE_FABRE: 15.0,
	}
	# Minuto 0 al 2: Lunatic es notablemente más común.
	if elapsed_seconds >= 120.0:
		weights[TYPE_PORING] = 32.0
		weights[TYPE_LUNATIC] = 43.0
		weights[TYPE_FABRE] = 25.0
	if elapsed_seconds >= 180.0:
		weights[TYPE_PORING] = 30.0
		weights[TYPE_LUNATIC] = 40.0
		weights[TYPE_FABRE] = 30.0
	# Semi-élite desde 5:00 en adelante.
	if elapsed_seconds >= 300.0:
		weights[TYPE_ROCKER] = 1.3333333
	return _weighted_pick(weights)


static func pick_random_payon(elapsed_seconds: float) -> String:
	# Primeros 2 min: más Zombie, Familiar casi ausente.
	var weights: Dictionary = {
		TYPE_ZOMBIE: 60.0,
		TYPE_SKELETON: 35.0,
		TYPE_FAMILIAR: 5.0,
	}
	if elapsed_seconds >= 120.0:
		weights[TYPE_ZOMBIE] = 40.0
		weights[TYPE_SKELETON] = 38.0
		weights[TYPE_FAMILIAR] = 22.0
	if elapsed_seconds >= 180.0:
		weights[TYPE_ZOMBIE] = 28.0
		weights[TYPE_SKELETON] = 42.0
		weights[TYPE_FAMILIAR] = 30.0
	if elapsed_seconds >= 240.0:
		weights[TYPE_ZOMBIE] = 22.0
		weights[TYPE_SKELETON] = 40.0
		weights[TYPE_FAMILIAR] = 38.0
	# Semi-élite a distancia desde 6:00 en adelante.
	if elapsed_seconds >= 360.0:
		weights[TYPE_ARCHER_SKELETON] = 1.3333333
	return _weighted_pick(weights)


static func pick_random_orc_village(elapsed_seconds: float) -> String:
	# Minuto 0–5: hordas de Orc Baby + Lady; Warriors y Archers escalan con el tiempo.
	var weights: Dictionary = {
		TYPE_ORC_BABY: 52.0,
		TYPE_ORC_LADY: 28.0,
		TYPE_ORC_WARRIOR: 14.0,
		TYPE_ORC_ARCHER: 6.0,
	}
	if elapsed_seconds >= 90.0:
		weights[TYPE_ORC_BABY] = 32.0
		weights[TYPE_ORC_LADY] = 38.0
		weights[TYPE_ORC_WARRIOR] = 22.0
		weights[TYPE_ORC_ARCHER] = 8.0
	if elapsed_seconds >= 180.0:
		weights[TYPE_ORC_BABY] = 18.0
		weights[TYPE_ORC_LADY] = 42.0
		weights[TYPE_ORC_WARRIOR] = 28.0
		weights[TYPE_ORC_ARCHER] = 12.0
	if elapsed_seconds >= 300.0:
		weights[TYPE_HIGH_ORC] = 1.3333333
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
