extends CanvasLayer
## Interfaz de operaciones bancarias. El motor financiero valida y guarda cada cambio.
## La confirmación se muestra dentro del propio panel (no en una ventana aparte) para que funcione
## igual con la ventana del juego incrustada en el editor, con escalado o con el juego en pausa.

const FichaCotizacion := preload("res://escenas/interfaces/graficos/FichaCotizacion.gd")

const TAB_CUENTA: int = 0
const TAB_EFECTIVO: int = 1
const TAB_INVERSIONES: int = 2
const TAB_MOVIMIENTOS: int = 3

var _fondo: ColorRect
var _panel: PanelContainer
var _pestanas: TabContainer
var _dia: Label
var _resumen: Label
var _lista_cartera: ItemList
var _aviso_mercado: Label
var _saldo_efectivo: Label
var _accion_efectivo: OptionButton
var _importe_efectivo: LineEdit
var _mensaje_efectivo: Label
var _ficha: VBoxContainer
var _accion_inversion: OptionButton
var _activo_inversion: OptionButton
var _cantidad_inversion: SpinBox
var _estimacion_inversion: Label
var _mensaje_inversion: Label
var _lista_movimientos: ItemList
var _mensaje: Label
var _capa_confirmacion: ColorRect
var _texto_confirmacion: Label
var _boton_confirmar: Button
var _operacion_pendiente: Dictionary = {}
var _abierto: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("banco_ui")
	_crear_interfaz()
	SistemaFinanciero.finanzas_actualizadas.connect(_actualizar_datos)
	SistemaMercado.precios_actualizados.connect(_actualizar_datos)
	EstadoJuego.dia_cambiado.connect(_actualizar_dia)
	_actualizar_datos()
	_cerrar_banco()


func _crear_interfaz() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.015, 0.025, 0.045, 0.88)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_panel = PanelContainer.new()
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 18
	_panel.offset_top = 14
	_panel.offset_right = -18
	_panel.offset_bottom = -14

	var margen := MarginContainer.new()
	_panel.add_child(margen)
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	for lado in ["top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 10)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 8)
	margen.add_child(raiz)

	var cabecera := HBoxContainer.new()
	raiz.add_child(cabecera)
	var titulo := Label.new()
	titulo.text = "BANCO · EURASIA"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)

	_dia = Label.new()
	_dia.text = EstadoJuego.etiqueta_dia()
	cabecera.add_child(_dia)

	var cerrar := Button.new()
	cerrar.text = "Cerrar (Esc)"
	cerrar.pressed.connect(_cerrar_banco)
	cabecera.add_child(cerrar)

	_pestanas = TabContainer.new()
	_pestanas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(_pestanas)
	_crear_pagina_cuenta()
	_crear_pagina_efectivo()
	_crear_pagina_inversiones()
	_crear_pagina_movimientos()

	_mensaje = Label.new()
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensaje.custom_minimum_size = Vector2(0, 24)
	raiz.add_child(_mensaje)

	_crear_confirmacion()


func _crear_confirmacion() -> void:
	_capa_confirmacion = ColorRect.new()
	_capa_confirmacion.color = Color(0, 0, 0, 0.6)
	_capa_confirmacion.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_capa_confirmacion)
	_capa_confirmacion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	_capa_confirmacion.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(440, 0)
	centro.add_child(caja)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 16)
	caja.add_child(margen)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 12)
	margen.add_child(contenido)

	var titulo := Label.new()
	titulo.text = "Confirmar operación"
	contenido.add_child(titulo)
	_texto_confirmacion = Label.new()
	_texto_confirmacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(_texto_confirmacion)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 10)
	botones.alignment = BoxContainer.ALIGNMENT_END
	contenido.add_child(botones)
	var cancelar := Button.new()
	cancelar.text = "Cancelar (Esc)"
	cancelar.pressed.connect(_cancelar_operacion)
	botones.add_child(cancelar)
	_boton_confirmar = Button.new()
	_boton_confirmar.text = "Confirmar (Intro)"
	_boton_confirmar.pressed.connect(_confirmar_operacion)
	botones.add_child(_boton_confirmar)
	_capa_confirmacion.visible = false


