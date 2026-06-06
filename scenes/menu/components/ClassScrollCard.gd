## Tarjeta de clase dentro del ScrollContainer horizontal.
class_name ClassScrollCard
extends PanelContainer

signal card_focused(class_data: ClassData)

var class_data: ClassData = null

@onready var _icon: TextureRect = $Margin/VBox/IconRect
@onready var _title: Label = $Margin/VBox/TitleLabel
@onready var _subtitle: Label = $Margin/VBox/SubtitleLabel


func _ready() -> void:
	_apply_borderless_panel()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_borderless_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	add_theme_stylebox_override(&"panel", style)


func setup(data: ClassData) -> void:
	class_data = data
	if class_data == null:
		return
	_title.text = class_data.display_name
	if class_data.icon_thumbnail != null:
		_icon.texture = class_data.icon_thumbnail
		_icon.visible = true
	else:
		_icon.visible = false
	if class_data.is_selectable:
		_subtitle.text = "Disponible"
	else:
		_subtitle.text = class_data.lock_reason
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_on_focus_entered)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		grab_focus()
		_emit_focus()


func _on_mouse_entered() -> void:
	grab_focus()


func _on_focus_entered() -> void:
	_emit_focus()


func _emit_focus() -> void:
	if class_data != null:
		card_focused.emit(class_data)


func apply_selection_visual(selected: bool, tween_host: Node) -> void:
	var target_scale: Vector2 = Vector2.ONE * (1.1 if selected else 1.0)
	var target_alpha: float = 1.0 if selected else 0.5
	if tween_host == null or not is_instance_valid(tween_host):
		scale = target_scale
		modulate.a = target_alpha
		return
	var tw: Tween = tween_host.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", target_scale, 0.18)
	tw.tween_property(self, "modulate:a", target_alpha, 0.18)
