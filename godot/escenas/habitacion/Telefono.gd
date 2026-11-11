extends Area2D
## Teléfono provisional para futuros eventos personales.

@onready var _indicador: Label = $Indicador
var _jugador_cerca: bool = false


func _ready() -> void:
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
	if not _jugador_cerca or GestorPartida.hay_ventanas_abiertas():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_consultar_telefono()
		get_viewport().set_input_as_handled()


func _consultar_telefono() -> void:
	var hud := get_tree().get_first_node_in_group("hud_habitacion")
	if hud == null:
		push_warning("No se encontró el HUD para mostrar el estado del teléfono.")
		return
	hud.call("mostrar_mensaje_temporal", "No hay llamadas pendientes.")
