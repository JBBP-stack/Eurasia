extends TileMapLayer
## Construye el marco mural a partir del atlas de 16 x 16 px.

func _ready() -> void:
	clear()
	# Tres filas de pared, con espacio libre para la puerta y el punto de entrada.
	for y in range(3):
		for x in range(18):
			if x >= 5 and x <= 10:
				continue
			set_cell(Vector2i(x, y), 0, Vector2i(x % 4, y))

	# Paredes laterales y zócalo inferior.
	for y in range(3, 20):
		set_cell(Vector2i(0, y), 0, Vector2i(y % 4, 3))
		set_cell(Vector2i(17, y), 0, Vector2i((y + 2) % 4, 3))
	for x in range(18):
		set_cell(Vector2i(x, 20), 0, Vector2i(x % 4, 2))
