## Pantalla 1 — Selección de avatar estilo arcade (splash vertical + cuadrícula bloqueada).
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _MenuEsc = preload("res://scripts/ui/menu_esc_handler.gd")
const _Catalog = preload("res://data/character_select_catalog.gd")
const _SlotScene: PackedScene = preload("res://scenes/menu/components/CharacterSelectSlot.tscn")
const BACKGROUND_PATH: String = "res://art/background.png"

@onready var background: TextureRect = $Background
@onready var preview_hbox: HBoxContainer = $RootMargin/MainHBox/PreviewHBox
@onready var splash_holder: Control = $RootMargin/MainHBox/PreviewHBox/SplashHolder
@onready var splash_rect: TextureRect = $RootMargin/MainHBox/PreviewHBox/SplashHolder/SplashRect
@onready var splash_fade: ColorRect = $RootMargin/MainHBox/PreviewHBox/SplashHolder/SplashFade
@onready var sprite_host: Control = $RootMargin/MainHBox/PreviewHBox/SpriteColumn/SpriteHost
@onready var menu_sprite: AnimatedSprite2D = $RootMargin/MainHBox/PreviewHBox/SpriteColumn/SpriteHost/MenuSprite
@onready var preview_name: Label = $RootMargin/MainHBox/PreviewHBox/SpriteColumn/PreviewName
@onready var right_panel: PanelContainer = $RootMargin/MainHBox/RightPanel
@onready var title_label: Label = $RootMargin/MainHBox/RightPanel/RightMargin/RightVBox/TitleLabel
@onready var hint_label: Label = $RootMargin/MainHBox/RightPanel/RightMargin/RightVBox/HintLabel
@onready var character_grid: GridContainer = $RootMargin/MainHBox/RightPanel/RightMargin/RightVBox/GridScroll/CharacterGrid
@onready var action_bar_layer: PanelContainer = $ActionBarLayer
@onready var back_button: Button = $ActionBarLayer/ActionBar/BackButton
@onready var confirm_button: Button = $ActionBarLayer/ActionBar/ConfirmButton

var _characters: Array[CharacterData] = []
var _selected: CharacterData = null
var _slots: Array[CharacterSelectSlot] = []
var _preview_tween: Tween = null


func _ready() -> void:
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH) as Texture2D
	splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_setup_action_bar()
	_Theme.apply_panel(right_panel)
	_Theme.style_title(title_label, 28)
	title_label.text = "SELECT YOUR AVATAR"
	_Theme.style_subtitle(hint_label, 13)
	hint_label.text = "Elige un avatar · Pulsa CONTINUAR para seguir"
	_Theme.style_title(preview_name, 24)
	back_button.pressed.connect(_on_back_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	_characters = _Catalog.get_all_characters()
	_build_grid()
	if not _characters.is_empty():
		_select_character(_characters[0], false)
		_focus_first_unlocked()
	preview_hbox.resized.connect(_layout_preview)
	call_deferred("_layout_preview")


func _setup_action_bar() -> void:
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.04, 0.06, 0.1, 0.92)
	bar_style.border_color = Color(0.0, 0.75, 0.85, 0.55)
	bar_style.set_border_width_all(1)
	bar_style.set_corner_radius_all(10)
	bar_style.content_margin_left = 14.0
	bar_style.content_margin_top = 8.0
	bar_style.content_margin_right = 14.0
	bar_style.content_margin_bottom = 8.0
	action_bar_layer.add_theme_stylebox_override(&"panel", bar_style)
	action_bar_layer.z_index = 20
	action_bar_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_Theme.apply_button(back_button, 48.0)
	_Theme.apply_cta_button(confirm_button, 48.0)
	confirm_button.text = "CONTINUAR"
	confirm_button.disabled = false
	back_button.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_button.mouse_filter = Control.MOUSE_FILTER_STOP


func _build_grid() -> void:
	for child: Node in character_grid.get_children():
		child.queue_free()
	_slots.clear()
	character_grid.columns = _Catalog.ROSTER_COLUMNS
	var roster: Array = _Catalog.get_roster_entries()
	for entry: Variant in roster:
		var slot: CharacterSelectSlot = _SlotScene.instantiate() as CharacterSelectSlot
		character_grid.add_child(slot)
		if entry is CharacterData:
			slot.setup(entry as CharacterData)
			slot.slot_focused.connect(_on_slot_focused)
		else:
			slot.setup_locked()
		_slots.append(slot)


func _focus_first_unlocked() -> void:
	for slot: CharacterSelectSlot in _slots:
		if not slot.is_locked:
			slot.grab_focus()
			return


func _on_slot_focused(character: CharacterData) -> void:
	_select_character(character, true)


func _select_character(character: CharacterData, animate: bool) -> void:
	if character == null:
		return
	_selected = character
	for slot: CharacterSelectSlot in _slots:
		slot.set_highlighted(not slot.is_locked and slot.character_data == character)
	preview_name.text = character.character_name
	_update_preview_visuals(character, animate)


func _update_preview_visuals(character: CharacterData, animate: bool) -> void:
	if character == null:
		return
	if character.large_splash != null:
		splash_rect.texture = character.large_splash
	if character.menu_sprite_frames != null:
		menu_sprite.sprite_frames = character.menu_sprite_frames
		var idle_anim: StringName = &"idle"
		if menu_sprite.sprite_frames.has_animation(&"idle_down"):
			idle_anim = &"idle_down"
		elif not menu_sprite.sprite_frames.has_animation(&"idle"):
			idle_anim = menu_sprite.sprite_frames.get_animation_name(0)
		menu_sprite.play(idle_anim)
	_layout_preview()
	if not animate:
		splash_fade.modulate.a = 0.0
		return
	if _preview_tween != null and _preview_tween.is_valid():
		_preview_tween.kill()
	splash_fade.modulate.a = 1.0
	_preview_tween = create_tween()
	_preview_tween.tween_property(splash_fade, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _layout_preview() -> void:
	if preview_hbox == null or splash_holder == null:
		return
	var area_h: float = preview_hbox.size.y
	if area_h < 32.0:
		return
	var splash_w: float = area_h * 0.42
	if splash_rect.texture != null:
		var tex: Texture2D = splash_rect.texture
		if tex.get_height() > 0:
			splash_w = area_h * (float(tex.get_width()) / float(tex.get_height()))
	splash_w = clampf(splash_w, 140.0, preview_hbox.size.x * 0.58)
	splash_holder.custom_minimum_size = Vector2(splash_w, area_h)
	splash_rect.size = Vector2(splash_w, area_h)
	splash_rect.position = Vector2.ZERO
	splash_fade.size = splash_rect.size
	splash_fade.position = splash_rect.position
	if sprite_host != null and menu_sprite != null:
		var sprite_scale: float = clampf(area_h / 300.0, 4.0, 8.0)
		menu_sprite.scale = Vector2(sprite_scale, sprite_scale)
		menu_sprite.position = Vector2(sprite_host.size.x * 0.5, sprite_host.size.y * 0.62)


func _on_confirm_pressed() -> void:
	Audio.play_ui_click()
	_confirm_selection()


func _confirm_selection() -> void:
	if _selected == null:
		return
	Global.select_character(_selected)
	Game.go_to_class_selection()


func _on_back_pressed() -> void:
	Audio.play_ui_click()
	Game.go_to_title()


func _unhandled_input(event: InputEvent) -> void:
	if _MenuEsc.is_back_pressed(event):
		_on_back_pressed()
		_MenuEsc.mark_input_handled(self)
