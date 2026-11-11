extends Area2D
## Portátil: abre la consulta financiera y el asistente de análisis de noticias.

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
		_indicador.text = "E: portátil (análisis disponible)"
	else:
		_indicador.text = "E: usar portátil"


func _unhandled_input(event: InputEvent) -> void:
	if not _jugador_cerca:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_consultar_estado()
		get_viewport().set_input_as_handled()


func _consultar_estado() -> void:
	var portatil_ui := get_tree().get_first_node_in_group("portatil_ui")
	if portatil_ui == null:
		push_warning("No se encontró la interfaz del portátil.")
		return
	# Si el análisis está disponible se abre directamente la pestaña del asistente.
	var pestana: int = 5 if NoticiasManager.puede_analizar_noticias_hoy() else 0
	portatil_ui.call("abrir_portatil", pestana)
