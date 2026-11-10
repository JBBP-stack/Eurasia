extends CanvasLayer
## Interfaz de operaciones bancarias. El motor financiero valida y guarda cada cambio.

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
var _saldo_efectivo: Label
var _accion_efectivo: OptionButton
var _importe_efectivo: LineEdit
var _accion_inversion: OptionButton
var _activo_inversion: OptionButton
var _cantidad_inversion: SpinBox
var _estimacion_inversion: Label
var _lista_movimientos: ItemList
var _mensaje: Label
var _confirmacion: ConfirmationDialog
var _operacion_pendiente: Dictionary = {}
var _abierto: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("banco_ui")
	_crear_interfaz()
	SistemaFinanciero.finanzas_actualizadas.connect(_actualizar_datos)
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
	margen.add_theme_constant_override("margin_left", 12)
	margen.add_theme_constant_override("margin_right", 12)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 10)

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

	_confirmacion = ConfirmationDialog.new()
	_confirmacion.title = "Confirmar operación"
	_confirmacion.ok_button_text = "Confirmar"
	_confirmacion.cancel_button_text = "Cancelar"
	_confirmacion.confirmed.connect(_confirmar_operacion)
	add_child(_confirmacion)


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

	var separador := HSeparator.new()
	pagina.add_child(separador)

	_lista_cartera = ItemList.new()
	_lista_cartera.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista_cartera.custom_minimum_size = Vector2(0, 100)
	pagina.add_child(_lista_cartera)

	var aviso := Label.new()
	aviso.text = "Precios fijos de prueba · comisión 0 € · no son cotizaciones históricas."
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(aviso)


func _crear_pagina_efectivo() -> void:
	var pagina := VBoxContainer.new()
	pagina.name = "Efectivo"
	pagina.add_theme_constant_override("separation", 10)
	_pestanas.add_child(pagina)

	var explicacion := Label.new()
	explicacion.text = "Traslada fondos entre el efectivo disponible y la cuenta bancaria. El patrimonio total no cambia."
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(explicacion)

	_saldo_efectivo = Label.new()
	_saldo_efectivo.text = "Efectivo disponible: 0,00 €"
	pagina.add_child(_saldo_efectivo)

	_accion_efectivo = OptionButton.new()
	_accion_efectivo.add_item("Ingresar efectivo en cuenta", 0)
	_accion_efectivo.add_item("Retirar efectivo de cuenta", 1)
	_accion_efectivo.select(0)
	pagina.add_child(_accion_efectivo)

	_importe_efectivo = LineEdit.new()
	_importe_efectivo.placeholder_text = "Importe en euros, por ejemplo 250,00"
	_importe_efectivo.custom_minimum_size = Vector2(0, 32)
	pagina.add_child(_importe_efectivo)

	var preparar := Button.new()
	preparar.text = "Revisar ingreso o retirada"
	preparar.pressed.connect(_preparar_traspaso)
	pagina.add_child(preparar)


func _crear_pagina_inversiones() -> void:
	var pagina := VBoxContainer.new()
	pagina.name = "Inversiones"
	pagina.add_theme_constant_override("separation", 10)
	_pestanas.add_child(pagina)

	var explicacion := Label.new()
	explicacion.text = "Opera con las posiciones de prueba de la partida. Solo se permiten acciones enteras y saldo disponible."
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pagina.add_child(explicacion)

	_accion_inversion = OptionButton.new()
	_accion_inversion.add_item("Comprar acciones", 0)
	_accion_inversion.add_item("Vender acciones", 1)
	_accion_inversion.select(0)
	_accion_inversion.item_selected.connect(_actualizar_estimacion)
	pagina.add_child(_accion_inversion)

	_activo_inversion = OptionButton.new()
	pagina.add_child(_activo_inversion)

	_cantidad_inversion = SpinBox.new()
	_cantidad_inversion.min_value = 1
	_cantidad_inversion.max_value = 100_000
	_cantidad_inversion.step = 1
	_cantidad_inversion.value = 1
	_cantidad_inversion.value_changed.connect(_actualizar_estimacion)
	pagina.add_child(_cantidad_inversion)

	_estimacion_inversion = Label.new()
	pagina.add_child(_estimacion_inversion)

	var preparar := Button.new()
	preparar.text = "Revisar compra o venta"
	preparar.pressed.connect(_preparar_inversion)
	pagina.add_child(preparar)

	_activo_inversion.item_selected.connect(_actualizar_estimacion)


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
	_activo_inversion.clear()
	for indice in range(EstadoJuego.cartera.size()):
		var activo: Dictionary = EstadoJuego.cartera[indice]
		_activo_inversion.add_item(str(activo.get("nombre", activo.get("id", "Activo"))))
		_activo_inversion.set_item_metadata(indice, str(activo.get("id", "")))
	if _activo_inversion.item_count > 0:
		_activo_inversion.select(0)


func abrir_banco(origen: String = "ventanilla") -> void:
	_abierto = true
	_fondo.visible = true
	_panel.visible = true
	var desde_cajero := origen == "cajero"
	_pestanas.set_tab_disabled(TAB_INVERSIONES, desde_cajero)
	_pestanas.current_tab = TAB_EFECTIVO if desde_cajero else TAB_CUENTA
	_mensaje.text = ""
	_cargar_activos()
	_actualizar_datos()
	get_tree().paused = true


