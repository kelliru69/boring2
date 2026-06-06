# Referencia de habilidades (progresión por nivel)

Daño efectivo ≈ `round(base × attack_multiplier × mult_nivel)`.  
CD activas y intervalos automáticos se reducen con stats de la tienda / tómbola.

**Regla de diseño:** cada nivel sube daño, alcance, proyectiles o cadencia; no hay retrocesos (p. ej. Thunder Storm ya no encoge el radio en nv.3).

---

## Mage

| Base export | Valor |
|-------------|-------|
| `fire_bolt_damage` | 25 |
| `cold_bolt_damage` | 18 |
| `sight_tick_damage` | 6 |
| Thunder Storm | 12 |

### Soul Strike (auto)

| Nv | Espíritus | Intervalo ráfaga | Mult. daño |
|----|-----------|------------------|------------|
| 1 | 1 | 2.0 s | 0.55 |
| 2 | 2 | 2.0 s | 0.62 |
| 3 | 3 | 2.0 s | 0.69 |
| 4 | 4 | 2.0 s | 0.76 |
| 5 | 5 | 1.5 s | 0.83 |

### Sight (orbital)

| Nv | Radio | Mult. daño | Extra |
|----|-------|------------|--------|
| 1 | 26 | 1.00 | — |
| 2 | 32.5 | 1.12 | — |
| 3 | 39 | 1.24 | — |
| 4 | 45.5 | 1.36 | Knockback |
| 5 | 52 | 1.48 | 2º orbe + knockback |

### Fire Bolt / Cold Bolt (auto, 2 s)

| Nv | Proyectiles | Mult. daño | Cold slow |
|----|-------------|------------|-----------|
| 1 | 1 | 1.00 | 20% |
| 2 | 2 | 1.10 | 27.5% |
| 3 | 2 | 1.20 | 35% |
| 4 | 3 | 1.30 | 42.5% |
| 5 | 3 | 1.40 | 50% |

### Fire Wall (auto, 3.5 s)

| Nv | Barreras | Radio | Mult. daño | Knockback |
|----|----------|-------|------------|-----------|
| 1 | 1 (−X) | 40 | 1.00 | — |
| 2 | 1 | 44 | 1.10 | 120 |
| 3 | 1 | 48 | 1.20 | 140 |
| 4 | 1 | 52 | 1.30 | 160 |
| 5 | 2 (−X y +X) | 56 | 1.40 | 180 |

### Lightning Bolt (auto, 2.2 s)

| Nv | Proyectiles | Alcance ida/vuelta | Mult. (× fire_bolt) |
|----|-------------|--------------------|---------------------|
| 1 | 1 | 140 | 0.60 |
| 2 | 1 | 195 | 0.70 |
| 3 | 2 | 250 | 0.80 |
| 4 | 2 | 305 | 0.90 |
| 5 | 3 | 360 | 1.00 |

Dirección aleatoria cada cast.

### Frost Diver (activa, CD 5 s)

| Nv | Radio | Mult. (× cold) | Stun | Línea |
|----|-------|----------------|------|-------|
| 1 | 48 | 1.00 | 1.0 s | — |
| 2 | 58 | 1.12 | 1.25 s | — |
| 3 | 68 | 1.24 | 1.5 s | 110 px |
| 4 | 78 | 1.36 | 1.75 s | 140 px |
| 5 | 88 | 1.48 | 2.0 s | 170 px |

### Thunder Storm (activa)

| Nv | Radio | Mult. | Duración | Intervalo pulso | Pulsos ~ | Knockback | CD |
|----|-------|-------|----------|-----------------|----------|-----------|-----|
| 1 | 68 | 1.00 | 2.0 s | 0.55 s | 4 | 100 | 6.0 s |
| 2 | 83 | 1.12 | 2.2 s | 0.51 s | 5 | 115 | 5.65 s |
| 3 | 98 | 1.24 | 2.4 s | 0.47 s | 6 | 130 | 5.3 s |
| 4 | 113 | 1.36 | 2.6 s | 0.43 s | 7 | 145 | 4.95 s |
| 5 | 128 | 1.48 | 2.8 s | 0.39 s | 8 | 175 | 4.6 s |

Casteo: 1.0 s → 0.8 s (nv.5). **Nv.3 ya supera a nv.2** en área, daño, pulsos y CD.

---

## Swordman

| Base | Valor |
|------|-------|
| `bash_base_damage` | 22 |
| `magnum_base_damage` | 28 |

### Bash (auto)

| Nv | Golpes | Intervalo | Mult. | Radio | Stun |
|----|--------|-----------|-------|-------|------|
| 1 | 1 | 2.00 s | 1.00 | 48 | — |
| 2 | 1 | 1.72 s | 1.12 | 56 | 15% |
| 3 | 2 | 1.44 s | 1.24 | 64 | 15% |
| 4 | 2 | 1.16 s | 1.36 | 72 | 35% |
| 5 | 3 | 0.88 s | 1.48 | 80 | 35% |

### HP Recovery

| Nv | Intervalo | Curación |
|----|-----------|----------|
| 1 | 2.0 s | 1 |
| 2 | 1.78 s | 1 |
| 3 | 1.56 s | 2 |
| 4 | 1.34 s | 2 |
| 5 | 1.12 s | 3 |

### Sword Mastery

+5% ATK por nivel.

### Endure

Reducción: `12% + (nv−1)×6%`; duración `2 + (nv−1)×0.5` s.

### Magnum Break (activa, CD 5 s)

| Nv | Radio | Mult. | Knockback | Buff fuego |
|----|-------|-------|-----------|------------|
| 1 | 80 | 1.00 | 180 | 8% |
| 2 | 94 | 1.14 | 205 | 16% |
| 3 | 108 | 1.28 | 230 | 24% |
| 4 | 122 | 1.42 | 255 | 32% |
| 5 | 136 | 1.56 | 280 | 40% |

### Provoke (activa, CD 6 s)

Radio `100 + (nv−1)×18`; slow `35% + (nv−1)×5%`; duración debuff `2 + (nv−1)×0.4` s.

---

## Archivos de balance

- Mage: `data/mage_skill_scaling.gd`
- Swordman: `data/swordman_scaling.gd`
