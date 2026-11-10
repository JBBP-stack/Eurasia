"""Valida estructura y consistencia de los datos del escenario (sin acceso a Internet).

Comprueba noticias, preguntas, anonimización, mercado y reglas. Uso:
    python tools/validar_noticias.py
"""
import json
import re
from pathlib import Path

datos = Path(__file__).resolve().parent.parent / "godot" / "datos"


def leer(ruta: Path):
    return json.loads(ruta.read_text(encoding="utf-8"))


noticias = leer(datos / "noticias" / "noticias_2008.json")["noticias"]
preguntas = leer(datos / "noticias" / "preguntas_2008.json")["preguntas"]
anonimizacion = leer(datos / "anonimizacion.json")
mercado = leer(datos / "mercado" / "mercado_2008.json")
reglas = leer(datos / "reglas_demo.json")

fecha_inicio = reglas["calendario"]["fecha_inicio"]
fecha_fin = reglas["calendario"]["fecha_fin_escenario"]
CAMPOS_VISIBLES = ("titulo", "resumen", "medio")
EFECTOS_PERMITIDOS = {"prudencia", "riesgo", "saldo_bancario_centimos", "efectivo_centimos", "comida", "salud"}
prohibidos = set(anonimizacion["terminos_prohibidos"]) | {e["real"] for e in anonimizacion["entidades"]}

# --- Noticias ---
ids = set()
falsas = 0
archivo = 0
sin_enlace = []
for noticia in noticias:
    identificador = noticia["id"]
    assert identificador not in ids, f"ID duplicado: {identificador}"
    ids.add(identificador)
    for campo in CAMPOS_VISIBLES:
        assert str(noticia.get(campo, "")).strip(), f"{identificador}: falta '{campo}'"
        for termino in prohibidos:
            assert not re.search(r"\b" + re.escape(termino), noticia[campo], re.IGNORECASE), \
                f"{identificador}: el campo visible '{campo}' contiene el término real «{termino}»"
    assert re.fullmatch(r"\d{4}-\d{2}-\d{2}", noticia["disponible_desde"]), identificador
    assert isinstance(noticia.get("falsa"), bool), f"{identificador}: 'falsa' debe ser booleano"
    origen = noticia["origen"]
    if noticia.get("archivo"):
        archivo += 1
        assert noticia["disponible_desde"] < fecha_inicio, f"{identificador}: la hemeroteca debe ser anterior al inicio"
        assert not noticia["pregunta_id"] and not noticia["falsa"], f"{identificador}: la hemeroteca no lleva cuestionario ni es falsa"
    if noticia["falsa"]:
        falsas += 1
        assert not noticia["pregunta_id"], f"{identificador}: una noticia falsa no debe tener cuestionario"
    else:
        assert origen["fecha_publicacion"] <= noticia["disponible_desde"], identificador
        assert origen["titulo_real"].strip() and origen["fuente"].strip(), identificador
        if origen["fuente_url"]:
            assert origen["fuente_url"].startswith("https://"), identificador
        else:
            sin_enlace.append(identificador)
    pregunta_id = noticia["pregunta_id"]
    if pregunta_id:
        assert pregunta_id in preguntas, identificador

# --- Preguntas ---
for pregunta_id, pregunta in preguntas.items():
    opciones = pregunta["opciones"]
    assert len(opciones) == 3, pregunta_id
    assert len({o["id"] for o in opciones}) == 3, pregunta_id
    assert sum(1 for o in opciones if o.get("adecuada") is True) == 1, f"{pregunta_id}: debe haber exactamente una opción adecuada"
    for opcion in opciones:
        claves = set(opcion["efecto"])
        assert claves <= EFECTOS_PERMITIDOS, f"{pregunta_id}/{opcion['id']}: efectos no admitidos {claves - EFECTOS_PERMITIDOS}"
    for termino in prohibidos:
        texto = pregunta["enunciado"] + " ".join(o["texto"] + o["explicacion"] for o in opciones)
        assert not re.search(r"\b" + re.escape(termino), texto, re.IGNORECASE), f"{pregunta_id}: contiene el término real «{termino}»"

# Al menos una noticia programada por día de partida.
from datetime import date, timedelta
dia = date.fromisoformat(fecha_inicio)
while dia <= date.fromisoformat(fecha_fin):
    assert any(n["disponible_desde"] == dia.isoformat() and not n.get("archivo") and not n["falsa"] for n in noticias), \
        f"No hay noticias auténticas para el {dia.isoformat()}"
    dia += timedelta(days=1)

# --- Mercado ---
ids_activos = set()
for activo in mercado["activos"]:
    assert activo["id"] not in ids_activos, f"Activo duplicado: {activo['id']}"
    ids_activos.add(activo["id"])
    precios = activo["precios_centimos"]
    assert min(precios) <= fecha_inicio, f"{activo['id']}: no hay precio en o antes de la fecha de inicio"
    assert max(precios) >= fecha_fin, f"{activo['id']}: la serie no llega al final del escenario"
    assert all(isinstance(v, int) and v > 0 for v in precios.values()), f"{activo['id']}: precios no válidos"
assert len(ids_activos) <= 10, "El catálogo supera el máximo de 10 posiciones"
inicial = reglas["situacion_inicial"]["cartera"]
assert {p["id"] for p in inicial} <= ids_activos, "La cartera inicial usa activos que no están en el mercado"
assert len(ids_activos) > len(inicial), "Debe haber empresas en las que el jugador no tenga acciones al principio"
activos = {a["id"]: a for a in mercado["activos"]}
caidas = [p["id"] for p in inicial if re.match(r"(Quiebra|Intervenida)", activos[p["id"]]["destino_real"])]
assert len(caidas) * 2 >= len(inicial), "Al menos la mitad de la cartera inicial debe ser de empresas quebradas o intervenidas"
valor_inicial = sum(p["acciones"] * activos[p["id"]]["precios_centimos"]["2008-08-29"] for p in inicial)
efectivo = reglas["situacion_inicial"]["efectivo_centimos"]
assert efectivo >= 200000, "El jugador debe empezar con al menos 2.000 € en efectivo"

# --- Reglas ---
estado = (datos.parent / "sistemas" / "EstadoJuego.gd").read_text(encoding="utf-8")
assert f'FECHA_INICIO_PROVISIONAL: String = "{fecha_inicio}"' in estado, \
    "calendario/fecha_inicio no coincide con EstadoJuego.FECHA_INICIO_PROVISIONAL"
assert 0.0 <= reglas["noticias"]["probabilidad_noticia_falsa"] <= 1.0

print(f"Datos coherentes: {len(noticias)} noticias ({archivo} de hemeroteca, {falsas} falsas), {len(preguntas)} preguntas, "
      f"{len(ids_activos)} activos. Cartera inicial: {valor_inicial / 100:.2f} € (quebradas o intervenidas: {', '.join(caidas)}).")
no_verificados = [a["id"] for a in mercado["activos"] if not a.get("verificado")]
if no_verificados:
    print(f"AVISO: series de precios no verificadas del todo: {', '.join(no_verificados)}.")
if sin_enlace:
    print(f"AVISO: {len(sin_enlace)} noticias reales sin enlace a la fuente primaria.")
print("Falta auditoría humana de fuentes, licencias y equivalencias reales de los activos.")
