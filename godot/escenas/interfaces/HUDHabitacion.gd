extends CanvasLayer
## HUD reutilizable: día y resumen del patrimonio del personaje.

var _dia: Label
var _saldo_bancario: Label
var _efectivo: Label
var _total_inversiones: Label
var _lista_inversiones: VBoxContainer
var _patrimonio_total: Label
var _vital: Label
var _barra_salud: ProgressBar
var _comida: Label
var _boton_decisiones: Button
var _mensaje: Label
var _temporizador_mensaje: Timer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud_habitacion")
	_crear_interfaz()
	EstadoJuego.dia_cambiado.connect(_al_cambiar_dia)
	NoticiasManager.decision_resuelta.connect(_al_resolver_decision)
	NoticiasManager.noticia_entregada.connect(_al_llegar_periodico)
	SistemaFinanciero.finanzas_actualizadas.connect(_al_actualizar_finanzas)
	SistemaMercado.precios_actualizados.connect(_al_actualizar_finanzas)
	EstadoJuego.estado_vital_actualizado.connect(_al_actualizar_finanzas)
	GestorPartida.resumen_dia.connect(_al_recibir_resumen_dia)
	GestorPartida.consecuencia_aplicada.connect(func(_id: String, texto: String) -> void:
		mostrar_mensaje_temporal("Consecuencia de tu decisión: " + texto, 8.0))
	NoticiasManager.noticias_actualizadas.connect(func(_c: int) -> void: actualizar())
	actualizar()


func _crear_interfaz() -> void:
	var panel_dia := PanelContainer.new()
	add_child(panel_dia)
	panel_dia.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel_dia.offset_left = 12
	panel_dia.offset_top = 12
	panel_dia.offset_right = 172
	panel_dia.offset_bottom = 48

	_dia = Label.new()
	_dia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dia.tooltip_text = "Para avanzar al día siguiente, acércate a la cama y pulsa E."
	panel_dia.add_child(_dia)

	_boton_decisiones = Button.new()
	add_child(_boton_decisiones)
	_boton_decisiones.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_boton_decisiones.offset_left = -170
	_boton_decisiones.offset_top = 42
	_boton_decisiones.offset_right = -5
	_boton_decisiones.offset_bottom = 75
	_boton_decisiones.tooltip_text = "Decisiones del día (tecla D)"
	_boton_decisiones.pressed.connect(_abrir_decisiones)

	_mensaje = Label.new()
	add_child(_mensaje)
	_mensaje.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_mensaje.offset_left = 270
	_mensaje.offset_top = 12
	_mensaje.offset_right = -220
	_mensaje.offset_bottom = 110
	_mensaje.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensaje.visible = false

	_temporizador_mensaje = Timer.new()
	_temporizador_mensaje.one_shot = true
	_temporizador_mensaje.wait_time = 4.0
	add_child(_temporizador_mensaje)
	_temporizador_mensaje.timeout.connect(_ocultar_mensaje)

	var panel_patrimonio := PanelContainer.new()
	add_child(panel_patrimonio)
	panel_patrimonio.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel_patrimonio.offset_left = 12
	panel_patrimonio.offset_top = 58
	panel_patrimonio.offset_right = 252
	panel_patrimonio.offset_bottom = 438

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 10)
	panel_patrimonio.add_child(margen)

	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 6)
	margen.add_child(contenido)

	var titulo := Label.new()
	titulo.text = "Patrimonio"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(titulo)
	contenido.add_child(HSeparator.new())

	_saldo_bancario = Label.new()
	contenido.add_child(_saldo_bancario)

	_efectivo = Label.new()
	contenido.add_child(_efectivo)

	_total_inversiones = Label.new()
	contenido.add_child(_total_inversiones)

	_lista_inversiones = VBoxContainer.new()
	_lista_inversiones.add_theme_constant_override("separation", 3)
	contenido.add_child(_lista_inversiones)

	contenido.add_child(HSeparator.new())
	_patrimonio_total = Label.new()
	contenido.add_child(_patrimonio_total)

	contenido.add_child(HSeparator.new())
	var fila_salud := HBoxContainer.new()
	fila_salud.add_theme_constant_override("separation", 6)
	contenido.add_child(fila_salud)
	var corazon := TextureRect.new()
	corazon.texture = load("res://assets/objetos/Corazón-20261108-133000.png") as Texture2D
	corazon.custom_minimum_size = Vector2(16, 16)
	corazon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	corazon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fila_salud.add_child(corazon)
	_vital = Label.new()
	_vital.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vital.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila_salud.add_child(_vital)
	_barra_salud = ProgressBar.new()
	_barra_salud.custom_minimum_size = Vector2(0, 12)
	_barra_salud.show_percentage = false
	var fondo_salud := StyleBoxFlat.new()
	fondo_salud.bg_color = Color("#35383b")
	_barra_salud.add_theme_stylebox_override("background", fondo_salud)
	contenido.add_child(_barra_salud)
	_comida = Label.new()
	_comida.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(_comida)


