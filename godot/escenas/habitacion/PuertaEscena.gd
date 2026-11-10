extends Area2D
## Puerta de transición entre la habitación y el banco.

@export_file("*.tscn") var escena_destino: String
@export var guardar_posicion_habitacion: bool = false
@export var restaurar_posicion_habitacion: bool = false
@export var texto_indicador: String = "E: entrar"

@onready var _indicador: Label = $Indicador
var _jugador_cerca: bool = false
var _transicionando: bool = false


func _ready() -> void:
	_indicador.text = texto_indicador
	body_entered.connect(_al_entrar_en_rango)
	body_exited.connect(_al_salir_del_rango)


func _al_entrar_en_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = true
		_indicador.visible = true


func _al_salir_del_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = false
		_indicador.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _jugador_cerca or _transicionando:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		get_viewport().set_input_as_handled()
		_transicionar()


func _transicionar() -> void:
	if escena_destino.is_empty():
		push_warning("La puerta no tiene una escena de destino asignada.")
		return

	var destino: String = escena_destino
	var debe_restaurar: bool = restaurar_posicion_habitacion
	if guardar_posicion_habitacion:
		var jugador := get_tree().current_scene.get_node_or_null("Jugador") as Node2D
		if jugador != null:
			EstadoJuego.posicion_retorno_habitacion = jugador.global_position + Vector2(0, 32)

	if debe_restaurar:
		EstadoJuego.regresar_a_habitacion = true
	_transicionando = true
	var error := get_tree().change_scene_to_file(destino)
	if error != OK:
		_transicionando = false
		if debe_restaurar:
			EstadoJuego.regresar_a_habitacion = false
		push_error("No se pudo cargar la escena: " + destino)
