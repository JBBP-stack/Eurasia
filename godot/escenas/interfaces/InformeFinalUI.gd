extends CanvasLayer
## Ficha de fin de partida: resultado, explicación básica y técnica, errores, decisiones
## y revelación de la información real (fechas, fuentes y noticias falsas).

var _fondo: ColorRect
var _titulo: Label
var _pestanas: TabContainer
var _basica: Label
var _tecnica: Label
var _errores: Label
var _decisiones: Label
var _revelacion: VBoxContainer


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("informe_final_ui")
	_crear_interfaz()
	GestorPartida.partida_finalizada.connect(_mostrar)
	if EstadoJuego.partida_terminada and not EstadoJuego.resultado_final.is_empty():
		_mostrar(EstadoJuego.resultado_final)
	else:
		_fondo.visible = false


func _exit_tree() -> void:
	GestorPartida.cerrar_ventana("informe_final")


func _crear_interfaz() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.02, 0.02, 0.03, 0.96)
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

	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", 22)
	raiz.add_child(_titulo)

	_pestanas = TabContainer.new()
	_pestanas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(_pestanas)
	_basica = _crear_pagina_texto("Explicación básica")
	_tecnica = _crear_pagina_texto("Explicación técnica")
	_errores = _crear_pagina_texto("Errores")
	_decisiones = _crear_pagina_texto("Decisiones")

	var scroll := ScrollContainer.new()
	scroll.name = "Información real"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pestanas.add_child(scroll)
	_revelacion = VBoxContainer.new()
	_revelacion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_revelacion.add_theme_constant_override("separation", 6)
	scroll.add_child(_revelacion)

	var nueva := Button.new()
	nueva.text = "Empezar una nueva partida"
	nueva.custom_minimum_size = Vector2(0, 40)
	nueva.pressed.connect(func() -> void: GestorPartida.reiniciar_partida())
	raiz.add_child(nueva)


func _crear_pagina_texto(nombre: String) -> Label:
	var scroll := ScrollContainer.new()
	scroll.name = nombre
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pestanas.add_child(scroll)
	var etiqueta := Label.new()
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(etiqueta)
	return etiqueta


func _mostrar(resultado: Dictionary) -> void:
	_titulo.text = "%s · %s" % [str(resultado.get("titulo", "Fin de la partida")), "Día %d" % int(resultado.get("dia", EstadoJuego.dia_de_partida))]
	_basica.text = str(resultado.get("explicacion_basica", ""))
	_tecnica.text = str(resultado.get("explicacion_tecnica", ""))

	var errores: Array = resultado.get("errores", [])
	var lineas_errores: Array[String] = []
	for error in errores:
		lineas_errores.append("• " + str(error))
	_errores.text = "\n\n".join(lineas_errores)

	var lineas_decisiones: Array[String] = []
	for decision in EstadoJuego.registro_decisiones:
		lineas_decisiones.append("Día %d — %s\nTu respuesta: %s (%s)\n%s" % [
			int(decision.get("dia", 0)),
			str(decision.get("enunciado", "")),
			str(decision.get("texto", "")),
			"adecuada" if bool(decision.get("adecuada", false)) else "perjudicial",
			str(decision.get("explicacion", ""))
		])
	_decisiones.text = "\n\n".join(lineas_decisiones) if not lineas_decisiones.is_empty() else "No respondiste ningún cuestionario."

	for hijo in _revelacion.get_children():
		hijo.queue_free()
	var cabecera := Label.new()
	cabecera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cabecera.text = "Escenario real: crisis financiera de 2008. Fecha real de inicio de la partida: %s. Los nombres del juego sustituían a entidades reales." % EstadoJuego.FECHA_INICIO_PROVISIONAL
	_revelacion.add_child(cabecera)
	for noticia in GestorPartida.noticias_para_revelar():
		var texto := Label.new()
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if bool(noticia.get("falsa", false)):
			texto.text = "FALSA · «%s»\n%s" % [str(noticia.get("titulo_juego", "")), str(noticia.get("fuente", ""))]
		else:
			texto.text = "REAL · «%s»\nEn la realidad: %s (%s)\nFuente: %s" % [
				str(noticia.get("titulo_juego", "")), str(noticia.get("titulo_real", "")),
				str(noticia.get("fecha_real", "")), str(noticia.get("fuente", ""))
			]
		_revelacion.add_child(texto)
		var url := str(noticia.get("fuente_url", ""))
		if url.begins_with("https://"):
			var enlace := LinkButton.new()
			enlace.text = "Abrir fuente original"
			enlace.uri = url
			_revelacion.add_child(enlace)

	_pestanas.current_tab = 0
	_fondo.visible = true
	GestorPartida.abrir_ventana("informe_final")
