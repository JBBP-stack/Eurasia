# EURASIA — Videojuego de simulación financiera e histórica

**Género:** Simulador de vida, estrategia financiera y aprendizaje histórico.  
**Motor:** Godot Engine 4.x.  
**Estilo visual:** Pixel art 2D con sensación de profundidad.  
**Referencias:** Disco Elysium, Undertale y Stardew Valley.  
**Estado del proyecto:** Desarrollo del primer prototipo jugable.

## 1. Concepto general

EURASIA es un videojuego de simulación de vida y gestión financiera cuyo objetivo principal es enseñar al jugador a interpretar información económica, administrar sus recursos y tomar decisiones financieras razonadas que pueda aplicar a situaciones de la vida real.

El jugador controla a un personaje que vive en un periodo histórico real, generalmente anterior a una crisis económica, financiera o política importante. Desconoce la época exacta y los acontecimientos que están por suceder.

A través de periódicos, conversaciones con una inteligencia artificial, un diccionario especializado y herramientas de gestión bancaria, deberá analizar su entorno y tomar decisiones que afectarán a su patrimonio, su calidad de vida y su supervivencia.

El videojuego no busca que el jugador prediga el futuro, sino que aprenda a gestionar la incertidumbre y comprender las consecuencias de sus decisiones.

## 2. Ambientación histórica

Cada escenario estará ambientado en un periodo histórico relevante. Entre los acontecimientos previstos se encuentran:

- La crisis económica de 1929.
- La Primera y Segunda Guerra Mundial.
- La Guerra Fría.
- El corralito argentino de 2001.
- La crisis financiera de 2008.
- La pandemia de coronavirus.
- Quiebras bancarias y otros acontecimientos económicos relevantes.

La primera demo estará ambientada antes de la crisis financiera de 2008.

Los acontecimientos, entidades financieras, inversiones y noticias estarán basados en datos históricos reales. Sin embargo, los nombres de empresas, bancos, países y otros elementos identificadores se sustituirán por nombres ficticios.

El jugador no conocerá la fecha histórica auténtica, aunque el motor del juego la utilizará internamente para determinar qué noticias aparecen y cómo evolucionan los mercados.

Al finalizar el juego sí tendrá acceso a toda la información real.

## 3. Inicio de la partida

Al comenzar, aparecerá la ficha **«Tu personaje»**, con retrato provisional y únicamente estos datos personales:

- Edad.
- Género.
- País de residencia.
- Clase social.

La ficha no mostrará fecha, salario, cuenta, efectivo, inversiones ni patrimonio. Esa información económica estará disponible en el HUD y en el portátil una vez iniciada la partida.

El estado financiero inicial de la demo tendrá un valor objetivo provisional de 30.000 €, distribuido así:

| Concepto | Cantidad |
|---|---:|
| Cuenta bancaria | 15.000 € |
| Efectivo | 2.000 € |
| Inversiones | Aproximadamente 13.000 € |
| **Patrimonio total** | **30.000 €** |

Las inversiones estarán distribuidas inicialmente entre tres empresas de la época, representadas mediante nombres ficticios.

El jugador podrá gestionar hasta diez posiciones de inversión.

Los datos personales del personaje, el salario y la composición exacta de la cartera todavía deberán definirse.

## 4. Habitación y entorno interactivo

Tras la presentación inicial, el jugador aparecerá en una habitación de pixel art 2D.

Podrá desplazarse libremente, siempre respetando las colisiones del escenario, y acercarse a diferentes objetos para interactuar con ellos mediante una tecla.

La habitación incluirá:

- **Buzón o punto de correo:** permite recibir y recoger periódicos.
- **Mesa con portátil:** permite consultar la información financiera y acceder al asistente de inteligencia artificial.
- **Diccionario financiero:** contiene explicaciones de conceptos y terminología económica.
- **Nevera:** permite consultar las existencias de comida, consumir alimentos y comprar provisiones.
- **Cama:** permite avanzar al siguiente día cuando se hayan completado las decisiones obligatorias.
- **Puerta del banco:** permite acceder a las operaciones bancarias y de inversión. Su implementación completa será la última fase de la demo.
- **Teléfono:** servirá en futuras versiones para recibir noticias personales y familiares relacionadas con contratos, deudas, hipotecas, empleo y problemas económicos.
- **Baño:** permitirá satisfacer necesidades fisiológicas del personaje. Se desarrollará en una fase posterior.

## 5. Sistema de periódicos

Los periódicos serán uno de los mecanismos principales del videojuego.

Cada día podrán llegar entre uno y cinco periódicos, dependiendo de los acontecimientos relevantes.

Su funcionamiento será el siguiente:

