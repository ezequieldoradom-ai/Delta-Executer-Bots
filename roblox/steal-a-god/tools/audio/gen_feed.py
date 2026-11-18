"""Sonidos ORIGINALES del aviso de sobres al amanecer (síntesis con numpy, sin muestras ajenas).
Un solo audio con 5 huecos de 3 s (como los gritos de los guardianes):
  1 Mítica      - arpegio de fuego (re menor) con chasquido
  2 Divina      - acorde coral que se abre + campana
  3 Celestial   - brillo cristalino que sube (galaxia)
  4 Primordial+ - golpe grave + barrido + acorde épico
  5 Secreta     - pulso oscuro y misterioso
Uso: python gen_feed.py carpeta_salida  ->  feed.ogg
"""
import sys, os
import numpy as np
import soundfile as sf

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
SR = 44100
SLOT = 3.0
rng = np.random.default_rng(3)


def t(d):
    return np.arange(int(d * SR)) / SR


def env(n, a=0.01, r=1.0):
    x = np.arange(n) / SR
    e = np.minimum(1, x / max(a, 1e-4)) * np.exp(-x / r)
    return e


def tone(f, d, a=0.005, r=0.6, harm=(1, 0.5, 0.25), detune=0.0):
    x = t(d)
    s = sum(w * np.sin(2 * np.pi * f * (k + 1) * (1 + detune * (k % 2)) * x) for k, w in enumerate(harm))
    return s * env(len(x), a, r)


def bell(f, d, r=1.2):
    x = t(d)
    parts = [(1, 1), (2.76, 0.5), (5.4, 0.25), (8.9, 0.12)]
    s = sum(w * np.sin(2 * np.pi * f * m * x) * np.exp(-x * (1 + m * 0.6) / r) for m, w in parts)
    return s * np.minimum(1, x / 0.002)


def place(buf, s, at):
    i = int(at * SR)
    j = min(len(buf), i + len(s))
    buf[i:j] += s[: j - i]


def reverb(s, mix=0.3):
    out = s.copy()
    for d, g in ((0.031, 0.5), (0.047, 0.42), (0.071, 0.35), (0.113, 0.28), (0.167, 0.2), (0.241, 0.14)):
        k = int(d * SR)
        out[k:] += s[:-k] * g * mix * 2
    return out


def note(n):  # n semitonos desde La4
    return 440 * 2 ** (n / 12)


slots = []

# 1 Mítica: arpegio rápido re-fa-la-re con brillo y chasquido de fuego
b = np.zeros(int(SLOT * SR))
for k, n in enumerate([-7, -4, 0, 5, 9]):
    place(b, tone(note(n), 1.4, r=0.5, harm=(1, 0.6, 0.3, 0.15)) * 0.35, k * 0.07)
crack = rng.normal(size=int(0.25 * SR)) * env(int(0.25 * SR), 0.001, 0.05)
place(b, crack * 0.25, 0)
slots.append(reverb(b, 0.35))

# 2 Divina: acorde mayor que se abre (coro) + campana
b = np.zeros(int(SLOT * SR))
x = t(2.6)
swell = np.minimum(1, x / 0.6) * np.exp(-np.maximum(0, x - 1.2) / 0.8)
for n in [-9, -5, -2, 3, 7]:
    for dt in (-0.004, 0.004):
        b[: len(x)] += np.sin(2 * np.pi * note(n) * (1 + dt) * x) * swell * 0.08
place(b, bell(note(15), 2.5) * 0.35, 0.05)
place(b, bell(note(22), 2.0) * 0.2, 0.25)
slots.append(reverb(b, 0.45))

# 3 Celestial: lluvia cristalina ascendente
b = np.zeros(int(SLOT * SR))
scale = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
for k, n in enumerate(scale):
    place(b, bell(note(n + 3), 1.2, r=0.7) * 0.22, k * 0.08)
x = t(2.4)
shimmer = rng.normal(size=len(x)) * np.exp(-x / 0.8) * np.minimum(1, x / 0.2)
place(b, np.convolve(shimmer, np.ones(8) / 8, "same") * 0.05, 0)
slots.append(reverb(b, 0.5))

# 4 Primordial+: golpe grave, barrido que sube y acorde épico
b = np.zeros(int(SLOT * SR))
x = t(1.2)
boom = np.sin(2 * np.pi * (55 - 25 * x) * x) * np.exp(-x / 0.35)
place(b, boom * 0.8, 0)
x = t(0.9)
sweep = rng.normal(size=len(x)) * np.minimum(1, x / 0.85) * 0.12
place(b, np.convolve(sweep, np.ones(30) / 30, "same") * 2, 0.1)
for n in [-14, -9, -5, -2, 3, 10]:
    place(b, tone(note(n), 1.8, a=0.02, r=0.9, harm=(1, 0.5, 0.35, 0.2)) * 0.12, 0.95)
place(b, bell(note(15), 2.0) * 0.3, 0.95)
slots.append(reverb(b, 0.4))

# 5 Secreta: pulso oscuro con disonancia y eco
b = np.zeros(int(SLOT * SR))
for k in range(3):
    place(b, tone(note(-26), 0.9, a=0.01, r=0.4, harm=(1, 0.8, 0.4)) * 0.4, k * 0.45)
place(b, tone(note(-1), 2.0, a=0.3, r=1.0, detune=0.01) * 0.12, 0.3)
place(b, tone(note(0), 2.0, a=0.3, r=1.0, detune=0.01) * 0.12, 0.3)
slots.append(reverb(b, 0.55))

audio = np.concatenate(slots)
audio /= np.max(np.abs(audio)) * 1.05
sf.write(os.path.join(OUT, "feed.wav"), np.stack([audio, audio], 1), SR, subtype="PCM_16")
print("ok feed.wav", round(len(audio) / SR, 1), "s")
