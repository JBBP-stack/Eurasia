extends Area2D
## Interacción provisional que comprueba si el análisis diario está desbloqueado.

@onready var _indicador: Label = $Indicador
var _jugador_cerca: bool = false


func _ready() -> void:
	body_entered.connect(_al_entrar_en_rango)
	body_exited.connect(_al_salir_del_rango)
	NoticiasManager.noticias_actualizadas.connect(_actualizar_indicador)
	_actualizar_indicador(0)


func _al_entrar_en_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = true
		_actualizar_indicador(0)


func _al_salir_del_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = false
		_actualizar_indicador(0)


func _actualizar_indicador(_cantidad: int) -> void:
	_indicador.visible = _jugador_cerca
	if not _jugador_cerca:
		return
	if NoticiasManager.puede_analizar_noticias_hoy():
		_indicador.text = "E: consultar análisis"
	else:
		_indicador.text = "E: estado del análisis"


func _unhandled_input(event: InputEvent) -> void:
	if not _jugador_cerca:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_consultar_estado()
		get_viewport().set_input_as_handled()


func _consultar_estado() -> void:
	var hud := get_tree().get_first_node_in_group("hud_habitacion")
	if hud == null:
		push_warning("No se encontró el HUD para mostrar el estado del análisis.")
		return

	if NoticiasManager.puede_analizar_noticias_hoy():
		hud.call("mostrar_mensaje_temporal", "Análisis desbloqueado. La integración con Claude está pendiente.")
	else:
		hud.call("mostrar_mensaje_temporal", NoticiasManager.motivo_analisis_no_disponible())
