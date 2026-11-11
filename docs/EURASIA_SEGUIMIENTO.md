# EURASIA — Seguimiento técnico

Actualizado: 11/11/2026

## Revisión de jugabilidad del 11/11/2026

- [x] **Periódico recogible y lectura separada.** Aviso de llegada en el HUD, periódico visible en el buzón, E lo recoge con una animación y la confirmación aparece en el HUD. W o el botón Buzón abren la lista de periódicos recogidos y la hemeroteca.
- [x] **Decisiones fuera de la noticia.** El artículo contiene titular y texto; el cuestionario y sus opciones aparecen en el panel de decisiones (D).
- [x] **Salud y comida con consecuencias visibles.** La salud y las raciones aparecen en el HUD y en la nevera; no comer acumula penalizaciones crecientes, comer reinicia la racha y permite recuperar salud al descansar.
- [x] **Aviso de hambre en el HUD.** Antes de acercarse a la nevera, el jugador puede ver cuánto perderá si se acuesta sin comer; el aviso cambia de color cuando quedan pocas raciones o la salud está baja.
- [x] **Nevera con estados visuales.** Usa nevera1 cerrada, nevera2 abierta con comida y nevera3 abierta vacía.
- [x] **Descanso desde la cama y controles modales.** Se quitó el botón de dormir junto al día; la cama es el único avance. Las interacciones E del mundo quedan bloqueadas con una ventana abierta.
- [x] **Habitación amueblada con PNGs.** Los objetos y cuadros usan regiones del atlas transparente `assets/escenarios/decoracion/habitacion_atlas.png`; cama y buzón también usan sprites PNG. El escritorio, la librería y los muebles principales tienen colisión.
- [x] **Banco amueblado con PNGs y TileSet.** Rótulo, paneles, empleado, mostrador, cajero, bancos y objetos usan `banco_atlas.png`. `pared_banco_atlas.png` se usa como TileSet para la pared lateral, zócalo y pared del fondo; el suelo conserva su tileset existente.
- [x] **Generación de arte local.** `tools/generar_atlas_escenarios.py` reconstruye los atlas PNG sin dependencias externas. Los atlas son sprites pixel art con transparencia; los suelos y paredes repetibles siguen siendo TileMapLayer/TileSet.
- [x] **Revisión estática de paneles.** Buzón, decisiones, diccionario, nevera, portátil, banco e informe tienen instrucciones de uso o cierre. Falta revisión visual y de juego en Godot.
- [x] **Avisos del depurador.** Se corrigieron la llamada de instancia a la función de archivo, las divisiones enteras y la transformación del nodo raíz. La recarga headless de Godot 4.7.2 ya no mostró esos avisos ni errores de GDScript.
- [ ] **Prueba visual del flujo completo y los nuevos muebles.** Revisar entrega, recogida, lectura, decisiones, comida, ambos sprites de nevera, descanso, el acceso a cama/portátil/buzón y las rutas al empleado y al cajero.
- [ ] **Ajustar reglas provisionales de hambre** (`perdida_salud_dia_sin_comer`, incremento y máximo) tras probar el ritmo real de varios días.

## Avances validados

- [x] **Primer calendario provisional (sustituido).** La prueba inicial comenzaba el 15/09/2008 y mostró tres noticias en el buzón. El calendario vigente empieza el 05/09/2008 y termina el 16/09/2008.
- [x] **Ficha inicial.** Muestra edad, género, país y clase social; reserva un espacio para el retrato y permite continuar a la habitación. Se confirmó que funciona en Godot. Los datos del perfil siguen siendo provisionales.
- [x] **HUD de la habitación.** Muestra día, saldo bancario, valor por empresa y patrimonio total desde EstadoJuego. Confirmado por el usuario.
- [x] **Reparto escalonado y bloqueo de dormir.** Las noticias llegan en orden determinista; las decisiones obligatorias bloquean el descanso desde la cama. Confirmado por el usuario.
- [x] **Recogida física del buzón.** Al acercarse y pulsar E se recoge un periódico; el archivo solo muestra periódicos recogidos y la lectura ocurre al abrir cada entrada. Confirmado por el usuario.
- [x] **Cama física.** La cama es el único control para avanzar el día y muestra el motivo si no se puede dormir. Confirmado por el usuario.
- [x] **Acceso al estado del análisis desde el portátil.** El bloqueo depende de que termine el reparto y de que se hayan recogido todas las noticias del día. La integración real con Claude queda separada.
- [x] **Nevera y alimentación.** Muestra existencias, permite comer y comprar raciones; el HUD refleja comida y salud. Confirmado por el usuario.
- [x] **Diccionario financiero ampliado.** Búsqueda local, panel legible y 62 términos. Confirmado por el usuario.
- [x] **Escena y acceso al banco.** La puerta permite entrar y volver a la habitación conservando la posición del personaje; acceso confirmado en Godot. Confirmado por el usuario.
- [x] **Teléfono provisional.** La interacción informa que no hay llamadas pendientes; no altera el estado económico. Confirmado por el usuario.

