extends Node
## Estado inicial de la demo. Cifras monetarias en céntimos para evitar errores de redondeo.
## Todos los datos salvo el reparto 15.000/15.000 y el total de 30.000 son provisionales.


signal dia_cambiado(nuevo_dia: int)

# Fecha temporal del prototipo. No es la fecha definitiva de la demo.
const FECHA_INICIO_PROVISIONAL: String = "2008-09-15"

# Calendario interno, no visible directamente para el jugador.
var fecha_historica_interna: String = FECHA_INICIO_PROVISIONAL
var dia_de_partida: int = 1
var posicion_retorno_habitacion: Vector2 = Vector2(135.0, 42.0)
var regresar_a_habitacion: bool = false
var partida_iniciada: bool = false


var perfil: Dictionary = {
	"edad": 30,
	"genero": "Hombre",
	"pais_ficticio": "República de Liria",
	"ingreso_mensual_centimos": 200_000
}

var saldo_bancario_centimos: int = 1_500_000  # 15.000 €

# Precios de PRUEBA (no cotizaciones históricas).
# Sustituiremos sus precios y cantidades por datos de la fecha real del escenario.
var cartera: Array[Dictionary] = [
	{"id": "AUR", "nombre": "Aurora Financiera", "acciones": 50, "precio_centimos": 10_000},
	{"id": "LIR", "nombre": "Liria Industrial", "acciones": 50, "precio_centimos": 10_000},
	{"id": "NEX", "nombre": "Nexo Comercial", "acciones": 50, "precio_centimos": 10_000}
]

var comida_disponible: int = 3
var dias_sin_comer: int = 0
var dias_sin_ir_al_bano: int = 0
var salud: int = 100

func valor_cartera_centimos() -> int:
	var total: int = 0
	for posicion in cartera:
		total += int(posicion["acciones"]) * int(posicion["precio_centimos"])
	return total

func patrimonio_total_centimos() -> int:
	return saldo_bancario_centimos + valor_cartera_centimos()

func euros(centimos: int) -> String:
	return "%.2f" % (float(centimos) / 100.0)


func etiqueta_dia() -> String:
	return "Día %d" % dia_de_partida


func avanzar_un_dia() -> void:
	restaurar_dia(dia_de_partida + 1)


func restaurar_dia(nuevo_dia: int) -> bool:
	if nuevo_dia < 1:
		push_warning("El día de partida no puede ser menor que 1.")
		return false

	var inicio: int = Time.get_unix_time_from_datetime_string(
		FECHA_INICIO_PROVISIONAL + "T00:00:00"
	)

	var segundos: int = inicio + (nuevo_dia - 1) * 86_400

	fecha_historica_interna = Time.get_date_string_from_unix_time(segundos)
	dia_de_partida = nuevo_dia

	dia_cambiado.emit(dia_de_partida)
	return true
