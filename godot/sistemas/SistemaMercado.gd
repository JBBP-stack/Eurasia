extends Node
## Mercado del escenario: catálogo de activos ficticios y precios por fecha interna.
## Los precios provienen de datos/mercado/mercado_2008.json. Mientras ese archivo tenga
## "verificado": false, las cotizaciones son ilustrativas y la interfaz lo indica.

signal precios_actualizados

const RUTA_MERCADO: String = "res://datos/mercado/mercado_2008.json"

var activos: Array[Dictionary] = []
var verificado: bool = false
var _fechas_ordenadas: Dictionary = {}  # id -> Array[String] de fechas con cotización


func _ready() -> void:
	_cargar()
	sincronizar_cartera()
	actualizar_precios()
	EstadoJuego.dia_cambiado.connect(_al_cambiar_dia)


func _cargar() -> void:
	activos.clear()
	_fechas_ordenadas.clear()
	if not FileAccess.file_exists(RUTA_MERCADO):
		push_error("No existe el archivo de mercado: " + RUTA_MERCADO)
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_MERCADO))
	if not datos is Dictionary:
		push_error("El archivo de mercado no es un objeto JSON válido.")
		return
	verificado = bool(datos.get("verificado", false))
	for activo in datos.get("activos", []):
		if not activo is Dictionary:
			continue
		var precios: Variant = activo.get("precios_centimos", {})
		if not precios is Dictionary or precios.is_empty():
			push_warning("Activo sin precios: " + str(activo.get("id", "?")))
			continue
		var fechas: Array = precios.keys()
		fechas.sort()
		_fechas_ordenadas[str(activo.get("id", ""))] = fechas
		activos.append(activo)


func _al_cambiar_dia(_nuevo_dia: int) -> void:
	actualizar_precios()


func info_activo(activo_id: String) -> Dictionary:
	for activo in activos:
		if str(activo.get("id", "")) == activo_id:
			return activo
	return {}


## Último precio conocido en o antes de la fecha indicada (los fines de semana conservan el cierre del viernes).
func precio_en(activo_id: String, fecha: String) -> int:
	var activo := info_activo(activo_id)
	if activo.is_empty():
		return 0
	var precios: Dictionary = activo.get("precios_centimos", {})
	var fechas: Array = _fechas_ordenadas.get(activo_id, [])
	if fechas.is_empty():
		return 0
	var elegida: String = str(fechas[0])
	for f in fechas:
		if str(f) <= fecha:
			elegida = str(f)
		else:
			break
	return int(precios.get(elegida, 0))


func precio_actual_centimos(activo_id: String) -> int:
	return precio_en(activo_id, EstadoJuego.fecha_historica_interna)


## Precio de la sesión anterior a la fecha actual, para mostrar la variación diaria.
func precio_sesion_anterior(activo_id: String) -> int:
	var fechas: Array = _fechas_ordenadas.get(activo_id, [])
	var anterior: String = ""
	for f in fechas:
		if str(f) < EstadoJuego.fecha_historica_interna:
			anterior = str(f)
		else:
			break
	if anterior.is_empty():
		return precio_actual_centimos(activo_id)
	return precio_en(activo_id, anterior)


func mercado_abierto(fecha: String = "") -> bool:
	if fecha.is_empty():
		fecha = EstadoJuego.fecha_historica_interna
	if not bool(Reglas.valor("mercado/cerrado_fines_de_semana", true)):
		return true
	var fecha_dict := Time.get_datetime_dict_from_datetime_string(fecha + "T00:00:00", true)
	var dia_semana := int(fecha_dict.get("weekday", 1))
	return dia_semana != Time.WEEKDAY_SATURDAY and dia_semana != Time.WEEKDAY_SUNDAY


## Garantiza que la cartera contiene una entrada (aunque sea con 0 acciones) por cada activo del catálogo.
func sincronizar_cartera() -> void:
	for activo in activos:
		var activo_id := str(activo.get("id", ""))
		var encontrado := false
		for posicion in EstadoJuego.cartera:
			if str(posicion.get("id", "")) == activo_id:
				posicion["nombre"] = str(activo.get("nombre", activo_id))
				encontrado = true
				break
		if not encontrado:
			EstadoJuego.cartera.append({
				"id": activo_id,
				"nombre": str(activo.get("nombre", activo_id)),
				"acciones": 0,
				"precio_centimos": precio_actual_centimos(activo_id)
			})


func actualizar_precios() -> void:
	for posicion in EstadoJuego.cartera:
		var precio := precio_actual_centimos(str(posicion.get("id", "")))
		if precio > 0:
			posicion["precio_centimos"] = precio
	precios_actualizados.emit()
