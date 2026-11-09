extends Node
## Estado inicial de la demo. Cifras monetarias en céntimos para evitar errores de redondeo.
## Todos los datos salvo el reparto 15.000/15.000 y el total de 30.000 son provisionales.

## signal patrimonio_actualizado

# La fecha histórica se mantiene oculta al jugador.
# Más adelante NoticiasManager utilizará esta misma fecha para evitar dos calendarios.
var fecha_historica_interna: String = "2007-07-02"
var dia_de_partida: int = 1

var perfil: Dictionary = {
	"edad": 28,
	"genero": "Mujer",
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