1. El juego determina las noticias correspondientes al día histórico.
2. Se programa la llegada de los periódicos durante el día.
3. Cuando llega uno, aparece un aviso en el HUD y el periódico cae con una pequeña animación en el buzón.
4. El jugador se acerca al buzón y pulsa E. El periódico se recoge con una animación breve y el HUD confirma el titular.
5. El botón «Buzón» o la tecla W abre la lista de periódicos recogidos y la hemeroteca; seleccionar un titular permite leerlo.
6. Los periódicos recogidos quedan guardados y se pueden volver a consultar desde ese panel.
7. Las preguntas y sus opciones aparecen por separado en el panel de decisiones, accesible con D; no forman parte del texto del artículo.
8. Al terminar el reparto, aparece un aviso indicando que no llegarán más periódicos ese día.

El sistema distinguirá entre noticias programadas, entregadas, recogidas y leídas.

### Contenido histórico

Las noticias estarán basadas en hechos reales de la época y conservarán su significado económico, pero sus entidades identificables serán sustituidas por nombres ficticios.

Claude podrá utilizarse durante el desarrollo para investigar fuentes históricas y generar adaptaciones originales de esas noticias.

Los textos utilizarán un lenguaje financiero técnico, con términos que puedan requerir la consulta del diccionario.

Las fuentes originales, las fechas reales y las equivalencias entre entidades se conservarán en los datos internos del proyecto, pero no serán visibles durante la partida.

### Noticias falsas

Con una probabilidad configurable aparecerán noticias inventadas entre las noticias históricas.

En el diseño inicial, estas noticias tendrán un tono más coloquial que las auténticas, de forma que el jugador pueda sospechar de su fiabilidad.

Internamente estarán identificadas como ficticias, pero el jugador no conocerá esa clasificación hasta que corresponda revelarla.

La mecánica busca enseñar a diferenciar información económica fiable de información potencialmente engañosa.

## 6. Diccionario financiero

El diccionario será una herramienta educativa disponible para el jugador durante la partida.

Contendrá definiciones y explicaciones de conceptos económicos, bancarios y financieros.

Permitirá consultar términos como liquidez, inflación, apalancamiento, diversificación, insolvencia, volatilidad, deuda, hipoteca, rentabilidad y riesgo.

Su función será facilitar la comprensión de las noticias sin revelar qué decisión debe tomar el jugador.

Para la demo se utilizará inicialmente un diccionario local, con información previamente preparada y verificada.

## 7. Portátil e inteligencia artificial

El portátil será uno de los objetos centrales de la habitación.

El jugador podrá consultar información sobre su cuenta bancaria, sus inversiones y la evolución de su patrimonio.

También será el punto de acceso al asistente Claude.

El análisis de noticias mediante Claude estará bloqueado hasta que se hayan entregado y recogido todos los periódicos programados para el día.

Una vez cumplida esa condición, el jugador podrá enviar al asistente las noticias recogidas.

### Limitaciones de Claude

La inteligencia artificial deberá:

- Explicar términos y conceptos financieros.
- Ayudar a interpretar las noticias disponibles.
- Comparar situaciones económicas con precedentes históricos conocidos hasta el momento de la partida.
- Exponer riesgos, posibilidades y consecuencias generales.
- Evitar revelar la época histórica real.
- Evitar proporcionar información sobre acontecimientos futuros.
- No indicar directamente qué opción del cuestionario es correcta.
- No ordenar comprar o vender inversiones.
- No modificar directamente el dinero ni los activos del jugador.

El asistente recibirá únicamente la información autorizada para el día actual.

La conexión con Claude se realizará mediante un servicio intermedio para proteger las claves de la API y controlar la información enviada.

## 8. Cuestionarios y decisiones

Algunas noticias relevantes generarán cuestionarios financieros.

Cada cuestionario tendrá tres opciones:

- Una respuesta considerada adecuada según los objetivos educativos.
- Dos respuestas perjudiciales, con consecuencias diferenciadas.

Las decisiones podrán modificar el patrimonio, la liquidez, la exposición al riesgo o las condiciones de vida del personaje.

No todas las noticias tendrán cuestionarios.

Se pretende que los días relevantes puedan incluir hasta tres decisiones financieras importantes, aunque deberá definirse si ese número será fijo o variable.

El jugador no podrá avanzar al día siguiente mientras tenga cuestionarios obligatorios sin responder.

El juego registrará las decisiones para poder explicar posteriormente sus consecuencias.

Una decisión prudente no tendrá que generar necesariamente beneficios inmediatos, ya que el objetivo es enseñar gestión del riesgo y no únicamente recompensar respuestas correctas con dinero.

## 9. Cuenta bancaria e inversiones

El personaje tendrá una cuenta bancaria y una cartera de inversiones.

El portátil permitirá consultar:

- Saldo bancario.
- Valor de las inversiones.
- Patrimonio total.
- Historial de movimientos.
- Evolución temporal mediante gráficas.
- Distribución de la cartera.
- Ingresos y gastos.
- Información de cada activo.

El jugador podrá comprar y vender inversiones, depositar y retirar dinero, y gestionar hasta diez posiciones.

Las operaciones requerirán confirmación antes de ejecutarse.

