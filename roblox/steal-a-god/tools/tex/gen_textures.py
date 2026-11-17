# Genera texturas en escala de grises (se tiñen en Roblox con Texture.Color3) y repetibles sin costuras.
# Uso: python3 gen_textures.py carpeta_salida
import sys, os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
N = 512
rng = np.random.default_rng(7)

def noise(scale, n=N):
    """Ruido fractal periódico (se repite sin costuras) entre 0 y 1."""
    f = np.fft.fftfreq(n)
    fx, fy = np.meshgrid(f, f)
    r = np.sqrt(fx ** 2 + fy ** 2)
    r[0, 0] = 1
    spec = (rng.normal(size=(n, n)) + 1j * rng.normal(size=(n, n))) / (r ** scale)
    spec[0, 0] = 0
    a = np.real(np.fft.ifft2(spec))
    return (a - a.min()) / (a.max() - a.min())

def save(name, rgb, alpha):
    rgb = np.clip(rgb, 0, 1)
    if rgb.ndim == 2:
        rgb = np.stack([rgb] * 3, -1)
    img = np.dstack([rgb, np.clip(alpha, 0, 1)])
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".png"))
    print("ok", name)

def blocks(rows, widths, grout, bevel, seed_shift=0):
    """Piedras/ladrillos: devuelve (luz, alfa)."""
    h = N // rows
    light = np.zeros((N, N))
    edge = np.full((N, N), 1e9)
    yy, xx = np.mgrid[0:N, 0:N]
    for r in range(rows):
        y0 = r * h
        x = (r % 2) * (N // (2 * len(widths))) + seed_shift
        k = 0
        while x < N + N:
            w = widths[(r * 3 + k) % len(widths)]
            # brillo distinto por pieza
            tone = 0.82 + 0.18 * rng.random()
            xs = np.arange(x, x + w) % N
            for yy_ in range(y0, y0 + h):
                light[yy_, xs] = tone
            # distancia al borde de la pieza (bisel)
            for yy_ in range(y0, y0 + h):
                dy = min(yy_ - y0, y0 + h - 1 - yy_)
                dx = np.minimum(np.arange(w), np.arange(w)[::-1])
                d = np.minimum(dx, dy)
                edge[yy_, xs] = np.minimum(edge[yy_, xs], d)
            x += w
            k += 1
            if k >= len(widths):
                break
    g = edge < grout
    bev = np.clip((edge - grout) / bevel, 0, 1)
    shade = light * (0.72 + 0.28 * bev)
    return shade, g

# 1) losas de piedra (suelos de plaza, parcelas y pasillo)
n1, n2 = noise(1.6), noise(2.4)
shade, g = blocks(4, [128, 128, 128, 128], 4, 18)
lum = shade * (0.85 + 0.15 * n1) - 0.08 * (n2 > 0.72)
lum[g] = 0.18
alpha = np.where(g, 0.85, 0.32 + 0.25 * (1 - shade) + 0.15 * n2)
save("paving", lum, alpha)

# 2) sillares grandes (murallas)
shade, g = blocks(4, [128, 96, 160, 128], 3, 14, 30)
lum = shade * (0.8 + 0.2 * noise(1.8)) - 0.1 * (noise(2.6) > 0.75)
lum[g] = 0.15
alpha = np.where(g, 0.8, 0.28 + 0.3 * (1 - shade))
save("ashlar", lum, alpha)

# 3) ladrillos (parcelas de nivel bajo, Babilonia)
shade, g = blocks(8, [64, 96, 64, 96, 64, 128], 3, 6)
lum = shade * (0.8 + 0.2 * noise(2.0))
lum[g] = 0.2
alpha = np.where(g, 0.85, 0.3 + 0.35 * (1 - shade))
save("bricks", lum, alpha)

# 4) suciedad, grietas y desgaste (se pone encima de muros y bases)
n = noise(1.4)
cr = noise(2.8)
lines = np.abs(cr - 0.5) < 0.012
lum = 0.15 + 0.2 * n
alpha = np.clip((n - 0.55) * 1.6, 0, 0.55) + lines * 0.55
save("grime", lum, alpha)

# 5) hierba con briznas
img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
for _ in range(5500):
    x, y = rng.random() * N, rng.random() * N
    l = 6 + rng.random() * 12
    a = -math.pi / 2 + (rng.random() - 0.5) * 0.9
    c = int(150 + rng.random() * 105)
    for ox in (-N, 0, N):
        for oy in (-N, 0, N):
            d.line([(x + ox, y + oy), (x + ox + math.cos(a) * l, y + oy + math.sin(a) * l)], fill=(c, c, c, int(90 + rng.random() * 110)), width=2)
save_img = img.filter(ImageFilter.GaussianBlur(0.4))
save_img.save(os.path.join(OUT, "grass.png")); print("ok grass")

# 6) greca griega (banda dorada repetible en horizontal)
img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
u = N // 8  # unidad
w = int(u * 0.38)
for k in range(2):
    x0 = k * N // 2
    pts = [(x0 + u * 0.5, u * 7), (x0 + u * 0.5, u * 1), (x0 + u * 3.5, u * 1), (x0 + u * 3.5, u * 5.5),
           (x0 + u * 2, u * 5.5), (x0 + u * 2, u * 3), (x0 + u * 2.6, u * 3)]
    d.line(pts, fill=(255, 255, 255, 255), width=w, joint="curve")
    d.line([(x0 + u * 0.5, u * 7), (x0 + u * 4.5, u * 7)], fill=(255, 255, 255, 255), width=w)
d.rectangle([0, 0, N, int(u * 0.25)], fill=(255, 255, 255, 255))
d.rectangle([0, N - int(u * 0.25), N, N], fill=(255, 255, 255, 255))
img.save(os.path.join(OUT, "meander.png")); print("ok meander")

# 7) relieve tallado: marco con roseta (paneles, altares, pedestales)
yy, xx = np.mgrid[0:N, 0:N] / N - 0.5
r = np.sqrt(xx ** 2 + yy ** 2)
ang = np.arctan2(yy, xx)
frame = np.maximum(np.abs(xx), np.abs(yy))
lum = np.full((N, N), 0.6)
al = np.zeros((N, N))
for lo, hi, v in [(0.44, 0.47, 1.0), (0.40, 0.42, 0.3), (0.36, 0.38, 0.95)]:
    m = (frame > lo) & (frame < hi)
    lum[m] = v; al[m] = 0.75
petals = (r < 0.22) & (np.cos(ang * 8) * 0.06 + 0.16 > r)
lum[petals] = 0.95; al[petals] = 0.7
ring = (r > 0.24) & (r < 0.26)
lum[ring] = 1.0; al[ring] = 0.8
core = r < 0.05
lum[core] = 1; al[core] = 0.9
save("carved", lum, al)

# 8) rayos (caras de los sobres)
rays = (np.cos(ang * 16) > 0.55) * np.clip(1 - r * 1.6, 0, 1)
glow = np.clip(1 - r * 2.2, 0, 1) ** 2
lum = np.ones((N, N))
save("rays", lum, np.clip(rays * 0.65 + glow * 0.6, 0, 1))

# 9) geometría sagrada / hexágonos (niveles altos, cósmico)
s = N / 8
q = (xx + 0.5) * N
p = (yy + 0.5) * N
best = np.full((N, N), 1e9)
for i in range(-1, 10):
    for j in range(-1, 10):
        cx = i * s * 1.5
        cy = j * s * math.sqrt(3) + (i % 2) * s * math.sqrt(3) / 2
        best = np.minimum(best, np.hypot(q - cx, p - cy))
hexl = np.abs(best - s * 0.86) < 2.2
lum = np.ones((N, N))
save("hexgrid", lum, hexl * 0.8 + np.clip(0.2 - best / (s * 6), 0, 0.2))
