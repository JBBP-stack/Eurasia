extends CanvasLayer
## Atención bancaria: conversación con Marisa, la gestora de la sucursal.
## Comenta la actualidad del día (solo lo publicado hasta la fecha), opina sobre la situación del
## jugador sin decirle qué hacer y da acceso a la ventanilla para hacer gestiones.
## Textos en datos/atencion_bancaria.json.

const RUTA_DIALOGOS: String = "res://datos/atencion_bancaria.json"
const SECTORES_FINANCIEROS: Array[String] = ["Banca", "Banca de inversión", "Financiación hipotecaria", "Seguros"]
const LETRAS_POR_SEGUNDO: float = 55.0

var _datos: Dictionary = {}
var _fondo: ColorRect
var _nombre: Label
var _texto: Label
var _continuar: Label
var _opciones: HBoxContainer
var _cola: Array[String] = []
var _indice_actualidad: int = 0
var _tween: Tween
var _abierta: bool = false


func _ready() -> void:
	layer = 39
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("atencion_ui")
	_cargar()
	_crear_interfaz()
	_cerrar()


func _cargar() -> void:
	if FileAccess.file_exists(RUTA_DIALOGOS):
		var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_DIALOGOS))
		if datos is Dictionary:
			_datos = datos


func _crear_interfaz() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0, 0, 0, 0.35)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.gui_input.connect(_al_pulsar_fondo)

	var caja := PanelContainer.new()
	_fondo.add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caja.offset_left = 24
	caja.offset_right = -24
	caja.offset_top = -250
	caja.offset_bottom = -20

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 14)
	caja.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	margen.add_child(fila)

	fila.add_child(_crear_retrato())

	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 8)
	fila.add_child(columna)

	var empleada: Dictionary = _datos.get("empleada", {})
	_nombre = Label.new()
	_nombre.text = "%s · %s" % [str(empleada.get("nombre", "Gestora")), str(empleada.get("cargo", ""))]
	_nombre.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	columna.add_child(_nombre)

	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto.custom_minimum_size = Vector2(0, 80)
	columna.add_child(_texto)

	_continuar = Label.new()
	_continuar.text = "▼ clic, E o Intro para continuar"
	_continuar.modulate = Color(1, 1, 1, 0.6)
	columna.add_child(_continuar)

	_opciones = HBoxContainer.new()
	_opciones.add_theme_constant_override("separation", 8)
	columna.add_child(_opciones)
	_agregar_opcion("¿Qué se cuenta hoy?", _pedir_actualidad)
	_agregar_opcion("¿Cómo ve mi situación?", _pedir_situacion)
	_agregar_opcion("Quiero hacer gestiones", _abrir_ventanilla)
	_agregar_opcion("Hasta luego", _despedirse)


func _crear_retrato() -> Control:
	# Retrato provisional en pixel art hecho con rectángulos (pendiente de arte definitivo).
	var marco := PanelContainer.new()
	marco.custom_minimum_size = Vector2(120, 150)
	var lienzo := Control.new()
	lienzo.custom_minimum_size = Vector2(120, 150)
	marco.add_child(lienzo)
	var piezas := [
		[Rect2(30, 20, 60, 22), Color("#5a3a22")],   # pelo
		[Rect2(36, 36, 48, 50), Color("#e8b98f")],   # cara
		[Rect2(30, 36, 8, 40), Color("#5a3a22")],
		[Rect2(82, 36, 8, 40), Color("#5a3a22")],
		[Rect2(46, 52, 8, 6), Color("#2b2b2b")],     # ojos
		[Rect2(66, 52, 8, 6), Color("#2b2b2b")],
		[Rect2(52, 72, 16, 4), Color("#b5524a")],    # boca
		[Rect2(24, 92, 72, 58), Color("#2f4f7f")],   # chaqueta
		[Rect2(52, 92, 16, 30), Color("#f2f2f2")],   # camisa
		[Rect2(40, 100, 10, 6), Color("#d9c27a")]    # placa con el nombre
	]
	for pieza in piezas:
		var rect := ColorRect.new()
		rect.position = (pieza[0] as Rect2).position
		rect.size = (pieza[0] as Rect2).size
		rect.color = pieza[1]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lienzo.add_child(rect)
	return marco


