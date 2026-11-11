extends Node

signal noticias_actualizadas(cantidad: int)
signal noticia_entregada(noticia_id: String, ultimo_del_dia: bool)
signal reparto_diario_finalizado
signal decision_resuelta(noticia_id: String, opcion_id: String, efecto: Dictionary)

# Cadencia provisional del prototipo, en segundos de juego activo.
const ESPERA_PRIMERA_ENTREGA_SEGUNDOS: float = 3.0
const INTERVALO_ENTREGAS_SEGUNDOS: float = 8.0

const RUTA_NOTICIAS := "res://datos/noticias/noticias_2008.json"
const RUTA_PREGUNTAS := "res://datos/noticias/preguntas_2008.json"
const RUTA_PARTIDA := "user://eurasia_calendario_noticias_v3.json"
const RUTA_PARTIDA_ANTERIOR := "user://eurasia_calendario_noticias_v2.json"
const RUTA_PARTIDA_ANTIGUA := "user://eurasia_noticias_partida.json"

var noticias: Array[Dictionary] = []
var preguntas: Dictionary = {}
var leidas: Dictionary = {}
var respuestas: Dictionary = {}
var entregadas: Dictionary = {}
var recogidas: Dictionary = {}
var _guardado_bloqueado: bool = false
# Semilla de la partida: decide de forma reproducible qué noticias falsas aparecen.
var semilla: int = 0
var _cola_entregas: Array[String] = []
var _reparto_finalizado: bool = false
var _temporizador_entrega: Timer


func _ready() -> void:
	_cargar_contenido()
	_cargar_partida()
	if semilla == 0:
		_generar_semilla()
		_guardar_partida()
	_crear_temporizador_entrega()
	call_deferred("_iniciar_reparto_diario")
	noticias_actualizadas.emit(cuantas_sin_leer())


func _crear_temporizador_entrega() -> void:
	_temporizador_entrega = Timer.new()
	_temporizador_entrega.one_shot = true
	_temporizador_entrega.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_temporizador_entrega)
	_temporizador_entrega.timeout.connect(_entregar_siguiente_noticia)


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


func _generar_semilla() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	semilla = rng.randi_range(1, 2_000_000_000)


## Las noticias auténticas siempre se programan; las falsas, con la probabilidad configurada en reglas_demo.json.
## El resultado es estable para una misma partida (depende de la semilla y del id).
func _noticia_programada(noticia: Dictionary) -> bool:
	if bool(noticia.get("archivo", false)):
		return false
	if not bool(noticia.get("falsa", false)):
		return true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(semilla) + ":" + str(noticia.get("id", "")))
	return rng.randf() < Reglas.decimal("noticias/probabilidad_noticia_falsa", 0.5)


func obtener_noticia(noticia_id: String) -> Dictionary:
	for noticia in noticias:
		if str(noticia.get("id", "")) == noticia_id:
			return noticia
	return {}


func obtener_noticias_hoy() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for noticia in noticias:
		if str(noticia.get("disponible_desde", "")) == EstadoJuego.fecha_historica_interna and _noticia_programada(noticia):
			resultado.append(noticia)
	resultado.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("prioridad", 0)) > int(b.get("prioridad", 0)))
	if resultado.size() > 5:
		resultado.resize(5)
	return resultado


func obtener_noticias_entregadas_hoy() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for noticia in obtener_noticias_hoy():
		if entregadas.has(str(noticia.get("id", ""))):
			resultado.append(noticia)
	return resultado


func obtener_noticias_recogidas() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for noticia in noticias:
		if recogidas.has(str(noticia.get("id", ""))):
			resultado.append(noticia)
	return resultado


## Hemeroteca: noticias relevantes de los dos años anteriores más todas las recogidas, de la más reciente a la más antigua.
func obtener_hemeroteca() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for noticia in noticias:
		if bool(noticia.get("archivo", false)) or recogidas.has(str(noticia.get("id", ""))):
			resultado.append(noticia)
	resultado.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var fecha_a := str(a.get("disponible_desde", ""))
		var fecha_b := str(b.get("disponible_desde", ""))
		if fecha_a != fecha_b:
			return fecha_a > fecha_b
		return int(a.get("prioridad", 0)) > int(b.get("prioridad", 0)))
	return resultado


## Decisiones del día con su estado: "por_llegar", "sin_recoger", "pendiente" o "respondida".
func decisiones_de_hoy() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for noticia in obtener_noticias_hoy():
		var noticia_id := str(noticia.get("id", ""))
		var pregunta := obtener_pregunta(noticia_id)
		if pregunta.is_empty():
			continue
		var estado := "por_llegar"
		if respuestas.has(noticia_id):
			estado = "respondida"
		elif recogidas.has(noticia_id):
			estado = "pendiente"
		elif entregadas.has(noticia_id):
			estado = "sin_recoger"
		resultado.append({"noticia": noticia, "pregunta": pregunta, "estado": estado})
	return resultado


