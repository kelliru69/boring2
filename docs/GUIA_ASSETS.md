# Guía: añadir sprites de monstruos y cartas

Esta guía explica cómo reemplazar los **cuadrados de colores** por tus propias imágenes.

---

## 1. Estructura de carpetas

Crea (o usa) estas rutas dentro del proyecto:

```
rosurvivor/
└── assets/
    └── sprites/
        ├── monsters/
        │   ├── poring.png          # sprite fijo (opcional)
        │   ├── poring/             # animación walk (opcional)
        │   │   ├── 00.png
        │   │   └── 01.png
        │   ├── lunatic.png
        │   └── fabre.png
        └── cards/
            ├── carta_poring.png
            ├── carta_lunatic.png
            └── carta_fabre.png
```

Los nombres deben coincidir con los del juego (minúsculas, sin espacios).

---

## 2. Formatos recomendados

| Formato | Uso |
|---------|-----|
| **PNG** | Recomendado (transparencia) |
| WebP | Válido en Godot 4 |
| SVG | Válido (se importa como textura) |

Tamaño sugerido:
- **Monstruos:** 32×32 hasta 64×64 px (fondo transparente).
- **Cartas:** ~24×32 px (proporción vertical tipo carta RO).

---

## 3. Jugador (Mage y Swordman) — Tiny RPG Soldier

El juego usa el pack **Tiny RPG Soldier** (celdas **100×100** por frame):

```
assets/sprites/player/soldier/
├── Soldier-Idle.png      # 6 frames (600×100)
├── Soldier-Walk.png      # 8 frames (800×100)
├── Soldier-Attack01.png  # Swordman — ataque cuerpo a cuerpo
├── Soldier-Attack02.png  # Mage — ataque a distancia
├── Soldier-Hurt.png
└── Soldier-Death.png
```

Configuración en `data/player_visual_catalog.gd` (FPS, tinte por clase, rutas).

### Importar en Godot

1. Abre el proyecto → selecciona una hoja en `soldier/`.
2. **Importar** → **Filtro: Nearest** (pixel art).
3. **Volver a importar** en todas las hojas del soldado.

### Ajustar tamaño en pantalla

- `scenes/player/Player.tscn` → **Sprite Height** (por defecto `52`).

### Diferencia Mage / Swordman

Misma base **Soldier**; el Swordman usa `Attack01`, el Mage `Attack02`, con un ligero **modulate** (tinte frío / cálido).

---

## 4. Monstruos — paso a paso

### A) Importar la imagen

1. Copia `poring.png` en `assets/sprites/monsters/`.
2. Abre Godot; en el panel **Sistema de archivos** verás el archivo.
3. Clic en la imagen → pestaña **Importar**:
   - **Filtro:** Nearest (pixel art) o Linear (arte suave).
   - Activa **Fix Alpha Border** si ves bordes raros.
4. Pulsa **Volver a importar**.

### B) Comprobar la ruta en código

En `data/enemy_catalog.gd` cada monstruo tiene:

```gdscript
"sprite_path": "res://assets/sprites/monsters/poring.png",
"sprite_height": 30.0,
```

- **sprite_path:** ruta al archivo.
- **sprite_height:** altura en pantalla (en píxeles del juego); el ancho se escala solo.

Si tu archivo tiene otro nombre, cambia solo `sprite_path`.

### C) Probar

Pulsa **F5**. Si el PNG existe, verás el sprite; si no, seguirá el cuadrado de color.

### D) Añadir un monstruo nuevo

1. Añade `assets/sprites/monsters/poporing.png`.
2. En `enemy_catalog.gd`, duplica un bloque en `get_definition()` con nuevo `id`, stats y `sprite_path`.
3. Registra el tipo en `pick_random_for_time()` si debe aparecer en partida.

---

### Color rosado en el sprite del monstruo

Eso pasaba porque el juego teñía el sprite con el color del **placeholder** (Poring = rosa).  
**Corregido:** si usas PNG o animación propia, el color es **blanco** (colores reales de tu imagen).  
El tinte de color solo se usa en el **cuadrado procedural** cuando no hay sprite.

---

## 4b. Monstruos nuevos y jefes (referencia rápida)

El juego busca el arte por el **`id` del monstruo** en `data/enemy_catalog.gd` (no por el nombre de la carpeta sola).  
La carpeta debe llamarse **igual que el id** en minúsculas.

