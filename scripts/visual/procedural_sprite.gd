## Asigna una textura procedural al Sprite2D en tiempo de ejecución.
extends Sprite2D

const _ShapeFactory = preload("res://scripts/util/shape_texture_factory.gd")

@export var shape: _ShapeFactory.Shape = _ShapeFactory.Shape.CIRCLE
@export var fill_color: Color = Color(0.4, 0.65, 1.0, 1.0)
@export var texture_size: int = 32
@export var display_scale: float = 1.0


func _ready() -> void:
	apply_visual(shape, fill_color)


func apply_visual(new_shape: _ShapeFactory.Shape, new_color: Color) -> void:
	shape = new_shape
	fill_color = new_color
	texture = _ShapeFactory.create(shape, texture_size, fill_color)
	scale = Vector2(display_scale, display_scale)
	centered = true
