## Storm Gust — 50% de congelar 2 s en la explosión.
extends FrostDiveTravel


func _on_explosion_hit(body: Node2D) -> void:
	if body == null or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage, _HitFlash.ELEMENT_ICE)
	if randf() < 0.5 and body.has_method("apply_freeze"):
		body.apply_freeze(2.0, 0.0)
