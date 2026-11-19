#!/usr/bin/env python3
"""Música de fondo ORIGINAL de Steal a God (plaza, parcelas y Ascenso al Olimpo): alegre y acogedora,
estilo obby. Sintetizada con numpy (sin muestras ni melodías ajenas): ukelele (Karplus-Strong), marimba,
campanitas, bajo saltarín, colchón cálido y batería suave.
118 BPM, fa mayor, 32 compases (65 s) en bucle sin costura (búfer circular: colas y reverberación dan la vuelta).
Uso: python3 gen_bgm.py carpeta_salida   →  bgm.wav y bgm.ogg
"""
import os, subprocess, sys, wave
import numpy as np

SR = 44100
BPM = 118
STEP = SR * 60 / BPM / 4  # semicorchea en muestras
BARS = 32
N = int(round(BARS * 16 * STEP))
rng = np.random.default_rng(7)
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

def smooth(x, k=3):
    if k <= 1:
        return x
    return np.convolve(x, np.ones(k) / k, mode="same")

# ---------------- instrumentos ----------------
_ks_cache = {}
def pluck(m, dur=0.9, bright=0.55):
    """Cuerda pulsada (Karplus-Strong) por bloques de un periodo: suena a ukelele/guitarra."""
    key = (m, round(dur, 2), round(bright, 2))
    if key in _ks_cache:
        return _ks_cache[key]
    f = hz(m)
    L = max(2, int(round(SR / f)))
    n = int(dur * SR)
    out = np.zeros(n + L)
    burst = rng.uniform(-1, 1, L)
    burst = smooth(burst, max(1, int(3 * (1 - bright)) + 1))
    out[:L] = burst
    decay = 0.996 - 0.0006 * max(0, (m - 60)) / 12
    i = L
    while i < n + L:
        blk = out[i - L:i]
        nxt = np.empty(L)
        nxt[:-1] = 0.5 * (blk[:-1] + blk[1:]) * decay
        nxt[-1] = 0.5 * (blk[-1] + nxt[0]) * decay
        end = min(i + L, n + L)
        out[i:end] = nxt[: end - i]
        i = end
    sig = out[L:] * env(n, 0.002, 1.2, 0.0, 0.03)
    sig = hp(sig) * 0.5 + sig * 0.5
    _ks_cache[key] = sig
    return sig

def marimba(m, dur=0.55):
    n = int(dur * SR); t = np.arange(n) / SR
    f = hz(m)
    s = np.sin(TAU * f * t) * np.exp(-t * 7)
    s += 0.35 * np.sin(TAU * f * 3.93 * t) * np.exp(-t * 22)
    s += 0.12 * np.sin(TAU * f * 9.8 * t) * np.exp(-t * 45)
    s *= np.minimum(1, t / 0.002)
    return s

def bell(m, dur=1.2):
    n = int(dur * SR); t = np.arange(n) / SR
    f = hz(m)
    s = np.sin(TAU * f * t + 1.2 * np.sin(TAU * f * 2.0 * t) * np.exp(-t * 5)) * np.exp(-t * 3.2)
    s += 0.25 * np.sin(TAU * f * 3.01 * t) * np.exp(-t * 6)
    s *= np.minimum(1, t / 0.003)
    return s

def bass_note(m, dur):
    n = int(dur * SR); t = np.arange(n) / SR
    f = hz(m)
    s = np.sin(TAU * f * t) + 0.25 * np.sin(2 * TAU * f * t) + 0.08 * np.sin(3 * TAU * f * t)
    return s * env(n, 0.004, 4.5, 0.25, 0.03)

def pad_chord(ms, dur):
    n = int(dur * SR); t = np.arange(n) / SR
    s = np.zeros(n)
    for m in ms:
        for det in (-0.08, 0.0, 0.09):
            f = hz(m + det)
            for k in range(1, 7):
                s += (0.6 / k) * np.sin(TAU * f * k * t) * np.exp(-t * 0.6 * (k - 1))
    s *= np.minimum(1, t / 0.6) * np.minimum(1, (dur - t) / 0.5)
    return s / (len(ms) * 3)

# batería suave
def kick():
    n = int(0.28 * SR); t = np.arange(n) / SR
    f = 52 + 90 * np.exp(-t * 35)
    s = np.sin(TAU * np.cumsum(f) / SR) * np.exp(-t * 11)
    s += 0.35 * np.sin(2 * TAU * np.cumsum(f) / SR) * np.exp(-t * 30)
    return s

