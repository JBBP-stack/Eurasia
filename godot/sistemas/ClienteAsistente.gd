extends Node
## Autoload "Asistente": cliente HTTP del asistente de análisis (Claude) a través del servicio intermedio
## (servidor_asistente/servidor.py). El juego nunca contiene claves de API. Solo envía:
## - el día de partida y los IDENTIFICADORES de las noticias recogidas hoy (el servidor carga sus textos
##   anonimizados y comprueba que no son de otros días),
## - un resumen de la situación financiera actual y la pregunta del jugador.
## Si el servicio no está en marcha y se ejecuta desde el proyecto, lo arranca automáticamente.
## Las respuestas son orientativas: nunca modifican dinero ni activos.

signal respuesta_recibida(texto: String)
signal error_asistente(mensaje: String)
signal estado_cambiado(texto: String)

const INTENTOS_ARRANQUE: int = 20

var historial: Array[Dictionary] = []  # {"rol": "jugador" | "asistente", "texto": String}
var ocupado: bool = false
var _http: HTTPRequest
var _http_salud: HTTPRequest
var _pid_servidor: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	_http.timeout = 180.0
	add_child(_http)
	_http.request_completed.connect(_al_completar)
	_http_salud = HTTPRequest.new()
	_http_salud.timeout = 2.0
	add_child(_http_salud)
	EstadoJuego.dia_cambiado.connect(func(_dia: int) -> void: historial.clear())


func _exit_tree() -> void:
	_detener_servidor()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_detener_servidor()


func _detener_servidor() -> void:
	if _pid_servidor > 0:
		OS.kill(_pid_servidor)
		_pid_servidor = -1


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
	ocupado = true
	historial.append({"rol": "jugador", "texto": texto})
	_enviar_cuando_listo(texto)
	return true


func _url_base() -> String:
	var url := Reglas.texto("asistente/url_servicio", "http://127.0.0.1:8787/analizar")
	return url.substr(0, url.rfind("/"))


func _servicio_responde() -> bool:
	if _http_salud.request(_url_base() + "/salud") != OK:
		return false
	var resultado: Array = await _http_salud.request_completed
	return int(resultado[0]) == HTTPRequest.RESULT_SUCCESS and int(resultado[1]) == 200


func _enviar_cuando_listo(texto: String) -> void:
	if not await _servicio_responde():
		if not bool(Reglas.valor("asistente/arrancar_servidor_automaticamente", true)):
			_fallar("El servicio del asistente no está en marcha. Arráncalo con: python servidor_asistente/servidor.py")
			return
		var error_arranque := _arrancar_servidor()
		if not error_arranque.is_empty():
			_fallar(error_arranque)
			return
		estado_cambiado.emit("Arrancando el servicio del asistente…")
		var listo := false
		for intento in range(INTENTOS_ARRANQUE):
			await get_tree().create_timer(0.5, true).timeout
			if await _servicio_responde():
				listo = true
				break
		if not listo:
			_detener_servidor()
			_fallar("El servicio del asistente no llegó a arrancar. Comprueba que las dependencias están instaladas: pip install -r requirements.txt (en el .venv del proyecto).")
			return
	estado_cambiado.emit("El asistente está pensando…")
	_enviar_peticion(texto)


## Arranca servidor_asistente/servidor.py con el Python del .venv del proyecto (o el del sistema).
## Devuelve un mensaje de error o "" si se lanzó.
func _arrancar_servidor() -> String:
	if _pid_servidor > 0:
		return ""
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var script := raiz.path_join("servidor_asistente/servidor.py")
	if not FileAccess.file_exists(script):
		return "No se encontró servidor_asistente/servidor.py. Arranca el servicio manualmente."
	var candidatos: Array[String] = [
		raiz.path_join(".venv/bin/python3"),
		raiz.path_join(".venv/bin/python"),
		raiz.path_join(".venv/Scripts/python.exe"),
		"/usr/local/bin/python3",
		"/opt/homebrew/bin/python3",
		"/usr/bin/python3",
		"python3",
		"python"
	]
	for python in candidatos:
		if python.is_absolute_path() and not FileAccess.file_exists(python):
			continue
		var pid := OS.create_process(python, [script])
		if pid > 0:
			_pid_servidor = pid
			return ""
	return "No se encontró Python para arrancar el servicio del asistente. Crea el entorno con: python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"


func _enviar_peticion(texto: String) -> void:
	var ids: Array[String] = []
	for noticia in NoticiasManager.obtener_noticias_recogidas_hoy():
		ids.append(str(noticia.get("id", "")))

	var turnos := Reglas.entero("asistente/max_turnos_historial", 6) * 2
	# El último turno es la pregunta actual: se envía aparte.
	var previos: Array[Dictionary] = historial.slice(0, historial.size() - 1)
	var historial_enviado: Array[Dictionary] = previos.slice(maxi(0, previos.size() - turnos))
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
		_fallar("No se pudo iniciar la conexión con el servicio del asistente (código %d)." % error)


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
	if resultado != HTTPRequest.RESULT_SUCCESS:
		_fallar("Se perdió la conexión con el servicio del asistente (resultado %d)." % resultado)
		return
	var datos: Variant = JSON.parse_string(cuerpo.get_string_from_utf8())
	if codigo != 200 or not datos is Dictionary:
		var detalle := str(datos.get("error", "")) if datos is Dictionary else ""
		_fallar(detalle if not detalle.is_empty() else "El servicio del asistente respondió con un error (%d)." % codigo)
		return
	var respuesta := str(datos.get("respuesta", "")).strip_edges()
	if respuesta.is_empty():
		_fallar("El asistente no devolvió ninguna respuesta.")
		return
	ocupado = false
	historial.append({"rol": "asistente", "texto": respuesta})
	respuesta_recibida.emit(respuesta)


func _fallar(mensaje: String) -> void:
	ocupado = false
	if not historial.is_empty() and str(historial[-1].get("rol", "")) == "jugador":
		historial.pop_back()
	error_asistente.emit(mensaje)
