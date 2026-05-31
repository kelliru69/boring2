## Colisiones en el borde exterior del tilemap (impide salir del mapa visible).
class_name ArenaBoundaryWalls
extends RefCounted


static func rebuild(walls_root: StaticBody2D, wall_thickness: float = 32.0) -> void:
	if walls_root == null or not Arena.is_ready():
		return
	for child: Node in walls_root.get_children():
		child.queue_free()
	var rect: Rect2 = Arena.world_rect
	var left: float = rect.position.x
	var top: float = rect.position.y
	var width: float = rect.size.x
	var height: float = rect.size.y
	var t: float = wall_thickness
	_add_segment(walls_root, Vector2(left, top - t), Vector2(width, t))
	_add_segment(walls_root, Vector2(left, top + height), Vector2(width, t))
	_add_segment(walls_root, Vector2(left - t, top), Vector2(t, height))
	_add_segment(walls_root, Vector2(left + width, top), Vector2(t, height))


static func _add_segment(walls_root: StaticBody2D, origin: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	shape_node.position = origin + size * 0.5
	body.add_child(shape_node)
	walls_root.add_child(body)