Los movimientos económicos afectarán al estado financiero del personaje. Por ejemplo, comprar acciones disminuirá el saldo disponible y aumentará la cantidad invertida.

Los precios de las inversiones deberán evolucionar de acuerdo con los datos históricos internos del escenario.

Las operaciones se realizarán mediante el banco al que se accede desde la puerta de la habitación.

El banco completo se desarrollará al final de la primera demo.

## 10. Necesidades y supervivencia

El personaje tendrá necesidades básicas que condicionarán sus finanzas y su calidad de vida.

### Alimentación

La nevera permitirá consultar la comida disponible, consumirla y comprar más.

Si el personaje pasa varios días sin comer, su salud o calidad de vida disminuirá.

La falta prolongada de alimentación podrá provocar su muerte y terminar la partida.

En el prototipo actual, la primera noche sin comer resta 15 puntos de salud; la pérdida sube 5 puntos por noche consecutiva hasta un máximo de 30. Comer reinicia la racha y, al descansar, permite recuperar hasta 10 puntos de salud. Son reglas provisionales y se ajustarán tras probar el ritmo de varios días.

### Necesidades fisiológicas

En el juego completo, el personaje deberá utilizar el baño periódicamente.

Ignorar esta necesidad afectará negativamente a su bienestar.

### Economía doméstica

El personaje tendrá ingresos mensuales y gastos generales.

La compra de comida, las deudas y otros compromisos económicos disminuirán su liquidez.

En futuras versiones, las llamadas telefónicas y los acontecimientos personales podrán introducir gastos inesperados y decisiones familiares.

## 11. Avance de los días

El jugador avanzará al día siguiente utilizando la cama.

Para hacerlo, deberá haber completado las decisiones financieras obligatorias del día.

Cuando avance el calendario, el videojuego actualizará:

- Noticias disponibles.
- Valor de las inversiones.
- Saldo y movimientos económicos.
- Gastos e ingresos correspondientes.
- Existencias de comida.
- Salud y necesidades.
- Acontecimientos narrativos.

El ciclo se repetirá hasta alcanzar una condición de derrota o un eventual final de escenario.

## 12. Condiciones de derrota

La partida terminará cuando el personaje:

1. Entre en bancarrota, según las reglas económicas establecidas.
2. Muera por falta de alimentación u otra causa de supervivencia.

La bancarrota deberá definirse teniendo en cuenta el patrimonio, las obligaciones y la capacidad de pago, no únicamente la ausencia de dinero líquido.

Al finalizar aparecerá una ficha con los errores cometidos, las decisiones más relevantes y las causas que provocaron el resultado.

El jugador podrá consultar dos explicaciones:

**Básica:** explicación comprensible, sin necesidad de conocimientos financieros previos.

**Técnica:** análisis detallado de liquidez, inversiones, riesgos, endeudamiento, gastos y consecuencias.

## 13. Alcance de la primera demo

La primera demo se centrará exclusivamente en el periodo anterior a la crisis financiera de 2008.

Deberá permitir experimentar un ciclo jugable completo:

Presentación → Habitación → Noticias → Lectura → Diccionario → Claude → Decisiones → Gestión financiera y vital → Dormir → Día siguiente.

Se desarrollarán primero el movimiento, las interacciones, las noticias, la memoria y el calendario.

Posteriormente se añadirán el diccionario, los cuestionarios, la economía doméstica, las gráficas financieras y el asistente Claude.

Finalmente se desarrollarán el banco, las operaciones económicas completas y la evaluación de derrota.

El teléfono familiar, las necesidades fisiológicas detalladas y otros periodos históricos quedarán fuera del alcance inicial.

## 14. Principios fundamentales del desarrollo

El videojuego deberá cumplir los siguientes principios:

1. Coherencia histórica: los acontecimientos y datos reales estarán asociados a sus fechas correctas.
2. Ausencia de información futura: el jugador no podrá obtener conocimiento de sucesos posteriores al día de la partida.
3. Anonimización consistente: las entidades reales conservarán siempre el mismo nombre ficticio.
4. Aprendizaje financiero: las decisiones deberán enseñar conceptos aplicables a la realidad.
5. Consecuencias verificables: las variaciones económicas dependerán de reglas programadas y no de respuestas arbitrarias de la IA.
6. Separación entre información y decisión: Claude orientará al jugador, pero no decidirá por él.
7. Trazabilidad: se conservarán las fuentes históricas, los datos de mercado y las decisiones realizadas.
8. Seguridad: las claves y credenciales de servicios externos no se almacenarán en el cliente ni en GitHub.
9. Desarrollo incremental: cada sistema se implementará, probará y validará antes de comenzar el siguiente.
10. Documentación continua: las decisiones de diseño y el progreso técnico se registrarán para evitar contradicciones y trabajo duplicado.

**Objetivo final:** construir una experiencia en la que el jugador aprenda a tomar decisiones financieras bajo incertidumbre, comprenda los acontecimientos económicos desde la perspectiva de quienes los vivieron y pueda reconocer los errores de su propia estrategia.
