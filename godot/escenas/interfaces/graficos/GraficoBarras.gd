extends Control
## Barras horizontales de una sola magnitud (p. ej. distribución del patrimonio).
## Un único tono: la identidad de cada barra la da su etiqueta, no el color.

const COLOR_FONDO := Color("#1a1a19")
const COLOR_TEXTO := Color("#f0efec")
const COLOR_TEXTO_SECUNDARIO := Color("#c3c2b7")
const COLOR_REJILLA := Color("#3a3936")
const COLOR_BARRA := Color("#3987e5")
const ANCHO_ETIQUETA := 150.0
const ANCHO_VALOR := 120.0
const ALTO_FILA := 22.0

## Cada elemento: {"etiqueta": String, "valor": int (céntimos)}
var elementos: Array[Dictionary] = []
var _indice_hover: int = -1
var _estilo_barra: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_estilo_barra = StyleBoxFlat.new()
	_estilo_barra.bg_color = COLOR_BARRA
	# Extremo de datos redondeado (4 px), base recta anclada al eje.
	_estilo_barra.corner_radius_top_right = 4
	_estilo_barra.corner_radius_bottom_right = 4
	mouse_exited.connect(func() -> void:
		_indice_hover = -1
		queue_redraw())


func establecer_elementos(nuevos: Array[Dictionary]) -> void:
	elementos = nuevos
	elementos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("valor", 0)) > int(b.get("valor", 0)))
	custom_minimum_size = Vector2(320, maxf(60.0, ALTO_FILA * elementos.size() + 12.0))
	queue_redraw()


func _draw() -> void:
	var fuente := get_theme_default_font()
	var tam := 11
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_FONDO)
	if elementos.is_empty():
		draw_string(fuente, Vector2(8, 24), "Sin datos todavía.", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, COLOR_TEXTO_SECUNDARIO)
		return

	var total := 0
	var maximo := 1
	for elemento in elementos:
		var v := maxi(0, int(elemento.get("valor", 0)))
		total += v
		maximo = maxi(maximo, v)

	var ancho_barras := maxf(10.0, size.x - ANCHO_ETIQUETA - ANCHO_VALOR - 16.0)
	var x0 := ANCHO_ETIQUETA + 8.0
	draw_line(Vector2(x0, 4), Vector2(x0, 8 + ALTO_FILA * elementos.size()), COLOR_REJILLA, 1.0)
	for i in range(elementos.size()):
		var elemento: Dictionary = elementos[i]
		var valor := maxi(0, int(elemento.get("valor", 0)))
		var y := 6.0 + ALTO_FILA * i
		if i == _indice_hover:
			draw_rect(Rect2(0, y - 2, size.x, ALTO_FILA), Color("#242423"))
		draw_string(fuente, Vector2(6, y + 13), str(elemento.get("etiqueta", "")), HORIZONTAL_ALIGNMENT_LEFT, ANCHO_ETIQUETA - 8, tam, COLOR_TEXTO)
		var largo := ancho_barras * float(valor) / float(maximo)
		if largo >= 1.0:
			draw_style_box(_estilo_barra, Rect2(x0, y + 3, largo, ALTO_FILA - 8))
		var peso := (float(valor) / float(total) * 100.0) if total > 0 else 0.0
		draw_string(fuente, Vector2(x0 + ancho_barras + 6, y + 13), "%s € · %.0f %%" % [EstadoJuego.euros(valor), peso], HORIZONTAL_ALIGNMENT_LEFT, ANCHO_VALOR + 8, tam, COLOR_TEXTO_SECUNDARIO)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var indice := int(floor((event.position.y - 4.0) / ALTO_FILA))
		if indice < 0 or indice >= elementos.size():
			indice = -1
		if indice != _indice_hover:
			_indice_hover = indice
			queue_redraw()
