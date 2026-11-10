extends Node
## Necesidades básicas: alimentación y salud. Reglas provisionales en datos/reglas_demo.json ("alimentacion").
## El estado vive en EstadoJuego; este sistema aplica las reglas y guarda.


func precio_racion_centimos() -> int:
	return Reglas.entero("alimentacion/precio_racion_centimos", 600)


func raciones_por_paquete() -> int:
	return maxi(1, Reglas.entero("alimentacion/raciones_por_paquete", 7))


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
	return {"ok": true, "mensaje": "Has comido. Te quedan %d raciones." % EstadoJuego.comida_disponible}


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
			eventos.append("Has comido bien: tu salud mejora hasta %d." % EstadoJuego.salud)
	else:
		EstadoJuego.dias_sin_comer += 1
		var perdida := Reglas.entero("alimentacion/perdida_salud_dia_sin_comer", 20)
		EstadoJuego.salud = maxi(0, EstadoJuego.salud - perdida)
		eventos.append("Ayer no comiste (%d día(s) seguidos). Salud: %d." % [EstadoJuego.dias_sin_comer, EstadoJuego.salud])
	EstadoJuego.comido_hoy = false
	EstadoJuego.estado_vital_actualizado.emit()
	return eventos