func cuantas_decisiones_pendientes() -> int:
	var total := 0
	for decision in decisiones_de_hoy():
		if str(decision.get("estado", "")) != "respondida":
			total += 1
	return total


## Noticias de hoy que el jugador ya ha recogido: es la única información que puede enviarse al asistente.
func obtener_noticias_recogidas_hoy() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for noticia in obtener_noticias_hoy():
		if recogidas.has(str(noticia.get("id", ""))):
			resultado.append(noticia)
	return resultado


func obtener_noticias_entregadas_pendientes_de_recoger() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for noticia in noticias:
		var id := str(noticia.get("id", ""))
		if entregadas.has(id) and not recogidas.has(id):
			resultado.append(noticia)
	resultado.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var fecha_a := str(a.get("disponible_desde", ""))
		var fecha_b := str(b.get("disponible_desde", ""))
		if fecha_a != fecha_b:
			return fecha_a < fecha_b
		return int(a.get("prioridad", 0)) > int(b.get("prioridad", 0)))
	return resultado


func obtener_pregunta(noticia_id: String) -> Dictionary:
	for noticia in noticias:
		if str(noticia.get("id", "")) == noticia_id:
			return preguntas.get(str(noticia.get("pregunta_id", "")), {})
	return {}


func cuantas_sin_leer() -> int:
	var total := 0
	for noticia in noticias:
		var id := str(noticia.get("id", ""))
		if entregadas.has(id) and not leidas.has(id):
			total += 1
	return total


func cuantas_por_recoger() -> int:
	return obtener_noticias_entregadas_pendientes_de_recoger().size()


func cuantas_pendientes_de_entrega() -> int:
	return _cola_entregas.size()


func reparto_finalizado() -> bool:
	return _reparto_finalizado


func recoger_siguiente_noticia() -> Dictionary:
	var pendientes := obtener_noticias_entregadas_pendientes_de_recoger()
	if pendientes.is_empty():
		return {}
	var noticia: Dictionary = pendientes[0]
	var noticia_id := str(noticia.get("id", ""))
	recogidas[noticia_id] = true
	_guardar_partida()
	noticias_actualizadas.emit(cuantas_sin_leer())
	return noticia


func puede_analizar_noticias_hoy() -> bool:
	var programadas := obtener_noticias_hoy()
	if programadas.is_empty() or not _reparto_finalizado:
		return false
	for noticia in programadas:
		var noticia_id := str(noticia.get("id", ""))
		if not entregadas.has(noticia_id) or not recogidas.has(noticia_id):
			return false
	return true


func motivo_analisis_no_disponible() -> String:
	var programadas := obtener_noticias_hoy()
	if programadas.is_empty():
		return "Hoy no hay noticias que analizar."
	if not _reparto_finalizado:
		return "Espera a que termine el reparto de noticias."
	for noticia in programadas:
		var noticia_id := str(noticia.get("id", ""))
		if not recogidas.has(noticia_id):
			return "Recoge todos los periódicos del día en el buzón."
	return ""


func marcar_leida(noticia_id: String) -> void:
	for noticia in obtener_noticias_recogidas():
		if str(noticia.get("id", "")) == noticia_id:
			if leidas.has(noticia_id):
				return
			leidas[noticia_id] = true
			_guardar_partida()
			noticias_actualizadas.emit(cuantas_sin_leer())
			return


func responder(noticia_id: String, opcion_id: String) -> Dictionary:
	if EstadoJuego.partida_terminada:
		return {}
	if respuestas.has(noticia_id) or not recogidas.has(noticia_id):
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


func motivo_no_puede_dormir() -> String:
	if EstadoJuego.partida_terminada:
		return "La partida ha terminado. Consulta el informe final."
	if not _reparto_finalizado:
		return "Todavía quedan periódicos programados por llegar."
	for noticia in obtener_noticias_hoy():
		var id := str(noticia.get("id", ""))
		if not obtener_pregunta(id).is_empty() and not respuestas.has(id):
			return "Debes responder las decisiones pendientes antes de dormir (pulsa D para verlas)."
	return ""


func puede_dormir() -> bool:
	return motivo_no_puede_dormir().is_empty()


func avanzar_dia() -> bool:
	if not puede_dormir():
		return false

	# El último día del escenario no se pasa al siguiente: se cierra la partida.
	if GestorPartida.es_ultimo_dia():
		GestorPartida.cerrar_ultimo_dia()
		_guardar_partida()
		return true

	EstadoJuego.avanzar_un_dia()
	# Salario, gastos, comida, salud, patrimonio y condiciones de derrota.
	GestorPartida.procesar_nuevo_dia()
	_iniciar_reparto_diario()
	_guardar_partida()
	return true


