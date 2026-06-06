# Guía de assets — Character Select + Class Select

## Conceptos

| Pantalla | Qué eliges | Ejemplos |
|----------|-----------|----------|
| **Character Select** | Avatar / apariencia | Maga, Gato azul |
| **Class Select** | Clase de combate | Mage, Swordman |

Cualquier avatar puede jugar cualquier clase inicial. Las evoluciones (Wizard, Sage, Knight, Crusader) son **Job Change** en partida.

---

## CharacterData — avatares (`resources/characters/`)

| Propiedad | Qué arrastrar |
|-----------|---------------|
| **Character Name** | "Maga" o "Gato azul" |
| **Character Id** | `char_mage_girl` / `char_blue_cat` |
| **Default Skin Id** | `mage_girl` / `blue_cat` (`player_skin_catalog.gd`) |
| **Icon Thumbnail** | PNG ~128×128 (cuadrícula) |
| **Large Splash** | Ilustración vertical ~480×720 |

Rutas sugeridas:
- `art/characters/mage_girl/mage_girl_icon.png`
- `art/characters/mage_girl/mage_girl_splash.png`
- `art/characters/blue_cat/blue_cat_icon.png`
- `art/characters/blue_cat/blue_cat_splash.png`

---

## ClassData — clases (`resources/classes/`)

| Propiedad | Qué arrastrar |
|-----------|---------------|
| **Display Name** | "Mage" o "Swordman" |
| **Class Id** | `mage` / `swordman` (constantes en `Game.gd`) |
| **Description** | Texto de la clase |
| **Class Background** | Ilustración de fondo al scrollear |
| **Icon Thumbnail** | Icono en tarjeta (~128×128) |

---

## Sin crear .tres (solo cambiar rutas en código)

Avatares: `data/character_select_catalog.gd`  
Clases: `data/class_select_catalog.gd`

---

## Flujo

`TitleScreen` → `CharacterSelect` (avatar) → `ClassSelect` (clase) → `Main` (Mapa 1)