func _crear_pagina_cuenta() -> void:
	var pagina := VBoxContainer.new()
	pagina.name = "Cuenta"
	pagina.add_theme_constant_override("separation", 8)
	_pestanas.add_child(pagina)

	var titulo := Label.new()
	titulo.text = "Resumen financiero"
	pagina.add_child(titulo)

	_resumen = Label.new()
	_resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(_resumen)

	pagina.add_child(HSeparator.new())

	_lista_cartera = ItemList.new()
	_lista_cartera.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista_cartera.custom_minimum_size = Vector2(0, 100)
	pagina.add_child(_lista_cartera)

	_aviso_mercado = Label.new()
	_aviso_mercado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(_aviso_mercado)


func _crear_pagina_efectivo() -> void:
	var pagina := VBoxContainer.new()
	pagina.name = "Efectivo"
	pagina.add_theme_constant_override("separation", 10)
	_pestanas.add_child(pagina)

	var explicacion := Label.new()
	explicacion.text = "Traslada dinero entre el efectivo que llevas encima y tu cuenta bancaria. El patrimonio total no cambia. Los gastos personales y la comida se pagan primero con efectivo."
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(explicacion)

	_saldo_efectivo = Label.new()
	pagina.add_child(_saldo_efectivo)

	_accion_efectivo = OptionButton.new()
	_accion_efectivo.add_item("Retirar efectivo de la cuenta", 1)
	_accion_efectivo.add_item("Ingresar efectivo en la cuenta", 0)
	_accion_efectivo.select(0)
	pagina.add_child(_accion_efectivo)

	_importe_efectivo = LineEdit.new()
	_importe_efectivo.placeholder_text = "Importe en euros, por ejemplo 250 o 1.000,50"
	_importe_efectivo.custom_minimum_size = Vector2(0, 32)
	_importe_efectivo.text_submitted.connect(func(_t: String) -> void: _preparar_traspaso())
	pagina.add_child(_importe_efectivo)

	var rapidos := HBoxContainer.new()
	rapidos.add_theme_constant_override("separation", 6)
	pagina.add_child(rapidos)
	for importe in [50, 100, 200, 500]:
		var boton := Button.new()
		boton.text = "%d €" % importe
		boton.pressed.connect(func() -> void: _importe_efectivo.text = str(importe))
		rapidos.add_child(boton)

	var preparar := Button.new()
	preparar.text = "Revisar ingreso o retirada"
	preparar.pressed.connect(_preparar_traspaso)
	pagina.add_child(preparar)

	_mensaje_efectivo = Label.new()
	_mensaje_efectivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(_mensaje_efectivo)


func _crear_pagina_inversiones() -> void:
	# Izquierda: ficha de cotización (con desplazamiento). Derecha: controles de operación siempre visibles.
	var pagina := HBoxContainer.new()
	pagina.name = "Inversiones"
	pagina.add_theme_constant_override("separation", 12)
	_pestanas.add_child(pagina)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pagina.add_child(scroll)
	_ficha = FichaCotizacion.new()
	_ficha.con_selector = false
	_ficha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_ficha)

	var operar := VBoxContainer.new()
	operar.custom_minimum_size = Vector2(300, 0)
	operar.add_theme_constant_override("separation", 8)
	pagina.add_child(operar)

	var titulo := Label.new()
	titulo.text = "Operar"
	operar.add_child(titulo)

	_activo_inversion = OptionButton.new()
	_activo_inversion.fit_to_longest_item = false
	_activo_inversion.item_selected.connect(_al_elegir_activo)
	operar.add_child(_activo_inversion)

	_accion_inversion = OptionButton.new()
	_accion_inversion.add_item("Comprar acciones", 0)
	_accion_inversion.add_item("Vender acciones", 1)
	_accion_inversion.select(0)
	_accion_inversion.item_selected.connect(_actualizar_estimacion)
	operar.add_child(_accion_inversion)

	_cantidad_inversion = SpinBox.new()
	_cantidad_inversion.min_value = 1
	_cantidad_inversion.max_value = 1_000_000
	_cantidad_inversion.step = 1
	_cantidad_inversion.value = 1
	_cantidad_inversion.suffix = "acciones"
	_cantidad_inversion.value_changed.connect(_actualizar_estimacion)
	operar.add_child(_cantidad_inversion)

	var preparar := Button.new()
	preparar.text = "Revisar compra o venta"
	preparar.pressed.connect(_preparar_inversion)
	operar.add_child(preparar)

	_estimacion_inversion = Label.new()
	_estimacion_inversion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	operar.add_child(_estimacion_inversion)

	_mensaje_inversion = Label.new()
	_mensaje_inversion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	operar.add_child(_mensaje_inversion)

	var ayuda := Label.new()
	ayuda.text = "Acciones enteras pagadas con el saldo de la cuenta. Máximo %d posiciones activas. Puedes operar cualquier día: si no hay sesión, se usa el último precio de cierre." % SistemaFinanciero.MAX_POSICIONES
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.modulate = Color(1, 1, 1, 0.75)
	operar.add_child(ayuda)


