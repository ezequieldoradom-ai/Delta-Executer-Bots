# Música original de Lucky Obby Race (Shadow): genera dos bucles en WAV.
#   obby.wav     · alegre tipo chiptune, 140 BPM, Do mayor, 16 compases (~27 s), bucle perfecto
#   tension.wav  · tensión para los guantazos, 96 BPM, La menor, 8 compases (~20 s), bucle perfecto
import numpy as np, soundfile as sf, sys, os
SR = 44100
out = sys.argv[1] if len(sys.argv) > 1 else '.'

def note_hz(n):  # n: semitonos desde La4 (440)
    return 440.0 * 2 ** (n / 12)

def env(n, a=0.005, r=0.08):
    e = np.ones(n)
    na, nr = max(1, int(a * SR)), max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] *= np.linspace(1, 0, nr)
    return e

def square(f, n, duty=0.5):
    t = np.arange(n) / SR
    return np.where((t * f) % 1 < duty, 1.0, -1.0)

def tri(f, n):
    t = np.arange(n) / SR
    return 2 * np.abs(2 * ((t * f) % 1) - 1) - 1

def saw(f, n):
    t = np.arange(n) / SR
    return 2 * ((t * f) % 1) - 1

def noise(n):
    return np.random.default_rng(1).uniform(-1, 1, n)

def kick(n):
    t = np.arange(n) / SR
    f = 120 * np.exp(-t * 30) + 45
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 9)

def snare(n):
    t = np.arange(n) / SR
    return (noise(n) * 0.7 + np.sin(2 * np.pi * 190 * t) * 0.3) * np.exp(-t * 18)

def hat(n):
    t = np.arange(n) / SR
    x = noise(n)
    x = np.diff(np.concatenate([[0], x]))  # brillo
    return x * np.exp(-t * 60)

def place(buf, start, sig, gain):
    s = int(start)
    e = min(len(buf), s + len(sig))
    if e > s:
        buf[s:e] += sig[: e - s] * gain

# ---------------- OBBY ----------------
def obby():
    bpm = 140
    beat = 60 / bpm
    bars = 16
    total = int(bars * 4 * beat * SR)
    mix = np.zeros(total)
    # acordes por compás (raíz en semitonos rel. La4; Do=-9): I V vi IV
    prog = [(-9, [0, 4, 7]), (-2, [0, 4, 7]), (0, [0, 3, 7]), (-4, [0, 4, 7])]
    # melodía (en semitonos sobre Do5=+3), 8 corcheas por compás; None = silencio
    melA = [
        [0, 4, 7, 12, 11, 7, 4, 7], [2, 7, 11, 14, 12, 11, 7, None],
        [4, 9, 12, 16, 14, 12, 9, 12], [5, 9, 12, 9, 7, 5, 4, 2],
    ]
    melB = [
        [12, None, 12, 11, 12, 14, 16, None], [14, None, 11, 7, 11, 14, 19, None],
        [16, 14, 12, 9, 12, 16, 21, 19], [17, 16, 14, 12, 11, 9, 7, 5],
    ]
    for b in range(bars):
        root, triad = prog[b % 4]
        t0 = b * 4 * beat * SR
        # bajo (triangular) en negras con octava
        for q in range(8):
            f = note_hz(root - 24 + (12 if q % 2 else 0))
            n = int(beat / 2 * SR * 0.9)
            place(mix, t0 + q * beat / 2 * SR, tri(f, n) * env(n, 0.003, 0.03), 0.30)
        # arpegio rápido (cuadrada estrecha)
        for k in range(16):
            iv = triad[k % 3] + (12 if (k // 3) % 2 else 0)
            f = note_hz(root + iv)
            n = int(beat / 4 * SR * 0.8)
            place(mix, t0 + k * beat / 4 * SR, square(f, n, 0.125) * env(n, 0.002, 0.02), 0.06)
        # melodía (cuadrada 25 %) — sección A los 8 primeros compases, B los 8 siguientes
        mel = (melA if b < 8 else melB)[b % 4]
        for i, m in enumerate(mel):
            if m is None:
                continue
            f = note_hz(3 + m)
            n = int(beat / 2 * SR * 0.92)
            sig = square(f, n, 0.25) * env(n, 0.004, 0.05)
            # pequeño vibrato/eco
            place(mix, t0 + i * beat / 2 * SR, sig, 0.13)
            place(mix, t0 + i * beat / 2 * SR + beat * 0.75 * SR, sig, 0.04)
        # batería
        for q in range(4):
            tb = t0 + q * beat * SR
            if q % 2 == 0:
                place(mix, tb, kick(int(0.3 * SR)), 0.55)
            else:
                place(mix, tb, snare(int(0.2 * SR)), 0.30)
            place(mix, tb + beat / 2 * SR, hat(int(0.05 * SR)), 0.12)
            place(mix, tb, hat(int(0.05 * SR)), 0.07)
    return mix

# ---------------- TENSIÓN ----------------
def tension():
    bpm = 96
    beat = 60 / bpm
    bars = 8
    total = int(bars * 4 * beat * SR)
    mix = np.zeros(total)
    t = np.arange(total) / SR
    # dron grave que respira (La1 + quinta), saw filtrada a mano (media móvil)
    drone = saw(note_hz(-36), total) * 0.5 + saw(note_hz(-29), total) * 0.3
    k = np.ones(60) / 60
    drone = np.convolve(drone, k, mode='same')
    breath = 0.6 + 0.4 * np.sin(2 * np.pi * t / (4 * beat))
    mix += drone * breath * 0.22
    # cuerdas agudas en trémolo que suben al final del bucle (sube la tensión)
    rise = np.linspace(0, 1, total) ** 2
    trem = 0.5 + 0.5 * np.sin(2 * np.pi * 12 * t)
    strings = np.sin(2 * np.pi * note_hz(-9) * t) + np.sin(2 * np.pi * note_hz(-8) * t) * 0.6  # disonancia de semitono
    mix += strings * trem * (0.03 + 0.07 * rise)
    # pulso de bajo en corcheas (como latido) y latido doble en cada compás
    for b in range(bars):
        t0 = b * 4 * beat * SR
        for q in range(8):
            n = int(beat / 2 * SR * 0.6)
            f = note_hz(-36 if (q % 8) < 6 else -35)
            place(mix, t0 + q * beat / 2 * SR, square(f, n, 0.5) * env(n, 0.002, 0.05), 0.07)
        place(mix, t0, kick(int(0.35 * SR)), 0.6)
        place(mix, t0 + 0.28 * SR, kick(int(0.3 * SR)), 0.4)
        place(mix, t0 + 2 * beat * SR, kick(int(0.35 * SR)), 0.55)
        place(mix, t0 + 2 * beat * SR + 0.28 * SR, kick(int(0.3 * SR)), 0.35)
        # tic-tac de reloj en semicorcheas
        for s16 in range(16):
            place(mix, t0 + s16 * beat / 4 * SR, hat(int(0.03 * SR)), 0.05 if s16 % 4 else 0.10)
    return mix

def finish(x, name):
    # bucle sin chasquido: fundido cruzado de los últimos 30 ms con el inicio
    n = int(0.03 * SR)
    x[:n] = x[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n)
    x = x[: len(x) - n]
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.85
    path = os.path.join(out, name)
    sf.write(path, np.stack([x, x], 1).astype(np.float32), SR)
    print(path, round(len(x) / SR, 1), 's')

finish(obby(), 'obby.wav')
finish(tension(), 'tension.wav')
