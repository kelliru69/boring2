# Guía: TileSet y MapGenerator (Prontera / Payon)

Esta guía explica cómo configurar tus **sprite sheets** en Godot 4.6 y cómo usar `MapGenerator.gd` en **boring**.

---

## 1. Archivos del proyecto

Coloca tus imágenes aquí:

```
assets/tiles/prontera/
├── grass_tileset.png    # Suelo + caminos (176×112 → 11×7 celdas @ 16px)
├── hills_tileset.png    # Acantilados / murallas (176×144)
├── props_things.png     # Árboles, rocas, flores (copia tu sheet "Basic Grass Biom things")
└── water_tile.png       # (opcional) charcos
```

**Importante:** renombra tu sheet de props a `props_things.png` o actualiza la ruta en `map_tileset_builder.gd`.

En el **Import** de cada PNG:
- **Filtro:** `Nearest` (pixel art)
- **Fix Alpha Border:** activado
- Pulsa **Volver a importar**

---

## 2. Configuración del TileMap en Godot 4 (Inspector)

### Paso A — Crear el TileSet (manual, opcional)

Si prefieres configurar a mano en lugar del builder automático:

1. Selecciona un nodo `TileMapLayer` → **Tile Set → New TileSet**.
2. Abre el TileSet → **+** → **Add Atlas Source**.
3. Arrastra `grass_tileset.png`.
4. En **Texture Region Size** pon **16×16** (ajusta si tu pack usa 32×32).
5. Godot cortará la hoja en celdas; revisa que cada tile cuadre.

### Paso B — Capas recomendadas

| Capa | Nodo | Z-index | Contenido |
|------|------|---------|-----------|
| Suelo | `GroundLayer` | -100 | Hierba clara/oscura (FastNoiseLite) |
| Caminos | `PathLayer` | -95 | Tierra / senderos |
| Obstáculos | `ObstacleLayer` | -85 | Árboles, rocas (con colisión) |
| Decoración | `DecorLayer` | -90 | Flores, hierba suelta (sin colisión) |
| Borde | `BorderLayer` | -80 | Muralla / acantilado perimetral |

En `FieldBackground.tscn` ya están creadas. Activa **Y Sort Enabled** en capas con árboles si quieres que el jugador pase “detrás”.

### Paso C — Physics Layers (colisiones)

1. Abre el **TileSet** → pestaña **Physics Layers** → **Add Element**.
2. **Collision Layer:** marca capa **1** (la misma que usa el `Player`: `collision_mask = 1`).
3. Selecciona cada tile de **árbol, roca o muralla** en el atlas.
4. Pinta un polígono en **Physics Layer 0** (rectángulo completo para muros; solo tronco para árboles grandes).

El script `MapTilesetBuilder.gd` añade colisión rectangular automática a los tiles listados en `MapTileCatalog.collision_tile_keys()`. Puedes refinar polígonos a mano después.

### Paso D — Asignar MapGenerator

Nodo `MapGenerator` (hijo de `FieldBackground`):

- **Ground Layer** → `../GroundLayer`
- **Path Layer** → `../PathLayer`
- **Obstacle Layer** → `../ObstacleLayer`
- **Decor Layer** → `../DecorLayer`
- **Border Layer** → `../BorderLayer`
- **Static Walls Path** → `../BoundaryWalls`

Pulsa **F5**. El mapa se genera en `_ready()`.

---

## 3. Ajustar IDs de tiles (coordenadas del atlas)

Edita **`data/map_tile_catalog.gd`**. Cada tile es:

```gdscript
"ground_grass_a": tile(SourceId.GROUND, Vector2i(0, 4)),
#                              ^ source 0      ^ columna, fila en la hoja 16×16
```

**Sources:**
- `0` = `grass_tileset.png`
- `1` = `hills_tileset.png`
- `2` = `props_things.png`

Para encontrar coordenadas: abre el TileSet en el editor, selecciona un tile y mira **Atlas Coords** en el panel inferior.

---

## 4. Densidad y estructura (Inspector de MapGenerator)

| Parámetro | Efecto |
|-----------|--------|
| `map_half_size` | Mitad del mapa en celdas. `50` = **100×100** celdas. |
| `border_thickness` | Grosor de muralla con colisión en el borde. |
| `ground_noise_frequency` | Más bajo = parches de hierba más grandes. |
| `path_count` / `path_walk_steps` | Más = más caminos orgánicos. |
| `path_half_width` | Ancho del sendero en celdas. |
| `obstacle_cluster_count` | **↑ más bosques / cuellos de botella.** |
| `obstacle_cluster_radius` | Tamaño de cada bosque. |
| `obstacle_cluster_fill` | **↑ más denso** (0.0–1.0). |
| `obstacle_min_dist_from_center` | Evita bosques encima del spawn central. |
| `map_seed` | `0` = aleatorio cada partida; fija un número para repetir el mismo mapa. |

---

## 5. Spawns de enemigos

Tras generar, `MapGenerator` calcula `free_spawn_cells` (celdas sin muro ni obstáculo).

`Main.gd` ya consulta:

```gdscript
field_background.get_map_generator().get_enemy_spawn_position(player_pos, radius)
```

API útil:

```gdscript
var gen: MapGenerator = $FieldBackground/MapGenerator
var pos: Vector2 = gen.get_random_free_world_position(2)
print(gen.last_result.get_free_cell_count())
```

---

## 6. Payon Dungeon

`PayonBackground.tscn` usa el mismo `MapGenerator` con `map_theme = PAYON`:
- Tile size **32×32** (procedural dungeon).
- Más clústers y densidad alta para corredores cerrados.

Cuando tengas tileset de calabozo en PNG, añade un atlas en `MapTilesetBuilder` y actualiza `MapTileCatalog.payon()`.

---

## 7. Regenerar mapa en runtime

```gdscript
$MapGenerator.generate(12345)  # seed fijo para pruebas
```

Señal:

```gdscript
map_generator.generation_finished.connect(func(result):
    print("Celdas libres: ", result.get_free_cell_count())
)
```

---

## 8. Checklist rápido

- [ ] PNGs en `assets/tiles/prontera/` con filtro **Nearest**
- [ ] `props_things.png` copiado (árboles / rocas)
- [ ] Coordenadas revisadas en `map_tile_catalog.gd`
- [ ] **F5** — jugador no atraviesa árboles ni sale del borde
- [ ] Enemigos no spawnean dentro de obstáculos
