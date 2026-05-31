## Definición visual del jugador (Tiny RPG Soldier — 100×100 por celda).
class_name PlayerVisualCatalog
extends RefCounted

const CLASS_MAGE: String = "mage"
const CLASS_SWORDMAN: String = "swordman"

const SOLDIER_BASE: String = "res://assets/sprites/player/soldier/"
const FRAME_PX: int = 100


static func get_definition(class_id: String) -> Dictionary:
	var attack_file: String = "Soldier-Attack02.png"
	var attack_fps: float = 12.0
	var tint: Color = Color(0.72, 0.82, 1.12)
	if class_id == CLASS_SWORDMAN:
		attack_file = "Soldier-Attack01.png"
		attack_fps = 14.0
		tint = Color(1.0, 0.94, 0.88)
	return {
		"frame_px": FRAME_PX,
		"sheet_base": SOLDIER_BASE,
		"sprite_height": 52.0,
		"anim_default": "idle",
		"tint": tint,
		"animations": [
			{"name": "idle", "file": "Soldier-Idle.png", "fps": 6.0, "loop": true},
			{"name": "walk", "file": "Soldier-Walk.png", "fps": 10.0, "loop": true},
			{
				"name": "attack",
				"file": attack_file,
				"fps": attack_fps,
				"loop": false,
			},
			{"name": "hurt", "file": "Soldier-Hurt.png", "fps": 10.0, "loop": false},
			{"name": "death", "file": "Soldier-Death.png", "fps": 8.0, "loop": false},
		],
	}
