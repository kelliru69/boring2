## Sacudida de cámara con decaimiento — enlazar al Camera2D de Main.
extends Camera2D
class_name CameraShakeController

var _shake_intensity: float = 0.0
var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0


func shake_camera(intensity: float, duration: float) -> void:
	if duration <= 0.0 or intensity <= 0.0:
		return
	if intensity >= _shake_intensity or _shake_time_left <= 0.0:
		_shake_intensity = intensity
		_shake_duration = duration
	_shake_time_left = maxf(_shake_time_left, duration)


func _physics_process(delta: float) -> void:
	if _shake_time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time_left -= delta
	var falloff: float = clampf(_shake_time_left / maxf(_shake_duration, 0.001), 0.0, 1.0)
	var amount: float = _shake_intensity * falloff * falloff
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * amount
	if _shake_time_left <= 0.0:
		_shake_intensity = 0.0
		offset = Vector2.ZERO


static func shake_active_scene(intensity: float, duration: float) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var cam: Node = tree.current_scene.get_node_or_null("Camera2D")
	if cam is CameraShakeController:
		(cam as CameraShakeController).shake_camera(intensity, duration)
	elif cam != null and cam.has_method("shake_camera"):
		cam.call("shake_camera", intensity, duration)
