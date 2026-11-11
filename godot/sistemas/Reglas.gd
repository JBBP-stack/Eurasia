extends Node
## Reglas provisionales de la demo, leídas de datos/reglas_demo.json.
## Se carga como primer autoload para que el resto de sistemas pueda consultarlas en su _ready().

const RUTA_REGLAS: String = "res://datos/reglas_demo.json"

var datos: Dictionary = {}


func _ready() -> void:
	_cargar()


func _cargar() -> void:
	if not FileAccess.file_exists(RUTA_REGLAS):
		push_error("No existe el archivo de reglas: " + RUTA_REGLAS)
		return
	var parseo: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_REGLAS))
	if parseo is Dictionary:
		datos = parseo
	else:
		push_error("El archivo de reglas no es un objeto JSON válido.")


## Devuelve el valor en la ruta "seccion/clave" o el valor por defecto si no existe.
func valor(ruta: String, por_defecto: Variant = null) -> Variant:
	if datos.is_empty():
		_cargar()
	var actual: Variant = datos
	for parte in ruta.split("/"):
		if not actual is Dictionary or not actual.has(parte):
			return por_defecto
		actual = actual[parte]
	return actual


func entero(ruta: String, por_defecto: int = 0) -> int:
	return int(valor(ruta, por_defecto))


func decimal(ruta: String, por_defecto: float = 0.0) -> float:
	return float(valor(ruta, por_defecto))


func texto(ruta: String, por_defecto: String = "") -> String:
	return str(valor(ruta, por_defecto))
