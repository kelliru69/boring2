## Tema premium indie — paleta neón, tarjetas y micro-interacciones.
## Tema global: autoload UITheme + PremiumThemeBuilder.
class_name ModernUITheme
extends RefCounted

# --- Paleta premium ---
const BG_VOID: Color = Color(0.04, 0.05, 0.07, 1.0)
const PANEL_FILL: Color = Color(0.071, 0.094, 0.141, 0.8)       # #121824cc
const PANEL_BORDER: Color = Color(0.0, 0.941, 1.0, 0.45)        # turquesa
const ACCENT: Color = Color(0.0, 0.941, 1.0, 1.0)               # #00f0ff
const ACCENT_GLOW: Color = Color(0.0, 0.941, 1.0, 0.9)
const TEXT_PRIMARY: Color = Color(1.0, 1.0, 1.0, 1.0)
const TEXT_MUTED: Color = Color(0.627, 0.682, 0.753, 1.0)       # #a0aec0
const ZENY_GOLD: Color = Color(1.0, 0.843, 0.2, 1.0)
const CAMPAIGN_ZENY: Color = Color(1.0, 0.45, 0.28, 1.0)
const BTN_NORMAL: Color = Color(0.06, 0.08, 0.12, 0.95)
const BTN_HOVER: Color = Color(0.10, 0.14, 0.22, 0.98)
const BTN_PRESSED: Color = Color(0.0, 0.35, 0.42, 1.0)
const BTN_BORDER: Color = Color(0.0, 0.75, 0.85, 0.55)
const BTN_BORDER_HOVER: Color = Color(0.0, 0.941, 1.0, 0.95)
const DIMMER: Color = Color(0.02, 0.04, 0.08, 0.78)
const CARD_FILL: Color = Color(0.08, 0.11, 0.16, 0.92)
const CARD_HOVER: Color = Color(0.11, 0.15, 0.22, 0.98)
const CORNER_PANEL: int = 16
const CORNER_BUTTON: int = 12
const CORNER_CARD: int = 14
const BORDER_WIDTH: int = 2
const SHADOW_SIZE: int = 8
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.45)
const HOVER_SCALE: float = 1.05
const HOVER_TWEEN_SEC: float = 0.1


static func make_panel_style(
	fill: Color = PANEL_FILL,
	border: Color = PANEL_BORDER,
	corner: int = CORNER_PANEL,
	shadow: bool = true
) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_width_left = BORDER_WIDTH
	box.border_width_top = BORDER_WIDTH
	box.border_width_right = BORDER_WIDTH
	box.border_width_bottom = BORDER_WIDTH
	box.border_color = border
	box.set_corner_radius_all(corner)
	box.content_margin_left = 18.0
	box.content_margin_top = 16.0
	box.content_margin_right = 18.0
	box.content_margin_bottom = 16.0
	if shadow:
		box.shadow_size = SHADOW_SIZE
		box.shadow_color = SHADOW_COLOR
		box.shadow_offset = Vector2(0, 4)
	return box


static func make_button_styles() -> Dictionary:
	return {
		"normal": _button_style(BTN_NORMAL, BTN_BORDER),
		"hover": _button_style(BTN_HOVER, BTN_BORDER_HOVER),
		"pressed": _button_style(BTN_PRESSED, ACCENT_GLOW),
		"disabled": _button_style(Color(0.06, 0.07, 0.09, 0.45), Color(0.3, 0.35, 0.4, 0.25)),
		"focus": _button_style(BTN_HOVER, ACCENT_GLOW),
	}


static func make_card_style(hover: bool = false, selected: bool = false) -> StyleBoxFlat:
	var fill: Color = CARD_HOVER if hover else CARD_FILL
	var border: Color = ACCENT_GLOW if selected else PANEL_BORDER
	return make_panel_style(fill, border, CORNER_CARD, true)


static func apply_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override(&"panel", make_panel_style())


static func apply_cta_button(button: Button, min_height: float = 52.0) -> void:
	var glow := StyleBoxFlat.new()
	glow.bg_color = Color(0.0, 0.55, 0.62, 0.98)
	glow.border_color = ACCENT_GLOW
	glow.set_border_width_all(2)
	glow.set_corner_radius_all(CORNER_BUTTON)
	glow.shadow_size = 12
	glow.shadow_color = Color(0.0, 0.75, 0.85, 0.45)
	glow.shadow_offset = Vector2(0, 3)
	var hover := glow.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.0, 0.72, 0.82, 1.0)
	hover.border_color = Color(1.0, 1.0, 1.0, 0.35)
	button.add_theme_stylebox_override(&"normal", glow)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", _button_style(BTN_PRESSED, ACCENT_GLOW))
	button.add_theme_stylebox_override(&"disabled", make_button_styles()["disabled"])
	button.add_theme_stylebox_override(&"focus", hover)
	button.add_theme_color_override(&"font_color", TEXT_PRIMARY)
	button.add_theme_color_override(&"font_hover_color", TEXT_PRIMARY)
	button.add_theme_font_size_override(&"font_size", 17)
	button.custom_minimum_size.y = maxf(min_height, button.custom_minimum_size.y)