func _crear_pagina_movimientos() -> void:
	var pagina := VBoxContainer.new()
	pagina.name = "Movimientos"
	pagina.add_theme_constant_override("separation", 8)
	_pestanas.add_child(pagina)

	var titulo := Label.new()
	titulo.text = "Historial reciente (máximo 200 operaciones)"
	pagina.add_child(titulo)

	_lista_movimientos = ItemList.new()
	_lista_movimientos.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista_movimientos.custom_minimum_size = Vector2(0, 120)
	pagina.add_child(_lista_movimientos)


func _cargar_activos() -> void:
	var seleccionado := _activo_seleccionado()
	_activo_inversion.clear()
	for indice in range(EstadoJuego.cartera.size()):
		var activo: Dictionary = EstadoJuego.cartera[indice]
		var acciones := int(activo.get("acciones", 0))
		_activo_inversion.add_item("%s%s" % [
			str(activo.get("nombre", activo.get("id", "Activo"))),
			" · tienes %d" % acciones if acciones > 0 else ""
		])
		_activo_inversion.set_item_metadata(indice, str(activo.get("id", "")))
		if str(activo.get("id", "")) == seleccionado:
			_activo_inversion.select(indice)
	if _activo_inversion.selected < 0 and _activo_inversion.item_count > 0:
		_activo_inversion.select(0)
	_ficha.call("mostrar_activo", _activo_seleccionado())


func _activo_seleccionado() -> String:
	if _activo_inversion == null or _activo_inversion.item_count == 0 or _activo_inversion.selected < 0:
		return ""
	return str(_activo_inversion.get_item_metadata(_activo_inversion.selected))


func _al_elegir_activo(_indice: int) -> void:
	_ficha.call("mostrar_activo", _activo_seleccionado())
	_actualizar_estimacion()


func abrir_banco(origen: String = "ventanilla") -> void:
	_abierto = true
	_fondo.visible = true
	_panel.visible = true
	# Desde el cajero se abre la pestaña de efectivo, pero todas las operaciones están disponibles.
	var desde_cajero := origen == "cajero"
	_pestanas.current_tab = TAB_EFECTIVO if desde_cajero else TAB_CUENTA
	_mensaje.text = ""
	_mensaje_efectivo.text = ""
	_mensaje_inversion.text = ""
	_cargar_activos()
	_actualizar_datos()
	GestorPartida.abrir_ventana("banco")


func _cerrar_banco() -> void:
	_abierto = false
	_operacion_pendiente.clear()
	if _capa_confirmacion:
		_capa_confirmacion.visible = false
	if _fondo:
		_fondo.visible = false
	if _panel:
		_panel.visible = false
	GestorPartida.cerrar_ventana("banco")


func _exit_tree() -> void:
	GestorPartida.cerrar_ventana("banco")


