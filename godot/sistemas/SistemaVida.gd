extends Node
## Necesidades básicas: alimentación y salud. Reglas provisionales en datos/reglas_demo.json ("alimentacion").
## El estado vive en EstadoJuego; este sistema aplica las reglas y guarda.


func precio_racion_centimos() -> int:
	return Reglas.entero("alimentacion/precio_racion_centimos", 600)


func raciones_por_paquete() -> int:
	return maxi(1, Reglas.entero("alimentacion/raciones_por_paquete", 7))


func perdida_salud_proxima_noche() -> int:
	if EstadoJuego.comido_hoy:
		return 0
	return perdida_salud_por_dias_sin_comer(EstadoJuego.dias_sin_comer + 1)


func perdida_salud_por_dias_sin_comer(dias: int) -> int:
	if dias <= 0:
		return 0
	var base := Reglas.entero("alimentacion/perdida_salud_dia_sin_comer", 15)
	var incremento := Reglas.entero("alimentacion/incremento_perdida_salud_por_dia_sin_comer", 5)
	var maximo := Reglas.entero("alimentacion/perdida_salud_maxima_dia_sin_comer", 30)
	return mini(maximo, base + (dias - 1) * incremento)


func etiqueta_estado_hambre() -> String:
	if EstadoJuego.comido_hoy:
		return "Has comido hoy"
	if EstadoJuego.dias_sin_comer <= 0:
		return "Aún no has comido hoy" if EstadoJuego.comida_disponible > 0 else "Nevera vacía"
	match EstadoJuego.dias_sin_comer:
		1:
			return "Hambre"
		2:
			return "Debilidad"
		3:
			return "Mareos"
		_:
			return "Riesgo grave por falta de comida"


func comer() -> Dictionary:
	if EstadoJuego.partida_terminada:
		return {"ok": false, "mensaje": "La partida ha terminado."}
	if EstadoJuego.comido_hoy:
		return {"ok": false, "mensaje": "Ya has comido hoy. Guarda la comida para mañana."}
	if EstadoJuego.comida_disponible <= 0:
		return {"ok": false, "mensaje": "La nevera está vacía. Compra provisiones."}
	EstadoJuego.comida_disponible -= 1
	EstadoJuego.comido_hoy = true
	EstadoJuego.guardar_estado()
	EstadoJuego.estado_vital_actualizado.emit()
	return {"ok": true, "mensaje": "Has comido hoy. Te quedan %d raciones; si mantienes las comidas, recuperarás salud al descansar." % EstadoJuego.comida_disponible}


func comprar_raciones(cantidad: int) -> Dictionary:
	if cantidad <= 0:
		return {"ok": false, "mensaje": "Cantidad de comida no válida."}
	var coste := cantidad * precio_racion_centimos()
	var resultado := SistemaFinanciero.pagar(
		"Compra de comida",
		"Compra de %d raciones de comida" % cantidad,
		coste
	)
	if not bool(resultado.get("ok", false)):
		return resultado
	EstadoJuego.comida_disponible += cantidad
	EstadoJuego.guardar_estado()
	EstadoJuego.estado_vital_actualizado.emit()
	return {"ok": true, "mensaje": "Has comprado %d raciones por %s €." % [cantidad, EstadoJuego.euros(coste)]}


## Aplica las consecuencias del día que termina. Devuelve mensajes para el resumen del día.
func procesar_fin_de_dia() -> Array[String]:
	var eventos: Array[String] = []
	var salud_maxima := Reglas.entero("alimentacion/salud_maxima", 100)
	if EstadoJuego.comido_hoy:
		EstadoJuego.dias_sin_comer = 0
		var recuperacion := Reglas.entero("alimentacion/recuperacion_salud_dia_comiendo", 10)
		if EstadoJuego.salud < salud_maxima:
			EstadoJuego.salud = mini(salud_maxima, EstadoJuego.salud + recuperacion)
			eventos.append("Comiste y descansaste: recuperas %d de salud (%d/%d)." % [recuperacion, EstadoJuego.salud, salud_maxima])
		else:
			eventos.append("Comiste y descansaste. Tu salud se mantiene en %d/%d." % [EstadoJuego.salud, salud_maxima])
	else:
		EstadoJuego.dias_sin_comer += 1
		var perdida := perdida_salud_por_dias_sin_comer(EstadoJuego.dias_sin_comer)
		EstadoJuego.salud = maxi(0, EstadoJuego.salud - perdida)
		var efecto := "Hambre" if EstadoJuego.dias_sin_comer == 1 else etiqueta_estado_hambre()
		eventos.append("Ayer no comiste. %s: −%d salud (%d/%d)." % [efecto, perdida, EstadoJuego.salud, salud_maxima])
	EstadoJuego.comido_hoy = false
	EstadoJuego.estado_vital_actualizado.emit()
	return eventos