func reiniciar_demo() -> void:
	_temporizador_entrega.stop()
	EstadoJuego.restaurar_dia(1)
	leidas.clear()
	respuestas.clear()
	entregadas.clear()
	recogidas.clear()
	_guardado_bloqueado = false
	_generar_semilla()
	_iniciar_reparto_diario()
	_guardar_partida()


func _iniciar_reparto_diario() -> void:
	_temporizador_entrega.stop()
	_cola_entregas.clear()
	var programadas := obtener_noticias_hoy()
	for noticia in programadas:
		var id := str(noticia.get("id", ""))
		if not entregadas.has(id):
			_cola_entregas.append(id)

	_reparto_finalizado = _cola_entregas.is_empty()
	if _reparto_finalizado:
		noticias_actualizadas.emit(cuantas_sin_leer())
		return

	var ya_entregadas := programadas.size() - _cola_entregas.size()
	if ya_entregadas == 0:
		_temporizador_entrega.start(ESPERA_PRIMERA_ENTREGA_SEGUNDOS)
	else:
		_temporizador_entrega.start(INTERVALO_ENTREGAS_SEGUNDOS)
	noticias_actualizadas.emit(cuantas_sin_leer())


func _entregar_siguiente_noticia() -> void:
	if _cola_entregas.is_empty():
		_reparto_finalizado = true
		reparto_diario_finalizado.emit()
		return

	var noticia_id: String = _cola_entregas.pop_front()
	entregadas[noticia_id] = true
	_reparto_finalizado = _cola_entregas.is_empty()
	_guardar_partida()
	noticias_actualizadas.emit(cuantas_sin_leer())
	noticia_entregada.emit(noticia_id, _reparto_finalizado)
	if _reparto_finalizado:
		reparto_diario_finalizado.emit()
	else:
		_temporizador_entrega.start(INTERVALO_ENTREGAS_SEGUNDOS)


func _guardar_partida() -> void:
	if _guardado_bloqueado:
		push_warning("Guardado bloqueado: archivo incompatible.")
		return

	var archivo := FileAccess.open(RUTA_PARTIDA, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo guardar la partida.")
		return

	var datos: Dictionary = {
		"version": 3,
		"fecha_inicio": EstadoJuego.FECHA_INICIO_PROVISIONAL,
		"dia_de_partida": EstadoJuego.dia_de_partida,
		"leidas": leidas,
		"respuestas": respuestas,
		"entregadas": entregadas,
		"recogidas": recogidas,
		"semilla": semilla
	}
	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.close()


func _cargar_partida() -> void:
	var ruta_guardado := RUTA_PARTIDA
	if not FileAccess.file_exists(ruta_guardado):
		ruta_guardado = RUTA_PARTIDA_ANTERIOR
	if not FileAccess.file_exists(ruta_guardado):
		if FileAccess.file_exists(RUTA_PARTIDA_ANTIGUA):
			print("Guardado antiguo detectado. Se conserva sin importar.")
		return

	var guardado: Dictionary = _leer_json(ruta_guardado)
	var version := int(guardado.get("version", 0))
	if (version != 2 and version != 3) or str(guardado.get("fecha_inicio", "")) != EstadoJuego.FECHA_INICIO_PROVISIONAL:
		EstadoJuego.archivar_guardado_incompatible(ruta_guardado, "El guardado de noticias pertenece a otra versión o calendario.")
		return

	var dia_guardado := int(guardado.get("dia_de_partida", 0))
	var leidas_guardadas = guardado.get("leidas", {})
	var respuestas_guardadas = guardado.get("respuestas", {})
	var entregadas_guardadas = guardado.get("entregadas", {})
	var recogidas_guardadas = guardado.get("recogidas", {})
	if not (leidas_guardadas is Dictionary and respuestas_guardadas is Dictionary and entregadas_guardadas is Dictionary and recogidas_guardadas is Dictionary):
		_guardado_bloqueado = true
		push_warning("Datos de noticias incompatibles.")
		return

	if not EstadoJuego.restaurar_dia(dia_guardado):
		_guardado_bloqueado = true
		return

	leidas = leidas_guardadas
	respuestas = respuestas_guardadas
	entregadas = entregadas_guardadas
	recogidas = recogidas_guardadas
	semilla = int(guardado.get("semilla", 0))
	# En partidas v2, las noticias leídas ya habían sido mostradas al jugador.
	if version == 2:
		for id in leidas.keys():
			entregadas[str(id)] = true
			recogidas[str(id)] = true