func _actualizar_datos() -> void:
	if not _resumen:
		return
	_resumen.text = "Cuenta bancaria: %s €\nEfectivo: %s €\nCartera: %s €\nPatrimonio total: %s €" % [
		EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos),
		EstadoJuego.euros(EstadoJuego.efectivo_centimos),
		EstadoJuego.euros(EstadoJuego.valor_cartera_centimos()),
		EstadoJuego.euros(EstadoJuego.patrimonio_total_centimos())
	]

	_lista_cartera.clear()
	for activo in EstadoJuego.cartera:
		var cantidad := int(activo.get("acciones", 0))
		if cantidad <= 0:
			continue
		var precio := int(activo.get("precio_centimos", 0))
		var anterior := SistemaMercado.precio_sesion_anterior(str(activo.get("id", "")))
		var variacion := (float(precio - anterior) / float(anterior) * 100.0) if anterior > 0 else 0.0
		_lista_cartera.add_item("%s · %d acciones · %s € por acción (%+.1f %% última sesión) · valor %s €" % [
			str(activo.get("nombre", activo.get("id", "Activo"))),
			cantidad,
			EstadoJuego.euros(precio),
			variacion,
			EstadoJuego.euros(cantidad * precio)
		])
	if _lista_cartera.item_count == 0:
		_lista_cartera.add_item("No tienes acciones en cartera.")

	var estado_bolsa := SistemaMercado.texto_estado_bolsa()
	_aviso_mercado.text = "%s · comisión %.2f %% (mínimo %s €) · cotizaciones reales de empresas con nombre ficticio, convertidas a euros." % [
		estado_bolsa,
		float(Reglas.entero("mercado/comision_puntos_base", 0)) / 100.0,
		EstadoJuego.euros(Reglas.entero("mercado/comision_minima_centimos", 0))
	]
	if EstadoJuego.saldo_bancario_centimos < 0:
		_aviso_mercado.text += "\nCuenta en descubierto: ingresa efectivo o vende inversiones antes de %d días." % Reglas.entero("bancarrota/dias_gracia_descubierto", 3)

	_saldo_efectivo.text = "Efectivo disponible: %s € · Saldo en cuenta: %s €" % [
		EstadoJuego.euros(EstadoJuego.efectivo_centimos), EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos)
	]
	if _activo_inversion.item_count != EstadoJuego.cartera.size():
		_cargar_activos()
	_actualizar_estimacion()
	_actualizar_movimientos()
	_actualizar_dia(EstadoJuego.dia_de_partida)


func _actualizar_dia(_nuevo_dia: int) -> void:
	if _dia:
		_dia.text = EstadoJuego.etiqueta_dia()


func _actualizar_estimacion(_valor: Variant = null) -> void:
	if not _estimacion_inversion:
		return
	var activo_id := _activo_seleccionado()
	if activo_id.is_empty():
		return
	var precio := SistemaFinanciero.precio_actual_centimos(activo_id)
	var importe := precio * int(_cantidad_inversion.value)
	var es_compra := _accion_inversion.get_selected_id() == 0
	var comision := SistemaFinanciero.estimar_comision(importe)
	_estimacion_inversion.text = "%s: %s € (importe %s € + comisión %s €)%s" % [
		"Coste total estimado" if es_compra else "Ingreso neto estimado",
		EstadoJuego.euros(importe + comision if es_compra else importe - comision),
		EstadoJuego.euros(importe),
		EstadoJuego.euros(comision),
		"" if SistemaMercado.mercado_abierto() else " · %s" % SistemaMercado.texto_estado_bolsa().to_lower()
	]


func _actualizar_movimientos() -> void:
	_lista_movimientos.clear()
	for movimiento in SistemaFinanciero.movimientos:
		_lista_movimientos.add_item("Día %s · %s · %s · cambio %s € · cuenta %s € · efectivo %s €" % [
			str(movimiento.get("dia", "?")),
			str(movimiento.get("tipo", "Movimiento")),
			str(movimiento.get("detalle", "")),
			EstadoJuego.euros(int(movimiento.get("importe_centimos", 0))),
			EstadoJuego.euros(int(movimiento.get("saldo_bancario_centimos", 0))),
			EstadoJuego.euros(int(movimiento.get("efectivo_centimos", 0)))
		])
	if SistemaFinanciero.movimientos.is_empty():
		_lista_movimientos.add_item("Todavía no hay movimientos.")


func _preparar_traspaso() -> void:
	var importe := leer_importe_centimos(_importe_efectivo.text)
	if importe <= 0:
		_mensaje_efectivo.text = "Escribe un importe válido mayor que cero (por ejemplo 250 o 1.000,50)."
		return
	var ingresar := _accion_efectivo.get_selected_id() == 0
	if ingresar and importe > EstadoJuego.efectivo_centimos:
		_mensaje_efectivo.text = "Solo llevas %s € en efectivo." % EstadoJuego.euros(EstadoJuego.efectivo_centimos)
		return
	if not ingresar and importe > EstadoJuego.saldo_bancario_centimos:
		_mensaje_efectivo.text = "Tu saldo en cuenta es de %s €." % EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos)
		return
	_pedir_confirmacion(
		{"tipo": "ingresar" if ingresar else "retirar", "importe_centimos": importe},
		"¿%s %s €?" % ["Ingresar en la cuenta" if ingresar else "Retirar de la cuenta", EstadoJuego.euros(importe)]
	)


