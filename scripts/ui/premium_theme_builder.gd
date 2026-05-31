## Construye el Theme global del proyecto (paleta premium indie).
class_name PremiumThemeBuilder
extends RefCounted

const _Palette = preload("res://scripts/ui/modern_ui_theme.gd")


static func build() -> Theme:
	var theme := Theme.new()
	var btn_styles: Dictionary = _Palette.make_button_styles()
	theme.set_stylebox(&"normal", &"Button", btn_styles["normal"])
	theme.set_stylebox(&"hover", &"Button", btn_styles["hover"])
	theme.set_stylebox(&"pressed", &"Button", btn_styles["pressed"])
	theme.set_stylebox(&"disabled", &"Button", btn_styles["disabled"])
	theme.set_stylebox(&"focus", &"Button", btn_styles["focus"])
	theme.set_color(&"font_color", &"Button", _Palette.TEXT_PRIMARY)
	theme.set_color(&"font_hover_color", &"Button", _Palette.ACCENT)
	theme.set_color(&"font_pressed_color", &"Button", _Palette.TEXT_PRIMARY)
	theme.set_color(&"font_disabled_color", &"Button", _Palette.TEXT_MUTED)
	theme.set_font_size(&"font_size", &"Button", 15)
	theme.set_stylebox(&"panel", &"PanelContainer", _Palette.make_panel_style())
	theme.set_color(&"font_color", &"Label", _Palette.TEXT_PRIMARY)
	theme.set_color(&"font_color", &"OptionButton", _Palette.TEXT_PRIMARY)
	theme.set_stylebox(&"normal", &"OptionButton", btn_styles["normal"])
	theme.set_stylebox(&"hover", &"OptionButton", btn_styles["hover"])
	theme.set_stylebox(&"pressed", &"OptionButton", btn_styles["pressed"])
	theme.set_color(&"font_color", &"HSlider", _Palette.TEXT_PRIMARY)
	theme.set_color(&"grabber_area_color", &"HSlider", _Palette.ACCENT * Color(1, 1, 1, 0.35))
	theme.set_color(&"grabber_area_highlight_color", &"HSlider", _Palette.ACCENT * Color(1, 1, 1, 0.65))
	return theme
