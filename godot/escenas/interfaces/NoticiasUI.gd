extends CanvasLayer

# Interfaz provisional para probar el sistema. Pulsar N o el botón superior.
var _oscurecer: ColorRect
var _ventana: PanelContainer
var _buzon: Button
var _titulo: Label
var _lista: ItemList
var _texto: Label
var _enlace: Button
var _opciones: VBoxContainer
var _resultado: Label
var _origen_url: String = ""
var _hoy: Array[Dictionary] = []
var _abierta: bool = false
var _indice_seleccionado: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_interfaz()
	NoticiasManager.noticias_actualizadas.connect(_actualizar)
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
	dormir.text = "Dormir (demo)"
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

	_enlace = Button.new()
	_enlace.text = "Ver fuente original"
	_enlace.pressed.connect(_abrir_fuente)
	contenido.add_child(_enlace)

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
	cerrar_buzon()

func _actualizar(_cantidad: int) -> void:
	_hoy = NoticiasManager.obtener_noticias_hoy()
	_titulo.text = "BUZÓN | " + EstadoJuego.etiqueta_dia()	
	_buzon.text = "Buzón: %d nueva(s)" % NoticiasManager.cuantas_sin_leer()
	_lista.clear()
	for noticia in _hoy:
		var id := str(noticia.get("id", ""))
		var marca := "✓ " if NoticiasManager.leidas.has(id) else "• "
		_lista.add_item(marca + str(noticia.get("titulo", "")))
	if _hoy.is_empty():
		_texto.text = "No se han programado noticias relevantes para este día."
		_enlace.visible = false
		_limpiar_opciones()
	elif _abierta:
		_seleccionar(mini(_indice_seleccionado, _hoy.size() - 1))

func abrir_buzon() -> void:
	_abierta = true
	_oscurecer.visible = true
	_ventana.visible = true
	_buzon.visible = false
	get_tree().paused = true
	_actualizar(NoticiasManager.cuantas_sin_leer())

func cerrar_buzon() -> void:
	_abierta = false
	if _oscurecer:
		_oscurecer.visible = false
	if _ventana:
		_ventana.visible = false
	if _buzon:
		_buzon.visible = true
	get_tree().paused = false

func _seleccionar(indice: int) -> void:
	if indice < 0 or indice >= _hoy.size():
		return
	_indice_seleccionado = indice
	var noticia: Dictionary = _hoy[indice]
	var noticia_id := str(noticia.get("id", ""))
	NoticiasManager.marcar_leida(noticia_id)
	_texto.text = str(noticia.get("titulo", "")) \
		+ "\n\n" + str(noticia.get("resumen", "")) \
		+ "\n\nPublicado: " + str(noticia.get("fecha_publicacion", "")) \
		+ "\nFuente: " + str(noticia.get("fuente", "")) \
		+ "\n\nTexto educativo adaptado por EURASIA."
	_origen_url = str(noticia.get("fuente_url", ""))
	_enlace.visible = not _origen_url.is_empty()
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
		_resultado.text = "Consecuencia educativa: " + str(opcion.get("explicacion", ""))
		_actualizar(NoticiasManager.cuantas_sin_leer())

func _dormir() -> void:
	if NoticiasManager.avanzar_dia():
		_actualizar(NoticiasManager.cuantas_sin_leer())
	else:
		_resultado.text = "Debes responder las decisiones pendientes antes de dormir."

func _abrir_fuente() -> void:
	if _origen_url.begins_with("https://"):
		OS.shell_open(_origen_url)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		if _abierta:
			cerrar_buzon()
		else:
			abrir_buzon()
		get_viewport().set_input_as_handled()
