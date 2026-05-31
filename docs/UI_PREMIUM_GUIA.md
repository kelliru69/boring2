# Guía UI Premium — rosurvivor

Rediseño estético indie premium: paleta neón, tarjetas, blur de fondo y micro-interacciones.

---

## 1. Sistema de diseño global

### Paleta

| Uso | Color | Hex |
|-----|-------|-----|
| Fondo panel (glass) | Grafito semi-transparente | `#121824cc` |
| Borde / acento activo | Turquesa neón | `#00f0ff` |
| Texto principal | Blanco | `#ffffff` |
| Texto secundario | Gris plata | `#a0aec0` |
| Precio Zeny | Oro | `#ffd733` |

### Archivos del tema

| Archivo | Rol |
|---------|-----|
| `scripts/ui/modern_ui_theme.gd` | Paleta, StyleBoxes, helpers (`apply_button`, `apply_panel`, tweens hover) |
| `scripts/ui/premium_theme_builder.gd` | Construye `Theme` global para controles base |
| `autoload/UITheme.gd` | Aplica el tema al `root` al iniciar |
| `shaders/ui_backdrop_blur.gdshader` | Desenfoque BackBuffer para modales |

### Inspector — Autoload UITheme

1. **Proyecto → Configuración del proyecto → Autoload**
2. Verificar entrada: `UITheme` → `res://autoload/UITheme.gd`
3. Orden recomendado: `Global`, `Audio`, **`UITheme`**, `Arena`, `Game`

### Botones — estados

- **Normal:** fondo `#0f141f`, borde turquesa suave  
- **Hover:** fondo más claro + escala `1.05` (tween 0.1 s) + SFX hover  
- **Pressed:** tono saturado `#00596b` + escala vuelve a `1.0` en 0.06 s  

Aplicar en código: `ModernUITheme.apply_button(mi_boton, 44.0)`

---

## 2. Árboles de nodos por pantalla

### TitleScreen (`scenes/menu/TitleScreen.tscn`)

```
TitleScreen (Control) — script: TitleScreen.gd
├── Background (TextureRect)          ← PNG pantalla completa
├── Overlay (ColorRect)               ← viñeta oscura
├── MenuPanel (PanelContainer)
│   └── Margin (MarginContainer)
│       └── VBox (VBoxContainer)
│           ├── TitleLabel (Label)
│           ├── SubtitleLabel (Label)
│           ├── StartButton (Button)
│           ├── OptionsButton (Button)
│           └── QuitButton (Button)
└── OptionsPanel (CanvasLayer)        ← instancia de OptionsPanel.tscn
```

**Inspector — Background**

- `Texture`: `res://art/background.png` (o tu PNG)
- `Expand Mode`: Ignore Size
- `Stretch Mode`: Keep Aspect Covered

**Inspector — MenuPanel**

- Anclas: centro (`anchor 0.5`)
- `custom_minimum_size` implícito vía offsets ±240×±190

---

### OptionsPanel (`scenes/ui/OptionsPanel.tscn`)

```
OptionsPanel (CanvasLayer) — layer 20, process_mode Always
├── BackBufferCopy (copy_mode: Viewport)
├── Dimmer (ColorRect + ShaderMaterial ui_backdrop_blur)
└── PanelRoot (CenterContainer)
    └── Panel (PanelContainer)
        └── Margin (MarginContainer)
            └── VBox (VBoxContainer)
                ├── TitleLabel
                ├── MusicRow → MusicLabel + MusicHBox (Slider + %)
                ├── SfxRow → SfxLabel + SfxHBox (Slider + %)
                └── CloseButton
```

**Lógica:** `OptionsPanel.gd` — sliders 0–100 → `linear_to_db` → buses `Music` y `SFX`.

---

### ZenyShopPanel (`scenes/menu/ZenyShopPanel.tscn`)

```
ZenyShopPanel (Control)
└── Margin (MarginContainer)
    └── VBox (VBoxContainer)
        ├── Header (HBoxContainer)
        │   ├── ShopTitle (Label)
        │   └── ZenyLabel (Label)     ← oro, alineado derecha
        ├── HintLabel (Label)
        └── Scroll (ScrollContainer)
            └── List (VBoxContainer)  ← ShopItemCard instanciadas por código
```

**Tarjeta de artículo** (`scenes/ui/components/ShopItemCard.tscn`):

```
ShopItemCard (PanelContainer)
└── Margin → HBox
    ├── IconFrame (PanelContainer) → Icon (TextureRect)
    ├── Info (VBox) → Title, Desc, Level
    └── Actions (VBox) → Price (oro), MinusBtn, BuyBtn
```

