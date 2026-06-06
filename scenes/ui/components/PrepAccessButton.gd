## Botón flotante: abre álbum de cartas y tienda Zeny desde cualquier menú de preparación.
class_name PrepAccessButton
extends Button

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _PrepOverlayScene: PackedScene = preload("res://scenes/menu/PrepQuickAccessOverlay.tscn")

var _overlay: Control = null


func _ready() -> void:
	text = "Cartas / Tienda"
	anchors_preset = Control.PRESET_TOP_RIGHT
	offset_left = -190.0
	offset_top = 10.0
	offset_right = -10.0
	offset_bottom = 46.0
	grow_horizontal = 0
	_Theme.apply_button(self, 36.0)
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	Audio.play_ui_click()
	if _overlay == null or not is_instance_valid(_overlay):
		_overlay = _PrepOverlayScene.instantiate() as Control
		get_tree().root.add_child(_overlay)
	if _overlay.has_method("open"):
		_overlay.call("open")


## Añade el botón flotante a cualquier pantalla de menú/preparación.
static func attach_to(host: Control) -> PrepAccessButton:
	if host == null:
		return null
	var existing: Node = host.get_node_or_null("PrepAccessButton")
	if existing is PrepAccessButton:
		return existing as PrepAccessButton
	var btn := PrepAccessButton.new()
	btn.name = "PrepAccessButton"
	host.add_child(btn)
	return btn
