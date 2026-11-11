# EURASIA — Estado del proyecto

**Nota de traspaso · 11/11/2026**

## Resumen

Prototipo avanzado de simulación financiera e histórica, desarrollado en Godot 4.7. El ciclo principal de juego está implementado y el usuario confirma que la jugabilidad funciona bien. Esta revisión completó las referencias de las noticias y corrigió algunos datos y fechas históricas. Los cambios de la ficha inicial y de continuar o reiniciar aún necesitan comprobación manual en Godot. El guardado automático existe en los sistemas, aunque conviene validar su recorrido completo.

Abre `godot/project.godot` en Godot y ejecuta el proyecto con F5. La puesta en marcha del servicio del asistente está en [servidor_asistente/README.md](../servidor_asistente/README.md).

## Qué incluye ahora

- **Habitación y HUD:** movimiento, interacciones con cama, buzón, portátil, nevera, diccionario, teléfono y puerta del banco. Se añadieron cuadros, perchero, alfombra, escritorio, librería, mesita, lámpara y planta; el HUD muestra día, patrimonio, cartera, salud, comida y decisiones pendientes.
- **Noticias y decisiones:** escenario del **5 al 16 de septiembre de 2008** (12 días); 40 noticias del periodo, 23 entradas de hemeroteca, cuatro rumores falsos candidatos y 12 cuestionarios. Los periódicos llegan escalonados, se recogen físicamente y las decisiones obligatorias bloquean el descanso. La interfaz oculta fechas y nombres reales durante la partida.
- **Finanzas y supervivencia:** cuenta, efectivo, inversiones, cotizaciones por fecha, gráficas, comisiones, gastos domésticos, nómina, compra de comida, salud, descubierto y condiciones de bancarrota/fin de escenario. El informe final explica decisiones y revela fuentes y equivalencias reales.
- **Banco:** cuenta, efectivo, operaciones de inversión con confirmación, historial y atención bancaria. Se amuebló con mostrador central, cajero lateral, paneles, bancos, mesa, plantas y revistero. El catálogo tiene diez empresas; las operaciones usan precios históricos según el día.
- **Asistente:** portátil integrado con un servicio local que limita las noticias al día actual, oculta campos internos y filtra la respuesta. Existe modo simulado; **no consta una llamada real a Claude**.
- **Guardado y reinicio:** decisión confirmada: guardado automático durante la partida, sin ranuras ni botón manual. Noticias, finanzas y estado vital se guardan en archivos separados bajo `user://`; el reinicio está coordinado. La ficha detecta progreso también durante el primer día y pide confirmar antes de borrar una partida al iniciar otra. Falta confirmar guardar, cerrar y continuar dentro del editor con esta revisión.
- **Fuentes históricas:** [REGISTRO_FUENTES_HISTORICAS.md](REGISTRO_FUENTES_HISTORICAS.md) reúne las noticias y cotizaciones. Las 59 noticias reales tienen una referencia anotada; las cuatro falsas no necesitan fuente. Se pueden seguir añadiendo enlaces y queda auditoría humana de licencias y equivalencias.

Los sistemas se reparten principalmente entre [EstadoJuego.gd](../godot/sistemas/EstadoJuego.gd), [NoticiasManager.gd](../godot/sistemas/NoticiasManager.gd), [GestorPartida.gd](../godot/sistemas/GestorPartida.gd), [SistemaFinanciero.gd](../godot/sistemas/SistemaFinanciero.gd), [SistemaMercado.gd](../godot/sistemas/SistemaMercado.gd) y [SistemaVida.gd](../godot/sistemas/SistemaVida.gd). Reglas provisionales: [reglas_demo.json](../godot/datos/reglas_demo.json). El seguimiento técnico detallado está en [EURASIA_SEGUIMIENTO.md](EURASIA_SEGUIMIENTO.md).

## Revisión jugable del 11/11/2026

- El reparto muestra un aviso en el HUD y deja el periódico en el buzón. E lo recoge con animación y confirma la acción en el HUD; W o el botón Buzón abren los periódicos recogidos y la hemeroteca. Las decisiones se responden en un panel separado.
- La salud y la comida aparecen en el HUD y en la nevera. El HUD anticipa la pérdida de salud si el jugador se acuesta sin comer; no comer aumenta el daño noche a noche. La nevera cambia entre cerrada y abierta con comida/vacía usando los sprites del proyecto.
- Se quitó el botón de dormir del HUD: el avance ocurre desde la cama. Las interacciones del mundo quedan bloqueadas mientras hay ventanas abiertas.
- Comprobación: validador de datos, `git diff --check` y referencias `res://` correctos. Godot 4.7.2 en modo *headless* recargó los scripts sin errores ni avisos de GDScript. Queda la prueba visual y de juego en el editor; la carga *headless* sí notificó problemas del almacén de certificados y al guardar ajustes del editor.
- Revisión histórica: se completaron las 30 referencias que estaban pendientes. Se corrigieron el dato de paro de agosto (103.085), la noticia de confianza del consumidor (repuntó en agosto), el primer día en que Ike llegó a categoría 4 y la fecha del anuncio de la OPEP.

## Escenarios amueblados el 11/11/2026 · revisión visual pendiente

La habitación y el banco usan atlas PNG pixel art con transparencia; el banco añade un atlas TileSet para paredes y conserva el TileSet del suelo. `tools/generar_atlas_escenarios.py` reconstruye los PNG. Godot 4.7.2 importó los tres atlas; no se ejecutó la partida. Se añadieron colisiones para los muebles principales. El usuario hará ahora la pasada visual y comprobará cama, buzón, portátil, ventanilla y cajero.

## Validación conocida

El proyecto se recargó con Godot 4.7.2 en modo *headless* después de corregir las advertencias del depurador; no quedaron avisos ni errores de GDScript. El usuario confirma que la jugabilidad va bien. La carga *headless* sí informó de problemas del almacén de certificados y de guardado de ajustes del editor, y no sustituye una revisión visual de la ficha y de continuar/nueva partida. Claude tampoco se ha probado con credenciales reales.

## Qué falta, por prioridad

1. **Prueba visual y de juego:** revisar los muebles nuevos y confirmar el alcance de las interacciones en la habitación y el banco; probar también el flujo de periódicos, comida, decisiones y descanso.
2. **Comprobar el guardado en Godot:** cambiar el estado durante la partida, cerrar y volver a abrir; elegir «Continuar» y confirmar que se conserva el progreso. Probar «Nueva partida» y cancelar/confirmar el aviso.
3. **Revisar datos y reglas:** la serie de Casa Halvard contrasta varios cierres diarios y los cierres mensuales de 2007–agosto de 2008. Sigue incompleta: falta auditar 2006 y algunas conversiones USD/EUR. Ajustar también las reglas económicas provisionales cuando se decida su balance; queda la auditoría humana de fuentes, licencias y equivalencias.
4. **Claude, al final:** el servicio está preparado y la dependencia `anthropic` instalada en el `.venv` local. Para cerrar la integración faltan una clave local en `.env` y una consulta real para revisar calidad, filtrado y coste; no incluir la clave en Git.
5. **Cierre técnico y arte:** renovar capturas después de la revisión visual, preparar empaquetado/exportación y ampliar la guía de colaboración. El arte se trabaja por separado.

**Nota para el equipo:** el contenido y las reglas son todavía de prototipo. Antes de editar, sincronizad Git y acordad quién trabaja en cada sistema para evitar conflictos. La lista de cambios y pruebas conocidas está en el seguimiento técnico; este documento resume el estado actual, no certifica que todo esté validado.
