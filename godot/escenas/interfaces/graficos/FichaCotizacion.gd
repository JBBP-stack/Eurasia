extends VBoxContainer
## Ficha de cotización de una empresa, como en una aplicación de bolsa: precio, variación del día,
## gráfica con rangos (5 días, 1 mes, 6 meses, 1 año, 2 años), rentabilidades y descripción.
## Nunca muestra datos posteriores al día de partida ni fechas reales (solo «Día N» o «hace N meses»).

signal activo_cambiado(activo_id: String)

const GraficoLineas := preload("res://escenas/interfaces/graficos/GraficoLineas.gd")
const RANGOS: Array[Dictionary] = [
	{"texto": "5 días", "dias": 7},
	{"texto": "1 mes", "dias": 31},
	{"texto": "6 meses", "dias": 183},
	{"texto": "1 año", "dias": 366},
	{"texto": "2 años", "dias": 731}
]

## Si es true, la ficha incluye su propio selector de empresa.
var con_selector: bool = true
var activo_id: String = ""
var _dias_rango: int = 31
var _selector: OptionButton
var _cabecera: Label
var _subcabecera: Label
var _grafico: Control
var _estadisticas: Label
var _botones_rango: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	if con_selector:
		_selector = OptionButton.new()
		_selector.item_selected.connect(func(indice: int) -> void:
			mostrar_activo(str(_selector.get_item_metadata(indice))))
		add_child(_selector)

	_cabecera = Label.new()
	_cabecera.add_theme_font_size_override("font_size", 18)
	_cabecera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_cabecera)
	_subcabecera = Label.new()
	_subcabecera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_subcabecera)

	var fila_rangos := HBoxContainer.new()
	fila_rangos.add_theme_constant_override("separation", 4)
	add_child(fila_rangos)
	var grupo := ButtonGroup.new()
	for rango in RANGOS:
		var boton := Button.new()
		boton.text = str(rango["texto"])
		boton.toggle_mode = true
		boton.button_group = grupo
		boton.button_pressed = int(rango["dias"]) == _dias_rango
		boton.pressed.connect(func() -> void:
			_dias_rango = int(rango["dias"])
			_actualizar())
		fila_rangos.add_child(boton)
		_botones_rango.append(boton)

	_grafico = GraficoLineas.new()
	_grafico.custom_minimum_size = Vector2(320, 200)
	_grafico.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_grafico)

	_estadisticas = Label.new()
	_estadisticas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_estadisticas)

	SistemaMercado.precios_actualizados.connect(_actualizar)
	SistemaFinanciero.finanzas_actualizadas.connect(_actualizar)
	recargar_selector()


func recargar_selector() -> void:
	if _selector == null:
		if activo_id.is_empty() and not SistemaMercado.activos.is_empty():
			mostrar_activo(str(SistemaMercado.activos[0].get("id", "")))
		return
	_selector.clear()
	for indice in range(SistemaMercado.activos.size()):
		var activo: Dictionary = SistemaMercado.activos[indice]
		_selector.add_item("%s (%s)" % [str(activo.get("nombre", "")), str(activo.get("sector", ""))])
		_selector.set_item_metadata(indice, str(activo.get("id", "")))
	if _selector.item_count > 0:
		var seleccionado := 0
		for indice in range(_selector.item_count):
			if str(_selector.get_item_metadata(indice)) == activo_id:
				seleccionado = indice
		_selector.select(seleccionado)
		mostrar_activo(str(_selector.get_item_metadata(seleccionado)))


func mostrar_activo(nuevo_id: String) -> void:
	if nuevo_id.is_empty():
		return
	var cambiado := nuevo_id != activo_id
	activo_id = nuevo_id
	_actualizar()
	if cambiado:
		activo_cambiado.emit(activo_id)


func _actualizar() -> void:
	if _cabecera == null or activo_id.is_empty():
		return
	var info := SistemaMercado.info_activo(activo_id)
	var precio := SistemaMercado.precio_actual_centimos(activo_id)
	var anterior := SistemaMercado.precio_sesion_anterior(activo_id)
	var cambio := precio - anterior
	var cambio_pct := (float(cambio) / float(anterior)) if anterior > 0 else 0.0
	_cabecera.text = "%s — %s €  %s %s € (%s) en la última sesión" % [
		str(info.get("nombre", activo_id)),
		EstadoJuego.euros(precio),
		"▲" if cambio > 0 else ("▼" if cambio < 0 else "■"),
		EstadoJuego.euros(absi(cambio)),
		_pct(cambio_pct)
	]
	var acciones := 0
	for posicion in EstadoJuego.cartera:
		if str(posicion.get("id", "")) == activo_id:
			acciones = int(posicion.get("acciones", 0))
	var estado_bolsa := SistemaMercado.texto_estado_bolsa()
	_subcabecera.text = "%s · %s · En tu cartera: %d acciones (%s €)" % [
		str(info.get("sector", "")), estado_bolsa, acciones, EstadoJuego.euros(acciones * precio)
	]

	var puntos: Array[Dictionary] = []
	for punto in SistemaMercado.serie(activo_id, SistemaMercado.fecha_hace_dias(_dias_rango)):
		puntos.append({"etiqueta": _etiqueta_fecha(str(punto["fecha"])), "valor": int(punto["valor"])})
	_grafico.call("establecer_puntos", puntos)

	var rango_anual := SistemaMercado.rango_precios(activo_id, 365)
	var variacion_2a := SistemaMercado.variacion_desde(activo_id, 730)
	var calidad := "Cotización real convertida a euros." if bool(info.get("verificado", false)) else "Serie reconstruida: algunos cierres son aproximados."
	_estadisticas.text = "Rentabilidad: 5 días %s · 1 mes %s · 6 meses %s · 1 año %s · 2 años %s\nMáximo / mínimo de las últimas 52 semanas: %s € / %s €\n\n%s\n%s\n\n%s" % [
		_pct(SistemaMercado.variacion_desde(activo_id, 7)),
		_pct(SistemaMercado.variacion_desde(activo_id, 31)),
		_pct(SistemaMercado.variacion_desde(activo_id, 183)),
		_pct(SistemaMercado.variacion_desde(activo_id, 366)),
		_pct(variacion_2a),
		EstadoJuego.euros(rango_anual.y), EstadoJuego.euros(rango_anual.x),
		str(info.get("descripcion", "")),
		_resumen_trayectoria(variacion_2a, SistemaMercado.variacion_desde(activo_id, 366)),
		calidad
	]


func _resumen_trayectoria(dos_anios: float, un_anio: float) -> String:
	var tendencia := "ha subido" if dos_anios >= 0.0 else "ha caído"
	return "En los últimos dos años la acción %s un %.0f %% (en el último año: %s)." % [tendencia, absf(dos_anios) * 100.0, _pct(un_anio)]


## Etiqueta sin fecha real: «Día N» durante la partida, «hace N d/m» antes.
func _etiqueta_fecha(fecha: String) -> String:
	if fecha >= EstadoJuego.FECHA_INICIO_PROVISIONAL:
		return "Día %d" % EstadoJuego.dia_de_fecha(fecha)
	var dias := EstadoJuego.dia_de_partida - EstadoJuego.dia_de_fecha(fecha)
	if dias < 60:
		return "hace %d d" % dias
	return "hace %d m" % int(round(float(dias) / 30.4))


func _pct(valor: float) -> String:
	return "%+.1f %%" % (valor * 100.0)