func _agregar_opcion(texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.pressed.connect(accion)
	_opciones.add_child(boton)


# --- Apertura y cierre --------------------------------------------------------

func abrir_atencion() -> void:
	_abierta = true
	_fondo.visible = true
	_indice_actualidad = 0
	GestorPartida.abrir_ventana("atencion")
	var saludos: Array = _datos.get("saludos", ["Buenos días."])
	var saludo := str(saludos[(EstadoJuego.dia_de_partida + randi()) % maxi(1, saludos.size())])
	_decir([saludo, "¿En qué le puedo ayudar?"])


func _cerrar() -> void:
	_abierta = false
	if _fondo:
		_fondo.visible = false
	GestorPartida.cerrar_ventana("atencion")


func _exit_tree() -> void:
	GestorPartida.cerrar_ventana("atencion")


# --- Diálogo ------------------------------------------------------------------

func _decir(lineas: Array[String]) -> void:
	_cola = lineas.duplicate()
	_siguiente_linea()


func _siguiente_linea() -> void:
	if _escribiendo():
		_tween.kill()
		_texto.visible_ratio = 1.0
		_actualizar_indicadores()
		return
	if _cola.is_empty():
		_actualizar_indicadores()
		return
	_texto.text = _cola.pop_front()
	_texto.visible_ratio = 0.0
	_tween = create_tween()
	_tween.tween_property(_texto, "visible_ratio", 1.0, maxf(0.2, _texto.text.length() / LETRAS_POR_SEGUNDO))
	_tween.finished.connect(_actualizar_indicadores)
	_actualizar_indicadores()


func _escribiendo() -> bool:
	return _tween != null and _tween.is_running()


func _actualizar_indicadores() -> void:
	var hay_mas := _escribiendo() or not _cola.is_empty()
	_continuar.visible = hay_mas
	_opciones.visible = not hay_mas


func _al_pulsar_fondo(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_siguiente_linea()


func _pedir_actualidad() -> void:
	var lineas: Array = (_datos.get("por_fecha", {}) as Dictionary).get(EstadoJuego.fecha_historica_interna, [])
	if lineas.is_empty():
		_decir(["Hoy está todo bastante tranquilo, la verdad."])
		return
	var dichas: Array[String] = []
	# Cada vez cuenta un par de cosas nuevas; al terminar, vuelve a empezar.
	for i in range(2):
		dichas.append(str(lineas[_indice_actualidad % lineas.size()]))
		_indice_actualidad += 1
		if _indice_actualidad % lineas.size() == 0:
			break
	_decir(dichas)


func _pedir_situacion() -> void:
	_decir(comentarios_situacion())


## Comentarios sobre la situación del jugador. Opina como una persona, sin decir qué hacer.
func comentarios_situacion() -> Array[String]:
	var lineas: Array[String] = []
	var patrimonio := maxi(1, EstadoJuego.patrimonio_total_centimos())

	if EstadoJuego.saldo_bancario_centimos < 0:
		lineas.append("Le tengo que avisar: su cuenta está en números rojos (%s €). Si sigue así varios días, tendremos un problema serio." % EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos))

	var proximos := GestorPartida.proximos_gastos(5)
	var a_pagar := 0
	for gasto in proximos:
		a_pagar += int(gasto["importe_centimos"])
	if a_pagar > 0 and EstadoJuego.liquidez_centimos() < a_pagar:
		lineas.append("En los próximos días le vienen %s € de recibos y no le llega con lo que tiene disponible." % EstadoJuego.euros(a_pagar))
	elif EstadoJuego.efectivo_centimos < 10_000:
		lineas.append("Lleva muy poco efectivo encima. Los gastos del día a día se pagan con algo, ¿eh?")

	var mayor: Dictionary = {}
	var valor_mayor := 0
	for posicion in EstadoJuego.cartera:
		var valor := int(posicion.get("acciones", 0)) * int(posicion.get("precio_centimos", 0))
		if valor > valor_mayor:
			valor_mayor = valor
			mayor = posicion
	if not mayor.is_empty() and float(valor_mayor) / float(patrimonio) > 0.3:
		lineas.append("Veo que buena parte de su dinero está en %s. Yo no le puedo decir qué hacer, pero a mí no me gustaría tener tantos huevos en la misma cesta." % str(mayor.get("nombre", "")))

	for posicion in EstadoJuego.cartera:
		var acciones := int(posicion.get("acciones", 0))
		var activo_id := str(posicion.get("id", ""))
		var inicio := SistemaMercado.precio_en(activo_id, EstadoJuego.FECHA_INICIO_PROVISIONAL)
		var actual := int(posicion.get("precio_centimos", 0))
		if acciones > 0 and inicio > 0 and actual < inicio * 0.7:
			var sector := str(SistemaMercado.info_activo(activo_id).get("sector", ""))
			lineas.append("Sus acciones de %s valen un %d %% menos que hace unos días%s." % [
				str(posicion.get("nombre", activo_id)),
				int(round((1.0 - float(actual) / float(inicio)) * 100.0)),
				". Con lo que está pasando en el sector financiero, entiendo que esté preocupado" if sector in SECTORES_FINANCIEROS else ""
			])
			break

	if EstadoJuego.valor_cartera_centimos() == 0:
		lineas.append("Lo tiene todo en la cuenta y en efectivo. Dormir tranquilo también vale dinero, aunque la cuenta rinda poco.")
	if EstadoJuego.saldo_bancario_centimos > 2_000_000:
		lineas.append("Recuerde que el fondo de garantía cubre hasta 20.000 € por persona y entidad. Usted ya pasa de esa cifra en esta caja.")
	if EstadoJuego.salud < 50:
		lineas.append("Y perdone que se lo diga, pero le veo mala cara. ¿Está comiendo y durmiendo bien?")
	elif EstadoJuego.comida_disponible == 0:
		lineas.append("Por cierto, ¿ha hecho la compra? Mi madre siempre dice que con la nevera vacía se piensa peor.")

	if lineas.is_empty():
		lineas.append("Pues, sinceramente, le veo bastante bien colocado. Cuentas al día y sin sustos. Ojalá todos mis clientes fueran así.")
	if lineas.size() > 3:
		lineas.resize(3)
	return lineas


func _abrir_ventanilla() -> void:
	var banco := get_tree().get_first_node_in_group("banco_ui")
	if banco == null:
		_decir(["Uy, el sistema se ha colgado. Vuelva en un rato."])
		return
	_cerrar()
	banco.call("abrir_banco", "ventanilla")


func _despedirse() -> void:
	var despedidas: Array = _datos.get("despedidas", ["Hasta luego."])
	_cola.clear()
	_texto.text = str(despedidas[randi() % maxi(1, despedidas.size())])
	_texto.visible_ratio = 1.0
	_opciones.visible = false
	_continuar.visible = false
	await get_tree().create_timer(1.2, true).timeout
	_cerrar()


func _unhandled_input(event: InputEvent) -> void:
	if not _abierta:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			_cerrar()
		elif event.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_siguiente_linea()
