#!/usr/bin/env python3
# Sube un .ogg a la cuenta de Roblox como Audio y devuelve su ID. ¡Cada subida cuenta para el cupo mensual!
# Uso: python3 tools/audio/upload_audio.py archivo.ogg "Nombre" ["Descripción"]
import json, sys, time, urllib.request, urllib.error, uuid
USER = "2054465776"
path, name = sys.argv[1], sys.argv[2]
desc = sys.argv[3] if len(sys.argv) > 3 else "Steal a God - original audio"
boundary = uuid.uuid4().hex
req = json.dumps({"assetType": "Audio", "displayName": name, "description": desc, "creationContext": {"creator": {"userId": USER}}})
body = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\nContent-Type: application/json\r\n\r\n{req}\r\n"
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"audio.ogg\"\r\nContent-Type: audio/ogg\r\n\r\n").encode() + open(path, "rb").read() + f"\r\n--{boundary}--\r\n".encode()
r = urllib.request.Request("https://apis.roblox.com/assets/v1/assets", data=body, method="POST",
                           headers={"x-api-key": "proxy-injected", "Content-Type": f"multipart/form-data; boundary={boundary}"})
try:
    op = json.loads(urllib.request.urlopen(r, timeout=180).read())
except urllib.error.HTTPError as e:
    print("ERROR HTTP", e.code, e.read().decode()[:600])
    sys.exit(1)
print("operación:", op.get("path"))
for _ in range(80):
    if op.get("done"):
        break
    time.sleep(3)
    q = urllib.request.Request("https://apis.roblox.com/assets/v1/" + op["path"], headers={"x-api-key": "proxy-injected"})
    op = json.loads(urllib.request.urlopen(q, timeout=60).read())
print(json.dumps(op, ensure_ascii=False)[:900])
