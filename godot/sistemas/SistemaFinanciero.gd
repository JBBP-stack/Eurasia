extends Node
## Motor financiero provisional, separado de las interfaces.

signal finanzas_actualizadas

const RUTA_GUARDADO: String = "user://eurasia_finanzas.json"
const VERSION_GUARDADO: int = 1
const ID_ESCENARIO: String = "eurasia_demo_2008_sep"
const MAX_POSICIONES: int = 10
const MAX_MOVIMIENTOS: int = 200
# Las comisiones y la disponibilidad del mercado se leen de datos/reglas_demo.json (provisionales).

var movimientos: Array[Dictionary] = []
var _guardado_bloqueado: bool = false


func _ready() -> void:
	_cargar_estado()


func depositar_efectivo(importe_centimos: int) -> Dictionary:
	if EstadoJuego.partida_terminada:
		return _error("La partida ha terminado.")
	if importe_centimos <= 0:
		return _error("Indica un importe mayor que cero.")
	if importe_centimos > EstadoJuego.efectivo_centimos:
		return _error("No tienes suficiente efectivo para ingresar ese importe.")

	var snapshot := _capturar_estado()
	EstadoJuego.efectivo_centimos -= importe_centimos
	EstadoJuego.saldo_bancario_centimos += importe_centimos
	return _finalizar_operacion(
		snapshot,
		"Ingreso de efectivo",
		"Ingreso en cuenta",
		importe_centimos
	)


func retirar_efectivo(importe_centimos: int) -> Dictionary:
	if EstadoJuego.partida_terminada:
		return _error("La partida ha terminado.")
	if importe_centimos <= 0:
		return _error("Indica un importe mayor que cero.")
	if importe_centimos > EstadoJuego.saldo_bancario_centimos:
		return _error("El saldo bancario no alcanza para retirar ese importe.")

	var snapshot := _capturar_estado()
	EstadoJuego.saldo_bancario_centimos -= importe_centimos
	EstadoJuego.efectivo_centimos += importe_centimos
	return _finalizar_operacion(
		snapshot,
		"Retirada de efectivo",
		"Retirada desde cuenta",
		-importe_centimos
	)


func comprar_acciones(activo_id: String, cantidad: int) -> Dictionary:
	var bloqueo := _motivo_mercado_no_disponible()
	if not bloqueo.is_empty():
		return _error(bloqueo)
	if cantidad <= 0:
		return _error("La cantidad debe ser de al menos una acción.")

	var indice := _buscar_activo(activo_id)
	if indice < 0:
		return _error("Ese activo no está disponible en este prototipo.")

	var activo: Dictionary = EstadoJuego.cartera[indice]
	var precio := int(activo.get("precio_centimos", 0))
	var acciones_actuales := int(activo.get("acciones", 0))
	if precio <= 0:
		return _error("El activo no tiene un precio válido.")
	if acciones_actuales == 0 and _contar_posiciones_activas() >= MAX_POSICIONES:
		return _error("Has alcanzado el máximo de %d posiciones." % MAX_POSICIONES)

	var subtotal := precio * cantidad
	var comision := _calcular_comision(subtotal)
	var coste_total := subtotal + comision
	if coste_total > EstadoJuego.saldo_bancario_centimos:
		return _error("No tienes saldo suficiente para completar la compra.")

	var snapshot := _capturar_estado()
	EstadoJuego.saldo_bancario_centimos -= coste_total
	EstadoJuego.cartera[indice]["acciones"] = acciones_actuales + cantidad
	var nombre := str(activo.get("nombre", activo_id))
	return _finalizar_operacion(
		snapshot,
		"Compra de acciones",
		"Compra de %d acciones de %s (comisión %s €)" % [cantidad, nombre, EstadoJuego.euros(comision)],
		-coste_total
	)


func vender_acciones(activo_id: String, cantidad: int) -> Dictionary:
	var bloqueo := _motivo_mercado_no_disponible()
	if not bloqueo.is_empty():
		return _error(bloqueo)
	if cantidad <= 0:
		return _error("La cantidad debe ser de al menos una acción.")

	var indice := _buscar_activo(activo_id)
	if indice < 0:
		return _error("Ese activo no está disponible en este prototipo.")

	var activo: Dictionary = EstadoJuego.cartera[indice]
	var precio := int(activo.get("precio_centimos", 0))
	var acciones_actuales := int(activo.get("acciones", 0))
	if precio <= 0:
		return _error("El activo no tiene un precio válido.")
	if cantidad > acciones_actuales:
		return _error("No tienes tantas acciones para vender.")

	var subtotal := precio * cantidad
	var comision := _calcular_comision(subtotal)
	var ingreso_neto := subtotal - comision
	if ingreso_neto < 0:
		return _error("Los costes de la operación superan su importe.")

	var snapshot := _capturar_estado()
	EstadoJuego.saldo_bancario_centimos += ingreso_neto
	EstadoJuego.cartera[indice]["acciones"] = acciones_actuales - cantidad
	var nombre := str(activo.get("nombre", activo_id))
	return _finalizar_operacion(
		snapshot,
		"Venta de acciones",
		"Venta de %d acciones de %s (comisión %s €)" % [cantidad, nombre, EstadoJuego.euros(comision)],
		ingreso_neto
	)


