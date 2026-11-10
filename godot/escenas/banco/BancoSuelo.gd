extends Node2D
## Baldosas sencillas para el escenario provisional del banco.


func _ready() -> void:
	var claro := Color(0.64, 0.62, 0.56, 1)
	var oscuro := Color(0.56, 0.54, 0.49, 1)
	var forma := PackedVector2Array([
		Vector2(0, 0), Vector2(30, 0), Vector2(30, 32), Vector2(0, 32)
	])

	for fila in range(10):
		for columna in range(9):
			var baldosa := Polygon2D.new()
			baldosa.polygon = forma
			baldosa.position = Vector2(-8 + columna * 32, 1 + fila * 34)
			baldosa.color = claro if (fila + columna) % 2 == 0 else oscuro
			add_child(baldosa)
