# Guía VFX — Editor Godot 4 (rosurvivor)

Referencia para ajustar colores, partículas y materiales sin tocar código.

## Arquitectura del proyecto

| Capa | Archivo / carpeta | Qué editas |
|------|-------------------|------------|
| Escenas de partículas | `scenes/vfx/particles/*.tscn` | Amount, Lifetime, preset |
| Materiales (código) | `scripts/vfx/elemental_vfx_config.gd` | Color ramps, velocidad, spread |
| Texturas suaves | `scripts/vfx/vfx_texture_factory.gd` | Degradado radial (sin cuadrados) |
| Colores globales | `scripts/vfx/combat_vfx_palette.gd` | Paleta jugador vs enemigo |
| Rayo Lightning Bolt | `scripts/vfx/lightning_bolt_beam.gd` | Grosor, zig-zag, ramas |

---

## 1. Colores de habilidades

### A) Partículas (`GPUParticles2D`)

1. Abre una escena en `scenes/vfx/particles/` (ej. `FireTrail.tscn`).
2. Selecciona el nodo raíz **GPUParticles2D**.
3. Inspector → **Process Material** → expande `ParticleProcessMaterial`.
4. Propiedades clave:
   - **Color** — tinte base de cada partícula.
   - **Color Ramp** — degradado de vida (alpha 1 → 0 evita bordes duros).
   - **Scale Min / Max** — tamaño de la “gota” de luz.

> Si `apply_material_preset` está activo en `VfxParticles.gd`, al ejecutar el juego el código sobrescribe el material. Para editar a mano: desmarca **Apply Material Preset** en el Inspector del nodo.

### B) Sprites de proyectiles (`Sprite2D` + `procedural_sprite.gd`)

1. Abre `FireBolt.tscn`, `ColdBolt.tscn`, etc.
2. Nodo **Sprite2D** → Inspector:
   - **Fill Color** — color del núcleo.
   - **Use Soft Glow** — activado = círculo con alpha suave (sin recuadro en Additive).
   - **Modulate** — multiplicador final (se anima en runtime para fuego/hielo).

### C) Modo Additive (brillo sin cuadrado)

1. Inspector → **CanvasItem → Material** → `CanvasItemMaterial`.
2. **Blend Mode** = `Add`.
3. **Light Mode** = `Unshaded` (evita artefactos con luces 2D).

El código aplica esto vía `CombatVfxPalette.apply_additive()`.

### D) Paleta global (código)

Edita constantes en `combat_vfx_palette.gd`:

- `PLAYER_FIRE_CORE`, `PLAYER_FIRE_MID` — Fire Bolt / Fire Wall.
- `PLAYER_LIGHTNING_CORE` — rayos.
- `ENEMY_THREAT_*` — solo amenazas enemigas (rojo).

---

## 2. Partículas: cantidad, velocidad y vida

Nodo **GPUParticles2D** → Inspector:

| Propiedad | Efecto |
|-----------|--------|
| **Amount** | Cuántas partículas existen a la vez (más = más denso). |
| **Lifetime** | Segundos que vive cada partícula. |
| **Explosiveness** | `0` = estela continua; `1` = burst instantáneo (impactos). |
| **Randomness** | Variación por partícula. |
| **Fixed FPS** | `30` suele bastar para VFX 2D. |
| **Local Coords** | `Off` en trails que siguen al proyectil; `On` en bursts de impacto. |

**Process Material → ParticleProcessMaterial:**

| Propiedad | Efecto |
|-----------|--------|
| **Direction + Spread** | Cono de emisión. |
| **Initial Velocity Min/Max** | Velocidad inicial (px/s aprox.). |
| **Gravity** | Caída / subida del humo. |
| **Damping Min/Max** | Frenado (trails cortos vs largos). |
| **Scale Min/Max + Scale Curve** | Encogimiento orgánico al morir. |

### Presets por habilidad

| Escena | Habilidad |
|--------|-----------|
| `FireTrail.tscn` | Fire Bolt |
| `FirewallSmokeLoop.tscn` | Fire Wall |
| `SightWispLoop.tscn` | Sight (orbe) |
| `LightningSparkBurst.tscn` | Lightning Bolt impacto |
| `IceTrail.tscn` | Cold Bolt / Frost Diver |

---

## 3. Lightning Bolt (Line2D)

Escena: `LightningBolt.tscn` → script `LightningBolt.gd`.

Visual: `LightningBoltBeam` (3 capas Line2D + ramas).

Inspector (export en el beam, si instancias la escena) o edita `lightning_bolt_beam.gd`:

| Export | Efecto |
|--------|--------|
| `core_width` | Núcleo blanco del rayo |
| `glow_width` | Halo exterior |
| `segment_count` | Segmentos del zig-zag |
| `jitter` | Desviación aleatoria (caos del rayo) |
| `branch_count` | Ramificaciones laterales |
| `beam_extra_length` | Extensión visual del trazo |

Impacto: `LightningSparkBurst.tscn` — sube **Amount** y **Initial Velocity** para más chispas.

---

## 4. Evitar “cuadrados de luz”

Checklist:

1. **GPUParticles2D → Texture** debe ser un círculo soft (automático vía `VfxTextureFactory`).
2. **Texture Filter** = `Linear` (no `Nearest` en VFX additive).
3. **Color Ramp** debe terminar en alpha `0`.
4. No uses sprites cuadrados con Additive; activa **Use Soft Glow** en proyectiles.
5. **ImpactFlash** usa `Sprite2D` radial (no `PointLight2D`) para evitar el flash cuadrado de 1 frame.
6. Bursts usan `curve_burst_pop()` (escala inicial ~6%) + `preprocess = 0.05` + emisión diferida en `VfxParticles.play_burst_at()`.

### Frost Diver (ajuste visual)

| Archivo | Rol |
|---------|-----|
| `frost_diver_beam.gd` | Haz cristalino Line2D durante el vuelo |
| `FrostDiverBurst.tscn` | Fragmentos de hielo al impactar (`frost_shatter`) |
| `frost_explosion_ring_fx.gd` | Anillo de escarcha expandiéndose |

---

## 5. Flujo recomendado de prueba

1. Edita la escena `.tscn` de partículas.
2. Desactiva **Apply Material Preset** temporalmente para ver cambios en el editor.
3. Play → lanza la habilidad en Payon (oscuro) y Prontera (claro).
4. Si te gusta el resultado, copia valores a `elemental_vfx_config.gd` o reactiva el preset.
