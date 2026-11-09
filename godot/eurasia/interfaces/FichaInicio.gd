extends CanvasLayer
## Primera pantalla provisional de la demo.
## Añadir como script a un nodo CanvasLayer llamado FichaInicio en habitacion1.tscn.

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.06, 0.08, 0.96)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 300)
	centro.add_child(panel)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 14)
	panel.add_child(margen)

	var contenido := VBoxContainer.new()
	margen.add_child(contenido)

	var titulo := Label.new()
	titulo.text = "EURASIA — TU PERSONAJE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(titulo)
	contenido.add_child(HSeparator.new())

	var info := Label.new()
	var persona: Dictionary = EstadoJuego.perfil
	info.text = "Edad: %d\nGénero: %s\nPaís: %s\nDinero en el banco: %s €\nInvertido: %s €" % [
		int(persona["edad"]),
		str(persona["genero"]),
		str(persona["pais_ficticio"]),
		EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos),
		EstadoJuego.euros(EstadoJuego.valor_cartera_centimos()),
	]
	contenido.add_child(info)

	var detalle := Label.new()
	detalle.text = "Inversiones actuales:"
	for posicion in EstadoJuego.cartera:
		detalle.text += "\n• %s — %s €" % [
			str(posicion["nombre"]),
			EstadoJuego.euros(int(posicion["acciones"]) * int(posicion["precio_centimos"]))
		]
	contenido.add_child(detalle)

	var empezar := Button.new()
	empezar.text = "\nCOMENZAR PARTIDA"
	empezar.pressed.connect(_comenzar)
	contenido.add_child(empezar)

	get_tree().paused = true

func _comenzar() -> void:
	get_tree().paused = false
	queue_free()
