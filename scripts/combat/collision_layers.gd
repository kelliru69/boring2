## Capas de colisión 2D del proyecto (Godot 4).
## Valores = bit de capa (1, 2, 4, 8...), no el índice del editor.
class_name CollisionLayers
extends RefCounted

const LAYER_PLAYER: int = 1
const LAYER_ENEMIES: int = 2
const LAYER_PROJECTILES: int = 4
const LAYER_LOOT: int = 8

## Cuerpo físico del jugador: choca con enemigos.
const MASK_PLAYER_BODY: int = LAYER_ENEMIES

## Cuerpo físico del enemigo: choca con jugador y entre ellos.
const MASK_ENEMY_BODY: int = LAYER_PLAYER | LAYER_ENEMIES

## Oleada en línea (muro direccional): sin colisión física; atraviesan mobs y jugador.
const MASK_ENEMY_LINEAR_WAVE: int = 0
