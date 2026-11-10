extends Node2D
## Restaura la posición del jugador al volver del banco.


func _ready() -> void:
	if not EstadoJuego.regresar_a_habitacion:
		return

	var jugador := get_node_or_null("Jugador") as Node2D
	if jugador != null:
		jugador.global_position = EstadoJuego.posicion_retorno_habitacion
	EstadoJuego.regresar_a_habitacion = false
