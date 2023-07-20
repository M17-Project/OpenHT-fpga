#!/usr/bin/env python
import numpy as np
import matplotlib.pyplot as plt
from scipy.fft import fft
from scipy import signal

fs = 8000
freq = 10
L = 5
x = np.arange(2048)
Q = 16

incoming_sig = np.sin(2 * np.pi * freq * x/fs)
print(incoming_sig)
plt.subplot(4,2,1)
plt.plot(incoming_sig)
plt.subplot(4,2,2)
plt.plot(20*np.log(fft(incoming_sig)))

sig_upsampled = np.zeros(len(x) * L)
sig_upsampled[::L] = incoming_sig
plt.subplot(4,2,3)
plt.plot(sig_upsampled)
plt.subplot(4,2,4)
plt.plot(20*np.log(fft(sig_upsampled)))

fir = signal.remez(400, [0, 3800, 4200, fs*L/2], [1,0], fs=fs*L) * L
fir = np.array([int(x * 2**Q) for x in fir]) / 2**Q

plt.subplot(4,2,5)
plt.plot(fir)

plt.subplot(4,2,6)
w,h = signal.freqz(fir)
plt.plot(w, 20*np.log(h))

interpol = signal.lfilter(fir, 1, sig_upsampled)
plt.subplot(4,2,7)
plt.plot(interpol)

plt.subplot(4,2,8)
plt.plot(20*np.log(fft(interpol)))

plt.show()
