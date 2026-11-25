#!/usr/bin/env python3
# Ejecuta un script Luau en un servidor de Roblox (Open Cloud Luau Execution) y muestra el resultado.
# Uso: python3 tools/lx.py prueba.luau [--version N]
#   --version N  ejecuta contra esa versión guardada del lugar (por defecto, la última guardada)
import json, sys, time, urllib.request, urllib.error
import json as _json, os as _os
_cfg = _json.load(open(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "..", "place.json")))
U, P = _cfg.get("universe", ""), _cfg.get("place", "")
if not U or not P:
    raise SystemExit("Falta el id de la experiencia en place.json (universe y place)")
BASE = "https://apis.roblox.com/cloud/v2/"
def req(method, url, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method, headers={"x-api-key": "proxy-injected", "Content-Type": "application/json"})
    last = None
    for attempt in range(5):
        try:
            with urllib.request.urlopen(r, timeout=60) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            last = e
            if e.code in (429, 500, 502, 503, 504):
                time.sleep(4 + attempt * 4)
                continue
            raise
        except urllib.error.URLError as e:
            last = e
            time.sleep(3 + attempt * 3)
    raise last
def run(script_path, version=None):
    script = open(script_path).read()
    where = f"universes/{U}/places/{P}/" + (f"versions/{version}/" if version else "")
    task = req("POST", BASE + where + "luau-execution-session-tasks", {"script": script, "timeout": "280s"})
    path = task["path"]
    for _ in range(170):
        time.sleep(2)
        task = req("GET", BASE + path)
        if task["state"] not in ("QUEUED", "PROCESSING"):
            break
    lines = ["ESTADO: " + task["state"]]
    if task.get("error"):
        lines.append("ERROR: " + json.dumps(task["error"], ensure_ascii=False))
    for r in (task.get("output") or {}).get("results", []):
        lines.append(r if isinstance(r, str) else json.dumps(r, ensure_ascii=False))
    try:
        logs = req("GET", BASE + path + "/logs")
        for chunk in logs.get("luauExecutionSessionTaskLogs", []):
            for m in chunk.get("messages", []):
                lines.append("LOG: " + m)
    except Exception as e:
        lines.append(f"(sin logs) {e}")
    return lines
if __name__ == "__main__":
    args = sys.argv[1:]
    version = None
    if "--version" in args:
        i = args.index("--version")
        version = args[i + 1]
        del args[i:i + 2]
    print("\n".join(run(args[0], version)))
