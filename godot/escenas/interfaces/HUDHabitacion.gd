extends CanvasLayer
## HUD reutilizable: día y resumen del patrimonio del personaje.

var _dia: Label
var _saldo_bancario: Label
var _total_inversiones: Label
var _lista_inversiones: VBoxContainer
var _patrimonio_total: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_interfaz()
	EstadoJuego.dia_cambiado.connect(_al_cambiar_dia)
	NoticiasManager.decision_resuelta.connect(_al_resolver_decision)
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
	panel_dia.add_child(_dia)

	var panel_patrimonio := PanelContainer.new()
	add_child(panel_patrimonio)
	panel_patrimonio.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel_patrimonio.offset_left = 12
	panel_patrimonio.offset_top = 58
	panel_patrimonio.offset_right = 252
	panel_patrimonio.offset_bottom = 400

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

	_total_inversiones = Label.new()
	contenido.add_child(_total_inversiones)

	_lista_inversiones = VBoxContainer.new()
	_lista_inversiones.add_theme_constant_override("separation", 3)
	contenido.add_child(_lista_inversiones)

	contenido.add_child(HSeparator.new())
	_patrimonio_total = Label.new()
	contenido.add_child(_patrimonio_total)


func actualizar() -> void:
	_dia.text = EstadoJuego.etiqueta_dia()
	_saldo_bancario.text = "Banco: %s €" % EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos)
	_total_inversiones.text = "Inversiones: %s €" % EstadoJuego.euros(EstadoJuego.valor_cartera_centimos())
	_patrimonio_total.text = "Total: %s €" % EstadoJuego.euros(EstadoJuego.patrimonio_total_centimos())

	while _lista_inversiones.get_child_count() > EstadoJuego.cartera.size():
		var ultima := _lista_inversiones.get_child(_lista_inversiones.get_child_count() - 1)
		_lista_inversiones.remove_child(ultima)
		ultima.queue_free()

	while _lista_inversiones.get_child_count() < EstadoJuego.cartera.size():
		var etiqueta := Label.new()
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_inversiones.add_child(etiqueta)

	for indice in range(EstadoJuego.cartera.size()):
		var posicion: Dictionary = EstadoJuego.cartera[indice]
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
