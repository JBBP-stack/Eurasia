extends Node
## Coordinador de la partida:
## - Pausa compartida entre ventanas (evita que cerrar una reanude el juego con otra abierta).
## - Proceso de cada nuevo día: comida y salud, nómina y gastos fijos, descubierto, patrimonio, derrota.
## - Aplicación y registro de las consecuencias de las decisiones.
## - Informe final (explicación básica y técnica) y reinicio completo de la partida.
## Todas las variaciones económicas salen de reglas programadas (datos JSON), nunca de la IA.

signal resumen_dia(eventos: Array[String])
signal partida_finalizada(resultado: Dictionary)
## Resumen legible de lo que ha provocado una decisión (ventas, compras, dinero, salud).
signal consecuencia_aplicada(noticia_id: String, texto: String)

var ultima_consecuencia: String = ""

const ESCENA_INICIAL: String = "res://escenas/habitacion/habitacion1.tscn"
const PATRIMONIO_INICIAL_CENTIMOS: int = 3_000_000
const SECTORES_FINANCIEROS: Array[String] = ["Banca", "Banca de inversión", "Financiación hipotecaria", "Seguros"]

var _ventanas_abiertas: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	NoticiasManager.decision_resuelta.connect(_aplicar_decision)
	_fijar_patrimonio_inicial()
	if EstadoJuego.historial_patrimonio.is_empty():
		EstadoJuego.registrar_patrimonio_del_dia()


func _fijar_patrimonio_inicial() -> void:
	if EstadoJuego.patrimonio_inicial_centimos > 0:
		return
	# En una partida ya empezada sin este dato (guardados anteriores) se usa el valor de diseño.
	if EstadoJuego.dia_de_partida == 1 and SistemaFinanciero.movimientos.is_empty():
		EstadoJuego.patrimonio_inicial_centimos = EstadoJuego.patrimonio_total_centimos()
	else:
		EstadoJuego.patrimonio_inicial_centimos = PATRIMONIO_INICIAL_CENTIMOS


# --- Pausa compartida ---------------------------------------------------------

func abrir_ventana(identificador: String) -> void:
	_ventanas_abiertas[identificador] = true
	get_tree().paused = true


func cerrar_ventana(identificador: String) -> void:
	_ventanas_abiertas.erase(identificador)
	get_tree().paused = not _ventanas_abiertas.is_empty()


func hay_ventanas_abiertas() -> bool:
	return not _ventanas_abiertas.is_empty()


# --- Avance del día -----------------------------------------------------------

## Lo llama NoticiasManager.avanzar_dia() justo después de cambiar la fecha.
func procesar_nuevo_dia() -> void:
	var eventos: Array[String] = []
	eventos.append_array(SistemaVida.procesar_fin_de_dia())
	eventos.append_array(_procesar_economia_domestica())
	eventos.append_array(_procesar_descubierto())
	EstadoJuego.registrar_patrimonio_del_dia()
	_comprobar_fin_de_partida()
	EstadoJuego.guardar_estado()
	resumen_dia.emit(eventos)


func _procesar_economia_domestica() -> Array[String]:
	var eventos: Array[String] = []
	var fecha := EstadoJuego.fecha_historica_interna
	var dia_del_mes := int(fecha.substr(8, 2))

	if dia_del_mes == Reglas.entero("economia_domestica/dia_del_mes_cobro", 28):
		var nomina := int(EstadoJuego.perfil.get("ingreso_mensual_centimos", 0))
		if nomina > 0:
			SistemaFinanciero.registrar_movimiento_externo("Nómina", "Ingreso mensual de la nómina", nomina)
			eventos.append("Has cobrado tu nómina: +%s €." % EstadoJuego.euros(nomina))

	for gasto in gastos_del_dia(fecha):
		var importe := int(gasto.get("importe_centimos", 0))
		SistemaFinanciero.cargar_gasto_obligatorio("Gasto fijo", str(gasto.get("concepto", "Gasto")), importe)
		eventos.append("Pagado: %s (−%s €)." % [str(gasto.get("concepto", "Gasto")), EstadoJuego.euros(importe)])
	return eventos


