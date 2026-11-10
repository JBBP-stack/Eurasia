# EURASIA — Seguimiento técnico

Actualizado: 10/11/2026

## Avances validados

- [x] **Calendario provisional y noticias del Día 1.** EstadoJuego inicia temporalmente el 15/09/2008, primera fecha disponible en el JSON. En Godot se confirmó que el buzón muestra tres noticias. Esta fecha es solo de prueba.
- [x] **Ficha inicial.** Muestra edad, género, país y clase social; reserva un espacio para el retrato y permite continuar a la habitación. Se confirmó que funciona en Godot. Los datos del perfil siguen siendo provisionales.
- [x] **HUD de la habitación.** Muestra día, saldo bancario, valor por empresa y patrimonio total desde EstadoJuego. Confirmado por el usuario.
- [x] **Reparto escalonado y bloqueo de dormir.** Las noticias llegan en orden determinista y ambos botones usan el mismo control: esperar al fin del reparto y responder las decisiones obligatorias. Confirmado por el usuario.
- [x] **Recogida física del buzón.** Al acercarse y pulsar E se recoge un periódico; el archivo solo muestra periódicos recogidos y la lectura ocurre al abrir cada entrada. Confirmado por el usuario.
- [x] **Cama física.** La interacción usa el mismo avance de día que ambos botones y muestra el motivo si no se puede dormir. Confirmado por el usuario.
- [x] **Acceso al estado del análisis desde el portátil.** El bloqueo depende de que termine el reparto y de que se hayan recogido todas las noticias del día. La integración real con Claude queda separada.
- [x] **Consulta de existencias en la nevera.** La interacción muestra la cantidad actual de comida de EstadoJuego; no consume ni compra raciones. Confirmado por el usuario.
- [x] **Diccionario financiero ampliado.** Búsqueda local, panel legible y siete conceptos con ejemplos. Confirmado por el usuario.
- [x] **Escena y acceso al banco.** La puerta permite entrar y volver a la habitación conservando la posición del personaje; acceso confirmado en Godot. Confirmado por el usuario.
- [x] **Teléfono provisional.** La interacción informa que no hay llamadas pendientes; no altera el estado económico. Confirmado por el usuario.

## Implementado el 10/11/2026 · validado con pruebas automáticas, pendiente de confirmar en el editor

Probado con Godot 4.7.2 en modo *headless* (escenas reales, sin errores de script) y con el servidor del asistente en modo simulado. Falta la prueba visual y de jugabilidad en el editor.

- [ ] **Guardado de estado vital y reinicio unificado.** `EstadoJuego` guarda comida, salud, decisiones, historial de patrimonio y fin de partida en `user://eurasia_estado.json`. `GestorPartida.reiniciar_partida()` reinicia todos los sistemas. La ficha permite «Continuar» o «Nueva partida». Se probó la carga de un guardado anterior (día 2).
- [ ] **Efectos y registro de decisiones.** Las opciones tienen `adecuada` y efectos (`prudencia`, `riesgo`, dinero, comida, salud) que aplica `GestorPartida`. Cada decisión queda registrada para el informe final.
- [ ] **Noticias anonimizadas.** Los campos visibles usan nombres ficticios (`datos/anonimizacion.json`). La fecha real, la fuente y el enlace pasan a `origen` y solo se revelan en el informe final. El buzón muestra «Día N · medio».
- [ ] **Noticias falsas.** Tres rumores de tono coloquial (`falsa: true`). Aparecen con la probabilidad `noticias/probabilidad_noticia_falsa`, de forma reproducible según la semilla de la partida.
- [ ] **Aviso de llegada.** El periódico cae con animación en el buzón y aparece un «!» mientras haya periódicos sin recoger.
- [ ] **Portátil.** Pestañas de resumen, cartera (distribución y ficha de cada activo), evolución del patrimonio (gráfica con información al pasar el ratón), ingresos y gastos, y asistente.
- [ ] **Asistente Claude a través de un servicio intermedio.** `servidor_asistente/servidor.py` guarda la clave, carga solo las noticias del día por ID, limita al asistente y filtra nombres reales y años. Probado en modo `--simulado` y con una clave inválida (error controlado). **No se ha hecho ninguna llamada real a Claude.**
- [ ] **Nevera.** Permite comer una ración al día y comprar raciones o paquetes. Cada día sin comer resta salud; con salud 0 el personaje muere.
- [ ] **Economía doméstica.** Nómina y gastos fijos el día de cobro de cada mes. El descubierto cuenta como días de impago.
- [ ] **Mercado por fecha y comisiones.** `SistemaMercado` asigna los precios según la fecha interna. Hay seis activos, la bolsa cierra los fines de semana y se cobra una comisión del 0,25 % con un mínimo de 2 €.
- [ ] **Derrota, fin de escenario e informe final.** Las causas de fin son la muerte, el patrimonio menor o igual a 0, superar el límite de descubierto, los días de impago y la fecha de fin del escenario. El informe incluye explicación básica y técnica, errores, decisiones y la información real.
- [ ] **Pausa compartida.** Las ventanas usan `GestorPartida.abrir_ventana()/cerrar_ventana()`, de modo que cerrar una no reanuda el juego si hay otra abierta.