def clap():
    n = int(0.22 * SR); t = np.arange(n) / SR
    noise = hp(rng.normal(0, 1, n))
    e = np.exp(-t * 26)
    for d in (0.008, 0.016):  # tres palmadas muy juntas
        k = int(d * SR)
        e[k:] += 0.6 * np.exp(-(t[k:] - d) * 60)
    return smooth(noise, 2) * e * 0.55

def shaker():
    n = int(0.07 * SR); t = np.arange(n) / SR
    return hp(rng.normal(0, 1, n), 2) * np.exp(-t * 55) * np.minimum(1, t / 0.006) * 0.35

def woodblock(p=1.0):
    n = int(0.12 * SR); t = np.arange(n) / SR
    return (np.sin(TAU * 1250 * p * t) + 0.4 * np.sin(TAU * 2480 * p * t)) * np.exp(-t * 48)

# ---------------- armonía y forma ----------------
CH = {
    "F": (41, [60, 65, 69, 72]), "C": (36, [60, 64, 67, 72]), "Dm": (38, [62, 65, 69, 74]),
    "Bb": (34, [62, 65, 70, 74]), "Am": (45, [60, 64, 69, 72]), "Gm": (43, [62, 67, 70, 74]),
}
A = ["F", "C", "Dm", "Bb", "F", "C", "Bb", "C"]
B = ["Bb", "C", "Am", "Dm", "Gm", "C", "F", "F"]
BR = ["Dm", "Bb", "F", "C", "Dm", "Bb", "Gm", "C"]
PROG = A + B + A + BR
SECTION = ["A"] * 8 + ["B"] * 8 + ["A2"] * 8 + ["BR"] * 8

# notas MIDI
F4, G4, A4, Bb4, C5, D5, E5, F5, G5, A5, Bb5, C6, D6, E6, F6, G6 = 65, 67, 69, 70, 72, 74, 76, 77, 79, 81, 82, 84, 86, 88, 89, 91
# melodía: (compás relativo, semicorchea, nota, duración en semicorcheas)
MEL_A = [
    (0, 0, A4, 2), (0, 2, C5, 2), (0, 4, F5, 4), (0, 8, E5, 2), (0, 10, C5, 2), (0, 12, D5, 4),
    (1, 0, C5, 6), (1, 6, G4, 2), (1, 8, A4, 2), (1, 10, Bb4, 2), (1, 12, C5, 4),
    (2, 0, D5, 2), (2, 2, F5, 2), (2, 4, A5, 4), (2, 8, G5, 2), (2, 10, F5, 2), (2, 12, E5, 2), (2, 14, D5, 2),
    (3, 0, F5, 8), (3, 8, D5, 2), (3, 10, C5, 2), (3, 12, Bb4, 4),
    (4, 0, A4, 2), (4, 2, C5, 2), (4, 4, F5, 4), (4, 8, E5, 2), (4, 10, C5, 2), (4, 12, D5, 4),
    (5, 0, C5, 2), (5, 2, E5, 2), (5, 4, G5, 4), (5, 8, F5, 2), (5, 10, E5, 2), (5, 12, C5, 4),
    (6, 0, D5, 4), (6, 4, F5, 4), (6, 8, Bb5, 4), (6, 12, A5, 4),
    (7, 0, G5, 6), (7, 6, E5, 2), (7, 8, C5, 6), (7, 14, C5, 2),
]
MEL_B = [
    (0, 0, D6, 4), (0, 4, C6, 2), (0, 6, Bb5, 2), (0, 8, A5, 4), (0, 12, F5, 4),
    (1, 0, E5, 4), (1, 4, G5, 4), (1, 8, C6, 6), (1, 14, Bb5, 2),
    (2, 0, A5, 4), (2, 4, C6, 2), (2, 6, A5, 2), (2, 8, E5, 4), (2, 12, A5, 4),
    (3, 0, F5, 6), (3, 6, E5, 2), (3, 8, D5, 8),
    (4, 0, Bb5, 4), (4, 4, A5, 2), (4, 6, G5, 2), (4, 8, D5, 4), (4, 12, G5, 4),
    (5, 0, E5, 2), (5, 2, G5, 2), (5, 4, C6, 4), (5, 8, Bb5, 2), (5, 10, A5, 2), (5, 12, G5, 4),
    (6, 0, A5, 8), (6, 8, C6, 4), (6, 12, A5, 4),
    (7, 0, F5, 8), (7, 12, C5, 2), (7, 14, D5, 2),
]
MEL_A2 = [x for x in MEL_A if x[0] < 6] + [
    (6, 0, D6, 4), (6, 4, C6, 4), (6, 8, Bb5, 4), (6, 12, D6, 4),
    (7, 0, C6, 4), (7, 4, G5, 2), (7, 6, A5, 2), (7, 8, Bb5, 2), (7, 10, C6, 2), (7, 12, D6, 2), (7, 14, E6, 2),
]
MEL_BR = [
    (0, 0, F5, 4), (0, 4, A5, 4), (0, 8, D6, 8),
    (1, 0, D6, 4), (1, 4, C6, 4), (1, 8, Bb5, 8),
    (2, 0, A5, 4), (2, 4, C6, 4), (2, 8, F6, 8),
    (3, 0, E6, 4), (3, 4, D6, 4), (3, 8, C6, 4), (3, 12, G5, 4),
    (4, 0, A5, 6), (4, 6, F5, 2), (4, 8, D5, 8),
    (5, 0, F5, 6), (5, 6, D5, 2), (5, 8, Bb4, 8),
    (6, 0, D5, 4), (6, 4, G5, 4), (6, 8, Bb5, 4), (6, 12, D6, 4),
    (7, 0, C6, 4), (7, 4, E5, 2), (7, 6, G5, 2), (7, 8, C6, 2), (7, 10, E6, 2), (7, 12, C6, 2), (7, 14, A4, 2),
]
MELODY = [(0, MEL_A), (8, MEL_B), (16, MEL_A2), (24, MEL_BR)]

