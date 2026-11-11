extends CanvasLayer
## Visor de términos financieros cargados desde un JSON local.

const RUTA_DATOS: String = "res://datos/diccionario_financiero.json"

var _fondo: ColorRect
var _panel: PanelContainer
var _filtro: LineEdit
var _lista: ItemList
var _detalle: Label
var _terminos: Array[Dictionary] = []
var _resultados: Array[Dictionary] = []
var _abierta: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("diccionario_ui")
	_crear_interfaz()
	_cargar_terminos()
	_cerrar_diccionario()


func _crear_interfaz() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.01, 0.02, 0.05, 0.82)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_panel = PanelContainer.new()
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 12
	_panel.offset_top = 12
	_panel.offset_right = -12
	_panel.offset_bottom = -12

	var margen := MarginContainer.new()
	_panel.add_child(margen)
	margen.add_theme_constant_override("margin_left", 10)
	margen.add_theme_constant_override("margin_right", 10)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 10)

	var raiz := VBoxContainer.new()
	margen.add_child(raiz)

	var cabecera := HBoxContainer.new()
	raiz.add_child(cabecera)
	var titulo := Label.new()
	titulo.text = "DICCIONARIO FINANCIERO"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)

	var cerrar := Button.new()
	cerrar.text = "Cerrar  (Esc)"
	cerrar.pressed.connect(_cerrar_diccionario)
	cabecera.add_child(cerrar)

	_filtro = LineEdit.new()
	_filtro.placeholder_text = "Busca cualquier palabra: quiebra, hipoteca, fondo de garantía, bulo..."
	_filtro.text_changed.connect(_filtrar)
	raiz.add_child(_filtro)

	var cuerpo := HSplitContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(cuerpo)

	_lista = ItemList.new()
	_lista.custom_minimum_size = Vector2(300, 0)
	_lista.item_selected.connect(_seleccionar_termino)
	cuerpo.add_child(_lista)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(scroll)

	_detalle = Label.new()
	_detalle.custom_minimum_size = Vector2(230, 0)
	_detalle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(_detalle)


func _cargar_terminos() -> void:
	if not FileAccess.file_exists(RUTA_DATOS):
		push_error("No existe el archivo del diccionario: " + RUTA_DATOS)
		_detalle.text = "No se pudo cargar el diccionario."
		return

	var contenido := FileAccess.get_file_as_string(RUTA_DATOS)
	var datos: Variant = JSON.parse_string(contenido)
	if not datos is Dictionary:
		push_error("El JSON del diccionario no contiene un objeto válido.")
		_detalle.text = "No se pudo leer el diccionario."
		return

	var lista_datos: Variant = datos.get("terminos", [])
	if not lista_datos is Array:
		push_error("El campo 'terminos' del diccionario debe ser una lista.")
		_detalle.text = "No hay términos disponibles."
		return

	for termino in lista_datos:
		if termino is Dictionary:
			_terminos.append(termino)
	_filtrar("")


## Busca cualquier palabra: primero en el nombre y sinónimos, después en definiciones y ejemplos.
## Si no hay resultados, sugiere los términos con el nombre más parecido.
func _filtrar(texto: String) -> void:
	_resultados.clear()
	_lista.clear()
	var consulta := _normalizar(texto)
	var palabras := consulta.split(" ", false)

	var en_nombre: Array[Dictionary] = []
	var en_texto: Array[Dictionary] = []
	for termino in _terminos:
		if palabras.is_empty():
			en_nombre.append(termino)
			continue
		var nombre := _normalizar(str(termino.get("termino", "")) + " " + " ".join(termino.get("aliases", [])))
		var cuerpo := _normalizar(str(termino.get("definicion", "")) + " " + str(termino.get("ejemplo", "")))
		if _contiene_todas(nombre, palabras):
			en_nombre.append(termino)
		elif _contiene_todas(nombre + " " + cuerpo, palabras):
			en_texto.append(termino)

	for termino in en_nombre:
		_resultados.append(termino)
		_lista.add_item(str(termino.get("termino", "")))
	for termino in en_texto:
		_resultados.append(termino)
		_lista.add_item(str(termino.get("termino", "")) + "  (en la definición)")

	if _resultados.is_empty():
		_mostrar_sugerencias(consulta)
	else:
		_lista.select(0)
		_mostrar_termino(0)


func _contiene_todas(texto: String, palabras: PackedStringArray) -> bool:
	for palabra in palabras:
		if not texto.contains(palabra):
			return false
	return true


func _mostrar_sugerencias(consulta: String) -> void:
	var puntuados: Array = []
	for termino in _terminos:
		var mejor := _normalizar(str(termino.get("termino", ""))).similarity(consulta)
		for alias in termino.get("aliases", []):
			mejor = maxf(mejor, _normalizar(str(alias)).similarity(consulta))
		puntuados.append([mejor, termino])
	puntuados.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	for indice in range(mini(5, puntuados.size())):
		var termino: Dictionary = puntuados[indice][1]
		_resultados.append(termino)
		_lista.add_item("¿Quizás? " + str(termino.get("termino", "")))
	_detalle.text = "No hay ningún término con «%s».\n\nA la izquierda tienes los términos más parecidos. Si buscas algo que no está en el diccionario, pregúntaselo al asistente del portátil." % consulta


func _normalizar(texto: String) -> String:
	return texto.strip_edges().to_lower().replace(",", " ").replace(".", " ") \
		.replace("á", "a").replace("é", "e").replace("í", "i") \
		.replace("ó", "o").replace("ú", "u").replace("ü", "u")


func _seleccionar_termino(indice: int) -> void:
	_mostrar_termino(indice)


func _mostrar_termino(indice: int) -> void:
	if indice < 0 or indice >= _resultados.size():
		return
	var termino: Dictionary = _resultados[indice]
	_detalle.text = str(termino.get("termino", "")) \
		+ "\n\n" + str(termino.get("definicion", "")) \
		+ "\n\nEjemplo: " + str(termino.get("ejemplo", ""))


func abrir_diccionario() -> void:
	_abierta = true
	_fondo.visible = true
	_panel.visible = true
	_filtro.clear()
	GestorPartida.abrir_ventana("diccionario")
	_filtro.grab_focus()


func _cerrar_diccionario() -> void:
	_abierta = false
	if _fondo:
		_fondo.visible = false
	if _panel:
		_panel.visible = false
	GestorPartida.cerrar_ventana("diccionario")


func _exit_tree() -> void:
	GestorPartida.cerrar_ventana("diccionario")


func _unhandled_input(event: InputEvent) -> void:
	if not _abierta:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_cerrar_diccionario()
		get_viewport().set_input_as_handled()
