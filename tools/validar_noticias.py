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
EFECTOS_PERMITIDOS = {"prudencia", "riesgo", "saldo_bancario_centimos", "efectivo_centimos", "comida", "salud",
                      "vender", "vender_todo", "comprar"}
ids_mercado = {a["id"] for a in mercado["activos"]}
prohibidos = set(anonimizacion["terminos_prohibidos"]) | {e["real"] for e in anonimizacion["entidades"]}

# --- Noticias ---
ids = set()
falsas = 0
archivo = 0
referencias_pendientes = []
for noticia in noticias:
    identificador = noticia["id"]
    assert identificador not in ids, f"ID duplicado: {identificador}"
    ids.add(identificador)
    assert noticia.get("seccion"), f"{identificador}: falta 'seccion'"
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
        fuente = str(origen.get("fuente", "")).strip().lower()
        if (
            not fuente
            or "referencia bibliográfica pendiente" in fuente
            or "pendiente de concretar" in fuente
        ):
            referencias_pendientes.append(identificador)
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
        for clave in ("vender", "comprar"):
            for activo_id, valor in opcion["efecto"].get(clave, {}).items():
                assert activo_id in ids_mercado, f"{pregunta_id}/{opcion['id']}: activo desconocido {activo_id}"
                assert valor > 0 and (clave != "vender" or valor <= 100), f"{pregunta_id}/{opcion['id']}: valor no válido en '{clave}'"
    for termino in prohibidos:
        texto = pregunta["enunciado"] + " ".join(o["texto"] + o["explicacion"] for o in opciones)
        assert not re.search(r"\b" + re.escape(termino), texto, re.IGNORECASE), f"{pregunta_id}: contiene el término real «{termino}»"

# Al menos una noticia programada por día de partida.
from datetime import date, timedelta
dia = date.fromisoformat(fecha_inicio)
while dia <= date.fromisoformat(fecha_fin):
    del_dia = [n for n in noticias if n["disponible_desde"] == dia.isoformat() and not n.get("archivo")]
    autenticas = [n for n in del_dia if not n["falsa"]]
    assert len(autenticas) >= 2, f"El {dia.isoformat()} necesita al menos 2 noticias auténticas"
    assert any(n["pregunta_id"] for n in autenticas), f"El {dia.isoformat()} necesita al menos una decisión"
    assert len(del_dia) <= 5, f"El {dia.isoformat()} supera las 5 noticias"
    assert any(n.get("seccion") not in ("Economía", "Economía de Liria") for n in autenticas), \
        f"El {dia.isoformat()} solo tiene noticias económicas: añade una primera plana general"
    dia += timedelta(days=1)

# Diálogos de la gestora del banco: uno o más comentarios por día y sin términos reales.
dialogos = leer(datos / "atencion_bancaria.json")
dia = date.fromisoformat(fecha_inicio)
while dia <= date.fromisoformat(fecha_fin):
    assert dialogos["por_fecha"].get(dia.isoformat()), f"La gestora no tiene comentarios para el {dia.isoformat()}"
    dia += timedelta(days=1)
for lineas in dialogos["por_fecha"].values():
    for linea in lineas:
        for termino in prohibidos:
            assert not re.search(r"\b" + re.escape(termino), linea, re.IGNORECASE), f"Diálogo con término real «{termino}»: {linea[:50]}"

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
def precio_cierre(activo, fecha):
    previas = [f for f in activo["precios_centimos"] if f <= fecha]
    return activo["precios_centimos"][max(previas)]
valor_inicial = sum(p["acciones"] * precio_cierre(activos[p["id"]], fecha_inicio) for p in inicial)
efectivo = reglas["situacion_inicial"]["efectivo_centimos"]
assert efectivo >= 200000, "El jugador debe empezar con al menos 2.000 € en efectivo"

# --- Reglas ---
estado = (datos.parent / "sistemas" / "EstadoJuego.gd").read_text(encoding="utf-8")
assert f'FECHA_INICIO_PROVISIONAL: String = "{fecha_inicio}"' in estado, \
    "calendario/fecha_inicio no coincide con EstadoJuego.FECHA_INICIO_PROVISIONAL"
assert 0.0 <= reglas["noticias"]["probabilidad_noticia_falsa"] <= 1.0

diccionario = leer(datos / "diccionario_financiero.json")["terminos"]
assert len(diccionario) >= 50, "El diccionario debería tener al menos 50 términos"
print(f"Diccionario: {len(diccionario)} términos.")
print(f"Datos coherentes: {len(noticias)} noticias ({archivo} de hemeroteca, {falsas} falsas), {len(preguntas)} preguntas, "
      f"{len(ids_activos)} activos. Cartera inicial: {valor_inicial / 100:.2f} € (quebradas o intervenidas: {', '.join(caidas)}).")
no_verificados = [a["id"] for a in mercado["activos"] if not a.get("verificado")]
if no_verificados:
    print(f"AVISO: series de precios no verificadas del todo: {', '.join(no_verificados)}.")
if referencias_pendientes:
    print(f"AVISO: {len(referencias_pendientes)} noticias reales necesitan concretar su referencia; la URL es opcional.")
print("Falta auditoría humana de fuentes, licencias y equivalencias reales de los activos.")
