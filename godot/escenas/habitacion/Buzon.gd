extends Area2D
## Punto provisional de recogida. Acércate y pulsa E.

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
	if NoticiasManager.cuantas_por_recoger() > 0:
		_indicador.text = "E: recoger periódico"
	elif NoticiasManager.cuantas_pendientes_de_entrega() > 0:
		_indicador.text = "Esperando reparto…"
	else:
		_indicador.text = "Buzón vacío"


func _unhandled_input(event: InputEvent) -> void:
	if not _jugador_cerca:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_interactuar()
		get_viewport().set_input_as_handled()


func _interactuar() -> void:
	var interfaz := get_tree().get_first_node_in_group("noticias_ui")
	if interfaz == null:
		push_warning("No se encontró la interfaz del buzón.")
		return

	var noticia := NoticiasManager.recoger_siguiente_noticia()
	if noticia.is_empty():
		if NoticiasManager.cuantas_pendientes_de_entrega() > 0:
			interfaz.call("mostrar_mensaje_temporal", "Todavía no ha llegado ningún periódico.")
		else:
			interfaz.call("mostrar_mensaje_temporal", "No hay periódicos por recoger.")
		return

	interfaz.call("abrir_buzon_con_noticia", str(noticia.get("id", "")))
