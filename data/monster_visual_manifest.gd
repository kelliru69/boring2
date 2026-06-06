## Rutas explícitas de frames walk — necesarias en export (.exe): DirAccess no lista res:// dentro del .pck.
class_name MonsterVisualManifest
extends RefCounted

const WALK_FRAMES: Dictionary = {
	"poring": [
		"res://assets/sprites/monsters/poring/00.png",
		"res://assets/sprites/monsters/poring/01.png",
		"res://assets/sprites/monsters/poring/02.png",
		"res://assets/sprites/monsters/poring/03.png",
	],
	"lunatic": [
		"res://assets/sprites/monsters/lunatic/00.png",
		"res://assets/sprites/monsters/lunatic/01.png",
		"res://assets/sprites/monsters/lunatic/02.png",
		"res://assets/sprites/monsters/lunatic/03.png",
		"res://assets/sprites/monsters/lunatic/04.png",
		"res://assets/sprites/monsters/lunatic/05.png",
		"res://assets/sprites/monsters/lunatic/06.png",
		"res://assets/sprites/monsters/lunatic/07.png",
		"res://assets/sprites/monsters/lunatic/08.png",
		"res://assets/sprites/monsters/lunatic/09.png",
		"res://assets/sprites/monsters/lunatic/10.png",
		"res://assets/sprites/monsters/lunatic/11.png",
	],
	"fabre": [
		"res://assets/sprites/monsters/fabre/00.png",
		"res://assets/sprites/monsters/fabre/01.png",
		"res://assets/sprites/monsters/fabre/02.png",
		"res://assets/sprites/monsters/fabre/03.png",
	],
	"zombie": [
		"res://assets/sprites/monsters/zombie/00.png",
		"res://assets/sprites/monsters/zombie/01.png",
		"res://assets/sprites/monsters/zombie/02.png",
		"res://assets/sprites/monsters/zombie/03.png",
		"res://assets/sprites/monsters/zombie/04.png",
		"res://assets/sprites/monsters/zombie/05.png",
		"res://assets/sprites/monsters/zombie/06.png",
		"res://assets/sprites/monsters/zombie/07.png",
		"res://assets/sprites/monsters/zombie/08.png",
		"res://assets/sprites/monsters/zombie/09.png",
		"res://assets/sprites/monsters/zombie/10.png",
		"res://assets/sprites/monsters/zombie/11.png",
		"res://assets/sprites/monsters/zombie/12.png",
		"res://assets/sprites/monsters/zombie/13.png",
		"res://assets/sprites/monsters/zombie/14.png",
		"res://assets/sprites/monsters/zombie/15.png",
		"res://assets/sprites/monsters/zombie/16.png",
		"res://assets/sprites/monsters/zombie/17.png",
		"res://assets/sprites/monsters/zombie/18.png",
		"res://assets/sprites/monsters/zombie/19.png",
	],
	"skeleton": [
		"res://assets/sprites/monsters/skeleton/00.png",
		"res://assets/sprites/monsters/skeleton/01.png",
		"res://assets/sprites/monsters/skeleton/02.png",
		"res://assets/sprites/monsters/skeleton/03.png",
		"res://assets/sprites/monsters/skeleton/04.png",
		"res://assets/sprites/monsters/skeleton/05.png",
		"res://assets/sprites/monsters/skeleton/06.png",
		"res://assets/sprites/monsters/skeleton/07.png",
		"res://assets/sprites/monsters/skeleton/08.png",
		"res://assets/sprites/monsters/skeleton/09.png",
	],
	"creamy": [
		"res://assets/sprites/monsters/creamy/00.png",
		"res://assets/sprites/monsters/creamy/01.png",
		"res://assets/sprites/monsters/creamy/02.png",
		"res://assets/sprites/monsters/creamy/03.png",
		"res://assets/sprites/monsters/creamy/04.png",
	],
	"familiar": [
		"res://assets/sprites/monsters/familiar/00.png",
		"res://assets/sprites/monsters/familiar/01.png",
		"res://assets/sprites/monsters/familiar/02.png",
		"res://assets/sprites/monsters/familiar/03.png",
		"res://assets/sprites/monsters/familiar/04.png",
		"res://assets/sprites/monsters/familiar/05.png",
		"res://assets/sprites/monsters/familiar/06.png",
		"res://assets/sprites/monsters/familiar/07.png",
	],
	"moonlight_flower": [
		"res://assets/sprites/monsters/moonlight_flower/00.png",
		"res://assets/sprites/monsters/moonlight_flower/01.png",
		"res://assets/sprites/monsters/moonlight_flower/02.png",
		"res://assets/sprites/monsters/moonlight_flower/03.png",
		"res://assets/sprites/monsters/moonlight_flower/04.png",
		"res://assets/sprites/monsters/moonlight_flower/05.png",
		"res://assets/sprites/monsters/moonlight_flower/06.png",
	],
	"rocker": [
		"res://assets/sprites/monsters/rocker/00.png",
		"res://assets/sprites/monsters/rocker/01.png",
		"res://assets/sprites/monsters/rocker/02.png",
		"res://assets/sprites/monsters/rocker/03.png",
		"res://assets/sprites/monsters/rocker/04.png",
		"res://assets/sprites/monsters/rocker/05.png",
		"res://assets/sprites/monsters/rocker/06.png",
	],
	"archer_skeleton": [
		"res://assets/sprites/monsters/archer_skeleton/00.png",
		"res://assets/sprites/monsters/archer_skeleton/01.png",
		"res://assets/sprites/monsters/archer_skeleton/02.png",
		"res://assets/sprites/monsters/archer_skeleton/03.png",
		"res://assets/sprites/monsters/archer_skeleton/04.png",
		"res://assets/sprites/monsters/archer_skeleton/05.png",
	],
	"orc_baby": [
		"res://assets/sprites/monsters/orc_baby/00.png",
		"res://assets/sprites/monsters/orc_baby/01.png",
		"res://assets/sprites/monsters/orc_baby/02.png",
	],
	"orc_warrior": [
		"res://assets/sprites/monsters/orc_warrior/00.png",
		"res://assets/sprites/monsters/orc_warrior/01.png",
		"res://assets/sprites/monsters/orc_warrior/02.png",
		"res://assets/sprites/monsters/orc_warrior/03.png",
		"res://assets/sprites/monsters/orc_warrior/04.png",
		"res://assets/sprites/monsters/orc_warrior/05.png",
	],
	"orc_lady": [
		"res://assets/sprites/monsters/orc_lady/00.png",
		"res://assets/sprites/monsters/orc_lady/01.png",
		"res://assets/sprites/monsters/orc_lady/02.png",
		"res://assets/sprites/monsters/orc_lady/03.png",
		"res://assets/sprites/monsters/orc_lady/04.png",
		"res://assets/sprites/monsters/orc_lady/05.png",
	],
	"orc_archer": [
		"res://assets/sprites/monsters/orc_archer/00.png",
		"res://assets/sprites/monsters/orc_archer/01.png",
		"res://assets/sprites/monsters/orc_archer/02.png",
		"res://assets/sprites/monsters/orc_archer/03.png",
		"res://assets/sprites/monsters/orc_archer/04.png",
		"res://assets/sprites/monsters/orc_archer/05.png",
	],
	"high_orc": [
		"res://assets/sprites/monsters/high_orc/00.png",
		"res://assets/sprites/monsters/high_orc/01.png",
		"res://assets/sprites/monsters/high_orc/02.png",
		"res://assets/sprites/monsters/high_orc/03.png",
		"res://assets/sprites/monsters/high_orc/04.png",
	],
	"orc_hero": [
		"res://assets/sprites/monsters/orc_hero/00.png",
		"res://assets/sprites/monsters/orc_hero/01.png",
		"res://assets/sprites/monsters/orc_hero/02.png",
		"res://assets/sprites/monsters/orc_hero/03.png",
		"res://assets/sprites/monsters/orc_hero/04.png",
		"res://assets/sprites/monsters/orc_hero/05.png",
	],
}


static func get_walk_frame_paths(monster_id: String) -> PackedStringArray:
	var raw: Variant = WALK_FRAMES.get(monster_id, [])
	if raw is PackedStringArray:
		return raw as PackedStringArray
	if raw is Array:
		var out: PackedStringArray = PackedStringArray()
		for p: Variant in raw:
			out.append(String(p))
		return out
	return PackedStringArray()


static func get_static_sprite_path(monster_id: String) -> String:
	var paths: PackedStringArray = get_walk_frame_paths(monster_id)
	if paths.size() > 0:
		return paths[0]
	return ""
