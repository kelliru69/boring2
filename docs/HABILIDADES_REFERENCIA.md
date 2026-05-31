# Referencia de habilidades (valores base)

Los números de **daño** usan `attack_multiplier` del jugador (tómbola, cartas, Sword Mastery, etc.).  
Los **intervalos** automáticos se dividen por `Global.get_attack_speed_multiplier()`.  
Las **activas** (Frost Diver, Thunder Storm, Magnum, Provoke) multiplican su CD por `Global.get_active_cooldown_multiplier()`.

Daño efectivo ≈ `round(base_export × attack_multiplier × mult_nivel)`.

---

## Mage — export en `Player.tscn`

| Stat export | Valor base |
|-------------|------------|
| `fire_bolt_damage` | 25 |
| `cold_bolt_damage` | 18 |
| `sight_tick_damage` | 6 |
| Thunder Storm base interno | 12 |

### Soul Strike (auto, hacia cursor)

| Nv | Espíritus | Intervalo entre ráfagas | Mult. daño (× fire_bolt base) |
|----|-----------|-------------------------|-------------------------------|
| 1 | 1 | 2.0 s | 0.55 |
| 2 | 2 | 2.0 s | 0.61 |
| 3 | 3 | 2.0 s | 0.67 |
| 4 | 4 | 2.0 s | 0.73 |
| 5 | 5 | 1.5 s | 0.79 |

Stagger entre espíritus de la misma ráfaga: 0.12 s (si hay más de uno).

### Sight (orbital, siempre activo)

| Nv | Radio hit | Mult. daño (× sight_tick) | Notas |
|----|-----------|---------------------------|--------|
| 1 | 26 | 1.0 | 1 orbe |
| 2 | 38 | 1.15 | |
| 3 | 52 | 1.35 | |
| 4 | 52 | 1.5 | Knockback 120 |
| 5 | 52 | 1.5 | 2 orbes, radio secundario 26 |

Tick de contacto cada **0.35 s** (por orbe); cooldown por enemigo **0.18 s**.

### Fire Bolt (auto, cada 2 s)

| Nv | Proyectiles | Mult. daño |
|----|-------------|------------|
| 1 | 1 | 1.0 |
| 2 | 1 | 1.2 |
| 3 | 2 | 1.0 |
| 4 | 2 | 1.2 |
| 5 | 3 | 1.2 |

Stagger entre proyectiles: **0.08 s**.

### Fire Wall (auto, cada 3.5 s)

- Barreras a **−X** (izquierda del mapa) y, en nv.5, también a **+X** (derecha).
- Offset: `72 + (nv−1)×6` px; radio 40 (nv.1–3) o 56 (nv.4–5).
- Daño por pulso: `round(18 × attack_mult × mult_nv)`; pulso cada **0.45 s**; duración barrera **3 s**.
- Mult. daño nv.: 1.0 → 1.2 (nv.3) → 1.28 (nv.4) → 1.36 (nv.5). Knockback 160 desde nv.2.

### Cold Bolt (auto, cada 2 s)

| Nv | Rayos | Mult. daño | Ralentización |
|----|-------|------------|---------------|
| 1 | 1 | 1.0 | 20% |
| 2 | 1 | 1.25 | 50% |
| 3 | 2 | 1.0 | 20% |
| 4 | 2 | 1.25 | 50% |
| 5 | 3 | 1.25 | 50% |

### Frost Diver (activa, CD base 5 s)

| Nv | Radio | Mult. (× cold_bolt) | Stun | Línea extra |
|----|-------|---------------------|------|-------------|
| 1 | 48 | 1.0 | 1 s | — |
| 2 | 58 | 1.12 | 1 s | — |
| 3 | 68 | 1.24 | 1 s | 120 px |
| 4 | 78 | 1.36 | 1 s | 145 px |
| 5 | 88 | 1.48 | 2 s | 170 px |

Casteo: instantáneo bajo el cursor.

### Lightning Bolt (auto, cada 2.2 s)

