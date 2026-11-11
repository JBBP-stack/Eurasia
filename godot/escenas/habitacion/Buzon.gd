extends Area2D
## Aquí se reciben y recogen los periódicos. E recoge; W abre después el buzón para leer.

const TEXTURA_PERIODICO: String = "res://assets/objetos/Periódico-20261108-135436.png"
const TEXTURA_PERIODICO_ABIERTO: String = "res://assets/objetos/periodico_recogido.png"

@onready var _indicador: Label = $Indicador

var _jugador_cercano: Node2D
var _alerta: Label
var _tween_alerta: Tween
var _periodicos_visuales: Array[Sprite2D] = []


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


func _actualizar_indicador(_cantidad: int) -> void:
	_sincronizar_periodicos_visuales()
	_actualizar_alerta()
	_indicador.visible = _jugador_cercano != null
	if _jugador_cercano == null:
		return
	if NoticiasManager.cuantas_por_recoger() > 0:
		_indicador.text = "E: recoger periódico · W: leer"
	elif NoticiasManager.cuantas_pendientes_de_entrega() > 0:
		_indicador.text = "Esperando reparto…"
	else:
		_indicador.text = "W: abrir buzón"


func _sincronizar_periodicos_visuales() -> void:
	var cantidad := NoticiasManager.cuantas_por_recoger()
	while _periodicos_visuales.size() < cantidad:
		_periodicos_visuales.append(_crear_sprite_periodico(TEXTURA_PERIODICO))
	while _periodicos_visuales.size() > cantidad:
		_periodicos_visuales.pop_back().queue_free()
	for indice in range(_periodicos_visuales.size()):
		_periodicos_visuales[indice].position = _posicion_periodico(indice)


func _crear_sprite_periodico(textura: String) -> Sprite2D:
	var periodico := Sprite2D.new()
	if ResourceLoader.exists(textura):
		periodico.texture = load(textura) as Texture2D
	periodico.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	periodico.scale = Vector2(0.48, 0.48)
	periodico.z_index = 5
	add_child(periodico)
	return periodico


func _posicion_periodico(indice: int) -> Vector2:
	var fila := floori(float(indice) / 3.0)
	return Vector2(float((indice % 3) - 1) * 4.0, -18.0 - float(fila) * 3.0)


func _al_llegar_periodico(_noticia_id: String, _ultimo_del_dia: bool) -> void:
	if _periodicos_visuales.is_empty():
		return
	var periodico: Sprite2D = _periodicos_visuales.back()
	var destino: Vector2 = _posicion_periodico(_periodicos_visuales.size() - 1)
	periodico.position = destino + Vector2(0, -54)
	periodico.rotation = -0.4
	periodico.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(periodico, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(periodico, "position", destino, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(periodico, "rotation", 0.0, 0.6)


func _al_entrar_en_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cercano = cuerpo
		_actualizar_indicador(0)


func _al_salir_del_rango(cuerpo: Node2D) -> void:
	if cuerpo == _jugador_cercano:
		_jugador_cercano = null
	_actualizar_indicador(0)


func _unhandled_input(event: InputEvent) -> void:
	if _jugador_cercano == null or GestorPartida.hay_ventanas_abiertas():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_interactuar()
		get_viewport().set_input_as_handled()


func _interactuar() -> void:
	var periodico_visual: Sprite2D = null
	if not _periodicos_visuales.is_empty():
		periodico_visual = _periodicos_visuales.pop_back()
	var noticia := NoticiasManager.recoger_siguiente_noticia()
	if noticia.is_empty():
		if is_instance_valid(periodico_visual):
			periodico_visual.queue_free()
		var hud_sin_noticia := get_tree().get_first_node_in_group("hud_habitacion")
		if hud_sin_noticia:
			hud_sin_noticia.call("mostrar_mensaje_temporal", "Todavía no ha llegado ningún periódico." if NoticiasManager.cuantas_pendientes_de_entrega() > 0 else "No hay periódicos por recoger.")
		return

	if not is_instance_valid(periodico_visual):
		periodico_visual = _crear_sprite_periodico(TEXTURA_PERIODICO_ABIERTO)
	if ResourceLoader.exists(TEXTURA_PERIODICO_ABIERTO):
		periodico_visual.texture = load(TEXTURA_PERIODICO_ABIERTO) as Texture2D
	periodico_visual.position = _posicion_periodico(_periodicos_visuales.size())
	periodico_visual.scale = Vector2(0.12, 0.48)
	periodico_visual.rotation = -0.2
	periodico_visual.modulate.a = 1.0
	var destino := to_local(_jugador_cercano.global_position) + Vector2(0, -14)
	var tween := create_tween()
	tween.tween_property(periodico_visual, "position", destino, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(periodico_visual, "scale", Vector2(0.6, 0.6), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(periodico_visual, "rotation", 0.0, 0.28)
	tween.tween_interval(0.22)
	tween.tween_property(periodico_visual, "modulate:a", 0.0, 0.24)
	tween.tween_callback(periodico_visual.queue_free)

	var hud := get_tree().get_first_node_in_group("hud_habitacion")
	if hud:
		hud.call("mostrar_mensaje_temporal", "Has recogido «%s». Pulsa W para leer el periódico." % str(noticia.get("titulo", "el periódico")), 5.0)
