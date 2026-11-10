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
	_filtro.placeholder_text = "Buscar término..."
	_filtro.text_changed.connect(_filtrar)
	raiz.add_child(_filtro)

	var cuerpo := HSplitContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(cuerpo)

	_lista = ItemList.new()
	_lista.custom_minimum_size = Vector2(145, 0)
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


func _filtrar(texto: String) -> void:
	_resultados.clear()
	_lista.clear()
	var consulta := _normalizar(texto)

	for termino in _terminos:
		var coincide := consulta.is_empty()
		var nombre := str(termino.get("termino", ""))
		if _normalizar(nombre).contains(consulta):
			coincide = true
		for alias in termino.get("aliases", []):
			if _normalizar(str(alias)).contains(consulta):
				coincide = true
		if coincide:
			_resultados.append(termino)
			_lista.add_item(nombre)

	if _resultados.is_empty():
		_detalle.text = "No hay términos que coincidan con la búsqueda."
	else:
		_lista.select(0)
		_mostrar_termino(0)


func _normalizar(texto: String) -> String:
	return texto.strip_edges().to_lower() \
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
	get_tree().paused = true
	_filtro.grab_focus()


func _cerrar_diccionario() -> void:
	_abierta = false
	if _fondo:
		_fondo.visible = false
	if _panel:
		_panel.visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not _abierta:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_cerrar_diccionario()
		get_viewport().set_input_as_handled()
