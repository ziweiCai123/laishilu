import numpy as np, wave, os

SR = 22050
out = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'audio'))
os.makedirs(out, exist_ok=True)

def save(name, y):
    y = np.clip(y, -1, 1)
    data = (y * 32767 * 0.85).astype('<i2')
    with wave.open(os.path.join(out, name), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())
    print('saved', name, len(y) / SR, 's')

# 风声:白噪声经圆周 FFT 低通(循环天然无缝) + 整周期阵风 LFO
dur = 12.0
n = int(SR * dur)
rng = np.random.default_rng(11)
x = rng.standard_normal(n)
X = np.fft.rfft(x)
freqs = np.fft.rfftfreq(n, 1 / SR)
X *= np.exp(-np.clip(freqs - 90, 0, None) / 160.0)
y = np.fft.irfft(X, n)
t = np.arange(n) / SR
y *= 0.55 + 0.45 * np.sin(2 * np.pi * 3 * t / dur + 1.2) ** 2
y /= np.max(np.abs(y)); y *= 0.6
save('wind.wav', y)

# 风铃:分音叠加指数衰减
dur = 4.0
n = int(SR * dur)
t = np.arange(n) / SR
y = np.zeros(n)
for f, a, dcy in [(784, 1.0, 1.6), (1568, 0.45, 1.1), (2291, 0.28, 0.8), (3220, 0.16, 0.55)]:
    ph = np.random.default_rng(f).standard_normal()
    y += a * np.sin(2 * np.pi * f * t + ph) * np.exp(-t * dcy)
trem = 0.5 + 0.5 * np.sin(2 * np.pi * 5.2 * t)
y += 0.12 * np.sin(2 * np.pi * 784 * t) * np.exp(-t * 0.9) * trem
y /= np.max(np.abs(y)); y *= 0.55
save('chime.wav', y)

# 拾起记忆的低钟:更沉更长
dur = 5.0
n = int(SR * dur)
t = np.arange(n) / SR
y = np.zeros(n)
for f, a, dcy in [(392, 1.0, 1.2), (784, 0.4, 0.9), (1176, 0.2, 0.7), (196, 0.5, 0.6)]:
    ph = np.random.default_rng(f).standard_normal()
    y += a * np.sin(2 * np.pi * f * t + ph) * np.exp(-t * dcy)
y /= np.max(np.abs(y)); y *= 0.5
save('collect.wav', y)

# 痊愈之声:五声音阶 pad(宫商角徵羽+高宫),世界随收集苏醒
def pad(freq, dur=9.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    y = (np.sin(2 * np.pi * freq * t) + 0.38 * np.sin(2 * np.pi * freq * 2 * t + 0.5)
         + 0.14 * np.sin(2 * np.pi * freq * 3 * t + 1.1) + 0.5 * np.sin(2 * np.pi * freq * 1.003 * t + 2.0))
    att = np.clip(t / 1.4, 0, 1) ** 2
    rel = np.exp(-np.maximum(t - dur * 0.45, 0) * 0.9)
    return y * att * rel

for i, f in enumerate([261.6, 293.7, 329.6, 392.0, 440.0, 523.3]):
    y = pad(f)
    y /= np.max(np.abs(y)); y *= 0.5
    save(f'note_{i}.wav', y)

# 低谷的低音持续(整周期循环无缝)
dur = 10.0
n = int(SR * dur)
t = np.arange(n) / SR
y = 0.8 * np.sin(2 * np.pi * 65.4 * t) + 0.5 * np.sin(2 * np.pi * 98.0 * t + 1.0) + 0.25 * np.sin(2 * np.pi * 130.8 * t + 2.0)
y *= 0.7 + 0.3 * np.sin(2 * np.pi * 2 * t / dur)
y /= np.max(np.abs(y)); y *= 0.5
save('drone.wav', y)

# 脚步:草/雪/石(短噪声脉冲,频域滚降塑形)
def fft_lp(x, cutoff):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1.0 / (1.0 + (f / cutoff) ** 3)
    return np.fft.irfft(X, len(x))

def step(kind):
    if kind == 'stone':
        n = int(SR * 0.12)
    else:
        n = int(SR * 0.16)
    t = np.arange(n) / SR
    if kind == 'grass':
        y = fft_lp(np.random.default_rng(3).standard_normal(n), 900) * np.exp(-t * 55)
    elif kind == 'snow':
        rng = np.random.default_rng(4)
        y = fft_lp(rng.standard_normal(n), 2600) * np.exp(-t * 70)
        y += 0.55 * fft_lp(rng.standard_normal(n), 2000) * np.exp(-np.maximum(t - 0.02, 0) * 60)
    else:
        thud = np.sin(2 * np.pi * 95 * t) * np.exp(-t * 45)
        tap = fft_lp(np.random.default_rng(5).standard_normal(n), 1400) * np.exp(-t * 80)
        y = thud * 0.8 + tap * 0.5
    y /= np.max(np.abs(y)); y *= 0.5
    save(f'step_{kind}.wav', y)

for k in ['grass', 'snow', 'stone']:
    step(k)
print('audio ok')
