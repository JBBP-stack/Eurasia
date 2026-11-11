extends CanvasLayer
## Ficha inicial del personaje. Se muestra sobre la habitación al arrancar el juego.
## Si existe una partida guardada permite continuarla o empezar una nueva.

const RUTA_RETRATO := "res://assets/personaje/jugador_idle_abajo_64x96.png"

var _confirmacion_nueva: ConfirmationDialog


func _ready() -> void:
	if EstadoJuego.partida_iniciada:
		queue_free()
		return
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_ficha()
	GestorPartida.abrir_ventana("ficha_inicio")


func _exit_tree() -> void:
	GestorPartida.cerrar_ventana("ficha_inicio")


func _crear_ficha() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.06, 0.08, 0.96)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	fondo.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 380)
	centro.add_child(panel)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 20)
	panel.add_child(margen)

	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 12)
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
	datos.add_theme_constant_override("separation", 6)
	datos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(datos)

	var persona: Dictionary = EstadoJuego.perfil
	_agregar_dato(datos, "Edad", str(persona.get("edad", "Por definir")))
	_agregar_dato(datos, "Género", str(persona.get("genero", "Por definir")))
	_agregar_dato(datos, "País", str(persona.get("pais_ficticio", "Por definir")))
	_agregar_dato(datos, "Clase social", str(persona.get("clase_social", "Por definir")))

	var retrato := PanelContainer.new()
	retrato.custom_minimum_size = Vector2(170, 210)
	retrato.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(retrato)

	# Sprite de 64x96 a escala x2 exacta para que el pixel art quede nítido.
	var imagen_retrato := TextureRect.new()
	imagen_retrato.texture = load(RUTA_RETRATO) as Texture2D
	imagen_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen_retrato.custom_minimum_size = Vector2(128, 192)
	imagen_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagen_retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	imagen_retrato.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	retrato.add_child(imagen_retrato)

	var nota := Label.new()
	nota.text = "El progreso se guarda automáticamente"
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(nota)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	contenido.add_child(botones)

	# La partida también puede tener progreso guardado durante el primer día.
	var hay_partida := GestorPartida.hay_progreso_guardado()
	var empezar := Button.new()
	empezar.text = "Continuar partida" if hay_partida else "Comenzar partida"
	empezar.custom_minimum_size = Vector2(0, 44)
	empezar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empezar.pressed.connect(_comenzar)
	botones.add_child(empezar)

	if hay_partida:
		var nueva := Button.new()
		nueva.text = "Nueva partida"
		nueva.custom_minimum_size = Vector2(0, 44)
		nueva.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nueva.pressed.connect(_pedir_confirmacion_nueva_partida)
		botones.add_child(nueva)

		_confirmacion_nueva = ConfirmationDialog.new()
		_confirmacion_nueva.title = "Empezar una nueva partida"
		_confirmacion_nueva.dialog_text = "Se reiniciará el progreso guardado. ¿Quieres continuar?"
		_confirmacion_nueva.ok_button_text = "Empezar nueva partida"
		_confirmacion_nueva.cancel_button_text = "Cancelar"
		_confirmacion_nueva.confirmed.connect(_nueva_partida)
		add_child(_confirmacion_nueva)


func _agregar_dato(contenedor: VBoxContainer, nombre: String, valor: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = "%s: %s" % [nombre, valor]
	contenedor.add_child(etiqueta)


func _comenzar() -> void:
	EstadoJuego.partida_iniciada = true
	queue_free()


func _nueva_partida() -> void:
	# reiniciar_partida() recarga la habitación y vuelve a mostrar esta ficha con los valores iniciales.
	GestorPartida.reiniciar_partida()


func _pedir_confirmacion_nueva_partida() -> void:
	if _confirmacion_nueva:
		_confirmacion_nueva.popup_centered()
