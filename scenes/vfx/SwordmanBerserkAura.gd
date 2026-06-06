## Aura rojiza ligera cuando Auto Berserk está activo y HP < 40%.
extends Node2D

@onready var _particles: CPUParticles2D = $CPUParticles2D


func _ready() -> void:
	visible = false
	if _particles:
		_particles.emitting = false


func set_active(active: bool) -> void:
	visible = active
	if _particles:
		_particles.emitting = active