static func apply_button(button: Button, min_height: float = 44.0) -> void:
	var styles: Dictionary = make_button_styles()
	button.add_theme_stylebox_override(&"normal", styles["normal"])
	button.add_theme_stylebox_override(&"hover", styles["hover"])
	button.add_theme_stylebox_override(&"pressed", styles["pressed"])
	button.add_theme_stylebox_override(&"disabled", styles["disabled"])
	button.add_theme_stylebox_override(&"focus", styles["focus"])
	button.add_theme_color_override(&"font_color", TEXT_PRIMARY)
	button.add_theme_color_override(&"font_hover_color", ACCENT)
	button.add_theme_color_override(&"font_pressed_color", TEXT_PRIMARY)
	button.add_theme_color_override(&"font_disabled_color", TEXT_MUTED)
	button.add_theme_font_size_override(&"font_size", 15)
	button.custom_minimum_size.y = maxf(min_height, button.custom_minimum_size.y)
	button.pivot_offset = button.size * 0.5
	if not button.has_meta("_premium_btn_fx"):
		button.set_meta("_premium_btn_fx", true)
		button.mouse_entered.connect(_on_button_hover_enter.bind(button))
		button.mouse_exited.connect(_on_button_hover_exit.bind(button))
		button.pressed.connect(_on_button_pressed_pop.bind(button))


static func style_title(label: Label, size: int = 28) -> void:
	label.add_theme_color_override(&"font_color", TEXT_PRIMARY)
	label.add_theme_font_size_override(&"font_size", size)


static func style_subtitle(label: Label, size: int = 14) -> void:
	label.add_theme_color_override(&"font_color", TEXT_MUTED)
	label.add_theme_font_size_override(&"font_size", size)


static func style_body(label: Label, size: int = 13) -> void:
	label.add_theme_color_override(&"font_color", TEXT_PRIMARY)
	label.add_theme_font_size_override(&"font_size", size)


static func style_accent(label: Label, size: int = 13) -> void:
	label.add_theme_color_override(&"font_color", ACCENT)
	label.add_theme_font_size_override(&"font_size", size)


static func style_zeny(label: Label, size: int = 16) -> void:
	label.add_theme_color_override(&"font_color", ZENY_GOLD)
	label.add_theme_font_size_override(&"font_size", size)


static func style_campaign_zeny(label: Label, size: int = 16) -> void:
	label.add_theme_color_override(&"font_color", CAMPAIGN_ZENY)
	label.add_theme_font_size_override(&"font_size", size)


static func apply_slider(slider: HSlider) -> void:
	slider.add_theme_color_override(&"grabber_area_color", ACCENT * Color(1, 1, 1, 0.35))
	slider.add_theme_color_override(&"grabber_area_highlight_color", ACCENT * Color(1, 1, 1, 0.65))


static func wire_card_hover(card: PanelContainer) -> void:
	if card.has_meta("_card_hover"):
		return
	card.set_meta("_card_hover", true)
	card.mouse_entered.connect(func() -> void:
		card.add_theme_stylebox_override(&"panel", make_card_style(true))
	)
	card.mouse_exited.connect(func() -> void:
		card.add_theme_stylebox_override(&"panel", make_card_style(false))
	)


static func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_width_left = BORDER_WIDTH
	box.border_width_top = BORDER_WIDTH
	box.border_width_right = BORDER_WIDTH
	box.border_width_bottom = BORDER_WIDTH
	box.border_color = border
	box.set_corner_radius_all(CORNER_BUTTON)
	box.content_margin_left = 20.0
	box.content_margin_top = 10.0
	box.content_margin_right = 20.0
	box.content_margin_bottom = 10.0
	box.shadow_size = 5
	box.shadow_color = SHADOW_COLOR
	box.shadow_offset = Vector2(0, 2)
	return box


static func _on_button_hover_enter(button: Button) -> void:
	if button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	var tween: Tween = button.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), HOVER_TWEEN_SEC)
	Audio.play_ui_hover()


static func _on_button_hover_exit(button: Button) -> void:
	var tween: Tween = button.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, HOVER_TWEEN_SEC)


static func _on_button_pressed_pop(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	var tween: Tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.06).set_trans(Tween.TRANS_BACK)


## Iconos/labels no bloquean clics: el Control raíz (tarjeta) recibe gui_input.
static func pass_clicks_to_root(root: Control) -> void:
	for child: Node in root.get_children():
		_set_mouse_ignore_recursive(child)


static func _set_mouse_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_set_mouse_ignore_recursive(child)
