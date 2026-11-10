extends Node

# Configuración: añadir como Autoload con el nombre "NoticiasManager".
signal noticias_actualizadas(cantidad: int)
signal decision_resuelta(noticia_id: String, opcion_id: String, efecto: Dictionary)

const RUTA_NOTICIAS := "res://datos/noticias/noticias_2008.json"
const RUTA_PREGUNTAS := "res://datos/noticias/preguntas_2008.json"
const RUTA_PARTIDA := "user://eurasia_calendario_noticias_v2.json"
const RUTA_PARTIDA_ANTIGUA := "user://eurasia_noticias_partida.json"

var noticias: Array[Dictionary] = []
var preguntas: Dictionary = {}
var leidas: Dictionary = {}
var respuestas: Dictionary = {}
var _guardado_bloqueado: bool = false

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
		if str(noticia.get("disponible_desde", "")) == EstadoJuego.fecha_historica_interna:
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

	EstadoJuego.avanzar_un_dia()

	_guardar_partida()
	noticias_actualizadas.emit(cuantas_sin_leer())

	return true


func reiniciar_demo() -> void:
	EstadoJuego.restaurar_dia(1)

	leidas.clear()
	respuestas.clear()
	_guardado_bloqueado = false

	_guardar_partida()
	noticias_actualizadas.emit(cuantas_sin_leer())


func _guardar_partida() -> void:
	if _guardado_bloqueado:
		push_warning("Guardado bloqueado: archivo incompatible.")
		return

	var archivo := FileAccess.open(RUTA_PARTIDA, FileAccess.WRITE)

	if archivo == null:
		push_error("No se pudo guardar la partida.")
		return

	var datos: Dictionary = {
		"version": 2,
		"fecha_inicio": EstadoJuego.FECHA_INICIO_PROVISIONAL,
		"dia_de_partida": EstadoJuego.dia_de_partida,
		"leidas": leidas,
		"respuestas": respuestas
	}

	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.close()



func _cargar_partida() -> void:
	if not FileAccess.file_exists(RUTA_PARTIDA):
		if FileAccess.file_exists(RUTA_PARTIDA_ANTIGUA):
			print("Guardado antiguo detectado. Se conserva sin importar.")
		return

	var guardado: Dictionary = _leer_json(RUTA_PARTIDA)

	if int(guardado.get("version", 0)) != 2:
		_guardado_bloqueado = true
		push_warning("Versión de guardado incompatible.")
		return

	if str(guardado.get("fecha_inicio", "")) != EstadoJuego.FECHA_INICIO_PROVISIONAL:
		_guardado_bloqueado = true
		push_warning("El guardado pertenece a otro calendario.")
		return

	var dia_guardado: int = int(guardado.get("dia_de_partida", 0))
	var leidas_guardadas = guardado.get("leidas", {})
	var respuestas_guardadas = guardado.get("respuestas", {})

	if not (leidas_guardadas is Dictionary and respuestas_guardadas is Dictionary):
		_guardado_bloqueado = true
		push_warning("Datos de noticias incompatibles.")
		return

	if not EstadoJuego.restaurar_dia(dia_guardado):
		_guardado_bloqueado = true
		return

	leidas = leidas_guardadas
	respuestas = respuestas_guardadas
