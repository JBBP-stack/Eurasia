extends CanvasLayer
## Nevera: consultar existencias, comer una ración al día y comprar provisiones.
## Las reglas (precio, pérdida de salud) están en datos/reglas_demo.json.

var _fondo: ColorRect
var _panel: PanelContainer
var _estado: Label
var _barra_salud: ProgressBar
var _mensaje: Label
var _boton_comer: Button
var _boton_una: Button
var _boton_paquete: Button
var _abierta: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("nevera_ui")
	_crear_interfaz()
	EstadoJuego.estado_vital_actualizado.connect(_actualizar)
	SistemaFinanciero.finanzas_actualizadas.connect(_actualizar)
	_cerrar()


func _crear_interfaz() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.01, 0.02, 0.05, 0.82)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	_fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 0)
	centro.add_child(_panel)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 14)
	_panel.add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 10)
	margen.add_child(raiz)

	var cabecera := HBoxContainer.new()
	raiz.add_child(cabecera)
	var titulo := Label.new()
	titulo.text = "NEVERA"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)
	var cerrar := Button.new()
	cerrar.text = "Cerrar (Esc)"
	cerrar.pressed.connect(_cerrar)
	cabecera.add_child(cerrar)
	raiz.add_child(HSeparator.new())

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(_estado)
	_barra_salud = ProgressBar.new()
	_barra_salud.custom_minimum_size = Vector2(0, 14)
	_barra_salud.show_percentage = false
	raiz.add_child(_barra_salud)

	_boton_comer = Button.new()
	_boton_comer.pressed.connect(_comer)
	raiz.add_child(_boton_comer)

	_boton_una = Button.new()
	_boton_una.pressed.connect(_comprar.bind(1))
	raiz.add_child(_boton_una)

	_boton_paquete = Button.new()
	_boton_paquete.pressed.connect(_comprar_paquete)
	raiz.add_child(_boton_paquete)

	_mensaje = Label.new()
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensaje.custom_minimum_size = Vector2(0, 40)
	raiz.add_child(_mensaje)


func _actualizar() -> void:
	if not _estado:
		return
	var precio := SistemaVida.precio_racion_centimos()
	var paquete := SistemaVida.raciones_por_paquete()
	var salud_maxima := Reglas.entero("alimentacion/salud_maxima", 100)
	var perdida_proxima := SistemaVida.perdida_salud_proxima_noche()
	var efecto_hambre := "Si no comes antes de dormir, perderás %d de salud; el daño aumenta con cada día seguido sin comer." % perdida_proxima
	if EstadoJuego.comido_hoy:
		efecto_hambre = "Ya has comido hoy. Al descansar recuperarás hasta %d de salud si te falta." % Reglas.entero("alimentacion/recuperacion_salud_dia_comiendo", 10)
	_estado.text = "COMIDA\n%d raciones · %s\n\nSALUD\n%d/%d · %s\n%d día(s) seguidos sin comer\n\n%s\n\nDinero disponible: efectivo %s € · cuenta %s €. Con salud 0 la partida termina." % [
		EstadoJuego.comida_disponible,
		"ya has comido hoy" if EstadoJuego.comido_hoy else "no has comido hoy",
		EstadoJuego.salud,
		salud_maxima,
		SistemaVida.etiqueta_estado_hambre(),
		EstadoJuego.dias_sin_comer,
		efecto_hambre,
		EstadoJuego.euros(EstadoJuego.efectivo_centimos),
		EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos)
	]
	_barra_salud.max_value = salud_maxima
	_barra_salud.value = EstadoJuego.salud
	var relleno_salud := StyleBoxFlat.new()
	relleno_salud.bg_color = Color("#d85a52") if EstadoJuego.salud <= 30 else (Color("#e6b94d") if EstadoJuego.salud <= 60 else Color("#68bd73"))
	_barra_salud.add_theme_stylebox_override("fill", relleno_salud)
	_boton_comer.text = "Ya has comido hoy" if EstadoJuego.comido_hoy else ("Comprar comida: la nevera está vacía" if EstadoJuego.comida_disponible <= 0 else "Comer ahora · 1 ración")
	_boton_comer.disabled = EstadoJuego.comido_hoy or EstadoJuego.comida_disponible <= 0 or EstadoJuego.partida_terminada
	_boton_una.text = "Comprar 1 ración · %s €" % EstadoJuego.euros(precio)
	_boton_paquete.text = "Comprar paquete de %d · %s €" % [paquete, EstadoJuego.euros(precio * paquete)]
	_boton_una.disabled = EstadoJuego.partida_terminada or EstadoJuego.liquidez_centimos() < precio
	_boton_paquete.disabled = EstadoJuego.partida_terminada or EstadoJuego.liquidez_centimos() < precio * paquete


func abrir_nevera() -> void:
	_abierta = true
	_fondo.visible = true
	_mensaje.text = ""
	_actualizar()
	_cambiar_apariencia_nevera(true)
	GestorPartida.abrir_ventana("nevera")


func _cerrar() -> void:
	_abierta = false
	if _fondo:
		_fondo.visible = false
	_cambiar_apariencia_nevera(false)
	GestorPartida.cerrar_ventana("nevera")


func _exit_tree() -> void:
	_cambiar_apariencia_nevera(false)
	GestorPartida.cerrar_ventana("nevera")


func _cambiar_apariencia_nevera(abierta: bool) -> void:
	var nevera := get_tree().get_first_node_in_group("nevera_objeto")
	if nevera:
		nevera.call("cambiar_estado_abierta", abierta)


func _comer() -> void:
	_mensaje.text = str(SistemaVida.comer().get("mensaje", ""))
	_actualizar()


func _comprar(cantidad: int) -> void:
	_mensaje.text = str(SistemaVida.comprar_raciones(cantidad).get("mensaje", ""))
	_actualizar()


func _comprar_paquete() -> void:
	_comprar(SistemaVida.raciones_por_paquete())


func _unhandled_input(event: InputEvent) -> void:
	if not _abierta:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_cerrar()
		get_viewport().set_input_as_handled()