func _preparar_inversion() -> void:
	var activo_id := _activo_seleccionado()
	if activo_id.is_empty():
		_mensaje_inversion.text = "No hay activos disponibles."
		return
	if not SistemaMercado.se_puede_operar():
		_mensaje_inversion.text = "La bolsa está cerrada hoy (%s). Podrás operar el próximo día con sesión." % SistemaMercado.motivo_mercado_cerrado()
		return
	var cantidad := int(_cantidad_inversion.value)
	var comprar := _accion_inversion.get_selected_id() == 0
	var precio := SistemaFinanciero.precio_actual_centimos(activo_id)
	var comision := SistemaFinanciero.estimar_comision(precio * cantidad)
	_pedir_confirmacion(
		{"tipo": "comprar" if comprar else "vender", "activo_id": activo_id, "cantidad": cantidad},
		"%s %d acciones de %s a %s € por acción?\nImporte: %s € · comisión: %s €\nTotal %s: %s €" % [
			"¿Comprar" if comprar else "¿Vender",
			cantidad,
			str(SistemaMercado.info_activo(activo_id).get("nombre", activo_id)),
			EstadoJuego.euros(precio),
			EstadoJuego.euros(precio * cantidad),
			EstadoJuego.euros(comision),
			"a pagar" if comprar else "a recibir",
			EstadoJuego.euros(precio * cantidad + comision if comprar else precio * cantidad - comision)
		]
	)


func _pedir_confirmacion(operacion: Dictionary, texto: String) -> void:
	_operacion_pendiente = operacion
	_texto_confirmacion.text = texto + "\n\nNo se aplicará hasta que confirmes."
	_capa_confirmacion.visible = true
	_boton_confirmar.grab_focus()


func _cancelar_operacion() -> void:
	_operacion_pendiente.clear()
	_capa_confirmacion.visible = false
	_mostrar_resultado("Operación cancelada.", false)


func _confirmar_operacion() -> void:
	_capa_confirmacion.visible = false
	if _operacion_pendiente.is_empty():
		return
	var resultado: Dictionary = {}
	var tipo := str(_operacion_pendiente.get("tipo", ""))
	match tipo:
		"ingresar":
			resultado = SistemaFinanciero.depositar_efectivo(int(_operacion_pendiente.get("importe_centimos", 0)))
		"retirar":
			resultado = SistemaFinanciero.retirar_efectivo(int(_operacion_pendiente.get("importe_centimos", 0)))
		"comprar":
			resultado = SistemaFinanciero.comprar_acciones(
				str(_operacion_pendiente.get("activo_id", "")),
				int(_operacion_pendiente.get("cantidad", 0))
			)
		"vender":
			resultado = SistemaFinanciero.vender_acciones(
				str(_operacion_pendiente.get("activo_id", "")),
				int(_operacion_pendiente.get("cantidad", 0))
			)
	var operacion_correcta := bool(resultado.get("ok", false))
	_operacion_pendiente.clear()
	_mostrar_resultado(str(resultado.get("mensaje", "La operación no se pudo completar.")), tipo in ["comprar", "vender"])
	if operacion_correcta and tipo in ["ingresar", "retirar"]:
		_importe_efectivo.clear()
	if operacion_correcta and tipo in ["comprar", "vender"]:
		_cargar_activos()
	_actualizar_datos()


func _mostrar_resultado(texto: String, en_inversiones: bool) -> void:
	_mensaje.text = texto
	if en_inversiones:
		_mensaje_inversion.text = texto
	else:
		_mensaje_efectivo.text = texto


## Admite formatos españoles: «250», «250,50», «1.000», «1.000,50» y también «250.50».
static func leer_importe_centimos(texto: String) -> int:
	var normalizado := texto.strip_edges().replace(" ", "").replace("€", "")
	if normalizado.contains(","):
		normalizado = normalizado.replace(".", "").replace(",", ".")
	elif RegEx.create_from_string("^\\d{1,3}(\\.\\d{3})+$").search(normalizado) != null:
		normalizado = normalizado.replace(".", "")
	if not normalizado.is_valid_float():
		return 0
	var euros := normalizado.to_float()
	if euros <= 0.0 or euros > 1_000_000_000.0:
		return 0
	return int(round(euros * 100.0))


func _unhandled_input(event: InputEvent) -> void:
	if not _abierto:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if _capa_confirmacion.visible:
			if event.keycode == KEY_ESCAPE:
				_cancelar_operacion()
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				_confirmar_operacion()
		elif event.keycode == KEY_ESCAPE:
			_cerrar_banco()
