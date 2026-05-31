# boring — Guía MVP

## ¿Es ejecutable ya?

**Sí.** No necesitas asignar sprites PNG externos.

1. Abre la carpeta del proyecto en **Godot 4.6**.
2. Pulsa **F5** (escena principal: `scenes/main/Main.tscn`).

Los gráficos son **procedurales** (generados por código al iniciar):

| Entidad | Forma | Color |
|---------|-------|-------|
| Mage (jugador) | Círculo | Azul |
| Poring | Cuadrado | Rosa |
| Lunatic | Cuadrado | Verde |
| Fabre | Cuadrado | Amarillo |
| Fire Bolt | Círculo pequeño | Naranja |
| Carta en suelo | Cuadrado | Dorado |

Si más adelante quieres sprites reales: sustituye el script `procedural_sprite.gd` del `Sprite2D` por una textura importada en el Inspector.

---

## Nuevas mecánicas

### Subida de nivel (1 de 3 mejoras)

- Al ganar XP suficiente, el juego se **pausa** y aparece `LevelUpUI`.
- Elige una de **3 mejoras aleatorias** (HP, curación, velocidad, daño, cadencia, rango).
- Si subes varios niveles de golpe, debes elegir una mejora por cada nivel.

### Dificultad por tiempo

- Cada **30 s** de partida:
  - Spawn más rápido (hasta mínimo 0.35 s).
  - Más enemigos permitidos en pantalla.
- A partir de **1 min** y **3 min** aparecen más Lunatic y Fabre (menos solo Porings).

### Game Over

- Al morir: panel con estadísticas y botón **Reintentar**.

---

## Mapa y audio (estilo Ragnarok)

### Fondo
- **Cielo** azul claro (gradiente).
- **Campo infinito** con baldosas procedurales: hierba verde, caminos de tierra, charcos poco profundos, flores.
- El mapa se genera alrededor de la cámara mientras te mueves.

### Sonidos (procedurales, sin archivos .wav)
| Evento | Sonido |
|--------|--------|
| BGM | Melodía suave en loop (campo) |
| Fire Bolt | Chispa mágica |
| Impacto | Golpe corto |
| Muerte monstruo | Arpegio descendente |
| Daño jugador | Golpe grave |
| Subir nivel | Arpegio ascendente |
| Zeny | “Moneda” aguda |
| Carta | Brillo |
| UI | Clic |

Volumen: menú **ESC → Pausa** (sliders) o autoload **Audio**. Se guarda en `user://audio_settings.cfg`.

### Tu propia canción (BGM)

Copia el archivo a `assets/audio/` como `bgm_field.ogg` (recomendado), `.mp3` o `.wav`.  
Guía completa: `assets/audio/README.md`

---

## Controles

- **WASD** o **flechas**: movimiento.

---

## Estructura relevante

```
data/upgrade_pool.gd      # Mejoras
data/enemy_catalog.gd     # Tipos de monstruo
scripts/util/shape_texture_factory.gd
scripts/visual/procedural_sprite.gd
scenes/ui/LevelUpUI.tscn
scenes/ui/GameOverUI.tscn
```
