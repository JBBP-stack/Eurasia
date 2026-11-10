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

## Pendiente

- [ ] **Sustituir la serie de precios ilustrativa por cotizaciones históricas verificadas.** `datos/mercado/mercado_2008.json` tiene `verificado: false`: la serie se generó a partir de una trayectoria aproximada de un índice general con betas ficticias. También falta asignar `equivalencia_real` a cada activo.
- [ ] Confirmar o ajustar las reglas provisionales de `datos/reglas_demo.json` (gastos, precio de la comida, salud, comisiones, bancarrota, probabilidad de rumores, fecha de fin).
- [ ] Ampliar el contenido: solo hay noticias en los días 1 a 3 y el escenario termina el día 26 (10/10/2008).
- [ ] Probar el asistente con una clave real y revisar la calidad y los límites de sus respuestas.
- [ ] Arte: retrato del personaje, sprites del jugador, del banco y de la nevera según las existencias.
- [ ] Distribuir los objetos interactivos de la habitación sin alterar movimiento, cámara ni colisiones.
- [ ] Corregir el GDD: 15.000 € + 13.000 € no suman 30.000 € (el código usa 15.000 € + 15.000 €).
- [ ] Al abrir el proyecto en el editor se generarán los `.uid` de los scripts nuevos: hay que añadirlos al repositorio.

## Notas

- El GDD de referencia está en `docs/EURASIA_DISENO_DEL_JUEGO.md`.
- Las cifras económicas provisionales están centralizadas en `godot/datos/reglas_demo.json`; ajústalas ahí, no en el código.
- `python tools/validar_noticias.py` valida noticias, preguntas, anonimización, mercado y reglas.
- El calendario y las noticias son datos de prototipo. Los nombres y fechas reales ya no son visibles en la partida: están en `origen`.

## En curso

- [ ] **Operaciones bancarias.** Interfaz de cuenta, efectivo, inversiones e historial: ingresos, retiradas y compraventa con confirmación y guardado persistente. Ahora usa los seis activos del mercado, precios por fecha y comisiones de las reglas. Falta validarlas en Godot.
