extends CanvasLayer
## Portátil: consulta financiera (resumen, cartera, evolución, ingresos y gastos) y asistente de análisis.
## Solo consulta: las operaciones se hacen en el banco y las decisiones en los cuestionarios.

const GraficoLineas := preload("res://escenas/interfaces/graficos/GraficoLineas.gd")
const GraficoBarras := preload("res://escenas/interfaces/graficos/GraficoBarras.gd")
const FichaCotizacion := preload("res://escenas/interfaces/graficos/FichaCotizacion.gd")

const TAB_RESUMEN: int = 0
const TAB_MERCADO: int = 2
const TAB_ASISTENTE: int = 5

var _fondo: ColorRect
var _pestanas: TabContainer
var _resumen: Label
var _grafico_distribucion: Control
var _info_activos: Label
var _grafico_evolucion: Control
var _ingresos_gastos: Label
var _lista_movimientos: ItemList
var _estado_asistente: Label
var _conversacion: Label
var _scroll_conversacion: ScrollContainer
var _pregunta: LineEdit
var _boton_analizar: Button
var _boton_enviar: Button
var _abierta: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("portatil_ui")
	Asistente.respuesta_recibida.connect(_al_recibir_respuesta)
	Asistente.error_asistente.connect(_al_recibir_error)
	Asistente.estado_cambiado.connect(func(texto: String) -> void: _estado_asistente.text = texto)
	_crear_interfaz()
	_cerrar()


func _crear_interfaz() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.015, 0.025, 0.045, 0.9)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	_fondo.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 18
	panel.offset_top = 14
	panel.offset_right = -18
	panel.offset_bottom = -14

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 10)
	panel.add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 8)
	margen.add_child(raiz)

	var cabecera := HBoxContainer.new()
	raiz.add_child(cabecera)
	var titulo := Label.new()
	titulo.text = "PORTÁTIL"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)
	var cerrar := Button.new()
	cerrar.text = "Cerrar (Esc)"
	cerrar.pressed.connect(_cerrar)
	cabecera.add_child(cerrar)

	_pestanas = TabContainer.new()
	_pestanas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(_pestanas)
	_crear_pagina_resumen()
	_crear_pagina_cartera()
	_crear_pagina_mercado()
	_crear_pagina_evolucion()
	_crear_pagina_ingresos()
	_crear_pagina_asistente()


