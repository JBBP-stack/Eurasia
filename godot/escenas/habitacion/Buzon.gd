extends Area2D
## Punto de recogida de periódicos. Acércate y pulsa E.
## Cuando llega un periódico se anima su caída y aparece un aviso "!" hasta que se recoge.

const TEXTURA_PERIODICO: String = "res://assets/objetos/Periódico-20261108-135436.png"

@onready var _indicador: Label = $Indicador
var _jugador_cerca: bool = false
var _alerta: Label
var _tween_alerta: Tween


func _ready() -> void:
	body_entered.connect(_al_entrar_en_rango)
	body_exited.connect(_al_salir_del_rango)
	_crear_alerta()
	NoticiasManager.noticias_actualizadas.connect(_actualizar_indicador)
	NoticiasManager.noticia_entregada.connect(_al_llegar_periodico)
	_actualizar_indicador(0)


func _crear_alerta() -> void:
	_alerta = Label.new()
	_alerta.text = "!"
	_alerta.add_theme_font_size_override("font_size", 16)
	_alerta.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_alerta.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	_alerta.add_theme_constant_override("outline_size", 4)
	_alerta.position = Vector2(-4, -36)
	_alerta.visible = false
	add_child(_alerta)


func _actualizar_alerta() -> void:
	var pendientes := NoticiasManager.cuantas_por_recoger() > 0
	_alerta.visible = pendientes
	if pendientes and (_tween_alerta == null or not _tween_alerta.is_valid()):
		_tween_alerta = create_tween().set_loops()
		_tween_alerta.tween_property(_alerta, "position:y", -40.0, 0.4).set_trans(Tween.TRANS_SINE)
		_tween_alerta.tween_property(_alerta, "position:y", -34.0, 0.4).set_trans(Tween.TRANS_SINE)
	elif not pendientes and _tween_alerta != null:
		_tween_alerta.kill()
		_tween_alerta = null


func _al_llegar_periodico(_noticia_id: String, _ultimo_del_dia: bool) -> void:
	var periodico := Sprite2D.new()
	if ResourceLoader.exists(TEXTURA_PERIODICO):
		periodico.texture = load(TEXTURA_PERIODICO)
	else:
		var marcador := Polygon2D.new()
		marcador.polygon = PackedVector2Array([Vector2(-8, -6), Vector2(8, -6), Vector2(8, 6), Vector2(-8, 6)])
		marcador.color = Color(0.92, 0.9, 0.82)
		periodico.add_child(marcador)
	periodico.position = Vector2(0, -70)
	periodico.rotation = -0.4
	periodico.modulate.a = 0.0
	add_child(periodico)
	var tween := create_tween()
	tween.tween_property(periodico, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(periodico, "position:y", -6.0, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(periodico, "rotation", 0.0, 0.6)
	tween.tween_interval(0.6)
	tween.tween_property(periodico, "modulate:a", 0.0, 0.3)
	tween.tween_callback(periodico.queue_free)


func _al_entrar_en_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = true
		_actualizar_indicador(0)


func _al_salir_del_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = false
	_actualizar_indicador(0)


func _actualizar_indicador(_cantidad: int) -> void:
	_actualizar_alerta()
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
