# EURASIA — Seguimiento técnico

Actualizado: 10/11/2026

## Avances validados

- [x] **Calendario provisional y noticias del Día 1.** EstadoJuego inicia temporalmente el 15/09/2008, primera fecha disponible en el JSON. En Godot se confirmó que el buzón muestra tres noticias. Esta fecha es solo de prueba.
- [x] **Ficha inicial.** Muestra edad, género, país y clase social; reserva un espacio para el retrato y permite continuar a la habitación. Se confirmó que funciona en Godot. Los datos del perfil siguen siendo provisionales.

## En curso

- [ ] **HUD de la habitación.** Mostrar día, saldo bancario, inversiones por empresa y patrimonio total desde EstadoJuego. Pendiente de comprobar en Godot.

## Pendiente

- [ ] Completar el ciclo de noticias: programadas, entregadas, recogidas, leídas y fin del reparto.
- [ ] Aplicar las mismas condiciones de avance del día a la cama y a cualquier botón de dormir; indicar el motivo cuando no se pueda dormir.
- [ ] Distribuir los objetos interactivos de la habitación sin alterar movimiento, cámara ni colisiones.
- [ ] Diseñar el escenario del banco y reservar sus operaciones para la última fase funcional.

## Notas

- `docs/EURASIA_GDD.md` no estaba presente en el repositorio al iniciar este seguimiento. El GDD de referencia se recibió como texto adjunto.
- El calendario y las noticias actuales son datos de prototipo; los JSON todavía contienen fechas y nombres históricos visibles.
