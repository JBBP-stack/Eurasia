
extends CharacterBody2D

## Orden de los fotogramas en jugador_idle_4_direcciones_32x48.png.
const FRAME_ABAJO := 0
const FRAME_IZQUIERDA := 1
const FRAME_ARRIBA := 2
const FRAME_DERECHA := 3

@export var velocidad: float = 100.0

@onready var _sprite: Sprite2D = $Sprite


func _physics_process(_delta: float) -> void:
	var direccion := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	velocity = direccion * velocidad
	move_and_slide()
	_orientar(direccion)


## Mira hacia donde se mueve; al pararse conserva la última orientación.
func _orientar(direccion: Vector2) -> void:
	if direccion == Vector2.ZERO:
		return
	if absf(direccion.x) > absf(direccion.y):
		_sprite.frame = FRAME_DERECHA if direccion.x > 0.0 else FRAME_IZQUIERDA
	else:
		_sprite.frame = FRAME_ABAJO if direccion.y > 0.0 else FRAME_ARRIBA