## Segunda iteración (10/11/2026) · validada con pruebas automáticas y capturas, pendiente de confirmar en el editor

- [ ] **Corrección del asistente.** Fallaba porque no había SDK `anthropic` en el `.venv` ni clave, y el servidor no arrancaba. Ahora el autoload `Asistente` arranca el servicio con el Python del `.venv`, el servidor lee la clave de `.env` y, si falta, explica cómo configurarla. El servicio se detiene al cerrar el juego.
- [ ] **Corrección del banco.** Ingresar fallaba porque había 0 € de efectivo. La confirmación pasa a estar dentro del panel en vez de en un `ConfirmationDialog` (una ventana aparte). Admite importes como «1.000» y «250,50». Los controles de compra quedan siempre visibles. Probado con clics reales: retirar, ingresar y comprar.
- [ ] **Calendario del 01/09/2008 al 18/09/2008** con noticias reales todos los días y fin al dormir el día 18.
- [ ] **Hemeroteca** de los dos años anteriores (18 noticias), a la que se suman los periódicos recogidos.
- [ ] **Decisiones del día** accesibles en todo momento (HUD y tecla D).
- [ ] **Puerta** a escala 1,5 con filtrado nítido.
- [ ] **Empresas reales con nombre ficticio:** 2 de las 3 de la cartera inicial quebraron o fueron intervenidas (Lehman, Fannie Mae). Hay 7 empresas nuevas.
- [ ] **Fichas de cotización** con gráfica (de 5 días a 2 años), rentabilidades, máximo y mínimo anuales, y trayectoria de los dos últimos años.
- [ ] **2.000 € de efectivo** iniciales y gastos domésticos repartidos por el mes.

## Tercera iteración (10/11/2026) · validada con pruebas automáticas y capturas, pendiente de confirmar en el editor

- [ ] **Corrección del cajero.** La pestaña de Inversiones estaba desactivada a propósito en el modo cajero; ahora está disponible.
- [ ] **Calendario del 05/09/2008 al 16/09/2008** (12 días). Las noticias del 30/08 al 04/09 pasan a la hemeroteca.
- [ ] **Atención bancaria con Marisa,** gestora de la sucursal (`datos/atencion_bancaria.json`): comentarios de actualidad por día, opinión sobre la situación del jugador sin decirle qué hacer, y acceso a la ventanilla.
- [ ] **Al menos 2 noticias auténticas y 1 decisión por día,** con textos más completos y primeras planas generales. Lo comprueba `tools/validar_noticias.py`.
- [ ] **Diccionario de 62 términos** con búsqueda de texto completo y sugerencias.
- [ ] **Compraventa cualquier día.** `mercado/operar_todos_los_dias`: en los días sin sesión se usa el último cierre.
- [ ] **Decisiones con consecuencias directas** (`vender`, `vender_todo`, `comprar`, dinero, salud), visibles en el buzón, la ventana de decisiones y el HUD.
- [ ] **Decisiones menos evidentes:** las tres opciones tienen argumentos plausibles y la explicación solo aparece al responder.

## Pendiente

- [ ] **Verificar la serie de Casa Halvard Hermanos (Lehman).** Están contrastados los cierres del 9, 10, 11, 12 y 15/09/2008 (prensa). Los cierres mensuales anteriores y los del 2 al 8 y del 16 al 18/09 son aproximados. Las otras 9 empresas usan datos diarios de Yahoo Finance.
- [ ] Enlazar la fuente primaria de las noticias que no tienen enlace (las marca `tools/validar_noticias.py`).
- [ ] Confirmar o ajustar las reglas provisionales de `datos/reglas_demo.json` (gastos, precio de la comida, salud, comisiones, bancarrota, probabilidad de rumores, fecha de fin).
- [ ] Crear `.env` con una clave real, probar el asistente y revisar la calidad y los límites de sus respuestas.
- [ ] Arte: retrato del personaje, sprites del jugador, del banco y de la nevera según las existencias.
- [ ] Distribuir los objetos interactivos de la habitación sin alterar movimiento, cámara ni colisiones.
- [ ] Al abrir el proyecto en el editor se generarán los `.uid` de los scripts nuevos: hay que añadirlos al repositorio.

## Notas

- El GDD de referencia está en `docs/EURASIA_DISENO_DEL_JUEGO.md`.
- Las cifras económicas provisionales están centralizadas en `godot/datos/reglas_demo.json`; ajústalas ahí, no en el código.
- `python tools/validar_noticias.py` valida noticias, preguntas, anonimización, mercado y reglas.
- El calendario y las noticias son datos de prototipo. Los nombres y fechas reales ya no son visibles en la partida: están en `origen`.

## En curso

- [ ] **Operaciones bancarias.** Interfaz de cuenta, efectivo, inversiones e historial: ingresos, retiradas y compraventa con confirmación y guardado persistente. Ahora usa los seis activos del mercado, precios por fecha y comisiones de las reglas. Falta validarlas en Godot.
