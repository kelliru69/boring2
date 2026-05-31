## Genera texturas 2D simples (círculo / cuadrado) sin archivos externos.
class_name ShapeTextureFactory
extends RefCounted

enum Shape { CIRCLE, SQUARE }


static func create(shape: Shape, size: int, color: Color) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	match shape:
		Shape.CIRCLE:
			_draw_circle(image, size, color)
		Shape.SQUARE:
			_draw_square(image, size, color)
	return ImageTexture.create_from_image(image)


static func _draw_circle(image: Image, size: int, color: Color) -> void:
	var center: Vector2 = Vector2(float(size) * 0.5, float(size) * 0.5)
	var radius: float = float(size) * 0.5 - 1.0
	for y: int in size:
		for x: int in size:
			if Vector2(float(x), float(y)).distance_to(center) <= radius:
				image.set_pixel(x, y, color)


static func _draw_square(image: Image, size: int, color: Color) -> void:
	var margin: int = maxi(int(size / 8.0), 1)
	for y: int in range(margin, size - margin):
		for x: int in range(margin, size - margin):
			image.set_pixel(x, y, color)
