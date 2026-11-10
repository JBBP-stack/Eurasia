extends Control
## Gráfica de una sola serie (p. ej. patrimonio por día) con cruz y tooltip al pasar el ratón.
## Una sola serie: el título del panel la nombra, por eso no hay leyenda.

const COLOR_FONDO := Color("#1a1a19")
const COLOR_TEXTO := Color("#f0efec")
const COLOR_TEXTO_SECUNDARIO := Color("#c3c2b7")
const COLOR_REJILLA := Color("#3a3936")
const COLOR_SERIE := Color("#3987e5")
const MARGEN_IZQ := 64.0
const MARGEN_DER := 16.0
const MARGEN_SUP := 12.0
const MARGEN_INF := 26.0

## Cada punto: {"etiqueta": String, "valor": int (céntimos)}
var puntos: Array[Dictionary] = []
var _indice_hover: int = -1


func _ready() -> void:
	custom_minimum_size = Vector2(320, 180)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void:
		_indice_hover = -1
		queue_redraw())


func establecer_puntos(nuevos: Array[Dictionary]) -> void:
	puntos = nuevos
	_indice_hover = -1
	queue_redraw()


func _area() -> Rect2:
	return Rect2(MARGEN_IZQ, MARGEN_SUP, maxf(1.0, size.x - MARGEN_IZQ - MARGEN_DER), maxf(1.0, size.y - MARGEN_SUP - MARGEN_INF))


func _rango() -> Vector2:
	var minimo := INF
	var maximo := -INF
	for punto in puntos:
		var v := float(punto.get("valor", 0))
		minimo = minf(minimo, v)
		maximo = maxf(maximo, v)
	if is_inf(minimo):
		return Vector2(0, 1)
	var margen := maxf((maximo - minimo) * 0.1, absf(maximo) * 0.02 + 100.0)
	return Vector2(minimo - margen, maximo + margen)


func _posicion(indice: int, rango: Vector2, area: Rect2) -> Vector2:
	var x := area.position.x + (area.size.x * 0.5 if puntos.size() == 1 else area.size.x * float(indice) / float(puntos.size() - 1))
	var t := (float(puntos[indice].get("valor", 0)) - rango.x) / (rango.y - rango.x)
	return Vector2(x, area.position.y + area.size.y * (1.0 - t))


func _draw() -> void:
	var fuente := get_theme_default_font()
	var tam := 11
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_FONDO)
	var area := _area()
	if puntos.is_empty():
		draw_string(fuente, Vector2(area.position.x, area.get_center().y), "Sin datos todavía.", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, COLOR_TEXTO_SECUNDARIO)
		return

	var rango := _rango()
	# Rejilla horizontal recesiva con etiquetas del eje Y.
	for i in range(5):
		var t := float(i) / 4.0
		var y := area.position.y + area.size.y * (1.0 - t)
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), COLOR_REJILLA, 1.0)
		var valor := rango.x + (rango.y - rango.x) * t
		draw_string(fuente, Vector2(4, y + 4), _formato_euros(valor), HORIZONTAL_ALIGNMENT_LEFT, MARGEN_IZQ - 8, tam, COLOR_TEXTO_SECUNDARIO)

	# Etiquetas del eje X: primera, última y algunas intermedias.
	var paso := maxi(1, int(ceil(float(puntos.size()) / 6.0)))
	for i in range(puntos.size()):
		if i % paso != 0 and i != puntos.size() - 1:
			continue
		var p := _posicion(i, rango, area)
		draw_string(fuente, Vector2(p.x - 18, size.y - 8), str(puntos[i].get("etiqueta", "")), HORIZONTAL_ALIGNMENT_CENTER, 36, tam, COLOR_TEXTO_SECUNDARIO)

	# Línea de 2 px y marcadores.
	var linea := PackedVector2Array()
	for i in range(puntos.size()):
		linea.append(_posicion(i, rango, area))
	if linea.size() >= 2:
		draw_polyline(linea, COLOR_SERIE, 2.0, true)
	if puntos.size() <= 40:
		for p in linea:
			draw_circle(p, 4.0, COLOR_FONDO)
			draw_circle(p, 3.0, COLOR_SERIE)

	# Cruz y tooltip.
	if _indice_hover >= 0 and _indice_hover < puntos.size():
		var p := linea[_indice_hover]
		draw_line(Vector2(p.x, area.position.y), Vector2(p.x, area.end.y), COLOR_TEXTO_SECUNDARIO, 1.0)
		draw_circle(p, 5.0, COLOR_SERIE)
		var texto := "%s: %s €" % [str(puntos[_indice_hover].get("etiqueta", "")), EstadoJuego.euros(int(puntos[_indice_hover].get("valor", 0)))]
		var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 12.0
		var caja := Rect2(Vector2(clampf(p.x + 8, 0, size.x - ancho), clampf(p.y - 28, 0, size.y - 20)), Vector2(ancho, 20))
		draw_rect(caja, Color("#2a2a28"))
		draw_rect(caja, COLOR_REJILLA, false, 1.0)
		draw_string(fuente, caja.position + Vector2(6, 14), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, COLOR_TEXTO)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not puntos.is_empty():
		var area := _area()
		var relativo := clampf((event.position.x - area.position.x) / area.size.x, 0.0, 1.0)
		var indice := 0 if puntos.size() == 1 else int(round(relativo * float(puntos.size() - 1)))
		if indice != _indice_hover:
			_indice_hover = indice
			queue_redraw()


func _formato_euros(centimos: float) -> String:
	var euros := centimos / 100.0
	if absf(euros) >= 1000.0:
		return "%.1fk €" % (euros / 1000.0)
	return "%d €" % int(round(euros))
