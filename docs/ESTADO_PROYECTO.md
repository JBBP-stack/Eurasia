# EURASIA — Estado del proyecto

**Nota de traspaso · 10/11/2026**

## Qué es

Videojuego retro de simulación financiera e histórica. La demo se desarrolla alrededor de una habitación que sirve de centro para las actividades del personaje: recibir noticias, tomar decisiones, consultar información y gestionar sus finanzas. El proyecto está hecho en **Godot 4.7**; abre `godot/project.godot`.

## Ya implementado y confirmado en Godot

- **Ficha de inicio y habitación:** perfil inicial, personaje controlable y HUD con día, banco, efectivo, inversiones y patrimonio.
- **Día y noticias:** reparto escalonado desde el buzón; se recogen y leen periódicos. Dormir queda bloqueado hasta que termina el reparto y se resuelven las decisiones obligatorias.
- **Habitación interactiva:** cama, buzón, portátil, nevera, libro/diccionario, teléfono y puerta del banco. La consulta de nevera solo muestra existencias; todavía no consume comida. El teléfono es una pantalla provisional.
- **Portátil:** indica cuándo se puede analizar el conjunto de noticias. La conexión con Claude aún no existe.
- **Diccionario financiero:** búsqueda local y conceptos con ejemplos.
- **Acceso al banco:** la puerta permite entrar y regresar a la habitación conservando la posición del personaje.

## Banco: implementado, pendiente de prueba final

La nueva interfaz tiene pestañas de cuenta, efectivo, inversiones e historial. La ventanilla permite acceder a todas; el cajero abre las operaciones de efectivo. Ingresos, retiradas, compras y ventas requieren confirmación, validan fondos y guardan el historial localmente.

El prototipo arranca con **15.000 € en cuenta**, **0 € en efectivo** y 50 acciones de cada uno de tres activos ficticios, valoradas a **100 € por acción**. Eso da 15.000 € en inversiones y 30.000 € de patrimonio total. Los precios son fijos de prueba, las comisiones son cero y se permiten hasta diez posiciones activas. **No son reglas ni cotizaciones históricas definitivas.** Falta probar las operaciones en Godot y comprobar que persisten al reiniciar.

## Estructura técnica útil

- `godot/sistemas/EstadoJuego.gd`: perfil, calendario, saldos y estado general.
- `godot/sistemas/NoticiasManager.gd`: noticias, entregas, recogidas, decisiones y avance del día.
- `godot/sistemas/SistemaFinanciero.gd`: operaciones bancarias, validación e historial persistente.
- `godot/datos/noticias/`: contenido JSON de noticias y preguntas.
- `godot/escenas/habitacion/`, `banco/`, `interfaces/`: escenas y pantallas.

Los sistemas principales están registrados como *autoloads* en `godot/project.godot`. El detalle de validaciones y pendientes está en [EURASIA_SEGUIMIENTO.md](EURASIA_SEGUIMIENTO.md).

## Próximos pasos recomendados

1. Probar en Godot ventanilla y cajero: cancelar y confirmar operaciones, comprobar límites y reiniciar para verificar el guardado.
2. Definir las reglas económicas pendientes y sustituir los precios de prueba por cotizaciones históricas verificadas.
3. Implementar consumo de comida y sus efectos cuando estén definidas las reglas.
4. Integrar el análisis real de noticias con Claude y terminar de organizar los objetos de la habitación.

**Importante para colaborar:** el calendario comienza provisionalmente el 15/09/2008; el perfil, los activos y varios valores también son datos de prototipo. Conviene mantenerlos identificados como provisionales hasta contrastarlos con el GDD. Antes de editar, sincronizad el repositorio y evitad trabajar simultáneamente en los mismos scripts.

