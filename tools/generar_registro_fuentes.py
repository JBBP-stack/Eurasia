"""Genera un índice legible de las referencias internas de EURASIA.

Uso desde la raíz del repositorio:
    python tools/generar_registro_fuentes.py

Los metadatos canónicos permanecen en los JSON del juego. Este índice es solo
documentación de desarrollo y no se muestra al jugador.
"""

from __future__ import annotations

import json
import re
from pathlib import Path


RAIZ = Path(__file__).resolve().parents[1]
RUTA_NOTICIAS = RAIZ / "godot" / "datos" / "noticias" / "noticias_2008.json"
RUTA_MERCADO = RAIZ / "godot" / "datos" / "mercado" / "mercado_2008.json"
RUTA_SALIDA = RAIZ / "docs" / "REGISTRO_FUENTES_HISTORICAS.md"


def cargar(ruta: Path) -> dict:
    with ruta.open(encoding="utf-8") as archivo:
        return json.load(archivo)


def celda(valor: object) -> str:
    texto = re.sub(r"\s+", " ", str(valor or "")).strip()
    return texto.replace("|", r"\|") or "—"


def estado_noticia(noticia: dict, origen: dict) -> str:
    if noticia.get("falsa", False):
        return "Ficticia; no requiere fuente"
    if origen.get("fuente_url"):
        return "Referencia y URL anotadas"
    fuente = str(origen.get("fuente", "")).lower()
    if not fuente or "pendiente de concretar" in fuente or "referencia bibliográfica pendiente" in fuente:
        return "Concretar la referencia"
    return "Fuente anotada; URL opcional"


def generar() -> None:
    noticias = cargar(RUTA_NOTICIAS).get("noticias", [])
    mercado = cargar(RUTA_MERCADO).get("activos", [])
    lineas = [
        "# Registro de fuentes históricas",
        "",
        "Índice de trabajo para rastrear los hechos que inspiran EURASIA. Es documentación interna: "
        "los nombres reales y las referencias no se muestran durante la partida.",
        "",
        "La URL directa es opcional. Cuando se investigue una noticia, basta con anotar aquí y en "
        "el campo origen del JSON el medio o institución, el título/documento y las fechas; si se "
        "encuentra, se añade también la URL. El JSON es la fuente canónica y este archivo se regenera "
        "con python tools/generar_registro_fuentes.py.",
        "",
        "## Noticias",
        "",
        "| ID | Fecha de juego | Hecho o titular real | Fecha del hecho / publicación | Fuente o nota actual | URL | Estado |",
        "|---|---|---|---|---|---|---|",
    ]

    for noticia in sorted(noticias, key=lambda n: (str(n.get("disponible_desde", "")), str(n.get("id", "")))):
        origen = noticia.get("origen") or {}
        if noticia.get("falsa", False):
            hecho_real = "Rumor ficticio"
        else:
            hecho_real = origen.get("titulo_real", "")
        fecha_evento = str(origen.get("fecha_evento", ""))
        fecha_publicacion = str(origen.get("fecha_publicacion", ""))
        fechas = fecha_evento
        if fecha_publicacion and fecha_publicacion != fecha_evento:
            fechas = f"{fecha_evento} / {fecha_publicacion}" if fecha_evento else fecha_publicacion
        lineas.append(
            "| "
            + " | ".join(
                celda(valor)
                for valor in (
                    noticia.get("id"),
                    noticia.get("disponible_desde"),
                    hecho_real,
                    fechas,
                    origen.get("fuente", "Ficticia; no aplica" if noticia.get("falsa", False) else ""),
                    origen.get("fuente_url"),
                    estado_noticia(noticia, origen),
                )
            )
            + " |"
        )

    lineas.extend(
        [
            "",
            "## Cotizaciones de mercado",
            "",
            "| ID | Empresa ficticia | Equivalencia real | Fechas cubiertas | Fuente / nota | Estado |",
            "|---|---|---|---|---|---|",
        ]
    )
    for activo in sorted(mercado, key=lambda a: str(a.get("id", ""))):
        fechas = sorted((activo.get("precios_centimos") or {}).keys())
        rango = f"{fechas[0]} – {fechas[-1]}" if fechas else "Sin cotizaciones"
        estado = "Verificada según el catálogo" if activo.get("verificado", False) else "Revisar; serie parcialmente aproximada"
        lineas.append(
            "| "
            + " | ".join(
                celda(valor)
                for valor in (
                    activo.get("id"),
                    activo.get("nombre"),
                    activo.get("equivalencia_real"),
                    rango,
                    activo.get("fuente"),
                    estado,
                )
            )
            + " |"
        )

    RUTA_SALIDA.write_text("\n".join(lineas) + "\n", encoding="utf-8")


if __name__ == "__main__":
    generar()
