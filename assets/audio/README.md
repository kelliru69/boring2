# Música y sonidos personalizados

## Canciones por contexto

| Archivo (en `assets/audio/`) | Cuándo suena |
|-------------------------------|--------------|
| **`bgm_menu.ogg`** (o `.mp3` / `.wav`) | Menú principal y hub de preparación |
| **`bgm_field.ogg`** / **`bgm_field.mp3`** | Partida en **Prontera Fields** |
| **`bgm_payon.ogg`** (o `.mp3` / `.wav`) | Partida en **Payon Dungeon** |

Si falta `bgm_menu.*`, el menú usa `bgm_field` como respaldo.  
Si falta `bgm_payon.*`, Payon usa `bgm_field`.

### Rutas en código (opcional)

En `data/map_config.gd` puedes cambiar `"bgm_path"` por mapa.

---

## Poner tus archivos

1. Copia las canciones a `assets/audio/`
2. Usa los nombres de la tabla (recomendado: **.ogg**)
3. En Godot: clic en el archivo → **Importar** → activa **Loop** → **Volver a importar**
4. **F5** para probar

### Override global (todas las partidas)

**Proyecto → Configuración → Autoload → Audio → Custom Bgm Path**  
(solo afecta el fallback de Prontera si no hay `bgm_field.*`)

---

## Efectos de sonido

Los SFX (disparos, monedas, UI) siguen siendo procedurales. Solo sustituyes las **músicas de fondo**.
