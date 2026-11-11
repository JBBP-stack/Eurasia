extends SceneTree
## Reduce imágenes "pixel art" de alta resolución (p. ej. generadas por IA) a su tamaño de juego,
## para usarlas en Godot a escala 1 en lugar de escalarlas en la escena.
##
## 1) Recorta al contenido (alfa >= 50 %, ignora el ruido casi transparente).
## 2) Promedia por áreas con alfa premultiplicado.
## 3) Alfa binario (sin bordes semitransparentes).
## 4) En cada píxel usa el color real del original más cercano a la media (sin mezclas borrosas).
##
## Uso (desde la raíz del repositorio; ancho o alto = 0 conserva la proporción):
##   Godot_v4.7.2-stable_win64.exe --headless -s tools/reducir_pixelart.gd -- <entrada> <salida> <ancho> <alto>
##
## Originales en arte/sprites/ y tamaños usados en el juego:
##   puerta.png                                   -> godot/assets/objetos/puerta.png             46 0  (46x87)
##   Escritorio retro con portátil y lámpara.png  -> godot/assets/objetos/(mismo nombre)         72 0  (72x84)
##   diccionario.png                              -> godot/assets/objetos/diccionario.png        84 0  (84x48)
##   peurta_banco_delbanco.png                    -> godot/assets/escenarios/(mismo nombre)      60 0  (60x56)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 4:
		printerr("Uso: -- <entrada> <salida> <ancho> <alto>")
		quit(1)
		return
	quit(reducir(a[0], a[1], int(a[2]), int(a[3])))


func reducir(entrada: String, salida: String, ancho: int, alto: int) -> int:
	var img := Image.load_from_file(entrada)
	if img == null or img.is_empty():
		printerr("No se pudo cargar ", entrada)
		return 1
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var datos := img.get_data()

	# 1) Rectángulo del contenido.
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	for y in h:
		var fila := y * w * 4
		for x in w:
			if datos[fila + x * 4 + 3] >= 128:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	if max_x < 0:
		printerr("Imagen vacía: ", entrada)
		return 1
	var cw := max_x - min_x + 1
	var ch := max_y - min_y + 1
	if ancho <= 0 and alto <= 0:
		printerr("Indica al menos el ancho o el alto.")
		return 1
	if ancho <= 0:
		ancho = maxi(1, roundi(float(alto) * cw / ch))
	if alto <= 0:
		alto = maxi(1, roundi(float(ancho) * ch / cw))

	var res := Image.create(ancho, alto, false, Image.FORMAT_RGBA8)
	var sx := float(cw) / ancho
	var sy := float(ch) / alto
	for ty in alto:
		var y0 := min_y + int(floor(ty * sy))
		var y1 := maxi(y0 + 1, min_y + int(floor((ty + 1) * sy)))
		for tx in ancho:
			var x0 := min_x + int(floor(tx * sx))
			var x1 := maxi(x0 + 1, min_x + int(floor((tx + 1) * sx)))
			# 2) Media con alfa premultiplicado.
			var sr := 0.0
			var sg := 0.0
			var sb := 0.0
			var sa := 0.0
			var n := 0
			for y in range(y0, y1):
				var fila := y * w * 4
				for x in range(x0, x1):
					var i := fila + x * 4
					var al := datos[i + 3] / 255.0
					sr += datos[i] * al
					sg += datos[i + 1] * al
					sb += datos[i + 2] * al
					sa += al
					n += 1
			# 3) Alfa binario.
			if sa / n < 0.5:
				res.set_pixel(tx, ty, Color(0, 0, 0, 0))
				continue
			var mr := sr / sa
			var mg := sg / sa
			var mb := sb / sa
			# 4) Color real más cercano a la media (ponderado por luminancia).
			var mejor := INF
			var br := mr
			var bg := mg
			var bb := mb
			for y in range(y0, y1):
				var fila := y * w * 4
				for x in range(x0, x1):
					var i := fila + x * 4
					if datos[i + 3] < 128:
						continue
					var dr := datos[i] - mr
					var dg := datos[i + 1] - mg
					var db := datos[i + 2] - mb
					var d := dr * dr * 0.30 + dg * dg * 0.59 + db * db * 0.11
					if d < mejor:
						mejor = d
						br = datos[i]
						bg = datos[i + 1]
						bb = datos[i + 2]
			res.set_pixel(tx, ty, Color8(int(br), int(bg), int(bb), 255))
	var error := res.save_png(salida)
	if error != OK:
		printerr("No se pudo guardar ", salida)
		return 1
	print("%s -> %s  (contenido %dx%d, salida %dx%d)" % [
		entrada.get_file(), salida.get_file(), cw, ch, ancho, alto])
	return 0
