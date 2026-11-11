# EURASIA — Estado del proyecto

**Nota de traspaso · 11/11/2026**

## Resumen

Prototipo avanzado de simulación financiera e histórica, desarrollado en Godot 4.7. El ciclo principal de juego está implementado y el usuario confirma que la jugabilidad funciona bien. Esta revisión mejora la ficha inicial y la elección entre continuar o reiniciar; esos cambios concretos necesitan comprobación manual en Godot. El guardado automático ya existe en los sistemas, aunque conviene validar su recorrido completo.

Abre `godot/project.godot` en Godot y ejecuta el proyecto con F5. La puesta en marcha del servicio del asistente está en [servidor_asistente/README.md](../servidor_asistente/README.md).

## Qué incluye ahora

- **Habitación y HUD:** movimiento, interacciones con cama, buzón, portátil, nevera, diccionario, teléfono y puerta del banco. El HUD muestra día, patrimonio, cartera, salud, comida y decisiones pendientes.
- **Noticias y decisiones:** escenario del **5 al 16 de septiembre de 2008** (12 días); 40 noticias del periodo, 23 entradas de hemeroteca, cuatro rumores falsos candidatos y 12 cuestionarios. Los periódicos llegan escalonados, se recogen físicamente y las decisiones obligatorias bloquean el descanso. La interfaz oculta fechas y nombres reales durante la partida.
- **Finanzas y supervivencia:** cuenta, efectivo, inversiones, cotizaciones por fecha, gráficas, comisiones, gastos domésticos, nómina, compra de comida, salud, descubierto y condiciones de bancarrota/fin de escenario. El informe final explica decisiones y revela fuentes y equivalencias reales.
- **Banco:** cuenta, efectivo, operaciones de inversión con confirmación, historial y atención bancaria. El catálogo tiene diez empresas; las operaciones usan precios históricos según el día.
- **Asistente:** portátil integrado con un servicio local que limita las noticias al día actual, oculta campos internos y filtra la respuesta. Existe modo simulado; **no consta una llamada real a Claude**.
- **Guardado y reinicio:** decisión confirmada: guardado automático durante la partida, sin ranuras ni botón manual. Noticias, finanzas y estado vital se guardan en archivos separados bajo `user://`; el reinicio está coordinado. La ficha detecta progreso también durante el primer día y pide confirmar antes de borrar una partida al iniciar otra. Falta confirmar guardar, cerrar y continuar dentro del editor con esta revisión.
- **Fuentes históricas:** [REGISTRO_FUENTES_HISTORICAS.md](REGISTRO_FUENTES_HISTORICAS.md) reúne las noticias y cotizaciones. El JSON de datos es el registro canónico; una referencia debe indicar medio o institución, publicación/documento y fecha. La URL directa es opcional.

Los sistemas se reparten principalmente entre [EstadoJuego.gd](../godot/sistemas/EstadoJuego.gd), [NoticiasManager.gd](../godot/sistemas/NoticiasManager.gd), [GestorPartida.gd](../godot/sistemas/GestorPartida.gd), [SistemaFinanciero.gd](../godot/sistemas/SistemaFinanciero.gd), [SistemaMercado.gd](../godot/sistemas/SistemaMercado.gd) y [SistemaVida.gd](../godot/sistemas/SistemaVida.gd). Reglas provisionales: [reglas_demo.json](../godot/datos/reglas_demo.json). El seguimiento técnico detallado está en [EURASIA_SEGUIMIENTO.md](EURASIA_SEGUIMIENTO.md).

## Revisión jugable del 11/11/2026

- El reparto muestra un aviso en el HUD y deja el periódico en el buzón. E lo recoge con animación y confirma la acción en el HUD; W o el botón Buzón abren los periódicos recogidos y la hemeroteca. Las decisiones se responden en un panel separado.
- La salud y la comida aparecen en el HUD y en la nevera. No comer aumenta la pérdida de salud noche a noche; la nevera cambia entre cerrada y abierta con comida/vacía usando los sprites del proyecto.
- Se quitó el botón de dormir del HUD: el avance ocurre desde la cama. Las interacciones del mundo quedan bloqueadas mientras hay ventanas abiertas.
- Comprobación: validador de datos, `git diff --check` y referencias `res://` correctos. Godot 4.7.2 en modo *headless* recargó los scripts sin errores ni avisos de GDScript. Queda la prueba visual y de juego en el editor; la carga *headless* sí notificó problemas del almacén de certificados y al guardar ajustes del editor.

## Validación conocida

El seguimiento registra pruebas automáticas con Godot 4.7.2 en modo *headless* y el servicio del asistente en modo simulado. En etapas anteriores, el usuario confirmó que funcionaban la habitación, el buzón, el avance de día, el diccionario y la puerta del banco; ahora confirma que la jugabilidad va bien. **En esta revisión no he ejecutado Godot ni repetido esas pruebas.** La ficha modificada y la secuencia de continuar/nueva partida deben revisarse en el editor. Claude tampoco se ha probado con credenciales reales.

## Qué falta, por prioridad

1. **Comprobar el guardado en Godot:** jugar unos minutos el primer día, recoger noticias y cambiar el estado vital, cerrar y volver a abrir; elegir «Continuar» y confirmar que se conserva el progreso. Probar «Nueva partida» y cancelar/confirmar el aviso.
2. **Revisar datos y reglas:** concretar las referencias de 53 noticias que ahora están marcadas como pendientes en el registro (la URL es opcional), validar cronología y anonimización, y verificar la serie de Casa Halvard (Lehman), que aún contiene cierres aproximados. Ajustar las reglas económicas provisionales cuando se decida su balance.
3. **Claude, al final:** el servicio está preparado y la dependencia `anthropic` instalada en el `.venv` local. Para cerrar la integración faltan una clave local en `.env` y una consulta real para revisar calidad, filtrado y coste; no incluir la clave en Git.
4. **Cierre técnico:** renovar capturas después de la revisión visual, preparar empaquetado/exportación y ampliar la guía de colaboración.
5. **Arte:** se trabaja por separado durante el día; no bloquea esta tanda de código y documentación.

**Nota para el equipo:** el contenido y las reglas son todavía de prototipo. Antes de editar, sincronizad Git y acordad quién trabaja en cada sistema para evitar conflictos. La lista de cambios y pruebas conocidas está en el seguimiento técnico; este documento resume el estado actual, no certifica que todo esté validado.
