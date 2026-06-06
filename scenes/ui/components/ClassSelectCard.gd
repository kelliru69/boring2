## Tarjeta de clase en CharacterSelection.
class_name ClassSelectCard
extends PanelContainer

signal class_chosen(class_id: String)

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

var _class_id: String = ""
var _available: bool = true

@onready var _portrait: TextureRect = $Margin/VBox/PortraitFrame/Portrait
@onready var _name_label: Label = $Margin/VBox/NameLabel
@onready var _tagline: Label = $Margin/VBox/TaglineLabel
@onready var _skills_box: VBoxContainer = $Margin/VBox/SkillsBox
@onready var _lock_overlay: ColorRect = $LockOverlay
@onready var _soon_label: Label = $LockOverlay/SoonLabel


func _ready() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style())
	_Theme.style_title(_name_label, 22)
	_Theme.style_accent(_tagline, 13)
	_Theme.style_subtitle(_soon_label, 28)
	_soon_label.text = "¡Pronto!"
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	_lock_overlay.visible = false
	_lock_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_Theme.pass_clicks_to_root(self)


func setup(entry: Dictionary) -> void:
	_class_id = String(entry.get("class_id", ""))
	_available = bool(entry.get("available", false))
	_name_label.text = String(entry.get("display_name", _class_id))
	_tagline.text = String(entry.get("tagline", ""))
	var portrait_path: String = String(entry.get("portrait_path", ""))
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		_portrait.texture = load(portrait_path) as Texture2D
	else:
		_portrait.texture = null
	for child: Node in _skills_box.get_children():
		child.queue_free()
	for line: Variant in entry.get("skill_lines", []):
		var lbl := Label.new()
		lbl.text = String(line)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_Theme.style_body(lbl, 12)
		_skills_box.add_child(lbl)
	_apply_lock_state()


func _apply_lock_state() -> void:
	_lock_overlay.visible = not _available
	modulate = Color.WHITE if _available else Color(0.45, 0.45, 0.5, 1.0)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _available else Control.CURSOR_FORBIDDEN


func _on_gui_input(event: InputEvent) -> void:
	if not _available:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Audio.play_ui_click()
		class_chosen.emit(_class_id)


func _on_hover_enter() -> void:
	if _available:
		add_theme_stylebox_override(&"panel", _Theme.make_card_style(true))


func _on_hover_exit() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false))
