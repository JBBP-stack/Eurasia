extends Node

# Configuración: añadir como Autoload con el nombre "NoticiasManager".
signal noticias_actualizadas(cantidad: int)
signal decision_resuelta(noticia_id: String, opcion_id: String, efecto: Dictionary)

const RUTA_NOTICIAS := "res://datos/noticias/noticias_2008.json"
const RUTA_PREGUNTAS := "res://datos/noticias/preguntas_2008.json"
const RUTA_PARTIDA := "user://eurasia_noticias_partida.json"

var fecha_actual: String = "2008-09-15"
var noticias: Array[Dictionary] = []
var preguntas: Dictionary = {}
var leidas: Dictionary = {}
var respuestas: Dictionary = {}

func _ready() -> void:
	_cargar_contenido()
	_cargar_partida()
	noticias_actualizadas.emit(cuantas_sin_leer())

func _leer_json(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		push_error("No existe: " + ruta)
		return {}
	var parseo := JSON.new()
	var error := parseo.parse(FileAccess.get_file_as_string(ruta))
	if error != OK or not (parseo.data is Dictionary):
		push_error("JSON inválido en " + ruta)
		return {}
	return parseo.data

func _cargar_contenido() -> void:
	noticias.clear()
	var datos := _leer_json(RUTA_NOTICIAS)
	for valor in datos.get("noticias", []):
		if valor is Dictionary:
			noticias.append(valor)
	preguntas = _leer_json(RUTA_PREGUNTAS).get("preguntas", {})

func obtener_noticias_hoy() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for noticia in noticias:
		if str(noticia.get("disponible_desde", "")) == fecha_actual:
			resultado.append(noticia)
	resultado.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("prioridad", 0)) > int(b.get("prioridad", 0)))
	if resultado.size() > 5:
		resultado.resize(5)
	return resultado

func obtener_pregunta(noticia_id: String) -> Dictionary:
	for noticia in obtener_noticias_hoy():
		if str(noticia.get("id", "")) == noticia_id:
			return preguntas.get(str(noticia.get("pregunta_id", "")), {})
	return {}

func cuantas_sin_leer() -> int:
	var total := 0
	for noticia in obtener_noticias_hoy():
		if not leidas.has(str(noticia.get("id", ""))):
			total += 1
	return total

func marcar_leida(noticia_id: String) -> void:
	for noticia in obtener_noticias_hoy():
		if str(noticia.get("id", "")) == noticia_id:
			if leidas.has(noticia_id):
				return
			leidas[noticia_id] = true
			_guardar_partida()
			noticias_actualizadas.emit(cuantas_sin_leer())
			return

func responder(noticia_id: String, opcion_id: String) -> Dictionary:
	if respuestas.has(noticia_id):
		return {}
	var pregunta := obtener_pregunta(noticia_id)
	for opcion in pregunta.get("opciones", []):
		if str(opcion.get("id", "")) == opcion_id:
			respuestas[noticia_id] = opcion_id
			var efecto: Dictionary = opcion.get("efecto", {})
			_guardar_partida()
			decision_resuelta.emit(noticia_id, opcion_id, efecto)
			return opcion
	return {}

func respuesta_de(noticia_id: String) -> String:
	return str(respuestas.get(noticia_id, ""))

func puede_dormir() -> bool:
	for noticia in obtener_noticias_hoy():
		var id := str(noticia.get("id", ""))
		if not obtener_pregunta(id).is_empty() and not respuestas.has(id):
			return false
	return true

func avanzar_dia() -> bool:
	if not puede_dormir():
		return false
	var segundos := Time.get_unix_time_from_datetime_string(fecha_actual + "T00:00:00")
	fecha_actual = Time.get_date_string_from_unix_time(int(segundos) + 86400)
	_guardar_partida()
	noticias_actualizadas.emit(cuantas_sin_leer())
	return true

func reiniciar_demo() -> void:
	fecha_actual = "2008-09-15"
	leidas.clear()
	respuestas.clear()
	_guardar_partida()
	noticias_actualizadas.emit(cuantas_sin_leer())

func _guardar_partida() -> void:
	var archivo := FileAccess.open(RUTA_PARTIDA, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo guardar el estado de noticias")
		return
	archivo.store_string(JSON.stringify({
		"fecha_actual": fecha_actual,
		"leidas": leidas,
		"respuestas": respuestas
	}, "\t"))

func _cargar_partida() -> void:
	if not FileAccess.file_exists(RUTA_PARTIDA):
		return
	var guardado := _leer_json(RUTA_PARTIDA)
	fecha_actual = str(guardado.get("fecha_actual", fecha_actual))
	leidas = guardado.get("leidas", {})
	respuestas = guardado.get("respuestas", {})