### Tabla de archivos

| Id en código | Dónde aparece | Sprite fijo (opcional) | Carpeta animación walk (recomendado) | Carta (drop) |
|--------------|---------------|------------------------|--------------------------------------|--------------|
| `poring` | Prontera | `monsters/poring.png` | `monsters/poring/00.png` … | `cards/carta_poring.png` |
| `lunatic` | Prontera | `monsters/lunatic.png` | `monsters/lunatic/00.png` … | `cards/carta_lunatic.png` |
| `fabre` | Prontera | `monsters/fabre.png` | `monsters/fabre/00.png` … | `cards/carta_fabre.png` |
| `zombie` | Payon Dungeon | `monsters/zombie.png` | `monsters/zombie/00.png` … | `cards/carta_zombie.png` |
| `skeleton` | Payon Dungeon | `monsters/skeleton.png` | `monsters/skeleton/00.png` … | `cards/carta_skeleton.png` |
| `creamy` | Jefe Prontera (9:00) | `monsters/creamy.png` | `monsters/creamy/00.png` … | `cards/carta_creamy.png` |
| `osiris` | Jefe Payon (9:00) | `monsters/osiris.png` | `monsters/osiris/00.png` … | `cards/carta_osiris.png` |

Ruta base: `assets/sprites/`

### Jugador Swordman

| Clase | Archivo |
|-------|---------|
| Swordman | `assets/sprites/player/swordman.png` (o carpeta `player/` con frames) |

### Creamy mostraba sprite de Poring — por qué y cómo arreglarlo

**Causa:** En `CreamyBoss.gd` el tipo era `enemy_type = "poring"`, así que `Enemy.apply_type()` cargaba el catálogo del Poring.

**Corregido en código:** ahora usa `enemy_type = "creamy"`.

**Qué debes tener en disco:**

```
assets/sprites/monsters/creamy/
├── 00.png
├── 01.png
├── 02.png
└── 03.png   (mínimo 2 PNG para animación walk)
```

Opcional: un solo frame `assets/sprites/monsters/creamy.png` si no quieres animación.

Tras copiar archivos: en Godot → clic en la carpeta/imágenes → **Volver a importar** → **F5**.

El jefe escala ~2.6× en pantalla; `sprite_height: 36` en el catálogo controla el tamaño base antes del escalado.

### Payon: Zombie y Skeleton

Misma lógica: carpeta `zombie/` o `skeleton/` con PNG numerados, o un PNG suelto con el nombre del id.

### Osiris (jefe Payon)

Igual que Creamy, pero con id `osiris` y carpeta `assets/sprites/monsters/osiris/`.

---

## 5. Cartas en el suelo (drop) — paso a paso

Cuando un monstruo suelta carta, aparece `CardPickup` en el mapa. El sprite se carga **solo** según el **id de la carta**.

### A) Método recomendado: nombre del archivo

Carpeta:

```
assets/sprites/cards/
```

| Monstruo | ID de carta (en código) | Archivo que debes poner |
|----------|------------------------|-------------------------|
| Poring | `carta_poring` | `carta_poring.png` |
| Lunatic | `carta_lunatic` | `carta_lunatic.png` |
| Fabre | `carta_fabre` | `carta_fabre.png` |
| Creamy | `carta_creamy` | `carta_creamy.png` |
| Osiris | `carta_osiris` | `carta_osiris.png` |
| Zombie | `carta_zombie` | `carta_zombie.png` |
| Skeleton | `carta_skeleton` | `carta_skeleton.png` |

Pasos:

1. Copia tu PNG a `assets/sprites/cards/` con el nombre exacto (ej. `carta_poring.png`).
2. En Godot: clic en la imagen → **Volver a importar**.
3. **F5** y mata monstruos hasta que caiga la carta (1% de probabilidad).

Si el archivo existe, verás tu imagen. Si no, aparece el **cuadrado dorado** de respaldo.

### B) Tamaño en pantalla

Abre `scenes/pickups/CardPickup.tscn` → nodo raíz **CardPickup** → Inspector:

- **Card Sprite Height** (por defecto `22`) — súbelo si se ve muy pequeña.

### C) Ruta personalizada (opcional, por carta)