STRUM = [(0, "d"), (4, "d"), (6, "u"), (10, "u"), (12, "d"), (14, "u")]

def build():
    drums, bass, uke, lead, bells, pad = Bus(), Bus(), Bus(), Bus(), Bus(), Bus()
    K, CL, SH = kick(), clap(), shaker()
    WB1, WB2 = woodblock(1.0), woodblock(1.33)
    for bar in range(BARS):
        root, chord = CH[PROG[bar]]
        sec = SECTION[bar]
        bridge = sec == "BR"
        # --- batería ---
        kicks = (0,) if bridge else ((0, 8, 10) if bar % 2 == 1 else (0, 8))
        for st in kicks:
            drums.add(pos(bar, st), K, 0.62)
        for st in ((12,) if bridge else (4, 12)):
            drums.add(pos(bar, st), CL, 0.5, pan=0.08)
        for st in range(0, 16):
            if bridge and st % 2 == 1:
                continue
            acc = 1.0 if st % 4 == 2 else (0.75 if st % 2 == 0 else 0.5)
            drums.add(pos(bar, st), SH, 0.42 * acc, pan=0.35)
        if bar % 8 == 7 and not bridge:  # remate con bloques de madera
            for i, st in enumerate((10, 12, 13, 14, 15)):
                drums.add(pos(bar, st), WB1 if i % 2 == 0 else WB2, 0.28, pan=(-0.4, 0.4)[i % 2])
        # --- bajo saltarín ---
        pat = [(0, 0, 3), (6, 7, 2), (8, 12, 2), (11, 7, 1), (12, 0, 2), (14, 10 if PROG[bar] in ("C", "Gm") else 9, 2)]
        if bridge:
            pat = [(0, 0, 6), (8, 7, 4), (12, 12, 4)]
        for st, iv, dur in pat:
            m = root + iv
            bass.add(pos(bar, st), bass_note(m, dur * STEP / SR * 0.9), 0.36)
        # --- ukelele (rasgueo) ---
        if not bridge or bar % 2 == 0:
            for st, d in (STRUM if not bridge else [(0, "d"), (8, "d")]):
                notes = chord if d == "d" else list(reversed(chord))
                for k, m in enumerate(notes):
                    sig = pluck(m, 0.9 if not bridge else 1.8, 0.6 if d == "d" else 0.75)
                    vol = (0.32 if d == "d" else 0.22) * (1.0 if st in (0, 12) else 0.85)
                    uke.add(pos(bar, st) + int(k * 0.009 * SR), sig, vol, pan=-0.25 + 0.15 * k)
        # --- campanitas: arpegio en la parte B y en el puente ---
        if sec in ("B", "BR"):
            tones = [chord[0] + 12, chord[2] + 12, chord[1] + 12, chord[3] + 12]
            for i, st in enumerate(range(0, 16, 2 if sec == "B" else 4)):
                bells.add(pos(bar, st), bell(tones[i % 4], 1.0), 0.13 if sec == "B" else 0.16, pan=(-0.55, 0.55)[i % 2])
        # --- colchón cálido ---
        if sec in ("B", "BR", "A2") and bar % 2 == 0:
            pad.add(pos(bar, 0), pad_chord([chord[0], chord[1], chord[2]], STEP * 32 / SR), 0.22 if sec != "A2" else 0.12)
    # --- melodía: marimba (y una octava abajo muy suave para altavoces pequeños) ---
    for bar0, phrase in MELODY:
        for b, st, m, dur in phrase:
            d = max(0.25, dur * STEP / SR * 1.3)
            sig = marimba(m, d) + 0.25 * marimba(m - 12, d)
            lead.add(pos(bar0 + b, st), sig, 0.42, pan=-0.05)
            if dur >= 4:  # notas largas: trémolo de marimba
                lead.add(pos(bar0 + b, st) + int(STEP * 2), marimba(m, d * 0.7), 0.2, pan=0.05)
    return drums, bass, uke, lead, bells, pad

