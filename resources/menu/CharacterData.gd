## Datos de un avatar/personaje seleccionable (apariencia). No es la clase de combate.
class_name CharacterData
extends Resource

## Nombre visible del avatar (ej. "Maga", "Gato azul").
@export var character_name: String = ""

## ID interno estable (ej. char_mage_girl, char_blue_cat).
@export var character_id: String = ""

@export var icon_thumbnail: Texture2D
@export var large_splash: Texture2D
@export var menu_sprite_frames: SpriteFrames

## Skin del jugador al iniciar run (player_skin_catalog: mage_girl | blue_cat).
@export var default_skin_id: String = ""


# --- DÓNDE PONER TUS PNG / SPRITES (AVATAR) ---
# Inspector (CharacterData.tres en resources/characters/):
#   • character_name    → "Maga" o "Gato azul" (puedes usar "Female" si prefieres)
#   • character_id      → char_mage_girl | char_blue_cat
#   • default_skin_id   → mage_girl | blue_cat (debe coincidir con player_skin_catalog.gd)
#   • icon_thumbnail    → PNG cuadrado ~128×128 (cuadrícula)
#   • large_splash      → ilustración vertical grande (~480×720)
#   • menu_sprite_frames → opcional; si vacío, se genera desde default_skin_id
# Las CLASES (Mage/Swordman) se configuran en resources/classes/ o class_select_catalog.gd
