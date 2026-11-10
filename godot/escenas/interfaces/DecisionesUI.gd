extends CanvasLayer
## Decisiones del día, accesibles en todo momento (botón del HUD o tecla D).
## Muestra las decisiones pendientes y respondidas de hoy y el historial de días anteriores.
## Una decisión solo puede responderse cuando su periódico ya se ha recogido del buzón.

var _fondo: ColorRect
var _titulo: Label
var _contenido: VBoxContainer
var _abierta: bool = false
var _consecuencias: Dictionary = {}  # noticia_id -> texto de la consecuencia aplicada


func _ready() -> void:
	layer = 38
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("decisiones_ui")
	_crear_interfaz()
	NoticiasManager.noticias_actualizadas.connect(func(_c: int) -> void: _refrescar_si_abierta())
	NoticiasManager.decision_resuelta.connect(func(_n: String, _o: String, _e: Dictionary) -> void: _refrescar_si_abierta())
	EstadoJuego.dia_cambiado.connect(func(_d: int) -> void: _refrescar_si_abierta())
	GestorPartida.consecuencia_aplicada.connect(func(noticia_id: String, texto: String) -> void:
		_consecuencias[noticia_id] = texto
		_refrescar_si_abierta())
	_cerrar()


func _crear_interfaz() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.01, 0.02, 0.05, 0.85)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	_fondo.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_top = 18
	panel.offset_right = -24
	panel.offset_bottom = -18

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	panel.add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 8)
	margen.add_child(raiz)

	var cabecera := HBoxContainer.new()
	raiz.add_child(cabecera)
	_titulo = Label.new()
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(_titulo)
	var cerrar := Button.new()
	cerrar.text = "Cerrar (Esc)"
	cerrar.pressed.connect(_cerrar)
	cabecera.add_child(cerrar)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	raiz.add_child(scroll)
	_contenido = VBoxContainer.new()
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_theme_constant_override("separation", 10)
	scroll.add_child(_contenido)


func abrir_decisiones() -> void:
	_abierta = true
	_fondo.visible = true
	_refrescar()
	GestorPartida.abrir_ventana("decisiones")


func _cerrar() -> void:
	_abierta = false
	if _fondo:
		_fondo.visible = false
	GestorPartida.cerrar_ventana("decisiones")


func _exit_tree() -> void:
	GestorPartida.cerrar_ventana("decisiones")


func _refrescar_si_abierta() -> void:
	if _abierta:
		_refrescar()


func _refrescar() -> void:
	for hijo in _contenido.get_children():
		hijo.queue_free()
	var decisiones := NoticiasManager.decisiones_de_hoy()
	_titulo.text = "DECISIONES · %s · %d pendiente(s)" % [EstadoJuego.etiqueta_dia(), NoticiasManager.cuantas_decisiones_pendientes()]

	if decisiones.is_empty():
		_agregar_texto("Hoy no hay decisiones obligatorias.")
	for decision in decisiones:
		_agregar_tarjeta(decision)

	if not NoticiasManager.reparto_finalizado():
		_agregar_texto("Todavía pueden llegar periódicos con nuevas decisiones hoy.")

	_contenido.add_child(HSeparator.new())
	_agregar_texto("DECISIONES ANTERIORES")
	var anteriores := 0
	for registro in EstadoJuego.registro_decisiones:
		if int(registro.get("dia", 0)) == EstadoJuego.dia_de_partida:
			continue
		anteriores += 1
		_agregar_texto("Día %d — %s\nTu respuesta: %s\n%s" % [
			int(registro.get("dia", 0)), str(registro.get("enunciado", "")),
			str(registro.get("texto", "")), str(registro.get("explicacion", ""))
		])
	if anteriores == 0:
		_agregar_texto("Aún no has tomado decisiones en días anteriores.")


func _agregar_texto(texto: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenido.add_child(etiqueta)


func _agregar_tarjeta(decision: Dictionary) -> void:
	var noticia: Dictionary = decision.get("noticia", {})
	var pregunta: Dictionary = decision.get("pregunta", {})
	var estado := str(decision.get("estado", ""))
	var noticia_id := str(noticia.get("id", ""))

	var tarjeta := PanelContainer.new()
	_contenido.add_child(tarjeta)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 10)
	tarjeta.add_child(margen)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	margen.add_child(caja)

	var textos_estado := {
		"por_llegar": "Esta decisión llegará con un periódico que aún no ha sido repartido.",
		"sin_recoger": "El periódico ya está en el buzón: recógelo (E junto al buzón) para poder decidir.",
		"pendiente": "PENDIENTE: responde antes de dormir.",
		"respondida": "Respondida."
	}
	var cabecera := Label.new()
	cabecera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if estado == "por_llegar":
		cabecera.text = "Decisión pendiente de llegar\n" + str(textos_estado[estado])
		caja.add_child(cabecera)
		return
	cabecera.text = "Noticia: %s\n%s\n\n%s" % [str(noticia.get("titulo", "")), str(textos_estado.get(estado, "")), str(pregunta.get("enunciado", ""))]
	caja.add_child(cabecera)

	var respondida := NoticiasManager.respuesta_de(noticia_id)
	for opcion in pregunta.get("opciones", []):
		var boton := Button.new()
		var elegida := str(opcion.get("id", "")) == respondida
		boton.text = ("✓ " if elegida else "") + str(opcion.get("texto", ""))
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.disabled = estado != "pendiente"
		boton.pressed.connect(_responder.bind(noticia_id, str(opcion.get("id", ""))))
		caja.add_child(boton)
		if elegida:
			var explicacion := Label.new()
			explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			explicacion.text = "%s%s" % [
				("Lo que ha pasado: %s\n\n" % _consecuencias[noticia_id]) if _consecuencias.has(noticia_id) else "",
				str(opcion.get("explicacion", ""))
			]
			caja.add_child(explicacion)


func _responder(noticia_id: String, opcion_id: String) -> void:
	NoticiasManager.responder(noticia_id, opcion_id)
	_refrescar()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if _abierta:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_D:
			_cerrar()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_D and not GestorPartida.hay_ventanas_abiertas() and EstadoJuego.partida_iniciada:
		abrir_decisiones()
		get_viewport().set_input_as_handled()
