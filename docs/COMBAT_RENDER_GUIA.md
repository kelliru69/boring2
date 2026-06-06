# Combate — Renderizado anti-flashbang (HDR, partículas, capas UI)

Guía para evitar que el blending aditivo del Mage sature la pantalla a blanco puro.

---

## Módulo 1 — WorldEnvironment (ACES + Glow)

### Qué hace el tonemapping ACES

Con **Linear**, los píxeles aditivos se suman sin límite → `(1+1+1)` = blanco sólido.

**ACES** comprime las altas luces: muchas partículas brillantes se ven luminosas y con color, pero el framebuffer no se “quema” a `#FFFFFF`.

### En el Inspector (manual)

1. Abre `scenes/main/Main.tscn`.
2. Selecciona el nodo **`WorldEnvironment`**.
3. En **Environment** → **New Environment** (o asigna `res://resources/vfx/combat_environment.tres` si lo generas).
4. Configura:

| Propiedad | Valor recomendado | Notas |
|-----------|-------------------|--------|
| **Background → Mode** | `Canvas` / Keep | No sustituye el fondo del mapa |
| **Tonemap → Mode** | `ACES` | Alternativa: `Filmic` |
| **Tonemap → Exposure** | `1.0` | Sube a `1.1` si se ve oscuro |
| **Tonemap → White** | `1.15` | Tope de blanco suave |
| **Glow → Enabled** | `On` | |
| **Glow → Intensity** | `0.5` | Sutil; baja a `0.35` si hay halo excesivo |
| **Glow → Strength** | `0.85` | |
| **Glow → Bloom** | `0.12` | |
| **Glow → Blend Mode** | `Screen` | Menos agresivo que `Additive` |
| **Glow → HDR Threshold** | `1.05` | Solo brillos fuertes hacen glow |

### Por código (ya integrado)

`Main.gd` llama a `CombatEnvironmentFactory.apply_to($WorldEnvironment)` en `_ready()`.

Archivo: `scripts/vfx/combat_environment_factory.gd`

Para exportar un `.tres` editable:

```gdscript
CombatEnvironmentFactory.save_default_resource()
# Crea res://resources/vfx/combat_environment.tres
```

---

## Módulo 2 — Partículas del Mage (alfa + vida útil)

### Dónde se configuran

| Habilidad | Preset / escena |
|-----------|-----------------|
| Fire Bolt | `FireTrail.tscn`, `FireImpactBurst.tscn` |
| Fire Wall | `FirewallSmokeLoop.tscn` |
| Thunder Storm | `ElectricRingBurst.tscn`, `LightningSparkBurst.tscn` |
| Soul Strike | `SoulTrail.tscn`, `SoulImpactBurst.tscn` |
| Cold / hielo | `IceTrail.tscn`, `IceShatterBurst.tscn` |

Lógica central: `scripts/vfx/elemental_vfx_config.gd`

### Reglas aplicadas automáticamente

- **Color Ramp**: alfa escala `×0.68` y curva `1.0 → 0.0` al morir la partícula.
- **Lifetime**: bursts `×0.72`, trails `×0.86`.
- **Amount**: bursts máx. `32`, trails máx. `22`.
- **HDR en sparks**: eliminado `Color(3,3,3)` (causaba flashes extremos).

### Ajuste fino en Inspector (una escena)

1. Abre p. ej. `scenes/vfx/particles/FireImpactBurst.tscn`.
2. Nodo raíz `GPUParticles2D`:
   - **Lifetime**: `0.3–0.45` en explosiones.
   - **Amount**: `16–28` en bursts.
   - **One Shot**: `On` en impactos.
3. **Process Material → Color Ramp**: último punto con **Alpha = 0**.

---

## Módulo 3 — Capas CanvasLayer (UI siempre legible)

### Jerarquía actual en partida

| Layer | Nodo | Contenido |
|-------|------|-----------|
| `-200` | `FieldSky` | Cielo de fondo |
| `0` | Mundo (`Main`) | Mapa, enemigos, VFX, loot (`z_index 64`) |
| `10` | `GameHUD`, `LevelUpUI` | HUD, barra de skills, XP |
| `12` | `FloatingCombatOverlay` | Números de daño flotantes |
| `12` | `RunResultUI` | Resultado de run |
| `20` | `PauseMenu`, `DebugRunPanel` | Menús modales |

### Números de daño

`DamageNumber.spawn()` ahora usa por defecto el grupo `floating_combat_overlay` (capa 12, sigue la cámara).

### Loot, cartas y curas en el suelo

Siguen en el mundo (necesitan `Area2D` para física), pero con **`z_index = 64`** para dibujarse por encima de la mayoría de VFX del mapa. El tonemapping ACES evita que se “laven” a blanco.

### Añadir un nuevo overlay

```gdscript
# Escena: CanvasLayer
layer = 10  # o superior al mundo
follow_viewport_enabled = true  # coordenadas de mundo
```

---

## Checklist de prueba

1. Lanza Fire Bolt + Thunder Storm + Fire Wall a la vez → sin pantalla blanca total.
2. Los números de daño siguen visibles sobre el caos.
3. Cartas/zeny/XP en suelo legibles durante el combate.
4. Si aún hay brillo alto: baja `glow_intensity` a `0.35` o `BASE_ALPHA_SCALE` a `0.55` en `elemental_vfx_config.gd`.
