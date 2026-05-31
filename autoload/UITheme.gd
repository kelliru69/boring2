## Aplica el tema premium global al árbol de UI al iniciar el juego.
extends Node

const _Builder = preload("res://scripts/ui/premium_theme_builder.gd")


func _ready() -> void:
	var theme: Theme = _Builder.build()
	get_tree().root.theme = theme