func _pagina_con_scroll(nombre: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = nombre
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pestanas.add_child(scroll)
	var pagina := VBoxContainer.new()
	pagina.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagina.add_theme_constant_override("separation", 8)
	scroll.add_child(pagina)
	return pagina


func _crear_pagina_resumen() -> void:
	var pagina := _pagina_con_scroll("Resumen")
	_resumen = Label.new()
	_resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(_resumen)


func _crear_pagina_cartera() -> void:
	var pagina := _pagina_con_scroll("Cartera")
	var titulo := Label.new()
	titulo.text = "Distribución del patrimonio"
	pagina.add_child(titulo)
	_grafico_distribucion = GraficoBarras.new()
	_grafico_distribucion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagina.add_child(_grafico_distribucion)
	pagina.add_child(HSeparator.new())
	var titulo_info := Label.new()
	titulo_info.text = "Información de cada activo"
	pagina.add_child(titulo_info)
	_info_activos = Label.new()
	_info_activos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(_info_activos)


func _crear_pagina_mercado() -> void:
	var pagina := _pagina_con_scroll("Mercado")
	var ayuda := Label.new()
	ayuda.text = "Consulta la cotización de cualquier empresa. Para comprar o vender, ve al banco."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(ayuda)
	var ficha := FichaCotizacion.new()
	ficha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagina.add_child(ficha)


func _crear_pagina_evolucion() -> void:
	var pagina := VBoxContainer.new()
	pagina.name = "Evolución"
	pagina.add_theme_constant_override("separation", 8)
	_pestanas.add_child(pagina)
	var titulo := Label.new()
	titulo.text = "Patrimonio total al final de cada día (pasa el ratón para ver el valor)"
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(titulo)
	_grafico_evolucion = GraficoLineas.new()
	_grafico_evolucion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grafico_evolucion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagina.add_child(_grafico_evolucion)


func _crear_pagina_ingresos() -> void:
	var pagina := VBoxContainer.new()
	pagina.name = "Ingresos y gastos"
	pagina.add_theme_constant_override("separation", 8)
	_pestanas.add_child(pagina)
	_ingresos_gastos = Label.new()
	_ingresos_gastos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(_ingresos_gastos)
	_lista_movimientos = ItemList.new()
	_lista_movimientos.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista_movimientos.custom_minimum_size = Vector2(0, 120)
	pagina.add_child(_lista_movimientos)


func _crear_pagina_asistente() -> void:
	var pagina := VBoxContainer.new()
	pagina.name = "Asistente"
	pagina.add_theme_constant_override("separation", 8)
	_pestanas.add_child(pagina)

	var aviso := Label.new()
	aviso.text = "El asistente explica conceptos y ayuda a interpretar las noticias de hoy. No conoce el futuro, no decide por ti ni modifica tu dinero."
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(aviso)

	_estado_asistente = Label.new()
	_estado_asistente.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(_estado_asistente)

	_scroll_conversacion = ScrollContainer.new()
	_scroll_conversacion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_conversacion.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pagina.add_child(_scroll_conversacion)
	_conversacion = Label.new()
	_conversacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_conversacion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_conversacion.add_child(_conversacion)

	_pregunta = LineEdit.new()
	_pregunta.placeholder_text = "Pregunta sobre las noticias de hoy o sobre un concepto financiero..."
	_pregunta.max_length = Reglas.entero("asistente/max_caracteres_pregunta", 600)
	_pregunta.text_submitted.connect(func(_t: String) -> void: _enviar_pregunta())
	pagina.add_child(_pregunta)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	pagina.add_child(botones)
	_boton_analizar = Button.new()
	_boton_analizar.text = "Analizar las noticias de hoy"
	_boton_analizar.pressed.connect(_analizar_noticias)
	botones.add_child(_boton_analizar)
	_boton_enviar = Button.new()
	_boton_enviar.text = "Enviar pregunta"
	_boton_enviar.pressed.connect(_enviar_pregunta)
	botones.add_child(_boton_enviar)


# --- Apertura y cierre --------------------------------------------------------

func abrir_portatil(pestana: int = TAB_RESUMEN) -> void:
	_abierta = true
	_fondo.visible = true
	_actualizar_todo()
	_pestanas.current_tab = pestana
	GestorPartida.abrir_ventana("portatil")


func _cerrar() -> void:
	_abierta = false
	if _fondo:
		_fondo.visible = false
	GestorPartida.cerrar_ventana("portatil")


func _exit_tree() -> void:
	GestorPartida.cerrar_ventana("portatil")


func _unhandled_input(event: InputEvent) -> void:
	if not _abierta:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_cerrar()
		get_viewport().set_input_as_handled()


# --- Contenido ----------------------------------------------------------------

func _actualizar_todo() -> void:
	_actualizar_resumen()
	_actualizar_cartera()
	_actualizar_evolucion()
	_actualizar_ingresos()
	_actualizar_asistente()


func _actualizar_resumen() -> void:
	var inicial := EstadoJuego.patrimonio_inicial_centimos
	var actual := EstadoJuego.patrimonio_total_centimos()
	var variacion := (float(actual - inicial) / float(inicial) * 100.0) if inicial > 0 else 0.0
	var gastos_fijos := 0
	for gasto in Reglas.valor("economia_domestica/gastos_fijos_mensuales", []):
		if gasto is Dictionary:
			gastos_fijos += int(gasto.get("importe_centimos", 0))
	var proximos: Array[String] = []
	for gasto in GestorPartida.proximos_gastos(10):
		proximos.append("· %s: %s € %s" % [
			str(gasto["concepto"]), EstadoJuego.euros(int(gasto["importe_centimos"])),
			"mañana" if int(gasto["dias"]) == 1 else "dentro de %d días" % int(gasto["dias"])
		])
	_resumen.text = "%s (quedan %d días del escenario)\n\nCuenta bancaria: %s €\nEfectivo: %s €\nInversiones: %s €\nPatrimonio total: %s € (%+.1f %% desde el inicio)\n\nIngreso mensual: %s € · Gastos fijos mensuales: %s €\nPróximos gastos:\n%s\n\nSalud: %d · Comida: %d raciones · %s\nBolsa: %s\n%s" % [
		EstadoJuego.etiqueta_dia(),
		GestorPartida.dias_restantes(),
		EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos),
		EstadoJuego.euros(EstadoJuego.efectivo_centimos),
		EstadoJuego.euros(EstadoJuego.valor_cartera_centimos()),
		EstadoJuego.euros(actual),
		variacion,
		EstadoJuego.euros(int(EstadoJuego.perfil.get("ingreso_mensual_centimos", 0))),
		EstadoJuego.euros(gastos_fijos),
		"\n".join(proximos) if not proximos.is_empty() else "· Ninguno en los próximos 10 días",
		EstadoJuego.salud,
		EstadoJuego.comida_disponible,
		"ya has comido hoy" if EstadoJuego.comido_hoy else "todavía no has comido hoy",
		SistemaMercado.texto_estado_bolsa().to_lower(),
		"Cotizaciones reales de empresas con nombre ficticio, convertidas a euros."
	]
	if EstadoJuego.saldo_bancario_centimos < 0:
		_resumen.text += "\n\n¡Cuenta en descubierto! Días de impago: %d de %d permitidos." % [
			EstadoJuego.dias_en_descubierto, Reglas.entero("bancarrota/dias_gracia_descubierto", 3)
		]


