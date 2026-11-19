# Texturas de suelos y cielos (repetibles sin costuras, 512x512):
#   galaxy  - galaxia de color (nebulosa morada/azul/rosa con estrellas)   -> suelo de la zona cósmica
#   stars   - estrellas blancas sobre transparente (se tiñen)              -> capa que se desplaza
#   cracks  - grietas blancas sobre transparente (se tiñen: lava, luz...)  -> suelos agrietados
#   aurora  - franjas verticales suaves para los haces de aurora del cielo
# Uso: python gen_sky_floor.py carpeta_salida
import sys, os
import numpy as np
from PIL import Image

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
N = 512
rng = np.random.default_rng(11)


def noise(scale, n=N):
    """Ruido fractal periódico entre 0 y 1."""
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


def star_field(count, rmin, rmax):
    yy, xx = np.mgrid[0:N, 0:N]
    out = np.zeros((N, N))
    for _ in range(count):
        cx, cy = rng.uniform(0, N, 2)
        r = rng.uniform(rmin, rmax)
        b = rng.uniform(0.5, 1)
        dx = (xx - cx + N / 2) % N - N / 2
        dy = (yy - cy + N / 2) % N - N / 2
        d2 = dx * dx + dy * dy
        out = np.maximum(out, b * np.exp(-d2 / (2 * r * r)))
        if r > rmax * 0.7:  # destello en cruz en las grandes
            cross = np.exp(-(dx * dx) / 0.8) * np.exp(-np.abs(dy) / (r * 4)) + np.exp(-(dy * dy) / 0.8) * np.exp(-np.abs(dx) / (r * 4))
            out = np.maximum(out, b * 0.8 * cross)
    return out


# --- galaxia ---
n1, n2, n3 = noise(2.2), noise(2.6), noise(1.8)
cloud = np.clip((n1 - 0.35) * 2.2, 0, 1) ** 1.4
wisps = np.clip((n3 - 0.45) * 3, 0, 1) ** 2
purple = np.array([0.55, 0.2, 0.95])
blue = np.array([0.1, 0.55, 1.0])
pink = np.array([1.0, 0.35, 0.75])
base = np.array([0.03, 0.02, 0.09])
mix = n2[..., None]
neb = purple * (1 - mix) + blue * mix
rgb = base + neb * cloud[..., None] * 0.9 + pink * wisps[..., None] * 0.5
stars = star_field(260, 0.6, 1.6) + star_field(18, 2, 3.4)
rgb = rgb + np.clip(stars, 0, 1)[..., None] * np.array([1, 1, 1])
save("galaxy", rgb, np.ones((N, N)))

# --- estrellas (capa transparente) ---
s = np.clip(star_field(180, 0.7, 1.8) + star_field(10, 2.2, 3.5), 0, 1)
save("stars", np.ones((N, N)), s)

# --- grietas: bordes de Voronoi periódico deformados por ruido ---
pts = rng.uniform(0, N, (34, 2))
yy, xx = np.mgrid[0:N, 0:N].astype(float)
warp = (noise(2.0) - 0.5) * 34
warp2 = (noise(2.0) - 0.5) * 34
X, Y = xx + warp, yy + warp2
d1 = np.full((N, N), 1e9)
d2 = np.full((N, N), 1e9)
for px, py in pts:
    for ox in (-N, 0, N):
        for oy in (-N, 0, N):
            d = np.hypot(X - px - ox, Y - py - oy)
            d2 = np.where(d < d1, d1, np.minimum(d2, d))
            d1 = np.minimum(d1, d)
edge = d2 - d1
crack = np.exp(-edge / 2.2)  # línea fina en el borde de cada celda
fine = np.exp(-edge / 0.9) * 0.6
mask = np.clip(crack * (0.6 + 0.6 * noise(1.6)) + fine, 0, 1)
mask = np.where(mask > 0.12, mask, 0)
save("cracks", np.ones((N, N)), mask)

# --- aurora: franjas verticales que se desvanecen arriba y abajo ---
x = noise(1.4)[0]  # una fila de ruido periódico
bands = np.tile(np.clip((x - 0.3) * 2, 0, 1) ** 1.5, (N, 1))
v = np.linspace(0, 1, N)[:, None]
fade = np.sin(v * np.pi) ** 1.2
save("aurora", np.ones((N, N)), bands * fade)
