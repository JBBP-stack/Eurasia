extends CanvasLayer
## El buzón sirve para leer periódicos ya recogidos y consultar la hemeroteca.
## E recoge físicamente; W o el botón abren/cerran esta interfaz.

var _oscurecer: ColorRect
var _ventana: PanelContainer
var _buzon: Button
var _titulo: Label
var _lista: ItemList
var _texto: Label
var _hoy: Array[Dictionary] = []
var _abierta: bool = false
var _indice_seleccionado: int = -1
var _modo_hemeroteca: bool = false
var _boton_recogidos: Button
var _boton_hemeroteca: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("noticias_ui")
	_crear_interfaz()
	NoticiasManager.noticias_actualizadas.connect(_actualizar)
	_actualizar(NoticiasManager.cuantas_sin_leer())


func _crear_interfaz() -> void:
	_oscurecer = ColorRect.new()
	_oscurecer.color = Color(0.01, 0.02, 0.05, 0.88)
	_oscurecer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_oscurecer)
	_oscurecer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_ventana = PanelContainer.new()
	add_child(_ventana)
	_ventana.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ventana.offset_left = 18
	_ventana.offset_top = 14
	_ventana.offset_right = -18
	_ventana.offset_bottom = -14

	var margen := MarginContainer.new()
	_ventana.add_child(margen)
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 14)
	for lado in ["top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 10)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 8)
	margen.add_child(raiz)

	var cabecera := HBoxContainer.new()
	raiz.add_child(cabecera)
	_titulo = Label.new()
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(_titulo)
	var cerrar := Button.new()
	cerrar.text = "Cerrar (W / Esc)"
	cerrar.pressed.connect(cerrar_buzon)
	cabecera.add_child(cerrar)

	var modos := HBoxContainer.new()
	modos.add_theme_constant_override("separation", 6)
	raiz.add_child(modos)
	var grupo := ButtonGroup.new()
	_boton_recogidos = Button.new()
	_boton_recogidos.text = "Periódicos recogidos"
	_boton_recogidos.toggle_mode = true
	_boton_recogidos.button_group = grupo
	_boton_recogidos.button_pressed = true
	_boton_recogidos.pressed.connect(func() -> void: _cambiar_modo(false))
	modos.add_child(_boton_recogidos)
	_boton_hemeroteca = Button.new()
	_boton_hemeroteca.text = "Hemeroteca · últimos dos años"
	_boton_hemeroteca.toggle_mode = true
	_boton_hemeroteca.button_group = grupo
	_boton_hemeroteca.pressed.connect(func() -> void: _cambiar_modo(true))
	modos.add_child(_boton_hemeroteca)

	var ayuda := Label.new()
	ayuda.text = "Selecciona un titular para leerlo. Las decisiones se responden aparte con D."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(ayuda)

	var cuerpo := HSplitContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.split_offset = 250
	raiz.add_child(cuerpo)

	_lista = ItemList.new()
	_lista.custom_minimum_size = Vector2(230, 0)
	_lista.item_selected.connect(_seleccionar)
	cuerpo.add_child(_lista)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cuerpo.add_child(scroll)

	_texto = Label.new()
	_texto.custom_minimum_size = Vector2(320, 0)
	_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(_texto)

	_buzon = Button.new()
	add_child(_buzon)
	_buzon.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_buzon.offset_left = -220
	_buzon.offset_top = 5
	_buzon.offset_right = -10
	_buzon.offset_bottom = 38
	_buzon.pressed.connect(_alternar_buzon)

	cerrar_buzon()


func _cambiar_modo(hemeroteca: bool) -> void:
	_modo_hemeroteca = hemeroteca
	_indice_seleccionado = -1
	_actualizar(NoticiasManager.cuantas_sin_leer())


## «Día N» para noticias de la partida; «Hace N meses» para la hemeroteca.
func _antiguedad(noticia: Dictionary) -> String:
	var fecha := str(noticia.get("disponible_desde", ""))
	var dia := EstadoJuego.dia_de_fecha(fecha)
	if dia >= 1:
		return "Día %d" % dia
	var dias := EstadoJuego.dia_de_partida - dia
	var meses := int(round(float(dias) / 30.4))
	if meses >= 12:
		var anios := floori(float(meses) / 12.0)
		var resto := meses % 12
		return "Hace %d año%s%s" % [anios, "" if anios == 1 else "s", (" y %d mes%s" % [resto, "" if resto == 1 else "es"]) if resto > 0 else ""]
	if meses >= 1:
		return "Hace %d mes%s" % [meses, "" if meses == 1 else "es"]
	return "Hace %d días" % dias


func _actualizar(_cantidad: int) -> void:
	var id_seleccionado := ""
	if _indice_seleccionado >= 0 and _indice_seleccionado < _hoy.size():
		id_seleccionado = str(_hoy[_indice_seleccionado].get("id", ""))
	_hoy = NoticiasManager.obtener_hemeroteca() if _modo_hemeroteca else NoticiasManager.obtener_noticias_recogidas()
	_titulo.text = ("HEMEROTECA" if _modo_hemeroteca else "PERIÓDICOS RECOGIDOS") + " · " + EstadoJuego.etiqueta_dia()
	_buzon.text = "Cerrar buzón (W)" if _abierta else _texto_boton_buzon()
	_buzon.tooltip_text = "%d por recoger · %d sin leer" % [NoticiasManager.cuantas_por_recoger(), NoticiasManager.cuantas_sin_leer()]
	_lista.clear()
	var indice_restaurado := -1
	for indice in range(_hoy.size()):
		var noticia: Dictionary = _hoy[indice]
		var id := str(noticia.get("id", ""))
		var prefijo := "✓ " if not _modo_hemeroteca and NoticiasManager.leidas.has(id) else "• "
		var titular := "[%s] %s" % [str(noticia.get("seccion", "")), str(noticia.get("titulo", ""))]
		_lista.add_item(titular if _modo_hemeroteca else prefijo + titular)
		if id == id_seleccionado:
			indice_restaurado = indice

	if indice_restaurado >= 0:
		_indice_seleccionado = indice_restaurado
		_lista.select(indice_restaurado)
		_mostrar_noticia(indice_restaurado)
		return

	_indice_seleccionado = -1
	if _modo_hemeroteca:
		_texto.text = "Selecciona una noticia de la hemeroteca." if not _hoy.is_empty() else "La hemeroteca está vacía."
	elif _hoy.is_empty():
		if NoticiasManager.cuantas_por_recoger() > 0:
			_texto.text = "%d periódico(s) esperan en el buzón. Cierra con W, acércate y pulsa E para recogerlos." % NoticiasManager.cuantas_por_recoger()
		elif NoticiasManager.cuantas_pendientes_de_entrega() > 0:
			_texto.text = "Aún no ha llegado ningún periódico. Cuando llegue, aparecerá en el buzón de la habitación."
		elif NoticiasManager.obtener_noticias_hoy().is_empty():
			_texto.text = "Hoy no hay noticias programadas. Puedes consultar la hemeroteca."
		else:
			_texto.text = "Todavía no has recogido los periódicos de hoy."
	else:
		_texto.text = "Selecciona un periódico recogido para leerlo."


func _mostrar_noticia(indice: int) -> void:
	if indice < 0 or indice >= _hoy.size():
		return
	var noticia: Dictionary = _hoy[indice]
	var noticia_id := str(noticia.get("id", ""))
	if not bool(noticia.get("archivo", false)) and not NoticiasManager.leidas.has(noticia_id):
		NoticiasManager.marcar_leida(noticia_id)
	var pregunta := NoticiasManager.obtener_pregunta(noticia_id)
	var ayuda_decision := ""
	if not pregunta.is_empty():
		ayuda_decision = "\n\nEsta noticia tiene una pregunta de análisis. Pulsa D para verla y responderla en el panel de decisiones."
	_texto.text = str(noticia.get("seccion", "Noticias")).to_upper() + "\n\n" + str(noticia.get("titulo", "")) \
		+ "\n\n" + str(noticia.get("resumen", "")) \
		+ "\n\nPublicado: " + _antiguedad(noticia) \
		+ "\nMedio: " + str(noticia.get("medio", "Desconocido")) \
		+ "\n\nTexto educativo adaptado por EURASIA. Contrasta la fiabilidad de cada medio." \
		+ ayuda_decision


func _seleccionar(indice: int) -> void:
	_indice_seleccionado = indice
	_mostrar_noticia(indice)


func abrir_buzon() -> void:
	if _abierta or GestorPartida.hay_ventanas_abiertas() or not EstadoJuego.partida_iniciada:
		return
	_abierta = true
	_buzon.visible = false
	_oscurecer.visible = true
	_ventana.visible = true
	GestorPartida.abrir_ventana("noticias")
	_actualizar(NoticiasManager.cuantas_sin_leer())


func cerrar_buzon() -> void:
	_abierta = false
	_indice_seleccionado = -1
	if _oscurecer:
		_oscurecer.visible = false
	if _ventana:
		_ventana.visible = false
	if _buzon:
		_buzon.visible = true
		_buzon.text = _texto_boton_buzon()
	GestorPartida.cerrar_ventana("noticias")


func _texto_boton_buzon() -> String:
	var por_recoger := NoticiasManager.cuantas_por_recoger()
	if por_recoger > 0:
		return "Buzón (W) · %d por recoger" % por_recoger
	return "Buzón (W) · %d sin leer" % NoticiasManager.cuantas_sin_leer()


func _alternar_buzon() -> void:
	if _abierta:
		cerrar_buzon()
	else:
		abrir_buzon()


func _exit_tree() -> void:
	GestorPartida.cerrar_ventana("noticias")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if _abierta:
		if event.keycode in [KEY_ESCAPE, KEY_W]:
			cerrar_buzon()
			get_viewport().set_input_as_handled()
	elif event.keycode == KEY_W and not GestorPartida.hay_ventanas_abiertas() and EstadoJuego.partida_iniciada:
		abrir_buzon()
		get_viewport().set_input_as_handled()
