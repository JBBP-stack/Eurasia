# Servicio intermedio del asistente (Claude)

El portátil del juego no llama a Claude directamente. Envía una petición a este servicio local,
que guarda la clave de la API, controla qué información se envía y filtra la respuesta.

## Puesta en marcha

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export ANTHROPIC_API_KEY=...        # o bien: ant auth login
python servidor_asistente/servidor.py
```

Para probar el flujo sin clave y sin coste:

```bash
python servidor_asistente/servidor.py --simulado
```

Después abre el juego en Godot, recoge todos los periódicos del día y usa el portátil (pestaña «Asistente»).

## Qué controla el servicio

- **Clave**: solo vive en el entorno del servidor. Nunca en Godot ni en GitHub (`.env` ya está en `.gitignore`).
- **Información enviada**: el juego manda el día y los *identificadores* de las noticias recogidas. El servicio
  carga los textos anonimizados de `godot/datos/noticias/` y rechaza noticias que no sean del día actual.
  Nunca se envían a Claude los campos `origen` (datos reales) ni `falsa`.
- **Límites del asistente**: el *prompt* de sistema le impide revelar la época, hablar del futuro, señalar la
  respuesta correcta de un cuestionario u ordenar compras o ventas.
- **Filtro de salida**: se ocultan los nombres reales de `datos/anonimizacion.json` y los años iguales o
  posteriores al de la partida.
- **Red**: escucha solo en `127.0.0.1:8787` (configurable con `--puerto` o `EURASIA_PUERTO`; en el juego,
  `asistente/url_servicio` de `godot/datos/reglas_demo.json`).

## Modelo

`claude-opus-5-5` con esfuerzo `medium`. Tiene activado el *fallback* del servidor
(`fallbacks="default"`): si el modelo rechaza una petición por sus filtros de seguridad, la API la
reintenta con un modelo alternativo. Para desactivarlo, elimina `betas` y `fallbacks` en `consultar_claude()`.
Cada consulta tiene coste en la cuenta de Anthropic asociada a la clave.
