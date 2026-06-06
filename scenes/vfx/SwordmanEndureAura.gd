## Anillo defensivo visible mientras Endure está activo (hijo del VisualRoot del jugador).
extends Node2D

const _Vfx = preload("res://scripts/vfx/swordman_skill_vfx.gd")

@export var radius: float = 38.0


func _ready() -> void:
	_Vfx.setup_attached_vfx(self)
	position = Vector2.ZERO
	visible = false
	set_process(true)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var pulse: float = 0.86 + 0.14 * sin(Time.get_ticks_msec() * 0.012)
	_Vfx.draw_endure_shield(self, radius * pulse, pulse, 0.94)
