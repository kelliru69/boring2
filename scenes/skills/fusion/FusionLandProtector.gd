## Zona sagrada — el jugador ignora daño entrante mientras dura (fusión Sage).
extends Node2D

var _player: Player = null
var _radius: float = 130.0
var _duration: float = 7.0
var _elapsed: float = 0.0


func setup(player: Player, radius: float = 130.0, duration: float = 7.0) -> void:
	_player = player
	_radius = radius
	_duration = duration
	if _player and _player.has_method("activate_land_protector"):
		_player.activate_land_protector(duration)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return
	global_position = _player.global_position
	_elapsed += delta
	queue_redraw()
	if _elapsed >= _duration:
		queue_free()


func _draw() -> void:
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, Color(0.45, 0.85, 1.0, 0.22), 3.0)
