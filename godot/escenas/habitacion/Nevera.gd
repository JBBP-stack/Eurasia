extends Area2D
## Nevera: abre la interfaz para consultar existencias, comer y comprar comida.

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
	if not _jugador_cerca:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_consultar_existencias()
		get_viewport().set_input_as_handled()


func _consultar_existencias() -> void:
	var nevera_ui := get_tree().get_first_node_in_group("nevera_ui")
	if nevera_ui == null:
		push_warning("No se encontró la interfaz de la nevera.")
		return
	nevera_ui.call("abrir_nevera")
