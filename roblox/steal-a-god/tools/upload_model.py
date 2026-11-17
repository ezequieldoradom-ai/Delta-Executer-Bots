#!/usr/bin/env python3
# Sube un .fbx a la cuenta de Roblox como Modelo y devuelve su ID.
# Uso: python3 tools/upload_model.py archivo.fbx "Nombre"
import json, sys, time, urllib.request, uuid
USER = "2054465776"
path, name = sys.argv[1], sys.argv[2]
boundary = uuid.uuid4().hex
req = json.dumps({"assetType": "Model", "displayName": name, "description": "Steal a God", "creationContext": {"creator": {"userId": USER}}})
body = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\nContent-Type: application/json\r\n\r\n{req}\r\n"
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"m.fbx\"\r\nContent-Type: model/fbx\r\n\r\n").encode() + open(path, "rb").read() + f"\r\n--{boundary}--\r\n".encode()
r = urllib.request.Request("https://apis.roblox.com/assets/v1/assets", data=body, method="POST",
                           headers={"x-api-key": "proxy-injected", "Content-Type": f"multipart/form-data; boundary={boundary}"})
op = json.loads(urllib.request.urlopen(r, timeout=120).read())
for _ in range(60):
    if op.get("done"):
        break
    time.sleep(3)
    q = urllib.request.Request("https://apis.roblox.com/assets/v1/" + op["path"], headers={"x-api-key": "proxy-injected"})
    op = json.loads(urllib.request.urlopen(q, timeout=60).read())
resp = op.get("response", {})
print(name, resp.get("assetId"), resp.get("moderationResult", {}).get("moderationState"))
