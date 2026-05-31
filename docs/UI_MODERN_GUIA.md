# Guía UI moderna (Dark Minimalist) — Godot 4.6

Estilo centralizado en `scripts/ui/modern_ui_theme.gd`. No uses los paneles grises por defecto: aplica `ModernUITheme.apply_panel()` / `apply_button()` en `_ready()` o crea `StyleBoxFlat` manualmente.

---

## Paleta rápida

| Uso | Color aprox. |
|-----|----------------|
| Fondo void | `#0A0D14` |
| Panel | `rgba(20, 26, 36, 0.88)` |
| Borde acento | azul `#5990F2` ~45% alpha |
| Texto | `#F0F5FA` |
| Texto muted | `#949FA8` |

---

## StyleBoxFlat en el Inspector (paso a paso)

1. Selecciona un **Button** o **PanelContainer**.
2. Inspector → **Theme Overrides** → **Styles** → elige el estado (`normal`, `hover`, `pressed`, `panel`).
3. Clic en **[empty]** → **New StyleBoxFlat**.
4. Expande el recurso y configura:

### Panel / tarjeta

| Propiedad | Valor recomendado |
|-----------|-------------------|
| **Bg Color** | `(0.08, 0.10, 0.14, 0.88)` |
| **Border Width** (Left/Top/Right/Bottom) | `1` px cada uno |
| **Border Color** | `(0.35, 0.55, 0.95, 0.45)` |
| **Corner Radius** → **All** | Panel: `14` · Botón: `10` · Tarjeta: `12` |
| **Shadow** → **Size** | `6` |
| **Shadow** → **Color** | `(0, 0, 0, 0.35)` |
| **Shadow** → **Offset** | `(0, 3)` |
| **Content Margin** | `14–18` px (padding interno) |

### Botón — tres estados

Crea **tres** StyleBoxFlat (normal / hover / pressed):

| Estado | Bg Color | Border Color |
|--------|----------|--------------|
| Normal | `(0.11, 0.14, 0.20, 0.92)` | blanco-azul `(0.55, 0.75, 1.0, 0.35)` |
| Hover | `(0.16, 0.22, 0.32, 0.96)` | `(0.65, 0.85, 1.0, 0.75)` |
| Pressed | `(0.08, 0.12, 0.18, 1.0)` | acento más intenso |

En **Theme Overrides → Colors**: `font_color`, `font_hover_color`, `font_pressed_color`.

Animación hover por código (ya en `ModernUITheme.apply_button`): escala `1.0 → 1.02` con Tween 0.12 s.

---

## StyleBoxFlat por código (botón)

```gdscript
var box := StyleBoxFlat.new()
box.bg_color = Color(0.11, 0.14, 0.20, 0.92)
box.set_corner_radius_all(10)
box.border_width_left = 1
box.border_width_top = 1
box.border_width_right = 1
box.border_width_bottom = 1
box.border_color = Color(0.55, 0.75, 1.0, 0.35)
box.shadow_size = 4
box.shadow_color = Color(0, 0, 0, 0.35)
box.shadow_offset = Vector2(0, 2)
button.add_theme_stylebox_override(&"normal", box)
```

Estados hover/pressed: duplica el box, cambia `bg_color` y `border_color`, asigna a `"hover"` y `"pressed"`.

Atajo: `ModernUITheme.apply_button(mi_boton)`.

---

## TitleScreen

| Nodo | Inspector |
|------|-----------|
| `Background` (TextureRect) | **Expand Mode**: Ignore Size · **Stretch Mode**: Keep Aspect Covered |
| Textura | Coloca `res://art/background.png` |
| `Overlay` (ColorRect) | Alpha ~0.55 para legibilidad del menú |
| `MenuPanel` | Estilizado en código con `apply_panel()` |

---

## Level Up — tarjetas (`UpgradeChoiceCard.tscn`)

- Contenedor: **PanelContainer** + **MarginContainer** + **VBoxContainer**.
- Título: color acento, 16 px (simula negrita).
- Descripción: gris muted, `autowrap_mode = Word`.
- Hover: borde más claro + scale 1.03 (script).

---

## Álbum de cartas (`CardAlbumPanel.tscn`)

### Carpetas de imágenes

```
res://art/
  background.png
  cards/
    carta_poring.png
    card_poring.png
    carta_osiris.png
res://assets/sprites/cards/
```

`CardVisualCatalog.load_texture("carta_poring")` prueba rutas en orden. El nombre del PNG debe coincidir con el ID de carta.

### Grid

- **GridContainer** → **Columns**: `4`
- **H/V Separation**: `12`
- Carta bloqueada: silueta oscura + candado sobre la miniatura.

### Panel de inspección

- **TextureRect** → min 240×320, **Stretch Mode**: Keep Aspect Centered.
- Labels con `ModernUITheme.style_title` / `style_body` / `style_accent`.

---

## Audio

| Archivo | Ruta |
|---------|------|
| Level up | `res://audio/level_up.mp3` |
| Golpes | `res://audio/hit/hit_01.wav`, `hit_02.wav`, … |

### HitSoundPlayer (Player / Enemy)

Inspector en **HitSoundPlayer** (`AudioStreamPlayer2D`):

| Propiedad | Valor |
|-----------|-------|
| **Max Polyphony** | `8` (jugador) · `10` (enemigo) |
| **Sound Paths** | array de rutas |
| **Pitch Random Range** | `0.08–0.12` |
| **Volume Db Offset** | `-2` a `-6` |

`max_polyphony` permite superponer golpes sin cortar el stream anterior.

---

## Checklist al pulir una escena nueva

1. `TextureRect` + overlay semitransparente en lugar de grises planos.
2. `PanelContainer` + `ModernUITheme.apply_panel()`.
3. Botones → `apply_button()`.
4. Labels → `style_title` / `style_subtitle` / `style_body`.
5. Dimmer pausa/level-up → `ModernUITheme.DIMMER`.
