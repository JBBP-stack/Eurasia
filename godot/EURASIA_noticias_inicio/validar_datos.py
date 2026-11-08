"""Valida estructura y consistencia del dataset editorial (sin acceso a Internet)."""
import json
from pathlib import Path

base = Path(__file__).parent / "noticias" / "datos"
noticias = json.loads((base / "noticias_2008.json").read_text(encoding="utf-8"))["noticias"]
preguntas = json.loads((base / "preguntas_2008.json").read_text(encoding="utf-8"))["preguntas"]
ids = set()
for noticia in noticias:
    identificador = noticia["id"]
    assert identificador not in ids, f"ID duplicado: {identificador}"
    ids.add(identificador)
    assert noticia["fecha_publicacion"] <= noticia["disponible_desde"], identificador
    assert noticia["fuente_url"].startswith("https://"), identificador
    assert noticia["resumen"].strip() and noticia["titulo"].strip(), identificador
    pregunta_id = noticia["pregunta_id"]
    if pregunta_id:
        assert pregunta_id in preguntas, identificador
        opciones = preguntas[pregunta_id]["opciones"]
        assert len(opciones) == 3, pregunta_id
        assert len({o["id"] for o in opciones}) == 3, pregunta_id
print(f"Datos coherentes: {len(noticias)} noticias, {len(preguntas)} preguntas. Falta auditoría humana de fuentes y licencias.")