func precio_actual_centimos(activo_id: String) -> int:
	var indice := _buscar_activo(activo_id)
	if indice < 0:
		return 0
	return int(EstadoJuego.cartera[indice].get("precio_centimos", 0))


func estimar_comision(importe_centimos: int) -> int:
	return _calcular_comision(importe_centimos)


## Pago voluntario (por ejemplo, comida). Usa primero el efectivo y después la cuenta; no permite descubierto.
func pagar(tipo: String, detalle: String, importe_centimos: int) -> Dictionary:
	if EstadoJuego.partida_terminada:
		return _error("La partida ha terminado.")
	if importe_centimos <= 0:
		return _error("El importe del pago no es válido.")
	if importe_centimos > maxi(0, EstadoJuego.saldo_bancario_centimos) + EstadoJuego.efectivo_centimos:
		return _error("No tienes liquidez suficiente (efectivo + cuenta) para pagar %s €." % EstadoJuego.euros(importe_centimos))

	var snapshot := _capturar_estado()
	var desde_efectivo := mini(EstadoJuego.efectivo_centimos, importe_centimos)
	EstadoJuego.efectivo_centimos -= desde_efectivo
	EstadoJuego.saldo_bancario_centimos -= importe_centimos - desde_efectivo
	return _finalizar_operacion(snapshot, tipo, detalle, -importe_centimos)


## Ingreso o cargo obligatorio (salario, gastos fijos, consecuencias de decisiones).
## Los cargos pueden dejar la cuenta en descubierto: ese es el origen de los impagos y de la bancarrota.
func registrar_movimiento_externo(tipo: String, detalle: String, delta_banco_centimos: int, delta_efectivo_centimos: int = 0) -> Dictionary:
	if delta_banco_centimos == 0 and delta_efectivo_centimos == 0:
		return {"ok": true, "mensaje": detalle}
	var snapshot := _capturar_estado()
	EstadoJuego.saldo_bancario_centimos += delta_banco_centimos
	EstadoJuego.efectivo_centimos = maxi(0, EstadoJuego.efectivo_centimos + delta_efectivo_centimos)
	return _finalizar_operacion(snapshot, tipo, detalle, delta_banco_centimos + delta_efectivo_centimos)


## Gasto obligatorio (alquiler, suministros, gastos personales): se paga primero con efectivo y el resto
## se carga en la cuenta, aunque la deje en descubierto.
func cargar_gasto_obligatorio(tipo: String, detalle: String, importe_centimos: int) -> Dictionary:
	if importe_centimos <= 0:
		return {"ok": true, "mensaje": detalle}
	var desde_efectivo := mini(EstadoJuego.efectivo_centimos, importe_centimos)
	return registrar_movimiento_externo(tipo, detalle, -(importe_centimos - desde_efectivo), -desde_efectivo)


## Borra movimientos y vuelve a los valores iniciales de EstadoJuego (que debe haberse reiniciado antes).
func reiniciar() -> void:
	movimientos.clear()
	_guardado_bloqueado = false
	_guardar_estado()
	finanzas_actualizadas.emit()


func _motivo_mercado_no_disponible() -> String:
	if EstadoJuego.partida_terminada:
		return "La partida ha terminado."
	if not SistemaMercado.mercado_abierto():
		return "La bolsa está cerrada hoy (%s). Podrás operar el próximo día con sesión." % SistemaMercado.motivo_mercado_cerrado()
	return ""


func _buscar_activo(activo_id: String) -> int:
	for indice in range(EstadoJuego.cartera.size()):
		if str(EstadoJuego.cartera[indice].get("id", "")) == activo_id:
			return indice
	return -1


func _contar_posiciones_activas() -> int:
	var activas := 0
	for activo in EstadoJuego.cartera:
		if int(activo.get("acciones", 0)) > 0:
			activas += 1
	return activas


func _calcular_comision(importe_centimos: int) -> int:
	if importe_centimos <= 0:
		return 0
	var puntos_base := Reglas.entero("mercado/comision_puntos_base", 0)
	var minima := Reglas.entero("mercado/comision_minima_centimos", 0)
	var proporcional := int(ceil(float(importe_centimos) * float(puntos_base) / 10_000.0))
	return maxi(minima, proporcional)


func _capturar_estado() -> Dictionary:
	return {
		"saldo_bancario_centimos": EstadoJuego.saldo_bancario_centimos,
		"efectivo_centimos": EstadoJuego.efectivo_centimos,
		"cartera": EstadoJuego.cartera.duplicate(true),
		"movimientos": movimientos.duplicate(true)
	}