---

### CardAlbumPanel (`scenes/menu/CardAlbumPanel.tscn`)

```
CardAlbumPanel (Control)
└── Margin → VBox
    ├── EquipHintTop, SlotsLabel, SlotsRow (Slot0…4)
    ├── AlbumLabel
    └── Body (HBoxContainer)
        ├── GridScroll → CardGrid (GridContainer)   ← CardGridEntry.tscn
        └── InspectPanel → arte + efectos pasivos
```

**Celda** (`CardGridEntry.tscn`): marco `PanelContainer` 108×148, miniatura 72×96, borde neón al seleccionar.

---

### RunSetupPanel / StageSelect (`scenes/menu/RunSetupPanel.tscn`)

```
RunSetupPanel (Control)
└── Margin → VBox
    ├── TitleLabel
    ├── ClassLabel
    ├── ClassRow (HBox) → MageButton, SwordButton
    ├── StageLabel
    ├── StageGrid (HBox)              ← StageSelectCard.tscn × N mapas
    ├── SummaryPanel (PanelContainer)
    └── LaunchButton
```

**Tarjeta de etapa** (`StageSelectCard.tscn`):

```
StageSelectCard (PanelContainer)
└── Margin → VBox
    ├── Preview (PanelContainer) → BgTint (ColorRect)  ← silueta/color del mapa
    ├── NameLabel
    ├── DifficultyLabel
    └── DescLabel
```

---

### PreparationHub (`scenes/menu/PreparationHub.tscn`)

```
PreparationHub (Control)
├── Background + Overlay
├── TopBarPanel → BackButton, ShopTab, CardsTab, RunTab
└── Panels
    ├── ZenyShopPanel (instancia)
    ├── CardAlbumPanel (instancia)
    └── RunSetupPanel (instancia)
```

---

## 3. Código clave (GDScript tipado)

### Panel de opciones — volumen real

Ver `scenes/ui/OptionsPanel.gd`:

```gdscript
func _set_bus_linear_percent(bus_name: StringName, percent: float) -> void:
    var idx: int = AudioServer.get_bus_index(bus_name)
    if idx < 0:
        return
    var linear: float = clampf(percent / 100.0, 0.0, 1.0)
    var db: float = -80.0 if linear <= 0.001 else linear_to_db(linear)
    AudioServer.set_bus_volume_db(idx, db)
```

Los buses se crean en `autoload/Audio.gd` (`Music`, `SFX`). BGM y SFX del juego enrutan a esos buses.

### Micro-interacciones de botón

Ver `scripts/ui/modern_ui_theme.gd` → `apply_button()`:

- `mouse_entered` → tween escala 1.05 + `Audio.play_ui_hover()`
- `mouse_exited` → tween escala 1.0
- `pressed` → pop rápido a escala 1.0

---

## 4. Checklist de implementación en Godot

1. Abrir proyecto; confirmar autoload **UITheme** activo.
2. Asignar `art/background.png` al `Background` de TitleScreen y PreparationHub.
3. Probar **Opciones** en menú principal: sliders deben cambiar música/SFX al instante.
4. En **Tienda Zeny**: cada fila es una tarjeta con precio dorado y botón Comprar.
5. En **Lanzar Run**: clic en tarjeta de mapa (borde neón = seleccionado) → Lanzar Run.
6. Pasar el mouse por botones: escala + sonido hover.

---

## 5. Personalización rápida

| Quieres cambiar… | Edita… |
|------------------|--------|
| Colores globales | Constantes en `modern_ui_theme.gd` |
| Blur del modal | `blur_lod` / `tint_color` en OptionsPanel → Dimmer → Material |
| Iconos de tienda | Pasar `Texture2D` en `ShopItemCard.setup(..., icon_tex)` |
| Tintes de mapas | Array `STAGES` en `RunSetupPanel.gd` |
| Título del juego | `TitleLabel` en TitleScreen |

---

## 6. Notas técnicas

- No hay `.theme` estático en disco: el tema se genera en runtime (más fácil de mantener con GDScript). Para exportar uno: en el editor, selecciona un Control con theme aplicado → **Theme → Save**.
- El blur requiere `BackBufferCopy` **antes** del `ColorRect` con shader; sin él el shader no ve la escena detrás.
- `apply_button` conecta señales una sola vez (`meta _premium_btn_fx`); los handlers de juego siguen llamando `Audio.play_ui_click()` en `pressed` aparte del pop visual.
