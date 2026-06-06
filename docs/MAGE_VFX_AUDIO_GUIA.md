# Mage — VFX, audio y game feel

Módulos en `scripts/vfx/` y hooks en escenas de skills.

## Regla de color (combate)

| Origen | Paleta |
|--------|--------|
| **Fuego del jugador** (Fire Bolt, Fire Wall) | Naranja brillante, amarillo intenso, blanco — **sin rojo puro** |
| **Hielo / rayo / alma** (Mage) | Celeste, blanco, violeta (constantes en `combat_vfx_palette.gd`) |
| **Enemigos** (flechas, telémetros, AoE) | Rojo vivo / carmesí + **outline negro** (`enemy_threat_vfx.gd`) |
| **Moonlight Flower** (Payon) | Rayos lineales + espíritus orbitales vía `draw_line_telegraph` / `draw_threat_zone` |

Centraliza materiales de partículas en `elemental_vfx_config.gd`; lógica de dibujo del Mage en `mage_skill_vfx.gd`.

## Escenas de partículas (Inspector)

Abre `scenes/vfx/particles/*.tscn` y ajusta **Amount**, **Lifetime**, **Explosiveness**, etc.  
El script `VfxParticles.gd` aplica el material según `vfx_preset`. Desmarca `apply_material_preset` si quieres editar el `ParticleProcessMaterial` a mano en el nodo.

| Escena | Uso |
|--------|-----|
| `IceShatterBurst.tscn` | Impacto hielo |
| `FireImpactBurst.tscn` | Impacto fuego |
| `ElectricRingBurst.tscn` | Rayo / tormenta |
| `EnemyHitSpark.tscn` | Chispa al golpear enemigo |
| `*Trail.tscn` | Estelas de proyectiles del jugador |
| `EnemyThreatTrail.tscn` | Estela roja (proyectiles enemigos) |
| `SightWispLoop.tscn` | Partículas orbitales de Sight |
| `SoulImpactBurst.tscn` | Destello al impactar Soul Strike |
| `FirewallSmokeLoop.tscn` | Humo de Fire Wall |

## Hit flash en enemigos

`Enemy.take_damage(cantidad, elemento)` — `elemento` opcional (`EnemyHitFlash.ELEMENT_FIRE`, `ELEMENT_ICE`, etc.).  
Flash blanco HDR en `VisualRoot` (~0.07 s) + partícula `EnemyHitSpark` si hay elemento.

## Archivos

| Archivo | Rol |
|---------|-----|
| `elemental_vfx_spawner.gd` | Instancia escenas VFX |
| `elemental_vfx_config.gd` | Materiales (preset) + textura radial suave |
| `combat_vfx_palette.gd` | Colores jugador vs enemigo |
| `mage_skill_vfx.gd` | Proyectiles Mage, barrera ígnea, impactos |
| `enemy_threat_vfx.gd` | Telémetros y flechas enemigas |
| `vfx_scene_registry.gd` | Preloads de `.tscn` |
| `enemy_hit_flash.gd` | Colores de flash por elemento |
| `camera_shake_controller.gd` | `shake_camera(intensity, duration)` en `Main/Camera2D` |
| `impact_flash.gd` | `PointLight2D` breve en impactos pesados |
| `lightning_zap_fx.gd` | Rayo vertical zigzag (`Line2D`) |
| `Audio.gd` | `play_sfx_varied()` + carga opcional desde `res://audio/sfx/` |

## Audio (pitch 0.9–1.1)

```gdscript
Audio.play_sfx_varied("frost_diver_cast")
Audio.play_sfx_varied("thunder_storm", 0.88, 1.05)
```

Coloca MP3/OGG en rutas listadas en `Audio.MAGE_SFX_CANDIDATES`; si no existen, suenan los procedurales de `procedural_sfx_factory.gd`.

## Sacudida de cámara

```gdscript
CameraShakeController.shake_active_scene(5.5, 0.22)
# o desde el nodo:
$Camera2D.shake_camera(5.5, 0.22)
```

Thunderstorm y Frost Diver impacto ya la disparan.

## PointLight2D en mapas oscuros

1. En el tilemap/mapa: **CanvasItem → Light Mask** compatible con capa 1.
2. `ImpactFlash.spawn(parent, world_pos, color, energy, duration, texture_scale)` — ya se usa en fuego, rayo y tormenta.
3. Inspector del `PointLight2D`: `Energy` 1.0–1.5, `Texture Scale` 2–3, `Blend Mode` Add, sin sombras en móvil.

## Inspector — ParticleProcessMaterial (Godot 4)

### Estela Soul / Fuego (trail continuo)

| Propiedad | Valor orientativo |
|-----------|-------------------|
| **GPUParticles2D → Amount** | 20–28 |
| **Lifetime** | 0.45–0.65 |
| **Explosiveness** | `0` (emisión continua) |
| **Direction** | Opuesto al movimiento (ej. Y+ en alma) |
| **Spread** | 25–40° |
| **Initial Velocity Min/Max** | 8–45 |
| **Damping Min/Max** | 30–80 (frenado suave) |
| **Scale Min/Max** | 0.2–0.9 |
| **Scale Curve** | 1 → 0 (se encogen al morir) |
| **Color Ramp** | Morado/naranja opaco → alpha 0 (fuego: amarillo→naranja, sin rojo) |
| **Material (nodo)** | CanvasItem **Blend Add** (alma, rayo, hielo, fuego jugador) |
| **Texture** | Gradiente radial (`apply_soft_particle_texture`) — evita cuadrados blancos |

### Hielo al impactar (burst)

| Propiedad | Valor |
|-----------|--------|
| **One Shot** | ✓ |
| **Explosiveness** | `1.0` (todo el burst a la vez) |
| **Spread** | `180°` |
| **Initial Velocity** | 120–280 |
| **Damping** | 180–320 (frenado en seco) |
| **Gravity** | Y+ ~120 |
| **Emission Shape** | Sphere, radio 4–8 |

### Fuego / humo (Fire Wall)

| Propiedad | Valor |
|-----------|--------|
| **Explosiveness** | `0` |
| **Direction** | Y− (sube) |
| **Color Ramp** | Naranja → gris → transparente |
| **Scale Curve** | Pico medio, 0 al final |
| **Amount** | 30–40 (no más en móvil) |

### Anillo eléctrico (Thunderstorm)

| Propiedad | Valor |
|-----------|--------|
| **Emission Shape** | **Ring** |
| **Explosiveness** | `1.0` |
| **Initial Velocity** | 18–40 (expansión radial) |
| **Blend Add** | ✓ |

## Rendimiento

- `fixed_fps` 28–30 en partículas.
- Bursts `one_shot` + `queue_free` tras `lifetime`.
- Evitar >50 partículas simultáneas por skill.