func actualizar() -> void:
	var restantes := GestorPartida.dias_restantes()
	_dia.text = EstadoJuego.etiqueta_dia() + (" de %d" % (EstadoJuego.dia_de_partida + restantes) if restantes >= 0 else "")
	var pendientes := NoticiasManager.cuantas_decisiones_pendientes()
	_boton_decisiones.text = "Decisiones (%d) · D" % pendientes
	_boton_decisiones.modulate = Color(1.0, 0.85, 0.35) if pendientes > 0 else Color(1, 1, 1)
	_saldo_bancario.text = "Banco: %s €" % EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos)
	_efectivo.text = "Efectivo: %s €" % EstadoJuego.euros(EstadoJuego.efectivo_centimos)
	_total_inversiones.text = "Inversiones: %s €" % EstadoJuego.euros(EstadoJuego.valor_cartera_centimos())
	_patrimonio_total.text = "Total: %s €" % EstadoJuego.euros(EstadoJuego.patrimonio_total_centimos())

	var salud_maxima := Reglas.entero("alimentacion/salud_maxima", 100)
	_vital.text = "Salud: %d/%d · %s" % [EstadoJuego.salud, salud_maxima, SistemaVida.etiqueta_estado_hambre()]
	_barra_salud.max_value = salud_maxima
	_barra_salud.value = EstadoJuego.salud
	var color_salud := Color("#68bd73")
	if EstadoJuego.salud <= 30:
		color_salud = Color("#d85a52")
	elif EstadoJuego.salud <= 60:
		color_salud = Color("#e6b94d")
	var relleno_salud := StyleBoxFlat.new()
	relleno_salud.bg_color = color_salud
	_barra_salud.add_theme_stylebox_override("fill", relleno_salud)
	_comida.tooltip_text = "Comer una ración evita la pérdida de salud de esta noche. Si mantienes las comidas, recuperas salud al descansar."
	if EstadoJuego.comido_hoy:
		_comida.text = "Comida: %d raciones · has comido hoy" % EstadoJuego.comida_disponible
		_comida.modulate = Color("#d7e2d2")
	else:
		var perdida_proxima := SistemaVida.perdida_salud_proxima_noche()
		_comida.text = "Comida: %d raciones\nSi duermes sin comer: −%d salud" % [
			EstadoJuego.comida_disponible,
			perdida_proxima
		]
		if EstadoJuego.comida_disponible <= 0 or EstadoJuego.salud <= 30:
			_comida.modulate = Color("#f08b81")
		elif EstadoJuego.comida_disponible <= 1 or EstadoJuego.dias_sin_comer > 0:
			_comida.modulate = Color("#f0c96f")
		else:
			_comida.modulate = Color("#f2f2f2")

	# Solo se listan las posiciones con acciones; el catálogo completo está en el portátil y el banco.
	var posiciones: Array[Dictionary] = []
	for posicion in EstadoJuego.cartera:
		if int(posicion.get("acciones", 0)) > 0:
			posiciones.append(posicion)

	while _lista_inversiones.get_child_count() > posiciones.size():
		var ultima := _lista_inversiones.get_child(_lista_inversiones.get_child_count() - 1)
		_lista_inversiones.remove_child(ultima)
		ultima.queue_free()

	while _lista_inversiones.get_child_count() < posiciones.size():
		var etiqueta := Label.new()
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_inversiones.add_child(etiqueta)

	for indice in range(posiciones.size()):
		var posicion: Dictionary = posiciones[indice]
		var valor_centimos := int(posicion.get("acciones", 0)) * int(posicion.get("precio_centimos", 0))
		var etiqueta := _lista_inversiones.get_child(indice) as Label
		etiqueta.text = "· %s: %s €" % [
			str(posicion.get("nombre", posicion.get("id", "Activo"))),
			EstadoJuego.euros(valor_centimos)
		]


func _al_cambiar_dia(_nuevo_dia: int) -> void:
	actualizar()


func _al_resolver_decision(_noticia_id: String, _opcion_id: String, _efecto: Dictionary) -> void:
	actualizar()


func _al_actualizar_finanzas() -> void:
	actualizar()


func _al_recibir_resumen_dia(eventos: Array[String]) -> void:
	if eventos.is_empty():
		return
	mostrar_mensaje_temporal("%s · %s" % [EstadoJuego.etiqueta_dia(), " ".join(eventos)], 8.0)


func _al_llegar_periodico(_noticia_id: String, ultimo_del_dia: bool) -> void:
	var aviso := "¡Nuevo periódico en el buzón! Acércate y pulsa E para recogerlo."
	if ultimo_del_dia:
		aviso += " El reparto de hoy ha terminado."
	mostrar_mensaje_temporal(aviso, 5.0)


func _abrir_decisiones() -> void:
	var interfaz := get_tree().get_first_node_in_group("decisiones_ui")
	if interfaz != null and not GestorPartida.hay_ventanas_abiertas():
		interfaz.call("abrir_decisiones")


func mostrar_mensaje_temporal(texto: String, segundos: float = 4.0) -> void:
	_mensaje.text = texto
	_mensaje.visible = true
	_temporizador_mensaje.start(segundos)


func _ocultar_mensaje() -> void:
	_mensaje.visible = false
