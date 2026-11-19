#!/usr/bin/env bash
# Gritos de los guardianes ("HEY!! That's MY pack!"…): voces de ElevenLabs (eleven_v3, clave inyectada por el proxy),
# procesadas con ffmpeg para que suenen a monstruo y juntadas en UN audio de 6 huecos de 5 s (Config.SHOUTS).
# Uso: bash tools/audio/make_shouts.sh carpeta_salida   →  guardian_shouts.ogg (luego upload_audio.py)
set -euo pipefail
OUT=${1:-out}; mkdir -p "$OUT"; cd "$OUT"
gen(){ curl -sS -o "$1.mp3" -X POST "https://api.elevenlabs.io/v1/text-to-speech/$2?output_format=mp3_44100_128" \
  -H "xi-api-key: proxy-injected" -H "Content-Type: application/json" \
  -d "{\"text\": \"$3\", \"model_id\": \"eleven_v3\", \"voice_settings\": {\"stability\": 0.0, \"similarity_boost\": 0.8, \"style\": 1.0}}"; }
gen minotaur SOYHLrjzK2X1ezoPC6cr "[furious] [shouting] HEY!! That's MY pack!"
gen dullahan N2lVS1w4EtoT3dr4eOWO "[menacing] [shouting] HEEEY! You can't escape me!"
gen sphinx   pFZP5JQG7iQjIQuC4Bku "[commanding] [shouting] HEY! Stop right there, thief!"
gen jaguar   IKne3meq5aSn9XLyUdCD "[growling] [shouting] HEY!! I see you!"
gen lamassu  pNInz6obpgDQGcFmaJgB "[booming] [shouting] HEY!! Give that back!"
gen fenrir   CwhRBWXzGAHq8TQ4Fs17 "[howling] [shouting] HEEEY!! Come back here!"
fx(){ ffmpeg -v error -y -i "$1.mp3" -af "$2" -ar 44100 -ac 1 "$1_fx.wav"; }
fx minotaur "asetrate=44100*0.74,aresample=44100,aeval='tanh(2.2*val(0))/tanh(2.2)',aecho=0.8:0.6:45:0.25,highpass=f=60"
fx dullahan "asetrate=44100*0.86,aresample=44100,highpass=f=120,aecho=0.8:0.9:90|180|270:0.5|0.35|0.2,tremolo=f=6:d=0.25"
fx sphinx   "asetrate=44100*0.93,aresample=44100,aecho=0.8:0.85:70|140:0.35|0.2"
fx jaguar   "asetrate=44100*0.82,aresample=44100,tremolo=f=32:d=0.4,aeval='tanh(1.8*val(0))/tanh(1.8)',aecho=0.8:0.5:40:0.2"
fx lamassu  "asetrate=44100*0.68,aresample=44100,aeval='tanh(1.6*val(0))/tanh(1.6)',aecho=0.8:0.88:110|220:0.45|0.25,highpass=f=50"
fx fenrir   "asetrate=44100*0.8,aresample=44100,vibrato=f=5:d=0.25,aecho=0.8:0.85:120|240:0.4|0.25"
python3 - <<'PY'
import wave, numpy as np, subprocess
SLOT, SR = 5.0, 44100
order = ["minotaur", "dullahan", "sphinx", "jaguar", "lamassu", "fenrir"]
out = np.zeros(int(SLOT * SR * len(order)))
for i, name in enumerate(order):
    w = wave.open(f"{name}_fx.wav"); x = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').astype(float) / 32768
    start = max(0, int(np.argmax(np.abs(x) > 0.02 * np.max(np.abs(x)))) - int(0.01 * SR)); x = x[start:]
    above = np.where(np.abs(x) > 0.01 * np.max(np.abs(x)))[0]; x = x[: above[-1] + int(0.05 * SR)]
    x = x[: int((SLOT - 0.15) * SR)]; x = x / np.max(np.abs(x)) * 0.89
    a = int(i * SLOT * SR); out[a:a + len(x)] = x
    print(name, round(len(x) / SR, 2), "s")
with wave.open("guardian_shouts.wav", "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((out * 32767).astype('<i2').tobytes())
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", "guardian_shouts.wav", "-c:a", "libvorbis", "-q:a", "6", "guardian_shouts.ogg"], check=True)
PY