func _restaurar_estado(snapshot: Dictionary) -> void:
	EstadoJuego.saldo_bancario_centimos = int(snapshot.get("saldo_bancario_centimos", 0))
	EstadoJuego.efectivo_centimos = int(snapshot.get("efectivo_centimos", 0))
	var cartera_restaurada: Array[Dictionary] = []
	for activo in snapshot.get("cartera", []):
		if activo is Dictionary:
			cartera_restaurada.append(activo)
	EstadoJuego.cartera = cartera_restaurada
	movimientos.clear()
	for movimiento in snapshot.get("movimientos", []):
		if movimiento is Dictionary:
			movimientos.append(movimiento)


func _finalizar_operacion(
	snapshot: Dictionary,
	tipo: String,
	detalle: String,
	importe_centimos: int
) -> Dictionary:
	var movimiento: Dictionary = {
		"dia": EstadoJuego.dia_de_partida,
		"fecha": EstadoJuego.fecha_historica_interna,
		"tipo": tipo,
		"detalle": detalle,
		"importe_centimos": importe_centimos,
		"saldo_bancario_centimos": EstadoJuego.saldo_bancario_centimos,
		"efectivo_centimos": EstadoJuego.efectivo_centimos
	}
	movimientos.push_front(movimiento)
	while movimientos.size() > MAX_MOVIMIENTOS:
		movimientos.pop_back()

	if not _guardar_estado():
		_restaurar_estado(snapshot)
		return _error("No se pudo guardar la operación; no se aplicó ningún cambio.")

	finanzas_actualizadas.emit()
	return {"ok": true, "mensaje": detalle + ". Operación guardada."}


func _guardar_estado() -> bool:
	if _guardado_bloqueado:
		return false

	var datos: Dictionary = {
		"version": VERSION_GUARDADO,
		"escenario": ID_ESCENARIO,
		"saldo_bancario_centimos": EstadoJuego.saldo_bancario_centimos,
		"efectivo_centimos": EstadoJuego.efectivo_centimos,
		"cartera": EstadoJuego.cartera,
		"movimientos": movimientos
	}
	var archivo := FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo abrir el archivo de finanzas para guardar.")
		return false
	archivo.store_string(JSON.stringify(datos, "\t"))
	var error := archivo.get_error()
	archivo.close()
	if error != OK:
		push_error("No se pudo escribir el archivo de finanzas.")
		return false
	return true


func _cargar_estado() -> void:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return

	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_GUARDADO))
	if not datos is Dictionary:
		_bloquear_guardado("El archivo de finanzas no tiene un formato válido.")
		return
	if int(datos.get("version", 0)) != VERSION_GUARDADO or str(datos.get("escenario", "")) != ID_ESCENARIO:
		EstadoJuego.archivar_guardado_incompatible(RUTA_GUARDADO, "El archivo de finanzas pertenece a otra versión o escenario.")
		return

	var saldo := int(datos.get("saldo_bancario_centimos", 0))
	var efectivo := int(datos.get("efectivo_centimos", -1))
	var cartera_guardada: Variant = datos.get("cartera", [])
	var movimientos_guardados: Variant = datos.get("movimientos", [])
	# El saldo bancario puede ser negativo (descubierto por cargos obligatorios); el efectivo no.
	if efectivo < 0 or not cartera_guardada is Array or not movimientos_guardados is Array:
		_bloquear_guardado("El archivo de finanzas contiene datos incompatibles.")
		return
	if cartera_guardada.size() > MAX_POSICIONES or movimientos_guardados.size() > MAX_MOVIMIENTOS:
		_bloquear_guardado("El archivo de finanzas supera los límites del prototipo.")
		return

	var cartera_cargada: Array[Dictionary] = []
	var ids_cargados: Dictionary = {}
	var posiciones_activas := 0
	for activo in cartera_guardada:
		if not activo is Dictionary:
			_bloquear_guardado("La cartera guardada no es válida.")
			return
		var activo_id := str(activo.get("id", ""))
		var acciones := int(activo.get("acciones", -1))
		var precio := int(activo.get("precio_centimos", 0))
		if activo_id.is_empty() or ids_cargados.has(activo_id) or acciones < 0 or precio <= 0:
			_bloquear_guardado("Una posición guardada no es válida.")
			return
		ids_cargados[activo_id] = true
		if acciones > 0:
			posiciones_activas += 1
		cartera_cargada.append(activo.duplicate(true))
	if posiciones_activas > MAX_POSICIONES:
		_bloquear_guardado("La cartera supera el máximo de posiciones.")
		return

	var movimientos_cargados: Array[Dictionary] = []
	for movimiento in movimientos_guardados:
		if not movimiento is Dictionary:
			_bloquear_guardado("El historial de movimientos no es válido.")
			return
		movimientos_cargados.append(movimiento.duplicate(true))

	EstadoJuego.saldo_bancario_centimos = saldo
	EstadoJuego.efectivo_centimos = efectivo
	EstadoJuego.cartera = cartera_cargada
	movimientos = movimientos_cargados


func _bloquear_guardado(mensaje: String) -> void:
	_guardado_bloqueado = true
	push_warning(mensaje + " Se mantienen los valores iniciales y no se sobrescribirá.")


func _error(mensaje: String) -> Dictionary:
	return {"ok": false, "mensaje": mensaje}
