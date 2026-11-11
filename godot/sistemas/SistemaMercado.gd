extends Node
## Mercado del escenario: catálogo de activos ficticios y precios por fecha interna.
## Los precios provienen de datos/mercado/mercado_2008.json: cotizaciones reales (empresas con nombre ficticio)
## en céntimos de euro. Cada activo indica si su serie está verificada ("verificado") y su fuente.

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


## Hay sesión si el activo de referencia cotizó ese día (cierra fines de semana y festivos reales).
func mercado_abierto(fecha: String = "") -> bool:
	if fecha.is_empty():
		fecha = EstadoJuego.fecha_historica_interna
	var referencia := info_activo(Reglas.texto("mercado/activo_referencia_sesiones", "COL"))
	if referencia.is_empty():
		return not _es_fin_de_semana(fecha)
	return (referencia.get("precios_centimos", {}) as Dictionary).has(fecha)


## Se puede comprar y vender si hay sesión o si las reglas permiten operar todos los días
## (en días sin sesión se usa el último precio de cierre).
func se_puede_operar() -> bool:
	return mercado_abierto() or bool(Reglas.valor("mercado/operar_todos_los_dias", false))


## Texto breve del estado de la bolsa para las interfaces.
func texto_estado_bolsa() -> String:
	if mercado_abierto():
		return "Bolsa abierta"
	if se_puede_operar():
		return "Hoy no hay sesión (%s): se opera al último precio de cierre" % motivo_mercado_cerrado()
	return "Bolsa cerrada hoy (%s)" % motivo_mercado_cerrado()


func motivo_mercado_cerrado(fecha: String = "") -> String:
	if fecha.is_empty():
		fecha = EstadoJuego.fecha_historica_interna
	if mercado_abierto(fecha):
		return ""
	return "fin de semana" if _es_fin_de_semana(fecha) else "festivo, sin sesión"


func _es_fin_de_semana(fecha: String) -> bool:
	var dia_semana := int(Time.get_datetime_dict_from_datetime_string(fecha + "T00:00:00", true).get("weekday", 1))
	return dia_semana == Time.WEEKDAY_SATURDAY or dia_semana == Time.WEEKDAY_SUNDAY


## Serie de cotizaciones entre dos fechas (incluidas) para las gráficas: [{"fecha": String, "valor": int}].
## Nunca devuelve datos posteriores a la fecha actual de la partida.
func serie(activo_id: String, desde: String, hasta: String = "") -> Array[Dictionary]:
	if hasta.is_empty() or hasta > EstadoJuego.fecha_historica_interna:
		hasta = EstadoJuego.fecha_historica_interna
	var resultado: Array[Dictionary] = []
	var activo := info_activo(activo_id)
	var precios: Dictionary = activo.get("precios_centimos", {})
	for f in _fechas_ordenadas.get(activo_id, []):
		var fecha := str(f)
		if fecha >= desde and fecha <= hasta:
			resultado.append({"fecha": fecha, "valor": int(precios[fecha])})
	return resultado


## Fecha interna desplazada N días hacia atrás desde hoy.
func fecha_hace_dias(dias: int) -> String:
	var hoy := Time.get_unix_time_from_datetime_string(EstadoJuego.fecha_historica_interna + "T00:00:00")
	return Time.get_date_string_from_unix_time(hoy - dias * 86_400)


## Variación porcentual del precio entre hace N días y hoy (0 si no hay datos).
func variacion_desde(activo_id: String, dias: int) -> float:
	var inicial := precio_en(activo_id, fecha_hace_dias(dias))
	var actual := precio_actual_centimos(activo_id)
	if inicial <= 0:
		return 0.0
	return float(actual - inicial) / float(inicial)


## Máximo y mínimo de cierre en los últimos N días: Vector2i(minimo, maximo).
func rango_precios(activo_id: String, dias: int) -> Vector2i:
	var minimo := 0
	var maximo := 0
	for punto in serie(activo_id, fecha_hace_dias(dias)):
		var v := int(punto["valor"])
		minimo = v if minimo == 0 else mini(minimo, v)
		maximo = maxi(maximo, v)
	return Vector2i(minimo, maximo)


## Garantiza que la cartera contiene una entrada (aunque sea con 0 acciones) por cada activo del catálogo.
func sincronizar_cartera() -> void:
	# Se descartan posiciones de activos que ya no existen en el catálogo (escenarios anteriores).
	var depurada: Array[Dictionary] = []
	for posicion in EstadoJuego.cartera:
		if not info_activo(str(posicion.get("id", ""))).is_empty():
			depurada.append(posicion)
	EstadoJuego.cartera = depurada
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
