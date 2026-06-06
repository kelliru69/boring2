## Cursor temático Ragnarok (ro_cursor.png) en menús, mapas y toda la UI.
extends Node

const CURSOR_PATH: String = "res://art/ui/ro_cursor.png"
const CURSOR_HOTSPOT: Vector2 = Vector2(0.0, 0.0)
## Escala del PNG respecto al original (0.3 = 75% del tamaño previo de 0.4).
const CURSOR_SCALE: float = 0.3

var _using_custom: bool = false
var _cached_texture: Texture2D = null


func _ready() -> void:
	apply_game_cursor()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_restore_system_cursor()


## Aplica ro_cursor.png — llamar al entrar a cualquier escena del juego.
func apply_game_cursor() -> void:
	_apply_custom_cursor()


func apply_in_game() -> void:
	apply_game_cursor()


## Compatibilidad con código antiguo que llamaba clear_custom_cursor en menús.
func clear_custom_cursor() -> void:
	apply_game_cursor()


func _apply_custom_cursor() -> void:
	if _cached_texture != null:
		_set_custom_cursor_texture(_cached_texture)
		return
	if not ResourceLoader.exists(CURSOR_PATH):
		push_warning("RoCursor: falta %s — coloca el PNG o ajusta CURSOR_PATH." % CURSOR_PATH)
		_restore_system_cursor()
		return
	var source: Texture2D = load(CURSOR_PATH) as Texture2D
	if source == null:
		push_warning("RoCursor: no se pudo cargar %s" % CURSOR_PATH)
		_restore_system_cursor()
		return
	_cached_texture = _build_scaled_cursor_texture(source)
	if _cached_texture == null:
		_restore_system_cursor()
		return
	_set_custom_cursor_texture(_cached_texture)


func _set_custom_cursor_texture(tex: Texture2D) -> void:
	var hotspot: Vector2 = CURSOR_HOTSPOT * CURSOR_SCALE
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, hotspot)
	_using_custom = true


func _restore_system_cursor() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_using_custom = false


func _build_scaled_cursor_texture(source: Texture2D) -> Texture2D:
	var image: Image = source.get_image()
	if image == null or image.is_empty():
		return null
	var new_w: int = maxi(int(round(float(image.get_width()) * CURSOR_SCALE)), 1)
	var new_h: int = maxi(int(round(float(image.get_height()) * CURSOR_SCALE)), 1)
	if new_w == image.get_width() and new_h == image.get_height():
		return source
	image = image.duplicate()
	image.resize(new_w, new_h, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)
