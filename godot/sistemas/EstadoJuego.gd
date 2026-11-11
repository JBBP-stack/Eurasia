extends Node
## Estado general de la partida. Cifras monetarias en céntimos para evitar errores de redondeo.
## Todos los datos salvo el reparto 15.000/15.000 y el total de 30.000 son provisionales.
##
## Reparto de responsabilidades de guardado:
## - Saldo, efectivo, cartera y movimientos: SistemaFinanciero (user://eurasia_finanzas.json).
## - Día, noticias entregadas/recogidas/leídas y respuestas: NoticiasManager.
## - Estado vital, decisiones, historial de patrimonio y fin de partida: este script.

signal dia_cambiado(nuevo_dia: int)
signal estado_vital_actualizado

# Fecha temporal del prototipo. No es la fecha definitiva de la demo.
# Debe coincidir con "calendario/fecha_inicio" de datos/reglas_demo.json (lo usa el servicio del asistente).
const FECHA_INICIO_PROVISIONAL: String = "2008-09-05"
const RUTA_GUARDADO: String = "user://eurasia_estado.json"
const VERSION_GUARDADO: int = 1
const MAX_HISTORIAL: int = 400

# Calendario interno, no visible directamente para el jugador.
var fecha_historica_interna: String = FECHA_INICIO_PROVISIONAL
var dia_de_partida: int = 1
var posicion_retorno_habitacion: Vector2 = Vector2(135.0, 42.0)
var regresar_a_habitacion: bool = false
# Solo de sesión: indica si ya se ha pasado la ficha inicial en esta ejecución.
var partida_iniciada: bool = false

var perfil: Dictionary = {}
var saldo_bancario_centimos: int = 0
var efectivo_centimos: int = 0
var cartera: Array[Dictionary] = []

# Estado vital (persistente).
var comida_disponible: int = 3
var comido_hoy: bool = false
var dias_sin_comer: int = 0
var dias_sin_ir_al_bano: int = 0  # Reservado: el baño queda fuera del alcance de la primera demo.
var salud: int = 100

# Evaluación de decisiones (persistente).
var prudencia: int = 0
var riesgo: int = 0
var registro_decisiones: Array[Dictionary] = []
var historial_patrimonio: Array[Dictionary] = []
var dias_en_descubierto: int = 0
# Patrimonio al empezar la partida (referencia del informe final). 0 = aún no fijado.
var patrimonio_inicial_centimos: int = 0

# Fin de partida (persistente).
var partida_terminada: bool = false
var resultado_final: Dictionary = {}

var _guardado_bloqueado: bool = false


func _ready() -> void:
	_restablecer_valores_iniciales()
	_cargar_estado()
	var fecha_reglas := Reglas.texto("calendario/fecha_inicio", FECHA_INICIO_PROVISIONAL)
	if fecha_reglas != FECHA_INICIO_PROVISIONAL:
		push_warning("calendario/fecha_inicio de reglas_demo.json no coincide con EstadoJuego.FECHA_INICIO_PROVISIONAL.")


func _restablecer_valores_iniciales() -> void:
	perfil = {
		"edad": 30,
		"genero": "Hombre",
		"pais_ficticio": "República de Liria",
		"clase_social": "Clase media",
		"ingreso_mensual_centimos": 200_000
	}
	# Situación inicial (reglas_demo.json): 15.000 € en cuenta, 2.000 € en efectivo y ~13.000 € invertidos.
	saldo_bancario_centimos = Reglas.entero("situacion_inicial/saldo_bancario_centimos", 1_500_000)
	efectivo_centimos = Reglas.entero("situacion_inicial/efectivo_centimos", 200_000)
	# Nombres y precios los completa SistemaMercado según el catálogo y la fecha.
	cartera = []
	for posicion in Reglas.valor("situacion_inicial/cartera", []):
		if posicion is Dictionary:
			cartera.append({
				"id": str(posicion.get("id", "")),
				"nombre": str(posicion.get("id", "")),
				"acciones": int(posicion.get("acciones", 0)),
				"precio_centimos": 0
			})
	comida_disponible = Reglas.entero("alimentacion/comida_inicial", 3)
	comido_hoy = false
	dias_sin_comer = 0
	dias_sin_ir_al_bano = 0
	salud = Reglas.entero("alimentacion/salud_maxima", 100)
	prudencia = 0
	riesgo = 0
	registro_decisiones = []
	historial_patrimonio = []
	dias_en_descubierto = 0
	patrimonio_inicial_centimos = 0
	partida_terminada = false
	resultado_final = {}


## Un guardado de otro calendario o versión se aparta (renombrado) y la partida empieza de cero.
## Así un cambio de escenario no deja el juego sin poder guardar.
func archivar_guardado_incompatible(ruta: String, motivo: String) -> void:
	var destino := ruta + ".incompatible.bak"
	if FileAccess.file_exists(destino):
		DirAccess.remove_absolute(destino)
	var error := DirAccess.rename_absolute(ruta, destino)
	push_warning("%s Se archiva como %s y se empieza una partida nueva." % [motivo, destino.get_file()] if error == OK else motivo)


func valor_cartera_centimos() -> int:
	var total: int = 0
	for posicion in cartera:
		total += int(posicion["acciones"]) * int(posicion["precio_centimos"])
	return total


func patrimonio_total_centimos() -> int:
	return saldo_bancario_centimos + efectivo_centimos + valor_cartera_centimos()


func liquidez_centimos() -> int:
	return saldo_bancario_centimos + efectivo_centimos


func euros(centimos: int) -> String:
	return "%.2f" % (float(centimos) / 100.0)


func etiqueta_dia() -> String:
	return "Día %d" % dia_de_partida


