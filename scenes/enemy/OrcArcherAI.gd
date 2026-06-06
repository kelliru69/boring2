## Orc Archer — IA de arquero con flechas rojas.
class_name OrcArcherAI
extends ArcherAI


func _fire_arrow() -> void:
	if arrow_scene == null:
		return
	var arrow: Node = arrow_scene.instantiate()
	if arrow == null:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return
	parent.add_child(arrow)
	if arrow is Node2D:
		(arrow as Node2D).global_position = global_position
	if arrow is ArrowProjectil:
		var proj: ArrowProjectil = arrow as ArrowProjectil
		if proj.sprite:
			proj.sprite.modulate = Color(1.0, 0.22, 0.12, 1.0)
	if arrow.has_method("setup"):
		arrow.call("setup", _shot_target_world, ranged_damage, arrow_speed, self)