En `Enemy.gd`, al crear `card_data` en `_try_drop_card()`, puedes añadir:

```gdscript
"sprite_path": "res://assets/sprites/cards/mi_carta_poring.png",
```

Eso ignora el nombre automático y usa ese archivo.

### D) Probar sin esperar al 1%

En `scenes/enemy/Enemy.gd`, cambia temporalmente:

```gdscript
const CARD_DROP_CHANCE: float = 1.0  # 100% para pruebas
```

Recuerda volverlo a `0.01` después.

---

## 5. Sustituir sprite en el editor (sin tocar código)

1. Abre `scenes/enemy/Enemy.tscn`.
2. Nodo **Sprite2D** → propiedad **Texture** → carga tu PNG.

Eso solo afecta la escena base; en partida `apply_type()` vuelve a aplicar catálogo o procedural. Para producción usa el **catálogo** (`enemy_catalog.gd`).

Para cartas: `scenes/pickups/CardPickup.tscn` → **Sprite2D** → Texture (prueba visual; en juego manda `configure()`).

---

## 6. Consejos estilo Ragnarok Online

- Vista **casi top-down** o **3/4**; el personaje se ve desde arriba.
- **Fondo transparente** en PNG.
- Paleta viva; contorno oscuro de 1 px ayuda a leer sprites pequeños.
- Mantén el punto de ancla al **centro** del sprite (`centered = true` ya está en código).

---

## 7. Resolución de problemas

| Problema | Solución |
|----------|----------|
| Sigue el cuadrado de color | Revisa ruta y nombre exacto del archivo |
| Sprite enorme o diminuto | Ajusta `sprite_height` en `enemy_catalog.gd` |
| Borde blanco/negro | Import → Fix Alpha Border / modo Alpha |
| No aparece la carta | Nombre debe ser `carta_XXXX.png` igual que `card_id` |

---

## 8. ¿Puedo usar un .GIF animado?

**No de forma directa.** Godot importa un GIF como **una sola imagen** (primer fotograma) o no como animación jugable en `AnimatedSprite2D`.

### Alternativas recomendadas (de mejor a peor)

| Método | Cómo |
|--------|------|
| **Varios PNG** | Carpeta `assets/sprites/monsters/poring/` con `00.png`, `01.png`, `02.png`… (2+ frames) |
| **Spritesheet** | Una imagen con 4 cuadros en fila + `sheet_hframes` en `enemy_catalog.gd` |
| **SpriteFrames** | Editor → crear `poring_frames.tres` y asignar `sprite_frames_path` |
| **Convertir GIF** | En [ezgif.com](https://ezgif.com/split) o Aseprite → exportar PNG o spritesheet |

### Animación automática en el juego

Si solo tienes **un PNG**, el monstruo ya tiene un **balanceo suave** al moverse (bob).  
Si añades **2 o más PNG** en la carpeta del monstruo, se reproduce animación **walk** en bucle.

Ejemplo Poring animado:

```
assets/sprites/monsters/poring/
├── 00.png
├── 01.png
├── 02.png
└── 03.png
```

Velocidad en `enemy_catalog.gd`: `"anim_fps": 8.0`

### Spritesheet (una sola imagen con varios frames)

En `enemy_catalog.gd` (Poring):

```gdscript
"sprite_sheet_path": "res://assets/sprites/monsters/poring_sheet.png",
"sheet_hframes": 4,
"sheet_vframes": 1,
"anim_fps": 8.0,
```

La hoja debe tener 4 cuadros **en horizontal**, mismo tamaño cada uno.

### Crear SpriteFrames en el editor (avanzado)

1. Clic derecho en `assets/sprites/monsters/` → **Nuevo recurso** → `SpriteFrames`.
2. Animación `walk` → añade texturas frame a frame.
3. Guarda como `poring_frames.tres`.
4. En `enemy_catalog.gd`:

```gdscript
"sprite_frames_path": "res://assets/sprites/monsters/poring_frames.tres",
"anim_default": "walk",
```

---

## 9. Mapa con límite

El campo tiene borde de **valla** (3 baldosas). No puedes salir del rectángulo jugable.

Ajustes en `scenes/world/FieldBackground.tscn` → Inspector:

- **Arena Half Tiles:** mitad del mapa en baldosas (más = mapa más grande).
- **Border Tiles:** grosor del borde visible.