func fecha_de_dia(dia: int) -> String:
	var inicio: int = Time.get_unix_time_from_datetime_string(FECHA_INICIO_PROVISIONAL + "T00:00:00")
	return Time.get_date_string_from_unix_time(inicio + (dia - 1) * 86_400)


## Convierte una fecha interna en número de día de partida (sin revelar la fecha al jugador).
func dia_de_fecha(fecha: String) -> int:
	if fecha.is_empty():
		return 0
	var inicio: int = Time.get_unix_time_from_datetime_string(FECHA_INICIO_PROVISIONAL + "T00:00:00")
	var objetivo: int = Time.get_unix_time_from_datetime_string(fecha + "T00:00:00")
	return int(floor(float(objetivo - inicio) / 86_400.0)) + 1


func avanzar_un_dia() -> void:
	restaurar_dia(dia_de_partida + 1)


func restaurar_dia(nuevo_dia: int) -> bool:
	if nuevo_dia < 1:
		push_warning("El día de partida no puede ser menor que 1.")
		return false

	fecha_historica_interna = fecha_de_dia(nuevo_dia)
	dia_de_partida = nuevo_dia

	dia_cambiado.emit(dia_de_partida)
	return true


## Guarda (o sustituye) la foto del patrimonio del día actual para las gráficas del portátil.
func registrar_patrimonio_del_dia() -> void:
	var entrada: Dictionary = {
		"dia": dia_de_partida,
		"patrimonio_centimos": patrimonio_total_centimos(),
		"banco_centimos": saldo_bancario_centimos,
		"efectivo_centimos": efectivo_centimos,
		"inversiones_centimos": valor_cartera_centimos()
	}
	for indice in range(historial_patrimonio.size()):
		if int(historial_patrimonio[indice].get("dia", 0)) == dia_de_partida:
			historial_patrimonio[indice] = entrada
			return
	historial_patrimonio.append(entrada)
	historial_patrimonio.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("dia", 0)) < int(b.get("dia", 0)))
	while historial_patrimonio.size() > MAX_HISTORIAL:
		historial_patrimonio.pop_front()


func hay_partida_guardada() -> bool:
	return FileAccess.file_exists(RUTA_GUARDADO)


## Restablece el estado vital y de evaluación. El día lo reinicia NoticiasManager y el dinero SistemaFinanciero.
func reiniciar() -> void:
	_guardado_bloqueado = false
	_restablecer_valores_iniciales()
	guardar_estado()
	estado_vital_actualizado.emit()


func guardar_estado() -> bool:
	if _guardado_bloqueado:
		push_warning("Guardado del estado bloqueado: el archivo existente no es compatible.")
		return false
	var datos: Dictionary = {
		"version": VERSION_GUARDADO,
		"fecha_inicio": FECHA_INICIO_PROVISIONAL,
		"comida_disponible": comida_disponible,
		"comido_hoy": comido_hoy,
		"dias_sin_comer": dias_sin_comer,
		"dias_sin_ir_al_bano": dias_sin_ir_al_bano,
		"salud": salud,
		"prudencia": prudencia,
		"riesgo": riesgo,
		"registro_decisiones": registro_decisiones,
		"historial_patrimonio": historial_patrimonio,
		"dias_en_descubierto": dias_en_descubierto,
		"patrimonio_inicial_centimos": patrimonio_inicial_centimos,
		"partida_terminada": partida_terminada,
		"resultado_final": resultado_final
	}
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo abrir el archivo de estado para guardar.")
		return false
	archivo.store_string(JSON.stringify(datos, "\t"))
	var error := archivo.get_error()
	archivo.close()
	return error == OK


func _cargar_estado() -> void:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_GUARDADO))
	if not datos is Dictionary:
		_bloquear_guardado("El archivo de estado no tiene un formato válido.")
		return
	if int(datos.get("version", 0)) != VERSION_GUARDADO or str(datos.get("fecha_inicio", "")) != FECHA_INICIO_PROVISIONAL:
		archivar_guardado_incompatible(RUTA_GUARDADO, "El archivo de estado pertenece a otra versión o calendario.")
		return

	var decisiones: Variant = datos.get("registro_decisiones", [])
	var historial: Variant = datos.get("historial_patrimonio", [])
	var resultado: Variant = datos.get("resultado_final", {})
	if not decisiones is Array or not historial is Array or not resultado is Dictionary:
		_bloquear_guardado("El archivo de estado contiene datos incompatibles.")
		return

	comida_disponible = maxi(0, int(datos.get("comida_disponible", comida_disponible)))
	comido_hoy = bool(datos.get("comido_hoy", false))
	dias_sin_comer = maxi(0, int(datos.get("dias_sin_comer", 0)))
	dias_sin_ir_al_bano = maxi(0, int(datos.get("dias_sin_ir_al_bano", 0)))
	salud = clampi(int(datos.get("salud", salud)), 0, Reglas.entero("alimentacion/salud_maxima", 100))
	prudencia = int(datos.get("prudencia", 0))
	riesgo = int(datos.get("riesgo", 0))
	dias_en_descubierto = maxi(0, int(datos.get("dias_en_descubierto", 0)))
	patrimonio_inicial_centimos = maxi(0, int(datos.get("patrimonio_inicial_centimos", 0)))
	partida_terminada = bool(datos.get("partida_terminada", false))
	resultado_final = resultado

	registro_decisiones = []
	for decision in decisiones:
		if decision is Dictionary:
			registro_decisiones.append(decision)
	historial_patrimonio = []
	for entrada in historial:
		if entrada is Dictionary:
			historial_patrimonio.append(entrada)


func _bloquear_guardado(mensaje: String) -> void:
	_guardado_bloqueado = true
	push_warning(mensaje + " Se mantienen los valores iniciales y no se sobrescribirá.")