func _cerrar_banco() -> void:
	_abierto = false
	_operacion_pendiente.clear()
	if _confirmacion:
		_confirmacion.hide()
	if _fondo:
		_fondo.visible = false
	if _panel:
		_panel.visible = false
	get_tree().paused = false


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
		var precio := int(activo.get("precio_centimos", 0))
		var valor := cantidad * precio
		_lista_cartera.add_item("%s · %d acciones · %s € por acción · valor %s €" % [
			str(activo.get("nombre", activo.get("id", "Activo"))),
			cantidad,
			EstadoJuego.euros(precio),
			EstadoJuego.euros(valor)
		])

	_saldo_efectivo.text = "Efectivo disponible: %s €" % EstadoJuego.euros(EstadoJuego.efectivo_centimos)

	if _activo_inversion.item_count != EstadoJuego.cartera.size():
		_cargar_activos()
	_actualizar_estimacion()
	_actualizar_movimientos()
	_actualizar_dia(EstadoJuego.dia_de_partida)


func _actualizar_dia(_nuevo_dia: int) -> void:
	if _dia:
		_dia.text = EstadoJuego.etiqueta_dia()


func _actualizar_estimacion(_valor: Variant = null) -> void:
	if not _estimacion_inversion or _activo_inversion.item_count == 0:
		return
	var activo_id := str(_activo_inversion.get_item_metadata(_activo_inversion.selected))
	var precio := SistemaFinanciero.precio_actual_centimos(activo_id)
	var cantidad := int(_cantidad_inversion.value)
	var importe := precio * cantidad
	var es_compra := _accion_inversion.get_selected_id() == 0
	var etiqueta := "Coste estimado" if es_compra else "Ingreso estimado"
	_estimacion_inversion.text = "%s: %s € · precio de prueba %s € por acción · comisión 0 €" % [
		etiqueta,
		EstadoJuego.euros(importe),
		EstadoJuego.euros(precio)
	]


func _actualizar_movimientos() -> void:
	_lista_movimientos.clear()
	for movimiento in SistemaFinanciero.movimientos:
		_lista_movimientos.add_item("Día %s · %s · %s · cambio %s € · saldo %s €" % [
			str(movimiento.get("dia", "?")),
			str(movimiento.get("tipo", "Movimiento")),
			str(movimiento.get("detalle", "")),
			EstadoJuego.euros(int(movimiento.get("importe_centimos", 0))),
			EstadoJuego.euros(int(movimiento.get("saldo_bancario_centimos", 0)))
		])


func _preparar_traspaso() -> void:
	var importe := _leer_importe_centimos(_importe_efectivo.text)
	if importe <= 0:
		_mostrar_mensaje("Escribe un importe válido mayor que cero.")
		return
	var ingresar := _accion_efectivo.get_selected_id() == 0
	_operacion_pendiente = {
		"tipo": "ingresar" if ingresar else "retirar",
		"importe_centimos": importe
	}
	_confirmacion.dialog_text = "%s %s €?\n\nNo se aplicará hasta que confirmes." % [
		"Ingresar en la cuenta" if ingresar else "Retirar de la cuenta",
		EstadoJuego.euros(importe)
	]
	_confirmacion.popup_centered(Vector2i(420, 180))


func _preparar_inversion() -> void:
	if _activo_inversion.item_count == 0:
		_mostrar_mensaje("No hay activos disponibles.")
		return
	var activo_id := str(_activo_inversion.get_item_metadata(_activo_inversion.selected))
	var cantidad := int(_cantidad_inversion.value)
	var comprar := _accion_inversion.get_selected_id() == 0
	var precio := SistemaFinanciero.precio_actual_centimos(activo_id)
	_operacion_pendiente = {
		"tipo": "comprar" if comprar else "vender",
		"activo_id": activo_id,
		"cantidad": cantidad
	}
	_confirmacion.dialog_text = "%s %d acciones de %s a %s € por acción?\nTotal estimado: %s €\n\nPrecio fijo de prueba, sin cotización histórica ni comisión." % [
		"¿Comprar" if comprar else "¿Vender",
		cantidad,
		_activo_inversion.get_item_text(_activo_inversion.selected),
		EstadoJuego.euros(precio),
		EstadoJuego.euros(precio * cantidad)
	]
	_confirmacion.popup_centered(Vector2i(520, 230))


func _confirmar_operacion() -> void:
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
	_mostrar_mensaje(str(resultado.get("mensaje", "La operación no se pudo completar.")))
	_actualizar_datos()
	if operacion_correcta and (tipo == "ingresar" or tipo == "retirar"):
		_importe_efectivo.clear()


func _leer_importe_centimos(texto: String) -> int:
	var normalizado := texto.strip_edges().replace(" ", "")
	if normalizado.contains(","):
		normalizado = normalizado.replace(".", "").replace(",", ".")
	var euros := normalizado.to_float()
	if euros <= 0.0 or euros > 1_000_000_000.0:
		return 0
	return int(round(euros * 100.0))


func _mostrar_mensaje(texto: String) -> void:
	_mensaje.text = texto


func _unhandled_input(event: InputEvent) -> void:
	if not _abierto:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			if _confirmacion.visible:
				_confirmacion.hide()
				_operacion_pendiente.clear()
			else:
				_cerrar_banco()