## Gastos obligatorios que vencen en una fecha: mensuales por día del mes y semanales por día de la semana (1 = lunes).
func gastos_del_dia(fecha: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var dia_del_mes := int(fecha.substr(8, 2))
	for gasto in Reglas.valor("economia_domestica/gastos_fijos_mensuales", []):
		if gasto is Dictionary and int(gasto.get("dia_del_mes", 1)) == dia_del_mes and int(gasto.get("importe_centimos", 0)) > 0:
			resultado.append(gasto)
	var dia_semana := int(Time.get_datetime_dict_from_datetime_string(fecha + "T00:00:00", true).get("weekday", 0))
	for gasto in Reglas.valor("economia_domestica/gastos_semanales", []):
		if gasto is Dictionary and int(gasto.get("dia_semana", 1)) == dia_semana and int(gasto.get("importe_centimos", 0)) > 0:
			resultado.append(gasto)
	return resultado


## Próximos gastos obligatorios (para el portátil): [{"dias": int, "concepto": String, "importe_centimos": int}].
func proximos_gastos(dias_vista: int = 14) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for dias in range(1, dias_vista + 1):
		var fecha := EstadoJuego.fecha_de_dia(EstadoJuego.dia_de_partida + dias)
		for gasto in gastos_del_dia(fecha):
			resultado.append({"dias": dias, "concepto": str(gasto.get("concepto", "")), "importe_centimos": int(gasto.get("importe_centimos", 0))})
	return resultado


func es_ultimo_dia() -> bool:
	var fecha_fin := Reglas.texto("calendario/fecha_fin_escenario", "")
	return not fecha_fin.is_empty() and EstadoJuego.fecha_historica_interna >= fecha_fin


func dias_restantes() -> int:
	var fecha_fin := Reglas.texto("calendario/fecha_fin_escenario", "")
	if fecha_fin.is_empty():
		return -1
	return maxi(0, EstadoJuego.dia_de_fecha(fecha_fin) - EstadoJuego.dia_de_partida)


## Al dormir el último día: se cierra el día (comida y salud) y termina el escenario si no hubo derrota.
func cerrar_ultimo_dia() -> void:
	var eventos: Array[String] = []
	eventos.append_array(SistemaVida.procesar_fin_de_dia())
	EstadoJuego.registrar_patrimonio_del_dia()
	_comprobar_fin_de_partida()
	if not EstadoJuego.partida_terminada:
		terminar_partida("fin_escenario")
	EstadoJuego.guardar_estado()
	resumen_dia.emit(eventos)


func _procesar_descubierto() -> Array[String]:
	var eventos: Array[String] = []
	if EstadoJuego.saldo_bancario_centimos < 0:
		EstadoJuego.dias_en_descubierto += 1
		var gracia := Reglas.entero("bancarrota/dias_gracia_descubierto", 3)
		eventos.append("Tu cuenta está en descubierto (%s €). Días de impago: %d de %d permitidos. Ingresa efectivo o vende inversiones." % [
			EstadoJuego.euros(EstadoJuego.saldo_bancario_centimos), EstadoJuego.dias_en_descubierto, gracia
		])
	else:
		EstadoJuego.dias_en_descubierto = 0
	return eventos


func _comprobar_fin_de_partida() -> void:
	if EstadoJuego.partida_terminada:
		return
	if EstadoJuego.salud <= 0:
		terminar_partida("fallecimiento")
		return
	if EstadoJuego.patrimonio_total_centimos() <= 0:
		terminar_partida("bancarrota_patrimonio")
		return
	if EstadoJuego.saldo_bancario_centimos < -Reglas.entero("bancarrota/limite_descubierto_centimos", 300_000):
		terminar_partida("bancarrota_limite")
		return
	if EstadoJuego.saldo_bancario_centimos < 0 and EstadoJuego.dias_en_descubierto > Reglas.entero("bancarrota/dias_gracia_descubierto", 3):
		terminar_partida("bancarrota_impago")
		return


# --- Decisiones ---------------------------------------------------------------

func _aplicar_decision(noticia_id: String, opcion_id: String, efecto: Dictionary) -> void:
	var noticia := NoticiasManager.obtener_noticia(noticia_id)
	var pregunta := NoticiasManager.obtener_pregunta(noticia_id)
	var opcion: Dictionary = {}
	for candidata in pregunta.get("opciones", []):
		if str(candidata.get("id", "")) == opcion_id:
			opcion = candidata

	EstadoJuego.prudencia += int(efecto.get("prudencia", 0))
	EstadoJuego.riesgo += int(efecto.get("riesgo", 0))
	var consecuencias := _aplicar_efectos_directos(efecto, str(opcion.get("texto", opcion_id)))
	ultima_consecuencia = " ".join(consecuencias) if not consecuencias.is_empty() else "Sin cambios inmediatos en tu dinero."

	EstadoJuego.registro_decisiones.append({
		"dia": EstadoJuego.dia_de_partida,
		"noticia_id": noticia_id,
		"titulo": str(noticia.get("titulo", "")),
		"enunciado": str(pregunta.get("enunciado", "")),
		"opcion_id": opcion_id,
		"texto": str(opcion.get("texto", "")),
		"adecuada": bool(opcion.get("adecuada", false)),
		"explicacion": str(opcion.get("explicacion", "")),
		"efecto": efecto
	})
	EstadoJuego.registrar_patrimonio_del_dia()
	_comprobar_fin_de_partida()
	EstadoJuego.guardar_estado()
	EstadoJuego.estado_vital_actualizado.emit()
	consecuencia_aplicada.emit(noticia_id, ultima_consecuencia)


## Ejecuta las consecuencias inmediatas de una decisión y devuelve frases que las describen.
func _aplicar_efectos_directos(efecto: Dictionary, texto_opcion: String) -> Array[String]:
	var frases: Array[String] = []
	var detalle := "Decisión: " + texto_opcion

	# Ventas (porcentaje de las acciones que se tienen) y venta total.
	var ventas: Dictionary = {}
	if bool(efecto.get("vender_todo", false)):
		for posicion in EstadoJuego.cartera:
			ventas[str(posicion.get("id", ""))] = 100
	var ventas_definidas: Variant = efecto.get("vender", {})
	if ventas_definidas is Dictionary:
		for activo_id in ventas_definidas:
			ventas[str(activo_id)] = int(ventas_definidas[activo_id])
	for activo_id in ventas:
		var tenidas := 0
		for posicion in EstadoJuego.cartera:
			if str(posicion.get("id", "")) == activo_id:
				tenidas = int(posicion.get("acciones", 0))
		var cantidad := int(floor(float(tenidas) * float(ventas[activo_id]) / 100.0))
		if cantidad <= 0:
			continue
		var resultado := SistemaFinanciero.vender_acciones(activo_id, cantidad)
		frases.append(str(resultado.get("mensaje", "")))

	# Compras por importe.
	var compras: Variant = efecto.get("comprar", {})
	if compras is Dictionary:
		for activo_id in compras:
			var precio := SistemaMercado.precio_actual_centimos(str(activo_id))
			var cantidad := int(floor(float(int(compras[activo_id])) / float(maxi(1, precio))))
			if cantidad <= 0:
				continue
			var resultado := SistemaFinanciero.comprar_acciones(str(activo_id), cantidad)
			frases.append(str(resultado.get("mensaje", "")))

	# Dinero: los pagos en efectivo que no se pueden cubrir salen de la cuenta.
	var delta_banco := int(efecto.get("saldo_bancario_centimos", 0))
	var delta_efectivo := int(efecto.get("efectivo_centimos", 0))
	if delta_efectivo < 0 and delta_banco == 0:
		SistemaFinanciero.cargar_gasto_obligatorio("Consecuencia de decisión", detalle, -delta_efectivo)
		frases.append("Pagas %s €." % EstadoJuego.euros(-delta_efectivo))
	elif delta_banco != 0 or delta_efectivo != 0:
		SistemaFinanciero.registrar_movimiento_externo("Consecuencia de decisión", detalle, delta_banco, delta_efectivo)
		if delta_banco != 0:
			frases.append("Tu cuenta %s %s €." % ["recibe" if delta_banco > 0 else "pierde", EstadoJuego.euros(absi(delta_banco))])
		if delta_efectivo != 0:
			frases.append("Tu efectivo %s %s €." % ["aumenta" if delta_efectivo > 0 else "disminuye", EstadoJuego.euros(absi(delta_efectivo))])

	if efecto.has("comida"):
		EstadoJuego.comida_disponible = maxi(0, EstadoJuego.comida_disponible + int(efecto["comida"]))
		frases.append("Comida %+d raciones." % int(efecto["comida"]))
	if efecto.has("salud"):
		EstadoJuego.salud = clampi(EstadoJuego.salud + int(efecto["salud"]), 0, Reglas.entero("alimentacion/salud_maxima", 100))
		frases.append("Salud %+d (ahora %d)." % [int(efecto["salud"]), EstadoJuego.salud])
	return frases


# --- Fin de partida e informe -------------------------------------------------

func terminar_partida(tipo: String) -> void:
	EstadoJuego.partida_terminada = true
	EstadoJuego.resultado_final = generar_informe(tipo)
	EstadoJuego.guardar_estado()
	partida_finalizada.emit(EstadoJuego.resultado_final)


func generar_informe(tipo: String) -> Dictionary:
	var metricas := _calcular_metricas()
	var titulo := ""
	var basica := ""
	match tipo:
		"fallecimiento":
			titulo = "Tu personaje ha muerto"
			basica = "Tu personaje pasó %d días seguidos sin comer y su salud llegó a cero. Gestionar el dinero también significa cubrir primero las necesidades básicas: la comida va antes que cualquier inversión." % EstadoJuego.dias_sin_comer
		"bancarrota_patrimonio":
			titulo = "Bancarrota"
			basica = "Tus deudas y pérdidas superaron todo lo que tenías. Tu patrimonio total quedó en %s €, así que ya no podías responder de tus obligaciones." % EstadoJuego.euros(EstadoJuego.patrimonio_total_centimos())
		"bancarrota_limite":
			titulo = "Bancarrota"
			basica = "Tu cuenta superó el límite de descubierto que permite el banco. Aunque tuvieras otros bienes, no los convertiste en dinero a tiempo para pagar lo que debías."
		"bancarrota_impago":
			titulo = "Bancarrota por impago"
			basica = "Tu cuenta estuvo en negativo más días de los permitidos. Tener patrimonio no basta: si no es líquido cuando llegan los pagos, no puedes cumplir tus compromisos."
		_:
			titulo = "Fin del escenario"
			basica = "Has llegado al final del periodo histórico de la demo. Tu patrimonio pasó de %s € a %s € (%s)." % [
				EstadoJuego.euros(int(metricas["patrimonio_inicial"])),
				EstadoJuego.euros(int(metricas["patrimonio_final"])),
				_porcentaje(float(metricas["variacion_patrimonio"]))
			]

	return {
		"tipo": tipo,
		"titulo": titulo,
		"dia": EstadoJuego.dia_de_partida,
		"explicacion_basica": basica,
		"explicacion_tecnica": _explicacion_tecnica(metricas),
		"errores": _detectar_errores(metricas),
		"metricas": metricas
	}


func _calcular_metricas() -> Dictionary:
	var inicial := EstadoJuego.patrimonio_inicial_centimos
	if inicial <= 0:
		inicial = PATRIMONIO_INICIAL_CENTIMOS
	var patrimonio_actual := EstadoJuego.patrimonio_total_centimos()

	var maximo := 0
	var caida_maxima := 0.0
	for entrada in EstadoJuego.historial_patrimonio:
		var valor := int(entrada.get("patrimonio_centimos", 0))
		maximo = maxi(maximo, valor)
		if maximo > 0:
			caida_maxima = maxf(caida_maxima, float(maximo - valor) / float(maximo))

	var valor_cartera := EstadoJuego.valor_cartera_centimos()
	var mayor_posicion := 0
	var nombre_mayor := ""
	var posiciones := 0
	var peso_banca := 0
	for posicion in EstadoJuego.cartera:
		var valor := int(posicion.get("acciones", 0)) * int(posicion.get("precio_centimos", 0))
		if int(posicion.get("acciones", 0)) > 0:
			posiciones += 1
		if valor > mayor_posicion:
			mayor_posicion = valor
			nombre_mayor = str(posicion.get("nombre", ""))
		if str(SistemaMercado.info_activo(str(posicion.get("id", ""))).get("sector", "")) in SECTORES_FINANCIEROS:
			peso_banca += valor

	var ingresos := 0
	var gastos := 0
	var operaciones := 0
	for movimiento in SistemaFinanciero.movimientos:
		var tipo := str(movimiento.get("tipo", ""))
		var importe := int(movimiento.get("importe_centimos", 0))
		if tipo == "Nómina":
			ingresos += importe
		elif tipo in ["Gasto fijo", "Compra de comida", "Consecuencia de decisión"] and importe < 0:
			gastos += -importe
		elif tipo in ["Compra de acciones", "Venta de acciones"]:
			operaciones += 1

	var adecuadas := 0
	for decision in EstadoJuego.registro_decisiones:
		if bool(decision.get("adecuada", false)):
			adecuadas += 1

	var gastos_fijos_mes := 0
	for gasto in Reglas.valor("economia_domestica/gastos_fijos_mensuales", []):
		if gasto is Dictionary:
			gastos_fijos_mes += int(gasto.get("importe_centimos", 0))

	return {
		"patrimonio_inicial": inicial,
		"patrimonio_final": patrimonio_actual,
		"variacion_patrimonio": (float(patrimonio_actual - inicial) / float(inicial)) if inicial != 0 else 0.0,
		"caida_maxima": caida_maxima,
		"liquidez": EstadoJuego.liquidez_centimos(),
		"peso_liquidez": (float(EstadoJuego.liquidez_centimos()) / float(patrimonio_actual)) if patrimonio_actual > 0 else 0.0,
		"valor_cartera": valor_cartera,
		"posiciones": posiciones,
		"mayor_posicion": nombre_mayor,
		"peso_mayor_posicion": (float(mayor_posicion) / float(patrimonio_actual)) if patrimonio_actual > 0 else 0.0,
		"peso_banca": (float(peso_banca) / float(patrimonio_actual)) if patrimonio_actual > 0 else 0.0,
		"ingresos": ingresos,
		"gastos": gastos,
		"operaciones": operaciones,
		"decisiones_total": EstadoJuego.registro_decisiones.size(),
		"decisiones_adecuadas": adecuadas,
		"prudencia": EstadoJuego.prudencia,
		"riesgo": EstadoJuego.riesgo,
		"dias_en_descubierto": EstadoJuego.dias_en_descubierto,
		"salud": EstadoJuego.salud,
		"gastos_fijos_mes": gastos_fijos_mes
	}


func _explicacion_tecnica(m: Dictionary) -> String:
	var lineas: Array[String] = []
	lineas.append("Patrimonio: %s € → %s € (%s). Caída máxima desde un pico: %s." % [
		EstadoJuego.euros(int(m["patrimonio_inicial"])), EstadoJuego.euros(int(m["patrimonio_final"])),
		_porcentaje(float(m["variacion_patrimonio"])), _porcentaje(-float(m["caida_maxima"]))
	])
	lineas.append("Liquidez (cuenta + efectivo): %s € (%s del patrimonio). Gastos fijos mensuales: %s €." % [
		EstadoJuego.euros(int(m["liquidez"])), _porcentaje(float(m["peso_liquidez"]), false),
		EstadoJuego.euros(int(m["gastos_fijos_mes"]))
	])
	lineas.append("Inversiones: %s € en %d posiciones. Mayor posición: %s (%s del patrimonio). Exposición al sector financiero: %s." % [
		EstadoJuego.euros(int(m["valor_cartera"])), int(m["posiciones"]), str(m["mayor_posicion"]),
		_porcentaje(float(m["peso_mayor_posicion"]), false), _porcentaje(float(m["peso_banca"]), false)
	])
	lineas.append("Ingresos registrados: %s €. Gastos registrados: %s €. Operaciones de compraventa: %d." % [
		EstadoJuego.euros(int(m["ingresos"])), EstadoJuego.euros(int(m["gastos"])), int(m["operaciones"])
	])
	lineas.append("Decisiones adecuadas: %d de %d. Índice de prudencia: %d. Riesgo asumido en decisiones: %d." % [
		int(m["decisiones_adecuadas"]), int(m["decisiones_total"]), int(m["prudencia"]), int(m["riesgo"])
	])
	lineas.append("Días en descubierto al final: %d. Salud final: %d." % [int(m["dias_en_descubierto"]), int(m["salud"])])
	lineas.append("Nota: precios ilustrativos pendientes de verificar; reglas económicas provisionales.")
	return "\n\n".join(lineas)


func _detectar_errores(m: Dictionary) -> Array[String]:
	var errores: Array[String] = []
	for decision in EstadoJuego.registro_decisiones:
		if not bool(decision.get("adecuada", false)):
			errores.append("Día %d — %s → elegiste «%s». %s" % [
				int(decision.get("dia", 0)), str(decision.get("enunciado", "")),
				str(decision.get("texto", "")), str(decision.get("explicacion", ""))
			])
	if float(m["peso_mayor_posicion"]) > 0.4:
		errores.append("Concentración: %s pesaba el %s de tu patrimonio. Una sola empresa no debería decidir tu futuro." % [
			str(m["mayor_posicion"]), _porcentaje(float(m["peso_mayor_posicion"]), false)
		])
	if float(m["peso_banca"]) > 0.3:
		errores.append("Exposición sectorial: mantenías el %s del patrimonio en empresas financieras durante una crisis financiera." % _porcentaje(float(m["peso_banca"]), false))
	if int(m["liquidez"]) < 3 * int(m["gastos_fijos_mes"]):
		errores.append("Fondo de emergencia insuficiente: tu liquidez no cubría tres meses de gastos fijos.")
	if int(m["dias_en_descubierto"]) > 0:
		errores.append("Terminaste con la cuenta en descubierto: los pagos obligatorios necesitan dinero disponible.")
	if EstadoJuego.dias_sin_comer > 0:
		errores.append("Pasaste %d día(s) sin comer: las necesidades básicas van antes que las inversiones." % EstadoJuego.dias_sin_comer)
	for posicion in EstadoJuego.cartera:
		var acciones := int(posicion.get("acciones", 0))
		var activo_id := str(posicion.get("id", ""))
		var precio_inicio := SistemaMercado.precio_en(activo_id, EstadoJuego.FECHA_INICIO_PROVISIONAL)
		var precio_actual := int(posicion.get("precio_centimos", 0))
		if acciones > 0 and precio_inicio > 0 and precio_actual < precio_inicio / 2:
			errores.append("Mantuviste %d acciones de %s hasta el final: su cotización cayó un %s durante la partida." % [
				acciones, str(posicion.get("nombre", activo_id)), _porcentaje(1.0 - float(precio_actual) / float(precio_inicio), false)
			])
	errores.append_array(_errores_por_rumores())
	if errores.is_empty():
		errores.append("No se detectaron errores relevantes según las reglas de la demo.")
	return errores


## Detecta compras realizadas el mismo día en que el jugador recogió una noticia falsa.
func _errores_por_rumores() -> Array[String]:
	var errores: Array[String] = []
	for noticia in NoticiasManager.noticias:
		var noticia_id := str(noticia.get("id", ""))
		if not bool(noticia.get("falsa", false)) or not NoticiasManager.recogidas.has(noticia_id):
			continue
		var dia := EstadoJuego.dia_de_fecha(str(noticia.get("disponible_desde", "")))
		for movimiento in SistemaFinanciero.movimientos:
			if int(movimiento.get("dia", 0)) == dia and str(movimiento.get("tipo", "")) == "Compra de acciones":
				errores.append("Día %d: compraste acciones el mismo día en que circulaba el rumor «%s», que era falso." % [dia, str(noticia.get("titulo", ""))])
				break
	return errores


## Empresas del mercado y su equivalencia real (se revela al terminar).
func empresas_para_revelar() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for activo in SistemaMercado.activos:
		resultado.append({
			"nombre": str(activo.get("nombre", "")),
			"real": str(activo.get("equivalencia_real", "")),
			"ticker": str(activo.get("ticker_real", "")),
			"destino": str(activo.get("destino_real", "")),
			"fuente": str(activo.get("fuente", ""))
		})
	return resultado


## Información real que se revela al terminar: fechas, fuentes y qué noticias eran falsas.
func noticias_para_revelar() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for noticia in NoticiasManager.noticias:
		var noticia_id := str(noticia.get("id", ""))
		if not NoticiasManager.entregadas.has(noticia_id) and not bool(noticia.get("archivo", false)):
			continue
		var origen: Dictionary = noticia.get("origen", {})
		resultado.append({
			"titulo_juego": str(noticia.get("titulo", "")),
			"falsa": bool(noticia.get("falsa", false)),
			"titulo_real": str(origen.get("titulo_real", "")),
			"fecha_real": str(origen.get("fecha_publicacion", "")),
			"fuente": str(origen.get("fuente", "")),
			"fuente_url": str(origen.get("fuente_url", ""))
		})
	return resultado


func _porcentaje(valor: float, con_signo: bool = true) -> String:
	var texto := "%.1f %%" % (valor * 100.0)
	if con_signo and valor > 0.0:
		texto = "+" + texto
	return texto


# --- Reinicio -----------------------------------------------------------------

## Borra la partida en todos los sistemas y vuelve a la ficha inicial.
func reiniciar_partida() -> void:
	EstadoJuego.reiniciar()
	SistemaMercado.sincronizar_cartera()
	NoticiasManager.reiniciar_demo()
	SistemaMercado.actualizar_precios()
	SistemaFinanciero.reiniciar()
	_fijar_patrimonio_inicial()
	EstadoJuego.registrar_patrimonio_del_dia()
	EstadoJuego.guardar_estado()
	EstadoJuego.partida_iniciada = false
	EstadoJuego.regresar_a_habitacion = false
	_ventanas_abiertas.clear()
	get_tree().paused = false
	get_tree().change_scene_to_file(ESCENA_INICIAL)
