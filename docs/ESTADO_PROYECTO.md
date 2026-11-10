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

Todo lo siguiente se probó automáticamente con Godot 4.7.2 en modo *headless*, sin errores. Falta revisarlo jugando en el editor (detalle en [EURASIA_SEGUIMIENTO.md](EURASIA_SEGUIMIENTO.md)).

- **Ciclo completo del día:** al dormir se aplican comida y salud, nómina y gastos fijos (el día 1 de cada mes), el descubierto y los precios del mercado según la fecha. Después se comprueba si la partida termina.
- **Decisiones con consecuencias** registradas para el informe final.
- **Noticias anonimizadas y noticias falsas** de tono coloquial. Los datos reales solo se ven al terminar.
- **Portátil** con resumen, cartera, gráfica de evolución, ingresos y gastos, y asistente Claude a través de `servidor_asistente/`.
- **Nevera** para comer y comprar comida. **Derrota** por muerte o bancarrota y **fin de escenario** el 10/10/2008, con informe básico y técnico.
- **Guardado de estado vital** y botón «Nueva partida» que reinicia todos los sistemas.

Las cifras provisionales están en `godot/datos/reglas_demo.json`. Los precios del mercado son una **serie ilustrativa no verificada** (`godot/datos/mercado/mercado_2008.json`, `verificado: false`).

## Banco: implementado, pendiente de prueba final

La nueva interfaz tiene pestañas de cuenta, efectivo, inversiones e historial. La ventanilla permite acceder a todas; el cajero abre las operaciones de efectivo. Ingresos, retiradas, compras y ventas requieren confirmación, validan fondos y guardan el historial localmente.

El prototipo arranca con **15.000 € en cuenta**, **0 € en efectivo** y 50 acciones de cada uno de tres activos ficticios, valoradas a **100 € por acción** el día 1. Eso da 15.000 € en inversiones y 30.000 € de patrimonio total. Hay tres activos más disponibles para comprar. A partir del día 1 los precios siguen la serie ilustrativa del mercado, la comisión es del 0,25 % (mínimo 2 €) y se permiten hasta diez posiciones activas. **No son reglas ni cotizaciones históricas definitivas.** Falta probar las operaciones en Godot y comprobar que persisten al reiniciar.

## Estructura técnica útil

- `godot/sistemas/EstadoJuego.gd`: perfil, calendario, saldos y estado general.
- `godot/sistemas/NoticiasManager.gd`: noticias, entregas, recogidas, decisiones y avance del día.
- `godot/sistemas/SistemaFinanciero.gd`: operaciones bancarias, pagos, cargos, validación e historial persistente.
- `godot/sistemas/Reglas.gd`: carga `datos/reglas_demo.json` (reglas provisionales).
- `godot/sistemas/SistemaMercado.gd`: catálogo de activos, precios por fecha y apertura de la bolsa.
- `godot/sistemas/SistemaVida.gd`: comida y salud.
- `godot/sistemas/GestorPartida.gd`: pausa compartida, proceso de cada día, efectos de las decisiones, derrota, informe final y reinicio.
- `godot/sistemas/ClienteAsistente.gd` y `servidor_asistente/`: asistente Claude a través de un servicio local (la clave nunca está en el juego).
- `godot/datos/noticias/`: contenido JSON de noticias y preguntas.
- `godot/escenas/habitacion/`, `banco/`, `interfaces/`: escenas y pantallas.

Los sistemas principales están registrados como *autoloads* en `godot/project.godot`. El detalle de validaciones y pendientes está en [EURASIA_SEGUIMIENTO.md](EURASIA_SEGUIMIENTO.md).

## Próximos pasos recomendados

1. Abrir el proyecto en el editor, jugar un ciclo completo y añadir al repositorio los `.uid` que genere Godot.
2. Revisar y ajustar las reglas provisionales de `datos/reglas_demo.json`.
3. Sustituir la serie de precios ilustrativa por cotizaciones históricas verificadas.
4. Probar el asistente con una clave real (`servidor_asistente/README.md`) y ampliar las noticias más allá del día 3.

**Importante para colaborar:** el calendario comienza provisionalmente el 15/09/2008; el perfil, los activos y varios valores también son datos de prototipo. Conviene mantenerlos identificados como provisionales hasta contrastarlos con el GDD. Antes de editar, sincronizad el repositorio y evitad trabajar simultáneamente en los mismos scripts.

