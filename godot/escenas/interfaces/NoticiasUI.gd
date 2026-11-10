extends CanvasLayer

# Interfaz provisional para probar el sistema. Pulsar N o el botón superior.
var _oscurecer: ColorRect
var _ventana: PanelContainer
var _buzon: Button
var _titulo: Label
var _lista: ItemList
var _texto: Label
var _opciones: VBoxContainer
var _resultado: Label
var _aviso_entrega: Label
var _temporizador_aviso: Timer
var _hoy: Array[Dictionary] = []
var _abierta: bool = false
var _indice_seleccionado: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("noticias_ui")
	_crear_interfaz()
	NoticiasManager.noticias_actualizadas.connect(_actualizar)
	NoticiasManager.noticia_entregada.connect(_al_llegar_noticia)
	_actualizar(NoticiasManager.cuantas_sin_leer())

func _crear_interfaz() -> void:
	_oscurecer = ColorRect.new()
	_oscurecer.color = Color(0.01, 0.02, 0.05, 0.82)
	add_child(_oscurecer)
	_oscurecer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_ventana = PanelContainer.new()
	add_child(_ventana)
	_ventana.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ventana.offset_left = 12
	_ventana.offset_top = 12
	_ventana.offset_right = -12
	_ventana.offset_bottom = -12

	var margen := MarginContainer.new()
	_ventana.add_child(margen)
	margen.add_theme_constant_override("margin_left", 10)
	margen.add_theme_constant_override("margin_right", 10)
	margen.add_theme_constant_override("margin_top", 8)
	margen.add_theme_constant_override("margin_bottom", 8)

	var raiz := VBoxContainer.new()
	margen.add_child(raiz)

	var cabecera := HBoxContainer.new()
	raiz.add_child(cabecera)
	_titulo = Label.new()
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(_titulo)

	var dormir := Button.new()
	dormir.text = "Dormir"
	dormir.pressed.connect(_dormir)
	cabecera.add_child(dormir)

	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.pressed.connect(cerrar_buzon)
	cabecera.add_child(cerrar)

	var cuerpo := HSplitContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(cuerpo)

	_lista = ItemList.new()
	_lista.custom_minimum_size = Vector2(185, 0)
	_lista.item_selected.connect(_seleccionar)
	cuerpo.add_child(_lista)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(scroll)

	var contenido := VBoxContainer.new()
	contenido.custom_minimum_size = Vector2(320, 0)
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(contenido)

	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(_texto)

	_opciones = VBoxContainer.new()
	contenido.add_child(_opciones)
	_resultado = Label.new()
	_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(_resultado)

	_buzon = Button.new()
	add_child(_buzon)
	_buzon.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_buzon.offset_left = -170
	_buzon.offset_top = 5
	_buzon.offset_right = -5
	_buzon.offset_bottom = 38
	_buzon.pressed.connect(abrir_buzon)

	_aviso_entrega = Label.new()
	add_child(_aviso_entrega)
	_aviso_entrega.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_aviso_entrega.offset_left = 220
	_aviso_entrega.offset_top = 44
	_aviso_entrega.offset_right = -220
	_aviso_entrega.offset_bottom = 78
	_aviso_entrega.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_entrega.visible = false

	_temporizador_aviso = Timer.new()
	_temporizador_aviso.one_shot = true
	_temporizador_aviso.wait_time = 4.0
	add_child(_temporizador_aviso)
	_temporizador_aviso.timeout.connect(_ocultar_aviso_entrega)

	cerrar_buzon()

func _actualizar(_cantidad: int) -> void:
	_hoy = NoticiasManager.obtener_noticias_recogidas()
	_titulo.text = "BUZÓN | " + EstadoJuego.etiqueta_dia()
	_buzon.text = "Buzón: %d por leer" % NoticiasManager.cuantas_sin_leer()
	_buzon.tooltip_text = "%d periódicos pendientes de recogida" % NoticiasManager.cuantas_por_recoger()
	_lista.clear()
	for noticia in _hoy:
		var id := str(noticia.get("id", ""))
		var marca := "✓ " if NoticiasManager.leidas.has(id) else "• "
		_lista.add_item(marca + str(noticia.get("titulo", "")))
	if _hoy.is_empty():
		if NoticiasManager.cuantas_por_recoger() > 0:
			_texto.text = "Hay periódicos entregados. Acércate al buzón y pulsa E para recogerlos."
		elif NoticiasManager.cuantas_pendientes_de_entrega() > 0:
			_texto.text = "Aún no ha llegado ningún periódico."
		elif NoticiasManager.obtener_noticias_hoy().is_empty():
			_texto.text = "No hay noticias programadas para este día."
		else:
			_texto.text = "Todavía no has recogido los periódicos de hoy."
		_limpiar_opciones()
	elif _abierta:
		var por_recoger := NoticiasManager.cuantas_por_recoger()
		if por_recoger > 0:
			_texto.text = "%d periódico(s) esperan en el buzón de la habitación. Acércate y pulsa E para recogerlos." % por_recoger
		else:
			_texto.text = "Selecciona un periódico recogido para leerlo."
		_limpiar_opciones()

