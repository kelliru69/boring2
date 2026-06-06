## Anillo de escarcha expandiéndose (Frost Diver impacto).
extends Node2D
class_name FrostExplosionRingFx

var _radius: float = 48.0
var _duration: float = 0.35
var _elapsed: float = 0.0


func setup(blast_radius: float, duration: float = 0.35) -> void:
	_radius = blast_radius
	_duration = maxf(duration, 0.05)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= _duration:
		queue_free()


func _draw() -> void:
	MageSkillVfx.draw_frost_explosion_ring(self, _radius, _elapsed / _duration, 1.0 - _elapsed / _duration)
