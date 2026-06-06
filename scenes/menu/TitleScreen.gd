## Pantalla de inicio — fondo a pantalla completa y botones Dark Minimalist.
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _MenuEsc = preload("res://scripts/ui/menu_esc_handler.gd")
const BACKGROUND_PATH: String = "res://art/background.png"

@onready var background: TextureRect = $Background
@onready var menu_panel: PanelContainer = $MenuPanel
@onready var title_label: Label = $MenuPanel/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $MenuPanel/Margin/VBox/SubtitleLabel
@onready var start_button: Button = $MenuPanel/Margin/VBox/StartButton
@onready var scoreboard_button: Button = $MenuPanel/Margin/VBox/ScoreboardButton
@onready var options_button: Button = $MenuPanel/Margin/VBox/OptionsButton
@onready var quit_button: Button = $MenuPanel/Margin/VBox/QuitButton
@onready var update_banner: PanelContainer = $UpdateBanner
@onready var update_label: Label = $UpdateBanner/Margin/HBox/UpdateLabel
@onready var update_download_button: Button = $UpdateBanner/Margin/HBox/DownloadButton
@onready var update_dismiss_button: Button = $UpdateBanner/Margin/HBox/DismissButton
@onready var version_label: Label = $VersionLabel
@onready var options_panel: CanvasLayer = $OptionsPanel
@onready var scoreboard_panel: Control = $ScoreboardPanel


func _ready() -> void:
	_apply_visuals()
	start_button.pressed.connect(_on_start_pressed)
	scoreboard_button.pressed.connect(_on_scoreboard_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	update_download_button.pressed.connect(_on_update_download_pressed)
	update_dismiss_button.pressed.connect(_on_update_dismiss_pressed)
	ReleaseChecker.check_finished.connect(_on_release_check_finished)
	update_banner.hide()
	ReleaseChecker.check_for_update()


func _apply_visuals() -> void:
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH) as Texture2D
	else:
		background.texture = null
		$Overlay.color = _Theme.BG_VOID
	_Theme.apply_panel(menu_panel)
	_Theme.apply_panel(update_banner)
	_Theme.style_title(title_label, 32)
	_Theme.style_subtitle(subtitle_label, 14)
	subtitle_label.text = "test para kellinduras"
	_Theme.style_subtitle(update_label, 13)
	update_label.add_theme_color_override("font_color", _Theme.ZENY_GOLD)
	_Theme.style_subtitle(version_label, 11)
	version_label.text = "v%s" % ReleaseChecker.get_local_version()
	for btn: Button in [
		start_button,
		scoreboard_button,
		options_button,
		quit_button,
		update_download_button,
		update_dismiss_button,
	]:
		_Theme.apply_button(btn, 36.0)


func _on_release_check_finished(has_update: bool, latest_version: String, _download_url: String) -> void:
	if not has_update:
		update_banner.hide()
		return
	var local_version: String = ReleaseChecker.get_local_version()
	update_label.text = "Hay una versión nueva: %s (tienes %s)" % [latest_version, local_version]
	update_banner.show()


func _on_update_download_pressed() -> void:
	Audio.play_ui_click()
	ReleaseChecker.open_download_page()


func _on_update_dismiss_pressed() -> void:
	Audio.play_ui_click()
	ReleaseChecker.dismiss_update(ReleaseChecker.latest_version)
	update_banner.hide()


func _on_start_pressed() -> void:
	Audio.play_ui_click()
	Game.go_to_character_selection()


func _on_scoreboard_pressed() -> void:
	Audio.play_ui_click()
	if scoreboard_panel and scoreboard_panel.has_method("show_scoreboard"):
		scoreboard_panel.show_scoreboard()


func _on_options_pressed() -> void:
	Audio.play_ui_click()
	if scoreboard_panel and scoreboard_panel.visible and scoreboard_panel.has_method("hide_scoreboard"):
		scoreboard_panel.hide_scoreboard()
	if options_panel.has_method("show_options"):
		options_panel.show_options()


func _unhandled_input(event: InputEvent) -> void:
	if not _MenuEsc.is_back_pressed(event):
		return
	if scoreboard_panel and scoreboard_panel.visible and scoreboard_panel.has_method("hide_scoreboard"):
		scoreboard_panel.hide_scoreboard()
		_MenuEsc.mark_input_handled(self)
		return
	if options_panel.visible and options_panel.has_method("hide_options"):
		options_panel.hide_options()
		_MenuEsc.mark_input_handled(self)


func _on_quit_pressed() -> void:
	Audio.play_ui_click()
	get_tree().quit()