def reverb(x, seed, length=1.6, decay=3.2):
    r = np.random.default_rng(seed)
    n = int(length * SR)
    ir = r.normal(0, 1, n) * np.exp(-np.arange(n) / SR * decay)
    ir[: int(0.018 * SR)] = 0
    ir = hp(ir)
    pad_ir = np.zeros(N)
    pad_ir[:n] = ir / np.sqrt(np.sum(ir ** 2))
    return np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(pad_ir), N)

def main(out):
    os.makedirs(out, exist_ok=True)
    drums, bass, uke, lead, bells, pad = build()
    buses = [drums, bass, uke, lead, bells, pad]
    dryL = sum(b.l for b in buses)
    dryR = sum(b.r for b in buses)
    sendL = 0.25 * drums.l + uke.l + lead.l + bells.l + pad.l
    sendR = 0.25 * drums.r + uke.r + lead.r + bells.r + pad.r
    L = dryL + 0.26 * reverb(sendL, 3)
    R = dryR + 0.26 * reverb(sendR, 4)
    mix = np.stack([L, R])
    fr = np.fft.rfftfreq(N, 1 / SR)
    gain = np.ones_like(fr)
    gain[fr < 32] = 0
    gain *= 10 ** (-4.0 / 20 * np.clip((120 - fr) / 70, 0, 1))
    gain *= 10 ** (4.0 / 20 * np.clip((fr - 1200) / 1800, 0, 1))
    gain *= 10 ** (-3.0 / 20 * np.clip((fr - 9000) / 4000, 0, 1))  # sin agudos chillones: acogedora
    mix = np.stack([np.fft.irfft(np.fft.rfft(ch) * gain, N) for ch in mix])
    mix = mix / np.percentile(np.abs(mix), 99.9) * 0.8
    mix = np.tanh(mix * 1.15) / np.tanh(1.15)
    mix = mix / np.max(np.abs(mix)) * 10 ** (-1.5 / 20)
    mono = mix.mean(0)
    rms = 20 * np.log10(np.sqrt(np.mean(mix ** 2)))
    peak = 20 * np.log10(np.max(np.abs(mix)))
    seam = abs(mono[0] - mono[-1]); typical = np.percentile(np.abs(np.diff(mono)), 95)
    spec = np.abs(np.fft.rfft(mono)) ** 2
    bands = [(20, 120), (120, 500), (500, 2000), (2000, 8000), (8000, 20000)]
    tot = spec.sum()
    print(f"duración {N / SR:.3f} s · {BARS} compases · {BPM} BPM · pico {peak:.2f} dBFS · RMS {rms:.2f} dBFS")
    print(f"costura: salto {seam:.4f} (salto típico entre muestras {typical:.4f})")
    print("bandas: " + " · ".join(f"{a}-{b} Hz {100 * spec[(fr >= a) & (fr < b)].sum() / tot:.1f}%" for a, b in bands))
    wav = os.path.join(out, "bgm.wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((mix.T * 32767).astype("<i2").tobytes())
    ogg = os.path.join(out, "bgm.ogg")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", ogg], check=True)
    print(f"ogg: {os.path.getsize(ogg) / 1024:.0f} KB")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "out")