func _al_llegar_noticia(_noticia_id: String, ultimo_del_dia: bool) -> void:
	if ultimo_del_dia:
		mostrar_mensaje_temporal("Ha llegado el último periódico. El reparto de hoy ha terminado.")
	else:
		mostrar_mensaje_temporal("Ha llegado un nuevo periódico.")

func mostrar_mensaje_temporal(texto: String) -> void:
	_aviso_entrega.text = texto
	_aviso_entrega.visible = true
	_temporizador_aviso.start()

func _ocultar_aviso_entrega() -> void:
	_aviso_entrega.visible = false

func abrir_buzon() -> void:
	_abrir_buzon("")

func abrir_buzon_con_noticia(noticia_id: String) -> void:
	_abrir_buzon(noticia_id)

func _abrir_buzon(noticia_id: String) -> void:
	_abierta = true
	_oscurecer.visible = true
	_ventana.visible = true
	_buzon.visible = false
	GestorPartida.abrir_ventana("noticias")
	_actualizar(NoticiasManager.cuantas_sin_leer())
	if noticia_id.is_empty():
		return
	for indice in range(_hoy.size()):
		if str(_hoy[indice].get("id", "")) == noticia_id:
			_lista.select(indice)
			_indice_seleccionado = indice
			_texto.text = "Has recogido: %s\n\nSelecciona el periódico para leerlo." % str(_hoy[indice].get("titulo", "Periódico"))
			return

func cerrar_buzon() -> void:
	_abierta = false
	if _oscurecer:
		_oscurecer.visible = false
	if _ventana:
		_ventana.visible = false
	if _buzon:
		_buzon.visible = true
	GestorPartida.cerrar_ventana("noticias")


func _exit_tree() -> void:
	GestorPartida.cerrar_ventana("noticias")

func _seleccionar(indice: int) -> void:
	if indice < 0 or indice >= _hoy.size():
		return
	_indice_seleccionado = indice
	var noticia: Dictionary = _hoy[indice]
	var noticia_id := str(noticia.get("id", ""))
	NoticiasManager.marcar_leida(noticia_id)
	# Solo se muestran campos anonimizados: la fecha real, la fuente y si es falsa se revelan en el informe final.
	var dia_publicacion := EstadoJuego.dia_de_fecha(str(noticia.get("disponible_desde", "")))
	_texto.text = str(noticia.get("titulo", "")) \
		+ "\n\n" + str(noticia.get("resumen", "")) \
		+ "\n\nRecibido: Día %d" % dia_publicacion \
		+ "\nMedio: " + str(noticia.get("medio", "Desconocido")) \
		+ "\n\nTexto educativo adaptado por EURASIA. Contrasta la fiabilidad de cada medio."
	_limpiar_opciones()
	var pregunta := NoticiasManager.obtener_pregunta(noticia_id)
	if pregunta.is_empty():
		return
	var explicacion := Label.new()
	explicacion.text = "DECISIÓN: " + str(pregunta.get("enunciado", ""))
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_opciones.add_child(explicacion)
	var respondida := NoticiasManager.respuesta_de(noticia_id)
	for opcion in pregunta.get("opciones", []):
		var boton := Button.new()
		boton.text = str(opcion.get("texto", ""))
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.disabled = not respondida.is_empty()
		boton.pressed.connect(_responder.bind(noticia_id, str(opcion.get("id", ""))))
		_opciones.add_child(boton)
		if str(opcion.get("id", "")) == respondida:
			_resultado.text = "Tu decisión: " + str(opcion.get("explicacion", ""))

func _limpiar_opciones() -> void:
	for hijo in _opciones.get_children():
		_opciones.remove_child(hijo)
		hijo.queue_free()
	_resultado.text = ""

func _responder(noticia_id: String, opcion_id: String) -> void:
	var opcion := NoticiasManager.responder(noticia_id, opcion_id)
	if not opcion.is_empty():
		_actualizar(NoticiasManager.cuantas_sin_leer())
		_seleccionar(_indice_seleccionado)
		_resultado.text = "Consecuencia educativa: " + str(opcion.get("explicacion", ""))

func _dormir() -> void:
	if NoticiasManager.avanzar_dia():
		_actualizar(NoticiasManager.cuantas_sin_leer())
	else:
		_resultado.text = NoticiasManager.motivo_no_puede_dormir()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		if _abierta:
			cerrar_buzon()
		else:
			abrir_buzon()
		get_viewport().set_input_as_handled()
