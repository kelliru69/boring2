## Capa 2D que sigue la cámara: números de daño y feedback flotante (encima del mapa/VFX).
extends CanvasLayer

const GROUP_ID: StringName = &"floating_combat_overlay"


func _ready() -> void:
	layer = 12
	follow_viewport_enabled = true
	add_to_group(GROUP_ID)
