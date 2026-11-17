#!/usr/bin/env python3
"""Música de persecución ORIGINAL de Steal a God, sintetizada con numpy (sin muestras ni melodías ajenas).
160 BPM, re menor, 24 compases (36 s), bucle sin costura: todo se escribe en un búfer circular
(las colas de las notas y de la reverberación dan la vuelta al principio).
Uso: python3 gen_chase.py carpeta_salida   →  chase.wav y chase.ogg
"""
import os, subprocess, sys, wave
import numpy as np

SR = 44100
BPM = 160
STEP = SR * 60 / BPM / 4  # semicorchea en muestras (4134.375)
BARS = 24
N = int(round(BARS * 16 * STEP))
rng = np.random.default_rng(11)
TAU = 2 * np.pi

def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)

def pos(bar, step):
    return int(round((bar * 16 + step) * STEP))

class Bus:
    def __init__(self):
        self.l = np.zeros(N)
        self.r = np.zeros(N)
    def add(self, start, sig, vol=1.0, pan=0.0):
        idx = (start + np.arange(len(sig))) % N
        np.add.at(self.l, idx, sig * vol * (1 - max(0, pan)))
        np.add.at(self.r, idx, sig * vol * (1 + min(0, pan)))

def tone(freq, n, kind="saw", cutoff=6000, mellow=0.0, vib=0.0):
    """Onda con armónicos limitados (sin aliasing). mellow > 0: los agudos se apagan con el tiempo (como un filtro)."""
    t = np.arange(n) / SR
    ph = TAU * freq * t
    if vib:
        ph = ph + vib * np.sin(TAU * 5.5 * t) * np.minimum(1, t / 0.25)
    kmax = int(max(1, min(40, cutoff // freq, (SR * 0.45) // freq)))
    out = np.zeros(n)
    for k in range(1, kmax + 1):
        if kind == "square" and k % 2 == 0:
            continue
        amp = 1.0 / k
        if mellow:
            out += amp * np.exp(-t * mellow * (k - 1)) * np.sin(k * ph)
        else:
            out += amp * np.sin(k * ph)
    return out

def env(n, a=0.005, d=8.0, s=0.0, r=0.02):
    t = np.arange(n) / SR
    e = s + (1 - s) * np.exp(-t * d)
    e *= np.minimum(1, t / max(a, 1e-4))
    rn = int(r * SR)
    if 0 < rn < n:
        e[-rn:] *= np.linspace(1, 0, rn)
    return e

def hp(x, times=1):
    for _ in range(times):
        x = np.diff(x, prepend=x[0])
    return x

def lp(x, k):
    y = np.empty_like(x)
    acc = 0.0
    a = 1 - k
    for i in range(len(x)):  # un polo; solo se usa en ráfagas cortas
        acc = acc * k + x[i] * a
        y[i] = acc
    return y

# ---------------- batería ----------------
def kick():
    n = int(0.32 * SR); t = np.arange(n) / SR
    f = 46 + 120 * np.exp(-t * 30)
    s = np.sin(TAU * np.cumsum(f) / SR) * np.exp(-t * 9)
    s += 0.5 * np.sin(2 * TAU * np.cumsum(f) / SR) * np.exp(-t * 30)  # armónico para altavoces pequeños
    s[: int(0.003 * SR)] += rng.normal(0, 0.4, int(0.003 * SR))
    return s

def taiko(pitch=1.0):
    n = int(0.42 * SR); t = np.arange(n) / SR
    f = (82 + 95 * np.exp(-t * 16)) * pitch
    s = np.sin(TAU * np.cumsum(f) / SR) * np.exp(-t * 6.5)
    s += 0.45 * np.sin(2.01 * TAU * np.cumsum(f) / SR) * np.exp(-t * 11)
    s += 0.25 * lp(rng.normal(0, 1, n), 0.6) * np.exp(-t * 38)
    return s

def snare():
    n = int(0.2 * SR); t = np.arange(n) / SR
    s = lp(hp(rng.normal(0, 1, n)), 0.35) * np.exp(-t * 21) * 1.6
    s += 0.6 * np.sin(TAU * 192 * t) * np.exp(-t * 32)
    return s

def hat(open_=False):
    n = int((0.22 if open_ else 0.05) * SR); t = np.arange(n) / SR
    return hp(rng.normal(0, 1, n), 2) * np.exp(-t * (16 if open_ else 75)) * 0.5

def crash():
    n = int(1.6 * SR); t = np.arange(n) / SR
    return hp(rng.normal(0, 1, n), 2) * np.exp(-t * 3.2) * 0.5

def riser():
    n = int(8 * STEP); t = np.arange(n) / n
    return hp(rng.normal(0, 1, n)) * t ** 3 * 0.8

# ---------------- armonía ----------------
# (fundamental del bajo, notas del acorde) por compás
CH = {
    "Dm": (38, [62, 65, 69]), "Bb": (34, [58, 62, 65]), "C": (36, [60, 64, 67]),
    "Gm": (43, [58, 62, 67]), "A": (45, [57, 61, 64]), "F": (41, [60, 65, 69]),
}
PROG = ["Dm", "Dm", "Dm", "Dm", "Bb", "Bb", "C", "C",
        "Gm", "Gm", "A", "A", "Bb", "Bb", "A", "A",
        "Dm", "Dm", "F", "F", "Bb", "Bb", "A", "A"]
FILL_BARS = (7, 15, 23)  # último compás de cada sección: redoble
B_SECTION = range(8, 16)

# melodía: (compás, semicorchea, nota MIDI, duración en semicorcheas)
D5, E5, F5, G5, A5, Bb5, C6, Cs6, D6, E6, F6, G6 = 74, 76, 77, 79, 81, 82, 84, 85, 86, 88, 89, 91
A4, C5, Cs5 = 69, 72, 73
PH1 = [(0, 0, D5, 3), (0, 3, F5, 3), (0, 6, E5, 2), (0, 8, D5, 4), (0, 12, A4, 4),
       (1, 0, C5, 2), (1, 2, D5, 6), (1, 8, F5, 2), (1, 10, E5, 2), (1, 12, D5, 4)]
PH2 = [(0, 0, A5, 3), (0, 3, G5, 3), (0, 6, F5, 2), (0, 8, E5, 4), (0, 12, D5, 4),
       (1, 0, F5, 2), (1, 2, E5, 2), (1, 4, D5, 4), (1, 8, A4, 8)]
PH_BB = [(0, 0, D5, 3), (0, 3, F5, 3), (0, 6, Bb5, 2), (0, 8, A5, 4), (0, 12, F5, 4),
         (1, 0, G5, 2), (1, 2, F5, 6), (1, 8, D5, 8)]
PH_C = [(0, 0, E5, 3), (0, 3, G5, 3), (0, 6, C6, 2), (0, 8, G5, 4), (0, 12, E5, 4),
        (1, 0, G5, 2), (1, 2, E5, 2), (1, 4, C5, 4)]
PH_GM = [(0, 0, G5, 2), (0, 2, Bb5, 2), (0, 4, D6, 4), (0, 8, C6, 2), (0, 10, Bb5, 2), (0, 12, A5, 2), (0, 14, G5, 2),
         (1, 0, Bb5, 4), (1, 4, A5, 2), (1, 6, G5, 2), (1, 8, D5, 8)]
PH_A = [(0, 0, A5, 2), (0, 2, Cs6, 2), (0, 4, E6, 4), (0, 8, D6, 2), (0, 10, Cs6, 2), (0, 12, Bb5, 2), (0, 14, A5, 2),
        (1, 0, Cs6, 4), (1, 4, Bb5, 2), (1, 6, A5, 2), (1, 8, E5, 8)]
PH_BB2 = [(0, 0, Bb5, 2), (0, 2, D6, 2), (0, 4, F6, 4), (0, 8, D6, 2), (0, 10, C6, 2), (0, 12, Bb5, 2), (0, 14, A5, 2),
          (1, 0, D6, 4), (1, 4, C6, 2), (1, 6, Bb5, 2), (1, 8, F5, 8)]
PH_A2 = [(0, 0, A5, 2), (0, 2, Cs6, 2), (0, 4, E6, 4), (0, 8, G6, 2), (0, 10, E6, 2), (0, 12, Cs6, 2), (0, 14, A5, 2),
         (1, 0, E6, 6), (1, 6, Cs6, 2)]
PH_END = [(0, 0, E5, 3), (0, 3, A5, 3), (0, 6, Cs6, 2), (0, 8, E6, 4), (0, 12, Cs6, 4),
          (1, 0, A5, 2), (1, 2, G5, 2), (1, 4, E5, 2), (1, 6, Cs5, 2)]
MELODY = [(0, PH1), (2, PH2), (4, PH_BB), (6, PH_C), (8, PH_GM), (10, PH_A), (12, PH_BB2), (14, PH_A2),
          (16, PH1), (18, PH2), (20, PH_BB), (22, PH_END)]

def build():
    drums, bass, stabs, lead, arp, pad = Bus(), Bus(), Bus(), Bus(), Bus(), Bus()
    K, T, S, HC, HO = kick(), taiko(), snare(), hat(False), hat(True)
    TH, TL = taiko(1.25), taiko(0.85)
    for bar in range(BARS):
        root, chord = CH[PROG[bar]]
        inB = bar in B_SECTION
        fill = bar in FILL_BARS
        # --- batería ---
        for st in ((0, 4, 8, 12) if inB else (0, 6, 8, 14)):
            drums.add(pos(bar, st), K, 0.8)
        for st in (4, 12):
            drums.add(pos(bar, st), S, 0.62)
        for st in ((3, 7, 11) if inB else (3, 11)):
            drums.add(pos(bar, st), T, 0.55, pan=0.25 if st == 3 else -0.25)
        for st in range(0, 16, 1 if inB else 2):
            acc = 1.0 if st % 4 == 2 else 0.6
            drums.add(pos(bar, st), HO if (st % 8 == 6 and not fill) else HC, 0.24 * acc, pan=0.3)
        if fill:  # redoble de tambores que sube hacia el siguiente bloque
            for i, st in enumerate(range(8, 16)):
                drums.add(pos(bar, st), (TL, T, TH, T)[i % 4] if i < 4 else (T, TH, TH, TH)[i % 4], 0.35 + 0.07 * i, pan=(-0.4, 0.4)[i % 2])
            drums.add(pos(bar, 8), riser(), 0.35)
        if bar % 8 == 0:
            drums.add(pos(bar, 0), crash(), 0.3)
        # --- bajo: galope de semicorcheas ---
        pat = [0, 0, 12, 0, 0, 0, 12, 0, 0, 0, 12, 0, 0, 7, 12, 7]
        n = int(STEP * 0.95)
        for st in range(16):
            m = root + pat[st]
            sig = tone(hz(m), n, "saw", cutoff=3400, mellow=3.2) * env(n, 0.004, 11, 0.12, 0.012)
            sig += 0.22 * np.sin(TAU * hz(m) * np.arange(n) / SR) * env(n, 0.004, 6, 0.3, 0.012)
            bass.add(pos(bar, st), sig, 0.42 * (1.0 if st % 4 == 0 else 0.8))
        # --- metales: golpes de acorde (tresillo) ---
        hits = [0, 3, 6] + ([10, 12] if bar % 2 == 1 and not fill else [])
        n = int(STEP * 1.7)
        for st in hits:
            sig = np.zeros(n)
            for m in [chord[0] - 12] + chord:
                for det in (-0.07, 0.06):
                    sig += tone(hz(m + det), n, "saw", cutoff=6800, mellow=1.3)
            sig *= env(n, 0.006, 13, 0.1, 0.03) / 6
            stabs.add(pos(bar, st), sig, 0.62, pan=-0.2)
            stabs.add(pos(bar, st) + 260, sig, 0.44, pan=0.35)  # ensanche estéreo
        # --- arpegio agudo ---
        tones = [chord[0] + 12, chord[1] + 12, chord[2] + 12, chord[0] + 24, chord[2] + 12, chord[1] + 12, chord[0] + 12, chord[2]]
        n = int(STEP * 1.1)
        for st in range(16):
            sig = tone(hz(tones[st % 8]), n, "square", cutoff=7000) * env(n, 0.003, 22, 0.0, 0.01)
            arp.add(pos(bar, st), sig, 0.14 if not inB else 0.18, pan=(-0.6, 0.6)[st % 2])
        # --- colchón (acorde largo cada 2 compases) ---
        if bar % 2 == 0:
            n = int(STEP * 34)
            sig = np.zeros(n)
            for m in chord:
                for det in (-0.09, 0.0, 0.1):
                    sig += tone(hz(m + det), n, "saw", cutoff=2400)
            t = np.arange(n) / SR
            sig *= np.minimum(1, t / 0.35) * np.minimum(1, (n / SR - t) / 0.3) / 9
            pad.add(pos(bar, 0), sig, 0.2)
    # --- melodía ---
    for bar0, phrase in MELODY:
        for b, st, m, dur in phrase:
            n = int(STEP * dur * 0.97)
            sig = 0.7 * tone(hz(m), n, "saw", cutoff=6500, mellow=0.9, vib=0.012 if dur >= 4 else 0)
            sig += 0.45 * tone(hz(m), n, "square", cutoff=5000)
            sig += 0.35 * tone(hz(m - 12), n, "saw", cutoff=3000)  # octava baja: se oye en altavoces pequeños
            sig *= env(n, 0.012, 3.2, 0.45, 0.03)
            lead.add(pos(bar0 + b, st), sig, 0.36)
    return drums, bass, stabs, lead, arp, pad

def reverb(x, seed, length=1.1, decay=4.2):
    """Reverberación por convolución CIRCULAR con ruido que decae: la cola da la vuelta al bucle."""
    r = np.random.default_rng(seed)
    n = int(length * SR)
    ir = r.normal(0, 1, n) * np.exp(-np.arange(n) / SR * decay)
    ir[: int(0.012 * SR)] = 0
    ir = hp(ir)
    pad_ir = np.zeros(N)
    pad_ir[:n] = ir / np.sqrt(np.sum(ir ** 2))
    return np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(pad_ir), N)

def main(out):
    os.makedirs(out, exist_ok=True)
    drums, bass, stabs, lead, arp, pad = build()
    dryL = drums.l + bass.l + stabs.l + lead.l + arp.l + pad.l
    dryR = drums.r + bass.r + stabs.r + lead.r + arp.r + pad.r
    sendL = 0.35 * drums.l + stabs.l + lead.l + arp.l + pad.l
    sendR = 0.35 * drums.r + stabs.r + lead.r + arp.r + pad.r
    L = dryL + 0.22 * reverb(sendL, 1)
    R = dryR + 0.22 * reverb(sendR, 2)
    mix = np.stack([L, R])
    # ecualización circular (no rompe el bucle): menos subgrave, algo más de brillo para altavoces de móvil
    fr = np.fft.rfftfreq(N, 1 / SR)
    gain = np.ones_like(fr)
    gain[fr < 30] = 0
    gain *= 10 ** (-5.0 / 20 * np.clip((130 - fr) / 70, 0, 1))
    gain *= 10 ** (3.0 / 20 * np.clip((fr - 900) / 1500, 0, 1))
    mix = np.stack([np.fft.irfft(np.fft.rfft(ch) * gain, N) for ch in mix])
    mix = mix / np.percentile(np.abs(mix), 99.9) * 0.82
    mix = np.tanh(mix * 1.25) / np.tanh(1.25)  # saturación suave
    mix = mix / np.max(np.abs(mix)) * 10 ** (-1.2 / 20)
    # --- comprobaciones ---
    mono = mix.mean(0)
    rms = 20 * np.log10(np.sqrt(np.mean(mix ** 2)))
    peak = 20 * np.log10(np.max(np.abs(mix)))
    seam = abs(mono[0] - mono[-1]); typical = np.percentile(np.abs(np.diff(mono)), 95)
    spec = np.abs(np.fft.rfft(mono)) ** 2
    fr = np.fft.rfftfreq(N, 1 / SR)
    bands = [(20, 120), (120, 500), (500, 2000), (2000, 8000), (8000, 20000)]
    tot = spec.sum()
    print(f"duración {N / SR:.3f} s · {BARS} compases · {BPM} BPM · pico {peak:.2f} dBFS · RMS {rms:.2f} dBFS")
    print(f"costura: salto {seam:.4f} (salto típico entre muestras {typical:.4f})")
    print("bandas: " + " · ".join(f"{a}-{b} Hz {100 * spec[(fr >= a) & (fr < b)].sum() / tot:.1f}%" for a, b in bands))
    wav = os.path.join(out, "chase.wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((mix.T * 32767).astype("<i2").tobytes())
    ogg = os.path.join(out, "chase.ogg")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", ogg], check=True)
    back = os.path.join(out, "back.wav")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", ogg, back], check=True)
    with wave.open(back) as w:
        print(f"ogg: {os.path.getsize(ogg) / 1024:.0f} KB · muestras decodificadas {w.getnframes()} (esperadas {N})")
    os.remove(back)

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "out")
