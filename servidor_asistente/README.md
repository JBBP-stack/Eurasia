# Servicio intermedio del asistente (Claude)

El portátil del juego no llama a Claude directamente. Envía una petición a este servicio local,
que guarda la clave de la API, controla qué información se envía y filtra la respuesta.

## Puesta en marcha

1. Instala las dependencias en el `.venv` del proyecto (solo una vez):

   ```bash
   python3 -m venv .venv
   .venv/bin/pip install -r requirements.txt
   ```

2. Copia `.env.example` como `.env` en la raíz del proyecto y escribe tu clave:
   `ANTHROPIC_API_KEY=...` (el archivo `.env` no se sube a GitHub).
3. Juega normalmente: al usar el asistente en el portátil, el juego **arranca el servicio solo**
   (con el Python del `.venv`) y lo detiene al cerrarse.

También puedes arrancarlo a mano (por ejemplo, para ver sus registros):

```bash
.venv/bin/python servidor_asistente/servidor.py              # con Claude
.venv/bin/python servidor_asistente/servidor.py --simulado   # respuesta de prueba, sin coste
```

Si falta la clave o el SDK, el servicio arranca igualmente y el juego muestra qué hay que configurar.

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
