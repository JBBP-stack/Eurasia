# EURASIA — Estado del proyecto

**Nota de traspaso · 10/11/2026**

## Qué es

Videojuego retro de simulación financiera e histórica. La demo se desarrolla alrededor de una habitación que sirve de centro para las actividades del personaje: recibir noticias, tomar decisiones, consultar información y gestionar sus finanzas. El proyecto está hecho en **Godot 4.7**; abre `godot/project.godot`.

## Ya implementado y confirmado en Godot

- **Ficha de inicio y habitación:** perfil inicial, personaje controlable y HUD con día, banco, efectivo, inversiones y patrimonio.
- **Día y noticias:** reparto escalonado desde el buzón; se recogen y leen periódicos. Dormir queda bloqueado hasta que termina el reparto y se resuelven las decisiones obligatorias.
- **Habitación interactiva:** cama, buzón, portátil, nevera, libro/diccionario, teléfono y puerta del banco. El teléfono sigue siendo una pantalla provisional (fuera del alcance de la primera demo).
- **Diccionario financiero:** búsqueda local y conceptos con ejemplos.
- **Acceso al banco:** la puerta permite entrar y regresar a la habitación conservando la posición del personaje.

## Implementado el 10/11/2026 · pendiente de prueba en el editor

Probado con Godot 4.7.2 en modo *headless* y con capturas reales, sin errores. Falta revisarlo jugando en el editor (detalle en [EURASIA_SEGUIMIENTO.md](EURASIA_SEGUIMIENTO.md)).

- **Escenario:** del lunes **01/09/2008** al jueves **18/09/2008** (18 días). Al dormir el día 18 termina la partida, salvo que antes haya una bancarrota o la muerte del personaje.
- **Situación inicial:** 15.000 € en cuenta, **2.000 € en efectivo** y unos 13.000 € en acciones: 30.000 € en total, como indica el GDD.
- **Cartera inicial de empresas reales con nombre ficticio:** Casa Halvard Hermanos (= Lehman Brothers, quiebra el 15/09), Hipotecaria Federal Fanara (= Fannie Mae, intervenida el 07/09) y Refrescos Cola Dorada (= Coca-Cola). Otras 7 empresas reales se pueden comprar. La equivalencia se revela al final.
- **Cotizaciones reales:** datos diarios de dos años convertidos a euros (Yahoo Finance; Lehman, reconstruida con cierres publicados en prensa). Fichas de cotización con rangos de 5 días a 2 años, rentabilidades y descripción, en el banco y en el portátil (pestaña «Mercado»). La bolsa cierra fines de semana y festivos reales.
- **Hemeroteca:** 18 noticias relevantes de los dos años anteriores. Los periódicos recogidos se van añadiendo.
- **Decisiones del día:** botón «Decisiones (N)» en el HUD o tecla D, para consultarlas y responderlas en cualquier momento.
- **Gastos domésticos:** alquiler, luz, gas, agua y teléfono en su día del mes, y gastos personales cada lunes. Se pagan primero con efectivo.
- **Banco:** confirmación dentro del panel (ya no usa una ventana aparte) e importes con formato español.
- **Asistente:** el portátil arranca solo el servicio local. La clave va en `.env` (ver `.env.example` y `servidor_asistente/README.md`).
- Siguen funcionando la nevera, la derrota, el informe final, las noticias falsas y el guardado de estado. Un guardado de una versión anterior se aparta como `.incompatible.bak` y se empieza de cero.

Las cifras provisionales están en `godot/datos/reglas_demo.json`.

## Estructura técnica útil

- `godot/sistemas/EstadoJuego.gd`: perfil, calendario, saldos y estado general.
- `godot/sistemas/NoticiasManager.gd`: noticias, entregas, recogidas, decisiones y avance del día.
- `godot/sistemas/SistemaFinanciero.gd`: operaciones bancarias, pagos, cargos, validación e historial persistente.
- `godot/sistemas/Reglas.gd`: carga `datos/reglas_demo.json` (reglas provisionales).
- `godot/sistemas/SistemaMercado.gd`: catálogo de activos, precios por fecha y apertura de la bolsa.
- `godot/sistemas/SistemaVida.gd`: comida y salud.
- `godot/sistemas/GestorPartida.gd`: pausa compartida, proceso de cada día, efectos de las decisiones, derrota, informe final y reinicio.
- `godot/sistemas/ClienteAsistente.gd` (autoload `Asistente`) y `servidor_asistente/`: asistente Claude a través de un servicio local que el juego arranca solo. La clave nunca está en el juego.
- `godot/datos/mercado/mercado_2008.json`: cotizaciones en céntimos de euro con equivalencias reales internas.
- `godot/datos/noticias/`: contenido JSON de noticias y preguntas.
- `godot/escenas/habitacion/`, `banco/`, `interfaces/`: escenas y pantallas.

Los sistemas principales están registrados como *autoloads* en `godot/project.godot`. El detalle de validaciones y pendientes está en [EURASIA_SEGUIMIENTO.md](EURASIA_SEGUIMIENTO.md).

## Próximos pasos recomendados

1. Abrir el proyecto en el editor, jugar los 18 días y añadir al repositorio los `.uid` que genere Godot.
2. Crear `.env` con la clave de Anthropic y probar el asistente.
3. Verificar los cierres aproximados de Lehman y enlazar las fuentes de las noticias que no tienen enlace.
4. Revisar y ajustar las reglas provisionales de `datos/reglas_demo.json`.

**Importante para colaborar:** el calendario va del 01/09/2008 al 18/09/2008. El perfil, los gastos y otros valores son datos de prototipo. Conviene mantenerlos identificados como provisionales hasta contrastarlos con el GDD. Antes de editar, sincronizad el repositorio y evitad trabajar simultáneamente en los mismos scripts.

