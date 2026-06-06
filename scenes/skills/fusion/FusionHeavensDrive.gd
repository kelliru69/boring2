## Heaven's Drive — línea recta enorme con ralentización severa (fusión Sage).
extends FrostDiveTravel


func _on_explosion_hit(body: Node2D) -> void:
	if body == null or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage, _HitFlash.ELEMENT_WIND)
	if body.has_method("apply_freeze"):
		body.apply_freeze(0.0, 0.72)


func _on_line_hit(body: Node2D) -> void:
	if body == null or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	var body_id: int = body.get_instance_id()
	if _hit_cooldowns.has(body_id):
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage, _HitFlash.ELEMENT_WIND)
		_hit_cooldowns[body_id] = hit_cooldown_sec
	if body.has_method("apply_freeze"):
		body.apply_freeze(0.0, 0.55)
