import numpy as np
import wave
import os

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")


def save(name, x):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(name, round(len(x) / SR, 1), "s")


def fft_lp(x, cutoff, sr=SR):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    X *= 1.0 / (1.0 + (f / cutoff) ** 3)
    return np.fft.irfft(X, len(x))


def fft_bp(x, lo, hi, sr=SR):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    X *= 1.0 / (1.0 + (f / lo) ** 3)
    X *= 1.0 / (1.0 + (hi / np.maximum(f, 1e-6)) ** 3)
    return np.fft.irfft(X, len(x))


def loop_xfade(x, fade_s):
    n = int(fade_s * SR)
    head = x[:n].copy()
    tail = x[-n:].copy()
    t = np.linspace(0, np.pi / 2, n)
    out = x[:-n].copy()
    out[:n] = out[:n] * np.sin(t) + tail * np.cos(t)
    return out


def pad(f, dur):
    t = np.linspace(0, dur, int(SR * dur), False)
    env = np.clip(np.minimum(t / 1.2, 1.0) * np.minimum((dur - t) / 1.6, 1.0), 0, 1)
    x = (np.sin(2 * np.pi * f * t)
         + 0.4 * np.sin(2 * np.pi * f * 2 * t)
         + 0.13 * np.sin(2 * np.pi * f * 3 * t))
    trem = 1.0 + 0.22 * np.sin(2 * np.pi * 0.9 * t)
    return x * env * trem


def theme():
    notes = [293.66, 329.63, 369.99, 440.0, 493.88, 440.0, 369.99, 329.63]
    slot = 3.25
    total = slot * len(notes)
    x = np.zeros(int(SR * total))
    for i, f in enumerate(notes):
        seg = pad(f, slot * 1.9)
        s = int(i * slot * SR)
        e = min(s + len(seg), len(x))
        x[s:e] += seg[: e - s] * 0.55
    t = np.linspace(0, total, len(x), False)
    x += (np.sin(2 * np.pi * 73.42 * t) + np.sin(2 * np.pi * 110.0 * t) * 0.6) * 0.05
    x = x / np.max(np.abs(x)) * 0.55
    save("dali_theme.wav", loop_xfade(x, 0.5))


def lake():
    dur = 14.0
    n = int(SR * dur)
    rng = np.random.default_rng(7)
    noise = rng.standard_normal(n)
    t = np.linspace(0, dur, n, False)
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * 0.07 * t + 1.0)
    lap = ((0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * t))
           * (0.5 + 0.5 * np.sin(2 * np.pi * 0.053 * t + 2.0)))
    x = fft_lp(noise, 420) * swell + fft_bp(noise, 700, 2200) * lap * 0.08
    x = x / np.max(np.abs(x)) * 0.6
    save("lake.wav", loop_xfade(x, 0.6))


def gust():
    dur = 4.0
    n = int(SR * dur)
    rng = np.random.default_rng(11)
    noise = rng.standard_normal(n)
    t = np.linspace(0, dur, n, False)
    lo = fft_bp(noise, 180, 480)
    hi = fft_bp(noise, 500, 1200)
    m = np.sin(np.pi * t / dur) ** 2
    x = lo * (1 - m * 0.6) + hi * m * 0.8
    x *= np.minimum(t / 0.8, 1) * np.minimum((dur - t) / 0.8, 1)
    x = x / np.max(np.abs(x)) * 0.7
    save("gust.wav", loop_xfade(x, 0.4))


if __name__ == "__main__":
    theme()
    lake()
    gust()
