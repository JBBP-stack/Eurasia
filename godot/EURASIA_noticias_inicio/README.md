# EURASIA — Sistema de noticias históricas (MVP)

## Qué contiene
- `noticias/NoticiasManager.gd`: motor de noticias, fechas, noticias leídas, preguntas, bloqueo de dormir y persistencia local.
- `noticias/NoticiasUI.tscn`: interfaz provisional (CanvasLayer), lista para añadir a la habitación.
- `noticias/NoticiasUI.gd`: interfaz con buzón, noticias, enlace a fuente, respuestas y botón de pasar día (solo para demostración).
- `noticias/datos/noticias_2008.json`: cinco noticias reales, con fuentes verificables, para tres días de septiembre de 2008. Las descripciones están adaptadas y no reproducen el artículo original.
- `noticias/datos/preguntas_2008.json`: tres ejercicios **ficticios** de educación financiera. Las puntuaciones de prudencia no son rendimientos bursátiles históricos.

## Instalar sin sobrescribir vuestra habitación
1. Copiad la carpeta `noticias` a la raíz de vuestro proyecto Godot (junto a `project.godot`).
2. En Godot: Proyecto → Ajustes del proyecto → Autoload. Seleccionad `res://noticias/NoticiasManager.gd`, poned el nombre `NoticiasManager` y pulsad Añadir/Enable.
3. Abrid `habitacion1.tscn`. Añadid una **instancia de escena hija** `res://noticias/NoticiasUI.tscn` al nodo raíz `Node2D`.
4. Ejecutad la escena (F6) o proyecto (F5).
5. Pulsad `N` o el botón **Buzón** de la esquina superior derecha. Seleccionad noticia, consultad la fuente, responded a las preguntas y pulsad **Dormir (demo)**.
6. Para repetir la demostración desde cero, borrad la partida de prueba en `user://eurasia_noticias_partida.json` o llamad a `NoticiasManager.reiniciar_demo()` desde código.

## Integración posterior
- Convertid el botón superior en un objeto `Buzon` de la habitación con área de clic. El callback puede llamar a `$NoticiasUI.abrir_buzon()`.
- Integrar la cama: en la lógica de dormir llamad a `NoticiasManager.avanzar_dia()`. Si devuelve `false`, enseñad el aviso de decisiones pendientes.
- Integrar el banco: conectad la señal `NoticiasManager.decision_resuelta(noticia_id, opcion_id, efecto)` a vuestro gestor financiero. **No** suméis dinero automáticamente por acertar: las rentabilidades reales deben depender de datos financieros históricos y de la cartera.
- Cambiad la fecha predeterminada del escenario en `NoticiasManager.gd`, o iniciad `fecha_actual` desde un gestor global del juego.
- No mostrarlos como textos periodísticos literales: son adaptaciones propias de eventos confirmados y cada noticia tiene un enlace original.

## Limitaciones deliberadas
- El dataset es de ejemplo, no cubre todos los días ni cinco noticias diarias.
- El reloj funciona por días, no por horas. La noticia de AIG de las 21:00 EDT del 16 de septiembre aparece el **17** para no anticipar el anuncio al comienzo del día 16.
- El motor de mercado y los impactos económicos aún no están conectados; solo se emiten señales para integrarlos.
- La UI se ha construido programáticamente como prototipo. Se podrá rediseñar con Pixelorama y nodos Control de Godot.
- El módulo se ha revisado estáticamente, pero **no se ha ejecutado en Godot en este entorno**.

## Referencias verificadas
- Lehman, noticia contemporánea (15/09/2008): https://www.theguardian.com/business/2008/sep/15/lehmanbrothers.creditcrunch
- Merrill Lynch (15/09/2008): https://www.theguardian.com/business/2008/sep/15/merrilllynch.wallstreet1
- Caídas bursátiles (15/09/2008): https://www.theguardian.com/business/2008/sep/15/marketturmoil.lehmanbrothers
- Reserva Federal, decisión de tipos (16/09/2008): https://www.federalreserve.gov/newsevents/pressreleases/monetary20080916a.htm
- Reserva Federal, línea AIG 21:00 EDT (16/09/2008): https://www.federalreserve.gov/newsevents/pressreleases/other20080916a.htm