## Cambios del 11/11/2026 · implementación pendiente de revisión manual

- [x] **Ficha inicial sin finanzas.** Solo muestra edad, género, país y clase social, tal como pide el boceto. El GDD y `docs/descripcion_proyecto.md` ya coinciden; el patrimonio se consulta durante la partida.
- [x] **Continuar o empezar de nuevo.** El usuario confirmó guardado automático durante la partida, sin botón manual. Noticias, operaciones bancarias, comida, decisiones y avance del día llaman a sus guardados; la detección contempla progreso del primer día y «Nueva partida» pide confirmación antes de reiniciar. Falta comprobar en Godot que cerrar y volver a abrir restaura todo el progreso.
- [x] **Registro histórico.** `docs/REGISTRO_FUENTES_HISTORICAS.md` se genera desde los JSON. Se completaron las 30 referencias que seguían pendientes; las 59 noticias reales tienen fuente anotada y las cuatro falsas no requieren fuente. La URL directa sigue siendo opcional. Esta revisión corrigió además la cifra del paro de agosto, el sentido del dato de confianza del consumidor, la cronología de Ike y la fecha del anuncio de la OPEP.
- [x] **Preparación de Claude.** SDK `anthropic` instalado en el `.venv` local. La integración real se deja para el final; quedarán configurar una clave local y hacer una llamada de verificación.
- [ ] **Prueba de la ficha y del guardado:** comprobar en el editor comenzar, guardar progreso el primer día, cerrar, continuar, y cancelar/confirmar «Nueva partida».

## Implementado el 10/11/2026 · prueba visual pendiente

Probado con Godot 4.7.2 en modo *headless* (escenas reales, sin errores de script) y con el servidor del asistente en modo simulado. Falta la prueba visual y de jugabilidad en el editor.

- [x] **Guardado automático y reinicio coordinado.** `EstadoJuego` guarda comida, salud, decisiones, historial de patrimonio y fin de partida en `user://eurasia_estado.json`; noticias y finanzas usan sus propios archivos. `GestorPartida.reiniciar_partida()` reinicia todos los sistemas. La carga se probó anteriormente con un guardado del día 2; la detección y confirmación de la ficha cambiaron el 11/11 y requieren nueva revisión manual.
- [x] **Efectos y registro de decisiones.** Las opciones aplican prudencia, riesgo y efectos económicos o vitales; cada respuesta queda registrada para el informe final.
- [x] **Noticias anonimizadas.** Los campos visibles usan nombres ficticios (`datos/anonimizacion.json`). Los datos reales quedan en `origen` y se revelan en el informe final; el buzón muestra «Día N · medio».
- [x] **Noticias falsas.** Hay cuatro rumores candidatos (`falsa: true`), seleccionados con la probabilidad de reglas y una semilla reproducible.
- [x] **Aviso y recogida del periódico.** La llegada se indica en el HUD; el periódico queda en el buzón hasta recogerlo con E.
- [x] **Portátil.** Incluye resumen, cartera, fichas, evolución del patrimonio, ingresos y gastos, y asistente.
- [x] **Preparación del asistente Claude.** `servidor_asistente/servidor.py` limita el contexto al día actual y filtra datos internos. El modo simulado está disponible; **no se ha hecho una llamada real a Claude**, que queda para la última fase.
- [x] **Nevera y salud.** Permite comer y comprar raciones; la falta de comida resta salud y llegar a cero termina la partida.
- [x] **Economía doméstica.** Nómina y gastos fijos se procesan por calendario; el descubierto acumula días de impago.
- [x] **Mercado por fecha y comisiones.** Hay diez activos, historial de precios y comisión del 0,25 % con mínimo de 2 €.
- [x] **Derrota, fin de escenario e informe final.** Se evalúan muerte, patrimonio, descubierto, impagos y fecha final; el informe recoge errores, decisiones y equivalencias reales.
- [x] **Pausa compartida.** Las ventanas usan `GestorPartida.abrir_ventana()/cerrar_ventana()` y mantienen la pausa hasta cerrar la última.

