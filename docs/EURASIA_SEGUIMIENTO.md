# EURASIA — Seguimiento técnico

Actualizado: 10/11/2026

## Avances validados

- [x] **Calendario provisional y noticias del Día 1.** EstadoJuego inicia temporalmente el 15/09/2008, primera fecha disponible en el JSON. En Godot se confirmó que el buzón muestra tres noticias. Esta fecha es solo de prueba.
- [x] **Ficha inicial.** Muestra edad, género, país y clase social; reserva un espacio para el retrato y permite continuar a la habitación. Se confirmó que funciona en Godot. Los datos del perfil siguen siendo provisionales.
- [x] **HUD de la habitación.** Muestra día, saldo bancario, valor por empresa y patrimonio total desde EstadoJuego. Confirmado por el usuario.
- [x] **Reparto escalonado y bloqueo de dormir.** Las noticias llegan en orden determinista y ambos botones usan el mismo control: esperar al fin del reparto y responder las decisiones obligatorias. Confirmado por el usuario.
- [x] **Recogida física del buzón.** Al acercarse y pulsar E se recoge un periódico; el archivo solo muestra periódicos recogidos y la lectura ocurre al abrir cada entrada. Confirmado por el usuario.

## Pendiente

- [ ] Completar el ciclo de noticias con recogida, lectura y desbloqueo del análisis después de recoger todas las noticias del día.
- [ ] Distribuir los objetos interactivos de la habitación sin alterar movimiento, cámara ni colisiones.
- [ ] Diseñar el escenario del banco y reservar sus operaciones para la última fase funcional.

## Notas

- `docs/EURASIA_GDD.md` no estaba presente en el repositorio al iniciar este seguimiento. El GDD de referencia se recibió como texto adjunto.
- El calendario y las noticias actuales son datos de prototipo; los JSON todavía contienen fechas y nombres históricos visibles.

## En curso

- [ ] **Cama física (pendiente de validación).** Al acercarse y pulsar E debe llamar al mismo avance de día que los dos botones de dormir y mostrar el motivo si el reparto o las decisiones están pendientes. La tecla E sigue siendo provisional.
