## Datos de una clase de combate (Mage, Swordman, etc.). Resource independiente del avatar.
class_name ClassData
extends Resource

## Nombre visible en UI (ej. "Mage", "Swordman").
@export var display_name: String = ""

@export_multiline var description: String = ""

## Ilustración de fondo al enfocar esta clase en Class Select.
@export var class_background: Texture2D

## Icono en la tarjeta del scroll (opcional).
@export var icon_thumbnail: Texture2D

## ID de gameplay (Game.CLASS_MAGE, Game.CLASS_SWORDMAN, Game.JOB_WIZARD, etc.).
@export var class_id: String = ""

## Solo clases avanzadas bloqueadas en previews futuras; Mage/Swordman = true al inicio.
@export var is_selectable: bool = true

@export var lock_reason: String = "Disponible tras Job Change"


func get_class_name() -> String:
	return display_name


# --- DÓNDE PONER TUS PNG FINALES (CLASE) ---
# Inspector (ClassData.tres en resources/classes/):
#   • display_name      → "Mage" o "Swordman"
#   • description       → texto de la clase
#   • class_background  → ilustración de fondo al scrollear
#   • icon_thumbnail    → icono en tarjeta (~128×128)
#   • class_id          → mage | swordman (IDs en Game.gd)
# Wizard/Sage/Knight/Crusader se desbloquean en Job Change, no aquí.
