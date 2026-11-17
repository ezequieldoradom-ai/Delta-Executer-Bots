#!/usr/bin/env python3
# Ejecuta un script Luau en un servidor de Roblox (Open Cloud Luau Execution) y muestra el resultado.
# Uso: python3 tools/lx.py prueba.luau
import json, sys, time, urllib.request, os
U, P = "2181650191", "6031775954"
BASE = "https://apis.roblox.com/cloud/v2/"
def req(method, url, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method, headers={"x-api-key": "proxy-injected", "Content-Type": "application/json"})
    with urllib.request.urlopen(r, timeout=60) as resp:
        return json.loads(resp.read().decode())
script = open(sys.argv[1]).read()
task = req("POST", f"{BASE}universes/{U}/places/{P}/luau-execution-session-tasks", {"script": script, "timeout": "240s"})
path = task["path"]
for _ in range(150):
    time.sleep(2)
    task = req("GET", BASE + path)
    if task["state"] not in ("QUEUED", "PROCESSING"):
        break
print("ESTADO:", task["state"])
if task.get("error"):
    print("ERROR:", json.dumps(task["error"], ensure_ascii=False))
for r in (task.get("output") or {}).get("results", []):
    print(r if isinstance(r, str) else json.dumps(r, ensure_ascii=False))
try:
    logs = req("GET", BASE + path + "/logs")
    for chunk in logs.get("luauExecutionSessionTaskLogs", []):
        for m in chunk.get("messages", []):
            print("LOG:", m)
except Exception as e:
    print("(sin logs)", e)