func _actualizar_cartera() -> void:
	var elementos: Array[Dictionary] = [
		{"etiqueta": "Cuenta bancaria", "valor": maxi(0, EstadoJuego.saldo_bancario_centimos)},
		{"etiqueta": "Efectivo", "valor": EstadoJuego.efectivo_centimos}
	]
	var lineas: Array[String] = []
	for posicion in EstadoJuego.cartera:
		var activo_id := str(posicion.get("id", ""))
		var acciones := int(posicion.get("acciones", 0))
		var precio := int(posicion.get("precio_centimos", 0))
		if acciones > 0:
			elementos.append({"etiqueta": str(posicion.get("nombre", activo_id)), "valor": acciones * precio})
		var info := SistemaMercado.info_activo(activo_id)
		var anterior := SistemaMercado.precio_sesion_anterior(activo_id)
		var variacion := (float(precio - anterior) / float(anterior) * 100.0) if anterior > 0 else 0.0
		lineas.append("%s — %s\n%s\nPrecio: %s € (%+.1f %% respecto a la sesión anterior) · En cartera: %d acciones" % [
			str(posicion.get("nombre", activo_id)),
			str(info.get("sector", "")),
			str(info.get("descripcion", "")),
			EstadoJuego.euros(precio),
			variacion,
			acciones
		])
	_grafico_distribucion.call("establecer_elementos", elementos)
	_info_activos.text = "\n\n".join(lineas)


func _actualizar_evolucion() -> void:
	var puntos: Array[Dictionary] = []
	for entrada in EstadoJuego.historial_patrimonio:
		puntos.append({
			"etiqueta": "Día %d" % int(entrada.get("dia", 0)),
			"valor": int(entrada.get("patrimonio_centimos", 0))
		})
	_grafico_evolucion.call("establecer_puntos", puntos)


func _actualizar_ingresos() -> void:
	var totales: Dictionary = {}
	var ingresos := 0
	var gastos := 0
	for movimiento in SistemaFinanciero.movimientos:
		var tipo := str(movimiento.get("tipo", "Movimiento"))
		var importe := int(movimiento.get("importe_centimos", 0))
		# Los traspasos y la compraventa no son ingresos ni gastos: cambian la forma del patrimonio.
		if tipo in ["Ingreso de efectivo", "Retirada de efectivo", "Compra de acciones", "Venta de acciones"]:
			continue
		totales[tipo] = int(totales.get(tipo, 0)) + importe
		if importe >= 0:
			ingresos += importe
		else:
			gastos += -importe
	var lineas: Array[String] = ["Ingresos: %s € · Gastos: %s € · Saldo neto: %s €" % [
		EstadoJuego.euros(ingresos), EstadoJuego.euros(gastos), EstadoJuego.euros(ingresos - gastos)
	]]
	for tipo in totales.keys():
		lineas.append("· %s: %s €" % [str(tipo), EstadoJuego.euros(int(totales[tipo]))])
	_ingresos_gastos.text = "\n".join(lineas)

	_lista_movimientos.clear()
	for movimiento in SistemaFinanciero.movimientos:
		_lista_movimientos.add_item("Día %s · %s · %s € · %s" % [
			str(movimiento.get("dia", "?")),
			str(movimiento.get("tipo", "")),
			EstadoJuego.euros(int(movimiento.get("importe_centimos", 0))),
			str(movimiento.get("detalle", ""))
		])
	if SistemaFinanciero.movimientos.is_empty():
		_lista_movimientos.add_item("Todavía no hay movimientos.")


func _actualizar_asistente() -> void:
	var disponible := NoticiasManager.puede_analizar_noticias_hoy() and not EstadoJuego.partida_terminada
	var ocupado := Asistente.ocupado
	if ocupado:
		_estado_asistente.text = "El asistente está pensando…"
	elif disponible:
		_estado_asistente.text = "Análisis desbloqueado: se enviarán las %d noticias recogidas hoy." % NoticiasManager.obtener_noticias_recogidas_hoy().size()
	else:
		_estado_asistente.text = "Bloqueado: " + NoticiasManager.motivo_analisis_no_disponible()
	_boton_analizar.disabled = not disponible or ocupado
	_boton_enviar.disabled = not disponible or ocupado
	_pregunta.editable = disponible and not ocupado
	_pintar_conversacion()


func _pintar_conversacion() -> void:
	var lineas: Array[String] = []
	var historial: Array = Asistente.historial
	for turno in historial:
		var prefijo := "Tú: " if str(turno.get("rol", "")) == "jugador" else "Asistente: "
		lineas.append(prefijo + str(turno.get("texto", "")))
	_conversacion.text = "\n\n".join(lineas)
	await get_tree().process_frame
	_scroll_conversacion.scroll_vertical = int(_scroll_conversacion.get_v_scroll_bar().max_value)


func _analizar_noticias() -> void:
	_enviar("Analiza las noticias que he recibido hoy: explica los conceptos financieros que aparecen, qué riesgos generales plantean y cómo podría valorar la fiabilidad de cada fuente.")


func _enviar_pregunta() -> void:
	_enviar(_pregunta.text)


func _enviar(texto: String) -> void:
	if Asistente.enviar(texto):
		_pregunta.clear()
	_actualizar_asistente()


func _al_recibir_respuesta(_texto: String) -> void:
	_actualizar_asistente()


func _al_recibir_error(mensaje: String) -> void:
	_actualizar_asistente()
	_estado_asistente.text = mensaje
