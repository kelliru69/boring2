## Pantalla de inicio — fondo a pantalla completa y botones Dark Minimalist.
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const BACKGROUND_PATH: String = "res://art/background.png"

@onready var background: TextureRect = $Background
@onready var menu_panel: PanelContainer = $MenuPanel
@onready var title_label: Label = $MenuPanel/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $MenuPanel/Margin/VBox/SubtitleLabel
@onready var start_button: Button = $MenuPanel/Margin/VBox/StartButton
@onready var options_button: Button = $MenuPanel/Margin/VBox/OptionsButton
@onready var quit_button: Button = $MenuPanel/Margin/VBox/QuitButton
@onready var options_panel: CanvasLayer = $OptionsPanel


func _ready() -> void:
	_apply_visuals()
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _apply_visuals() -> void:
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH) as Texture2D
	else:
		background.texture = null
		$Overlay.color = _Theme.BG_VOID
	_Theme.apply_panel(menu_panel)
	_Theme.style_title(title_label, 32)
	_Theme.style_subtitle(subtitle_label, 14)
	subtitle_label.text = "test para kellinduras"
	for btn: Button in [start_button, options_button, quit_button]:
		_Theme.apply_button(btn, 44.0)


func _on_start_pressed() -> void:
	Audio.play_ui_click()
	Game.go_to_preparation()


func _on_options_pressed() -> void:
	Audio.play_ui_click()
	if options_panel.has_method("show_options"):
		options_panel.show_options()


func _on_quit_pressed() -> void:
	Audio.play_ui_click()
	get_tree().quit()