## Segunda iteración (10/11/2026) · registro histórico; el calendario se sustituyó en la siguiente iteración

- [x] **Corrección del asistente.** El autoload `Asistente` arranca el servicio con el Python del `.venv`, el servidor lee la clave local y explica cómo configurarla si falta.
- [x] **Corrección del banco.** Los ingresos, retiradas y compras tienen confirmación dentro del panel y aceptan importes como «1.000» y «250,50».
- [x] **Calendario del 01/09/2008 al 18/09/2008.** Versión inicial sustituida por el calendario vigente del 05/09 al 16/09/2008.
- [x] **Hemeroteca.** El primer corte tenía 18 entradas; el conjunto vigente contiene 23 noticias de archivo además de los periódicos recogidos.
- [x] **Decisiones del día** accesibles desde el HUD y la tecla D.
- [x] **Puerta** a escala 1,5 con filtrado nítido.
- [x] **Empresas con nombres ficticios** y cartera inicial con activos de Lehman y Fannie Mae.
- [x] **Fichas de cotización** con gráficos, rentabilidades, máximo y mínimo anuales e histórico.
- [x] **Efectivo inicial de 2.000 €** y gastos domésticos distribuidos en el mes.

## Tercera iteración (10/11/2026) · implementación vigente

- [x] **Corrección del cajero.** La pestaña de inversiones está disponible en el modo cajero.
- [x] **Calendario del 05/09/2008 al 16/09/2008** (12 días), con las noticias anteriores en la hemeroteca.
- [x] **Atención bancaria con Marisa** (`datos/atencion_bancaria.json`): comentarios de actualidad, lectura de la situación del jugador y acceso a ventanilla.
- [x] **Al menos 2 noticias reales y 1 decisión por día**, comprobado por `tools/validar_noticias.py`.
- [x] **Diccionario de 62 términos** con búsqueda de texto completo y sugerencias.
- [x] **Compraventa cualquier día** usando el último cierre cuando no hay sesión.
- [x] **Decisiones con consecuencias directas** visibles en el buzón, el panel de decisiones y el HUD.
- [x] **Opciones de decisión con argumentos plausibles**; la explicación se revela al responder.

## Pendiente

- [ ] **Completar la auditoría de Casa Halvard Hermanos (Lehman).** Se documentaron los cierres mensuales de ene-2007–ago-2008 y los diarios del 2–17/09 con fuentes. Se corrigieron precios en EUR del 2–12 y 17/09, y se quitó el punto del 18/09 porque no hay cotización NYSE. Falta auditar 2006 y verificar todas las conversiones/redondeos USD/EUR; la serie sigue marcada como parcial.
- [x] Concretar las 30 referencias que estaban pendientes. Las referencias se anotan en `origen` de cada noticia y en el registro generado; la auditoría humana de licencias y equivalencias reales sigue pendiente.
- [ ] Confirmar o ajustar las reglas provisionales de `datos/reglas_demo.json` (gastos, precio de la comida, salud, comisiones, bancarrota, probabilidad de rumores, fecha de fin).
- [ ] Al final, crear `.env` local con una clave real, probar el asistente y revisar la calidad y los límites de sus respuestas. No incluir la clave en Git.
- [ ] Arte: el usuario completa esta parte por separado durante el día.
- [x] Distribución y decoración inicial de la habitación y el banco según los bocetos. Falta que el usuario revise visualmente la circulación y el aspecto final dentro de Godot.
- [x] **Archivos `.uid`.** Revisión del 11/11/2026: todos los scripts GDScript tienen su `.uid` en el repositorio.

## Notas

- El GDD de referencia está en `docs/EURASIA_DISENO_DEL_JUEGO.md`.
- Las cifras económicas provisionales están centralizadas en `godot/datos/reglas_demo.json`; ajústalas ahí, no en el código.
- `python tools/validar_noticias.py` valida noticias, preguntas, anonimización, mercado y reglas.
- El calendario y las noticias son datos de prototipo. Los nombres y fechas reales ya no son visibles en la partida: están en `origen`.

## En curso

- [x] **Operaciones bancarias.** Interfaz de cuenta, efectivo, inversiones e historial: ingresos, retiradas y compraventa con confirmación y guardado persistente. Usa los diez activos del mercado, precios por fecha y comisiones de las reglas. La experiencia de juego se considera funcional; quedan las comprobaciones del guardado descritas arriba.
