# Crear mapas a mano en Godot (Prontera / Payon)

Godot **incluye un editor de mapas** integrado. No necesitas Tiled ni otra herramienta externa: pintas directamente en la escena y el juego carga esa escena al elegir el mapa.

---

## Cómo se conecta con el juego

| Mapa en menú | Escena que debes editar |
|--------------|------------------------|
| **Prontera Fields** | `scenes/world/FieldBackground.tscn` |
| **Payon Dungeon** | `scenes/world/PayonBackground.tscn` |

`data/map_config.gd` ya apunta a esas escenas. Cuando el jugador elige un mapa, `Main.gd` instancia la escena correspondiente.

---

## Paso 1 — Abrir la escena del mapa

1. En Godot, panel **Sistema de archivos**.
2. Abre **`scenes/world/FieldBackground.tscn`** (Prontera).
3. Pulsa **F6** (*Ejecutar escena actual*) para probar solo el mapa mientras diseñas.

---

## Paso 2 — TileSet (tu sprite sheet)

Cada `TileMapLayer` usa un **TileSet** (recorte de tus PNG en celdas).

### Opción A — Automática (rápida)

Al ejecutar, `FieldBackground` asigna un TileSet desde:

```
assets/tiles/prontera/
├── grass_tileset.png
├── hills_tileset.png
└── props_things.png
```

Con **Auto Assign Tileset** activado en el nodo raíz (Inspector), ya puedes pintar.

### Opción B — Manual en el editor (recomendada a largo plazo)

1. Selecciona **GroundLayer**.
2. Inspector → **Tile Set** → **Nuevo TileSet**.
3. Abajo aparece el panel **TileSet** → **+** → **Atlas**.
4. Arrastra `grass_tileset.png`.
5. **Texture Region Size:** `16×16` (Sprout Lands).
6. Godot corta la hoja; revisa que cada tile cuadre.
7. Repite atlas para `hills_tileset.png` y `props_things.png` en el **mismo** TileSet (varias fuentes).
8. **Guardar como recurso:** botón desplegable del TileSet → **Guardar como…**  
   → `assets/tiles/prontera/prontera_tileset.tres`
9. Asigna ese `.tres` a **todas** las capas (Ground, Path, Obstacle, Decor, Border).

**Importar PNG:** Comprimir → **Lossless**. Filtro global: **Proyecto → Configuración → Rendering → Default Texture Filter → Nearest**.

---

## Paso 3 — Pintar el mapa (editor integrado)

1. Selecciona una capa, por ejemplo **GroundLayer**.
2. Abajo del viewport aparece la barra de **TileMap**.
3. Elige un tile en la rejilla y pinta con el **pincel** en el viewport.

### Capas sugeridas

| Capa | Qué pintar | Colisión |
|------|------------|----------|
| **GroundLayer** | Hierba, tierra base | No |
| **PathLayer** | Caminos | No |
| **DecorLayer** | Flores, hierba suelta | No |
| **ObstacleLayer** | Árboles, rocas | **Sí** |
| **BorderLayer** | Muros / acantilados del borde | **Sí** |

### Colisiones (Physics Layer)

1. Abre el **TileSet** (panel inferior).
2. Pestaña **Physics Layers** → **Add Element** → capa de colisión **1** (igual que el jugador).
3. Selecciona un tile de árbol o muro.
4. Pinta un polígono en **Physics Layer 0** (rectángulo o solo el tronco del árbol).
5. Repite en tiles de obstáculo y borde.

---

## Paso 4 — Tamaño y límites del mapa

En el nodo raíz **FieldBackground** (Inspector):

| Propiedad | Prontera (ejemplo) | Payon (ejemplo) |
|-----------|-------------------|-----------------|
| **Tile Px** | 16 | 32 |
| **Map Visual Scale** | 2.0 | 1.0 |
| **Arena Half Tiles** | 36 | 36 |
| **Border Tiles** | 3 | 3 |

- **Arena Half Tiles:** mitad del mapa en celdas. Con 36 → de la celda **-36** a **35**.
- Pinta tu mapa **dentro** de ese rectángulo.
- Deja **3 celdas** de borde con muros/colisión para que el jugador no salga.

Ajusta **Arena Half Tiles** si tu mapa pintado es más grande o más pequeño.

---

## Paso 5 — Probar en el juego completo

1. **Ctrl+S** — guarda la escena del mapa.
2. **F5** — partida normal.
3. En el hub, elige **Prontera Fields** o **Payon Dungeon**.

El juego carga la escena que editaste; no hace falta tocar código.

---

## Payon Dungeon

Mismo flujo con **`PayonBackground.tscn`**.

Hoy usa baldosas procedurales (32×32). Cuando tengas tileset de calabozo en PNG:

1. Crea `assets/tiles/payon/payon_tileset.tres`.
2. Asigna a las capas de `PayonBackground.tscn`.
3. Desactiva **Auto Assign Tileset** en el nodo raíz.

---

## Consejos de diseño (Bullet Heaven)

- **Bosques compactos** y rocas en grupos → cuellos de botella.
- **Caminos** que crucen el mapa → orientación visual.
- **Centro más abierto** → spawn del jugador y combate inicial.
- **Borde cerrado** en **BorderLayer** con colisión.

---

## MapGenerator (opcional)

El script procedural `scripts/world/map_generator.gd` sigue en el proyecto por si quieres mapas aleatorios más adelante. **Ya no se usa** en `FieldBackground` ni `PayonBackground` por defecto.

---

## Resumen rápido

```
1. Abrir FieldBackground.tscn o PayonBackground.tscn
2. Configurar TileSet (16×16 + tus PNG)
3. Pintar capas con el editor TileMap de Godot
4. Colisiones en árboles/muros
5. Guardar escena → F5
```

¿Dudas frecuentes?

- **¿Hay editor aparte?** No; el de Godot es el editor oficial.
- **¿Un mapa por escena?** Sí: una escena = un mapa del juego.
- **¿Cambiar qué mapa carga el menú?** Edita `background_scene` en `data/map_config.gd`.