| Nv | Proyectiles | Distancia ida/vuelta | Mult. daño (× fire_bolt) |
|----|-------------|----------------------|--------------------------|
| 1 | 1 | 140 | **0.5** |
| 2 | 1 | 220 | **0.5** |
| 3 | 2 | 140 | **0.5** |
| 4 | 1 | 360 | **0.5** |
| 5 | 3 | 360 | **0.625** (0.5 × 1.25) |

Dirección base **aleatoria** cada cast; con varios proyectiles se reparten en un arco (±63° aprox.). Stagger: **0.06 s**.

### Thunder Storm (activa, CD base 6 s)

| Nv | Radio | Mult. daño (× base 12) | Pulsos en 2.25 s |
|----|-------|------------------------|------------------|
| 1 | 64 | 1.2 | ~5 (cada 0.5 s) |
| 2 | 88 | 1.2 | ~5 |
| 3 | 64 | 1.38 | ~5 |
| 4 | 120 | 1.62 | ~5 |
| 5 | 150 | 1.62 | ~5 |

- **Casteo:** 1 s (tormenta aparece donde apuntas con el cursor al pulsar).
- **Duración:** 2.25 s (+50% respecto a 1.5 s).
- **Daño por pulso:** `round(12 × attack_mult × mult_nv)` (sin doble multiplicador).

### Thunder Storm (auto-legacy en `Player`, si sigue activo)

Timer `thunderstorm_interval` export **4 s** (enemigo aleatorio, sin casteo de 1 s).

---

## Swordman — export en `Player.tscn`

| Stat export | Valor base |
|-------------|------------|
| `bash_base_damage` | 22 |
| `magnum_base_damage` | 28 |
| `bash_interval` (legacy) | 0.85 |
| `magnum_interval` (legacy) | 5 s |

### Bash (auto)

| Nv | Golpes | Intervalo | Mult. | Arco° | Stun |
|----|--------|-----------|-------|-------|------|
| 1 | 1 | 2.0 s | 1.0 | 65 | — |
| 2 | 1 | 1.0 s | 1.1 | 73 | 15% |
| 3 | 2 | 2.0 s | 1.2 | 81 | 15% |
| 4 | 2 | 1.0 s | 1.3 | 89 | 35% |
| 5 | 3 | 1.4 s | 1.4 | 97 | 35% |

Radio bash: `48 + (nv−1)×8`.

### HP Recovery (auto)

| Nv | Intervalo | Curación |
|----|-----------|----------|
| 1 | 1.98 s | 1 HP |
| 2 | 1.76 s | 1 HP |
| 3 | 1.54 s | 2 HP |
| 4 | 1.32 s | 2 HP |
| 5 | 1.10 s | 3 HP |

### Sword Mastery (pasiva)

+5% ATK por nivel (aplicado vía `Global` / multiplicador de ataque).

### Endure (pasiva al recibir golpe)

Reducción de daño: `12% + (nv−1)×6%`; duración buff: `2 + (nv−1)×0.5` s.

### Magnum Break (activa, CD 5 s)

| Nv | Radio | Mult. (× magnum_base) | Knockback | Buff fuego ATK |
|----|-------|----------------------|-----------|----------------|
| 1 | 80 | 1.0 | 180 | +8% 3 s |
| 2 | 94 | 1.14 | 205 | +16% |
| 3 | 108 | 1.28 | 230 | +24% |
| 4 | 122 | 1.42 | 255 | +32% |
| 5 | 136 | 1.56 | 280 | +40% |

### Provoke (activa, CD 6 s)

Radio `100 + (nv−1)×18`; slow `35% + (nv−1)×5%`; shred def `8%×nv`; duración debuff `2 + (nv−1)×0.4` s.

---

## Jefe Creamy

| Stat | Valor |
|------|--------|
| HP | `2000 × 10 × 0.5` = **10 000** |
| Ataque en área (telegraph en jugador) | CD **2.64 s** (+20%), carga **1.35 s**, radio **78**, daño impacto **75** |
| Balas dirigidas | cada **2.8 s** |
| Bala radial (1 disparo) | cada **22 s** |

---

## Cartas (visual)

| Uso | Archivo |
|-----|---------|
| Drop / suelo | `art/cards/carta_{mob}.png` |
| Álbum / menú | `art/cards/{mob}_card.png` o `assets/{mob}_card.png` |
