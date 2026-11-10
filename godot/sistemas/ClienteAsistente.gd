extends Node
## Cliente HTTP del asistente de análisis (Claude) a través del servicio intermedio (servidor_asistente/).
## El cliente nunca contiene claves de API. Solo envía:
## - el día de partida y los IDENTIFICADORES de las noticias recogidas hoy (el servidor carga sus textos
##   anonimizados y comprueba que no son de días futuros),
## - un resumen de la situación financiera actual y la pregunta del jugador.
## Las respuestas son orientativas: nunca modifican dinero ni activos.

signal respuesta_recibida(texto: String)
signal error_asistente(mensaje: String)

var historial: Array[Dictionary] = []  # {"rol": "jugador" | "asistente", "texto": String}
var ocupado: bool = false
var _http: HTTPRequest


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	_http.timeout = 180.0
	add_child(_http)
	_http.request_completed.connect(_al_completar)
	EstadoJuego.dia_cambiado.connect(func(_dia: int) -> void: historial.clear())


func enviar(pregunta: String) -> bool:
	if ocupado:
		return false
	if not NoticiasManager.puede_analizar_noticias_hoy():
		error_asistente.emit(NoticiasManager.motivo_analisis_no_disponible())
		return false
	var texto := pregunta.strip_edges()
	var maximo := Reglas.entero("asistente/max_caracteres_pregunta", 600)
	if texto.length() > maximo:
		texto = texto.substr(0, maximo)
	if texto.is_empty():
		error_asistente.emit("Escribe una pregunta para el asistente.")
		return false

	var ids: Array[String] = []
	for noticia in NoticiasManager.obtener_noticias_recogidas_hoy():
		ids.append(str(noticia.get("id", "")))

	var turnos := Reglas.entero("asistente/max_turnos_historial", 6) * 2
	var historial_enviado: Array[Dictionary] = historial.slice(maxi(0, historial.size() - turnos))
	var cuerpo: Dictionary = {
		"dia": EstadoJuego.dia_de_partida,
		"noticias": ids,
		"pregunta": texto,
		"historial": historial_enviado,
		"contexto_financiero": _contexto_financiero()
	}
	var url := Reglas.texto("asistente/url_servicio", "http://127.0.0.1:8787/analizar")
	var error := _http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(cuerpo))
	if error != OK:
		error_asistente.emit("No se pudo iniciar la conexión con el servicio del asistente (código %d)." % error)
		return false
	ocupado = true
	historial.append({"rol": "jugador", "texto": texto})
	return true


func _contexto_financiero() -> Dictionary:
	var posiciones: Array[Dictionary] = []
	for posicion in EstadoJuego.cartera:
		var acciones := int(posicion.get("acciones", 0))
		if acciones <= 0:
			continue
		var activo := SistemaMercado.info_activo(str(posicion.get("id", "")))
		posiciones.append({
			"nombre": str(posicion.get("nombre", "")),
			"sector": str(activo.get("sector", "")),
			"valor_euros": float(acciones * int(posicion.get("precio_centimos", 0))) / 100.0
		})
	var gastos_fijos := 0
	for gasto in Reglas.valor("economia_domestica/gastos_fijos_mensuales", []):
		if gasto is Dictionary:
			gastos_fijos += int(gasto.get("importe_centimos", 0))
	return {
		"saldo_bancario_euros": float(EstadoJuego.saldo_bancario_centimos) / 100.0,
		"efectivo_euros": float(EstadoJuego.efectivo_centimos) / 100.0,
		"patrimonio_euros": float(EstadoJuego.patrimonio_total_centimos()) / 100.0,
		"ingreso_mensual_euros": float(int(EstadoJuego.perfil.get("ingreso_mensual_centimos", 0))) / 100.0,
		"gastos_fijos_mensuales_euros": float(gastos_fijos) / 100.0,
		"posiciones": posiciones
	}


func _al_completar(resultado: int, codigo: int, _cabeceras: PackedStringArray, cuerpo: PackedByteArray) -> void:
	ocupado = false
	if resultado != HTTPRequest.RESULT_SUCCESS:
		_deshacer_ultimo_turno()
		error_asistente.emit("No se pudo contactar con el servicio del asistente. ¿Está arrancado servidor_asistente/servidor.py?")
		return
	var datos: Variant = JSON.parse_string(cuerpo.get_string_from_utf8())
	if codigo != 200 or not datos is Dictionary:
		_deshacer_ultimo_turno()
		var detalle := str(datos.get("error", "")) if datos is Dictionary else ""
		error_asistente.emit("El servicio del asistente respondió con un error (%d). %s" % [codigo, detalle])
		return
	var respuesta := str(datos.get("respuesta", "")).strip_edges()
	if respuesta.is_empty():
		_deshacer_ultimo_turno()
		error_asistente.emit("El asistente no devolvió ninguna respuesta.")
		return
	historial.append({"rol": "asistente", "texto": respuesta})
	respuesta_recibida.emit(respuesta)


func _deshacer_ultimo_turno() -> void:
	if not historial.is_empty() and str(historial[-1].get("rol", "")) == "jugador":
		historial.pop_back()
