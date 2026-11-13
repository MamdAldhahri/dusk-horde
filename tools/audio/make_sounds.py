"""Synthesises the placeholder sound effects and music loops for Dusk Horde
and writes them as .ogg files to assets/audio/. Every sound is made from
scratch here (noise, oscillators, filters), so there are no licences to track.
Replace any file with a real recording of the same name later.

Needs numpy and ffmpeg (with libvorbis).
Run from the repo root:  python3 tools/audio/make_sounds.py
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
SR = 22050
rng = np.random.default_rng(5)


def t(seconds):
    return np.arange(int(SR * seconds)) / SR


def noise(seconds):
    return rng.uniform(-1, 1, int(SR * seconds))


def band(x, lo, hi, circular=False):
    """FFT band-pass between lo and hi Hz with soft edges. Circular filtering
    keeps music loops seamless; sound effects are padded so they don't wrap."""
    n = len(x)
    pad = 0 if circular else n
    spec = np.fft.rfft(np.concatenate([x, np.zeros(pad)]))
    f = np.fft.rfftfreq(n + pad, 1 / SR)
    gain = 1 / (1 + (lo / np.maximum(f, 1)) ** 4) if lo > 0 else np.ones_like(f)
    gain = gain / (1 + (f / hi) ** 4)
    return np.fft.irfft(spec * gain, n + pad)[:n]


def env(n, attack, decay):
    """Fast attack, exponential decay (seconds)."""
    tt = np.arange(n) / SR
    a = np.minimum(1, tt / max(attack, 1e-4))
    return a * np.exp(-tt / decay)


def sweep(f0, f1, seconds, shape=np.sin):
    tt = t(seconds)
    freq = f0 * (f1 / f0) ** (tt / seconds)
    return shape(2 * np.pi * np.cumsum(freq) / SR)


def saw(phase):
    return 2 * (phase / (2 * np.pi) % 1) - 1


def norm(x, peak=0.9):
    m = np.max(np.abs(x))
    return x / m * peak if m > 0 else x


def write(name, x):
    x = np.clip(x, -1, 1)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, name + ".wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((x * 32767).astype(np.int16).tobytes())
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4",
             os.path.join(OUT, name + ".ogg")],
            check=True,
        )


def gunshot(seconds, lo, hi, boom_hz, boom, decay):
    n = int(SR * seconds)
    crack = band(noise(seconds), lo, hi) * env(n, 0.001, decay)
    thump = np.sin(2 * np.pi * boom_hz * t(seconds) * np.exp(-t(seconds) * 8)) * env(n, 0.002, decay * 1.5)
    return norm(crack + boom * thump)


# ------------------------------------------------------------------ SFX ---
sfx = {}
sfx["pistol"] = gunshot(0.22, 300, 5000, 90, 0.8, 0.04)
sfx["smg"] = gunshot(0.11, 600, 7000, 120, 0.4, 0.022) * 0.8
sfx["shotgun"] = gunshot(0.45, 150, 3500, 60, 1.4, 0.09)
sfx["rifle"] = gunshot(0.2, 800, 9000, 110, 0.6, 0.03)
sfx["empty"] = norm(band(noise(0.04), 2000, 8000) * env(int(SR * 0.04), 0.0005, 0.006)) * 0.6

n = int(SR * 0.3)
click = band(noise(0.3), 1500, 7000)
clack = np.zeros(n)
clack[: int(SR * 0.03)] = click[: int(SR * 0.03)] * env(int(SR * 0.03), 0.0005, 0.008)
clack[int(SR * 0.18): int(SR * 0.22)] += click[: int(SR * 0.04)] * env(int(SR * 0.04), 0.0005, 0.012) * 1.3
sfx["reload"] = norm(clack) * 0.7

sfx["hit"] = norm(band(noise(0.09), 200, 1800) * env(int(SR * 0.09), 0.001, 0.025)) * 0.6

tt = t(0.6)
groan = saw(2 * np.pi * np.cumsum(110 * np.exp(-tt * 1.2) * (1 + 0.04 * np.sin(2 * np.pi * 7 * tt))) / SR)
sfx["zombie_die"] = norm(band(groan + 0.4 * noise(0.6), 80, 900) * env(len(tt), 0.02, 0.22))

chirp = sweep(2400, 500, 0.35) * (1 + 0.5 * np.sin(2 * np.pi * 60 * t(0.35)))
sfx["alien_die"] = norm(band(chirp + 0.2 * noise(0.35), 300, 6000) * env(len(chirp), 0.005, 0.12)) * 0.8

tt = t(0.9)
explosion = band(noise(0.9), 30, 1200) * env(len(tt), 0.003, 0.25)
explosion += 0.8 * np.sin(2 * np.pi * 45 * tt) * env(len(tt), 0.005, 0.3)
sfx["explosion"] = norm(np.tanh(explosion * 2))

tt = t(0.25)
sfx["hurt"] = norm(np.tanh(3 * (np.sin(2 * np.pi * 70 * tt) + 0.5 * band(noise(0.25), 100, 900))) * env(len(tt), 0.002, 0.08))

whoosh = band(noise(0.3), 400, 2500) * np.sin(np.pi * t(0.3) / 0.3) ** 2
sfx["dodge"] = norm(whoosh) * 0.6

tt = t(0.25)
chime = np.sin(2 * np.pi * 880 * tt) * env(len(tt), 0.002, 0.08)
chime[int(SR * 0.07):] += (np.sin(2 * np.pi * 1320 * tt) * env(len(tt), 0.002, 0.1))[: len(tt) - int(SR * 0.07)]
sfx["pickup"] = norm(chime) * 0.6

