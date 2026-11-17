#!/usr/bin/env python3
"""Compila ESTA copia del juego, la sube como borrador (Saved, no publicado) y ejecuta cosas contra esa versión exacta.

  python3 tools/preview.py build
      → compila y sube; imprime VERSION=N

  python3 tools/preview.py run tools/test_full.luau [--version N]
      → ejecuta un script Luau en un servidor de Roblox contra la versión N (si no se da, compila y sube antes)

  python3 tools/preview.py render --views vistas.json --out carpeta [--export tools/export_scene.luau] [--version N]
      → exporta las piezas del mundo y dibuja las vistas en PNG (aproximado: sin texturas, partículas, luces ni carteles)
        vistas.json: [{"name":"fuente","cam":[camX,camY,camZ, miraX,miraY,miraZ, fov]}, ...]

Cada copia de trabajo sube su propia versión y ejecuta contra ella, así varias copias no se pisan.
Los jugadores no ven nada de esto: solo ven la versión PUBLICADA.
"""
import json, os, subprocess, sys, socket, tempfile, time, urllib.request, urllib.error
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
MAIN_RENDER = "/home/user/Delta-Executer-Bots/roblox/steal-a-god/tools/render"
U, P = "2181650191", "6031775954"
sys.path.insert(0, HERE)
import lx  # noqa: E402

def build_and_upload():
    out = os.path.join(tempfile.mkdtemp(prefix="sag_"), "place.rbxlx")
    r = subprocess.run([os.path.expanduser("~/bin/rojo"), "build", os.path.join(ROOT, "default.project.json"), "-o", out], capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout + r.stderr)
        sys.exit("ERROR: rojo build falló")
    data = open(out, "rb").read()
    last = None
    for attempt in range(5):
        try:
            req = urllib.request.Request(f"https://apis.roblox.com/universes/v1/{U}/places/{P}/versions?versionType=Saved", data=data, method="POST",
                                         headers={"x-api-key": "proxy-injected", "Content-Type": "application/xml"})
            with urllib.request.urlopen(req, timeout=120) as resp:
                return json.loads(resp.read().decode())["versionNumber"]
        except Exception as e:  # reintenta ante fallos de red o límites
            last = e
            time.sleep(5 + attempt * 5)
    sys.exit(f"ERROR: no se pudo subir el borrador: {last}")

def arg(name, default=None):
    if name in sys.argv:
        return sys.argv[sys.argv.index(name) + 1]
    return default

def ensure_server():
    s = socket.socket()
    try:
        s.settimeout(1)
        s.connect(("127.0.0.1", 8765))
    except OSError:
        subprocess.Popen([sys.executable, "-m", "http.server", "8765"], cwd=MAIN_RENDER, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        time.sleep(1.5)
    finally:
        s.close()

def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("build", "run", "render"):
        sys.exit(__doc__)
    cmd = sys.argv[1]
    version = arg("--version")
    if not version:
        version = build_and_upload()
    print(f"VERSION={version}")
    if cmd == "build":
        return
    if cmd == "run":
        print("\n".join(lx.run(sys.argv[2], version)))
        return
    views, out = arg("--views"), arg("--out")
    if not views or not out:
        sys.exit("render necesita --views y --out")
    out, views = os.path.abspath(out), os.path.abspath(views)
    os.makedirs(out, exist_ok=True)
    export = arg("--export", os.path.join(HERE, "export_scene.luau"))
    lines = lx.run(export, version)
    scene = os.path.join(out, "scene.txt")
    open(scene, "w").write("\n".join(lines))
    if not any(";" in l and l.startswith(("box", "ball", "cyl", "wedge", "head")) for l in lines):
        print("\n".join(l[:600] for l in lines[:12]))
        sys.exit("ERROR: la exportación no devolvió piezas")
    ensure_server()
    r = subprocess.run(["node", os.path.join(MAIN_RENDER, "render.mjs"), scene, os.path.abspath(out), os.path.abspath(views)], cwd=MAIN_RENDER, capture_output=True, text=True)
    print(r.stdout[-2000:] + r.stderr[-2000:])
    if r.returncode != 0:
        sys.exit("ERROR: el dibujo falló")

if __name__ == "__main__":
    main()
