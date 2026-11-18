#!/usr/bin/env python3
"""Junta varios outfits.json (formato de tools/catalog.py) en src/server/Outfits.luau.
Uso: python3 tools/merge_outfits.py carpeta_o_json [carpeta_o_json ...]
Las carpetas se recorren buscando */outfits.json. Si un id aparece dos veces, gana el último.
"""
import json, os, sys, glob
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "src", "server", "Outfits.luau")
LIST_FIELDS = ["hat", "hair", "face", "neck", "shoulders", "front", "back", "waist"]
LAYER_TYPES = {"Shirt", "Pants", "Jacket", "Sweater", "Shorts", "DressSkirt", "TShirt", "LeftShoe", "RightShoe"}

def files(args):
    for a in args:
        if os.path.isdir(a):
            yield from sorted(glob.glob(os.path.join(a, "**", "outfits.json"), recursive=True))
        else:
            yield a

def ids(v):
    out = []
    for x in v or []:
        try:
            n = int(x)
        except (TypeError, ValueError):
            continue
        if n > 0:
            out.append(n)
    return out

def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'

def main():
    merged = {}
    for f in files(sys.argv[1:]):
        data = json.load(open(f))
        for k, v in data.items():
            merged[k] = v
    lines = [
        "-- Ropa real del catálogo de Roblox para cada personaje (dioses, guardianes y vendedores).",
        "-- Generado con tools/merge_outfits.py a partir de los conjuntos elegidos mirando las miniaturas",
        "-- y comprobados en un servidor real con tools/catalog.py check.",
        "-- Campos: hat, hair, face, neck, shoulders, front, back, waist = { ids } · layered = { { type, id } }",
        "--         shirt, pants = id · keep = { \"item\", \"head\", \"wings\" } (piezas propias que se conservan)",
        "return {",
    ]
    for k in sorted(merged):
        o = merged[k]
        parts = []
        for f in LIST_FIELDS:
            v = ids(o.get(f))
            if v:
                parts.append(f"{f} = {{ {', '.join(str(x) for x in v)} }}")
        lay = []
        for l in o.get("layered") or []:
            if l.get("type") in LAYER_TYPES and ids([l.get("id")]):
                lay.append(f"{{ type = {lua_str(l['type'])}, id = {int(l['id'])} }}")
        if lay:
            parts.append(f"layered = {{ {', '.join(lay)} }}")
        for f in ("shirt", "pants"):
            v = ids([o.get(f)])
            if v:
                parts.append(f"{f} = {v[0]}")
        keep = [x for x in (o.get("keep") if o.get("keep") is not None else ["item"]) if x in ("item", "head", "wings")]
        parts.append(f"keep = {{ {', '.join(lua_str(x) for x in keep)} }}")
        note = o.get("note")
        if note:
            lines.append(f"\t-- {str(note).replace(chr(10), ' ')[:180]}")
        lines.append(f"\t{k} = {{ {', '.join(parts)} }},")
    lines.append("}")
    open(OUT, "w").write("\n".join(lines) + "\n")
    print(f"{len(merged)} personajes -> {OUT}")

if __name__ == "__main__":
    main()