zap = sweep(300, 1400, 0.3, lambda p: np.sign(np.sin(p))) * env(int(SR * 0.3), 0.01, 0.12)
sfx["plasma"] = norm(band(zap, 200, 5000)) * 0.6

tt = t(1.8)
beam = saw(2 * np.pi * 95 * tt) + 0.6 * saw(2 * np.pi * 142.5 * tt) + 0.3 * noise(1.8)
beam *= (0.7 + 0.3 * np.sin(2 * np.pi * 13 * tt)) * np.minimum(1, tt / 0.05) * np.minimum(1, (1.8 - tt) / 0.2)
sfx["beam"] = norm(band(beam, 60, 3000)) * 0.7

tt = t(1.4)
roar = saw(2 * np.pi * np.cumsum(60 + 25 * np.sin(2 * np.pi * 1.3 * tt)) / SR)
roar = np.tanh(3 * band(roar + 0.6 * noise(1.4), 50, 1400)) * env(len(tt), 0.08, 0.6)
sfx["boss_roar"] = norm(roar)

tt = t(1.2)
drum = np.sin(2 * np.pi * 55 * tt * np.exp(-tt * 2)) * env(len(tt), 0.002, 0.35)
drum += 0.3 * band(noise(1.2), 60, 400) * env(len(tt), 0.002, 0.15)
sfx["wave_start"] = norm(drum)

tt = t(0.7)
arp = np.zeros(len(tt))
for i, f in enumerate([523, 659, 784, 1047]):
    s = int(SR * 0.1 * i)
    arp[s:] += (np.sin(2 * np.pi * f * tt) * env(len(tt), 0.003, 0.15))[: len(tt) - s]
sfx["unlock"] = norm(arp) * 0.7

tt = t(2.5)
chord = sum(np.sin(2 * np.pi * f * tt) for f in (196, 247, 294, 392))
sfx["dawn"] = norm(chord * np.minimum(1, tt / 0.6) * np.exp(-tt / 1.2)) * 0.7

# ---------------------------------------------------------------- music ---
L = 32.0  # seconds; every frequency below is a multiple of 1/L so it loops
tt = t(L)


def q(f):
    """Snap a frequency to a whole number of cycles per loop."""
    return round(f * L) / L


def tone(f, shape=np.sin):
    return shape(2 * np.pi * q(f) * tt)


def gas_station():
    # Low, uneasy drone: detuned saws through a dark filter, a slow heartbeat,
    # and a dissonant metal ping now and then.
    drone = sum(tone(f, saw) for f in (55, 55.4, 82.4, 58.3))
    drone = band(drone, 30, 260, circular=True) * (0.75 + 0.25 * tone(1 / 8))
    beat = np.zeros(len(tt))
    for k in range(int(L / 1.6)):
        s = int(SR * k * 1.6)
        for off, amp in ((0, 1.0), (0.28, 0.6)):
            p = s + int(SR * off)
            seg = np.sin(2 * np.pi * 48 * t(0.35)) * env(int(SR * 0.35), 0.005, 0.09) * amp
            end = min(len(beat), p + len(seg))
            beat[p:end] += seg[: end - p]
    pings = np.zeros(len(tt))
    for start, f in ((5, 622), (13.5, 587), (21, 659), (27.5, 554)):
        p = int(SR * start)
        seg = (np.sin(2 * np.pi * f * t(3)) + 0.5 * np.sin(2 * np.pi * f * 2.76 * t(3))) * env(int(SR * 3), 0.01, 0.9)
        pings[p:p + len(seg)] += seg[: len(pings) - p]
    wind = band(rng.uniform(-1, 1, len(tt)), 200, 900, circular=True) * (0.5 + 0.5 * tone(1 / 16))
    return norm(0.9 * norm(drone) + 0.6 * norm(beat) + 0.25 * norm(pings) + 0.18 * norm(wind), 0.6)


def crash_site():
    # Alien night: a wavering theremin-like line, a pulsing synth bass, and a
    # hiss like something breathing in the hive.
    vib = 6 * np.sin(2 * np.pi * q(5.5) * tt)
    line_f = 330 + 60 * np.sin(2 * np.pi * q(1 / 4) * tt) + 25 * np.sin(2 * np.pi * q(3 / 32) * tt)
    phase = 2 * np.pi * np.cumsum(line_f + vib) / SR
    # Close the loop exactly: shift the phase so it ends on a whole cycle.
    phase -= np.linspace(0, phase[-1] - 2 * np.pi * round(phase[-1] / (2 * np.pi)), len(phase))
    theremin = np.sin(phase) * (0.5 + 0.5 * np.sin(2 * np.pi * q(1 / 8) * tt) ** 2)
    pulse = (tone(2) > 0.6).astype(float)
    bass = band(tone(41.2, saw) + tone(41.6, saw), 30, 200, circular=True) * band(pulse, 0, 30, circular=True)
    hive = band(rng.uniform(-1, 1, len(tt)), 1500, 6000, circular=True) * (0.5 + 0.5 * tone(1 / 2)) ** 3
    pad = band(sum(tone(f, saw) for f in (110, 116.5, 164.8)), 60, 500, circular=True)
    return norm(0.45 * norm(theremin) + 0.8 * norm(bass) + 0.2 * norm(hive) + 0.5 * norm(pad), 0.6)


os.makedirs(OUT, exist_ok=True)
for name, x in sfx.items():
    write(name, x)
write("music_gas_station", gas_station())
write("music_crash_site", crash_site())
print("wrote", len(sfx), "effects and 2 music loops")
