extends CanvasLayer
## Ficha inicial del personaje. Se muestra sobre la habitación hasta comenzar.

func _ready() -> void:
	if EstadoJuego.partida_iniciada:
		queue_free()
		return
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_ficha()
	get_tree().paused = true


func _crear_ficha() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.06, 0.08, 0.96)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 350)
	centro.add_child(panel)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 20)
	panel.add_child(margen)

	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 14)
	margen.add_child(contenido)

	var titulo := Label.new()
	titulo.text = "Tu personaje"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(titulo)
	contenido.add_child(HSeparator.new())

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 24)
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenido.add_child(fila)

	var datos := VBoxContainer.new()
	datos.add_theme_constant_override("separation", 12)
	datos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(datos)

	var persona: Dictionary = EstadoJuego.perfil
	_agregar_dato(datos, "Edad", str(persona.get("edad", "Por definir")))
	_agregar_dato(datos, "Género", str(persona.get("genero", "Por definir")))
	_agregar_dato(datos, "País", str(persona.get("pais_ficticio", "Por definir")))
	_agregar_dato(datos, "Clase social", str(persona.get("clase_social", "Por definir")))

	var retrato := PanelContainer.new()
	retrato.custom_minimum_size = Vector2(170, 190)
	retrato.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(retrato)

	var marcador_retrato := Label.new()
	marcador_retrato.text = "Retrato\nprovisional"
	marcador_retrato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marcador_retrato.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	retrato.add_child(marcador_retrato)

	var nota := Label.new()
	nota.text = "Perfil provisional · retrato pendiente"
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(nota)

	var empezar := Button.new()
	empezar.text = "Comenzar partida"
	empezar.custom_minimum_size = Vector2(0, 48)
	empezar.pressed.connect(_comenzar)
	contenido.add_child(empezar)


func _agregar_dato(contenedor: VBoxContainer, nombre: String, valor: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = "%s: %s" % [nombre, valor]
	contenedor.add_child(etiqueta)


func _comenzar() -> void:
	EstadoJuego.partida_iniciada = true
	get_tree().paused = false
	queue_free()
