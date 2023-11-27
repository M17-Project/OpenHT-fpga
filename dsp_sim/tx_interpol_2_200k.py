#!/usr/bin/env python
import numpy as np
import matplotlib.pyplot as plt
from scipy.fft import fft
from scipy import signal

fs = 200000
freq = 3400
L = 2
x = np.arange(3000)
Q = 16

def quantize(val, bits):
    return int(val * (2**bits))/2**bits

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

fir = signal.remez(100, [0, 4400, 30000, fs*L/2], [1.0, 0], fs=fs*L)

print('')
print('Python-like taps:')
for i in enumerate(fir):
    r=fir[i[0]];
    print(f"{r:f}", end=', ')
    if (i[0] + 1) % L == 0:
        print('')
print('')

fir = np.array([quantize(x, Q) for x in fir])

plt.subplot(4,2,5)
plt.plot(fir)

plt.subplot(4,2,6)
w,h = signal.freqz(fir)
plt.plot(w, 20*np.log(h))

interpol = signal.lfilter(fir, 1, sig_upsampled)
plt.subplot(4,2,7)
plt.plot(interpol)

plt.subplot(4,2,8)
plt.plot(np.arange(3000*L) / 3000 * fs,20*np.log(fft(interpol)))

for i in enumerate(fir):
    r = int(i[1] * 2**Q)
    if r < 0:
        r += 2**Q
    print(f"x\"{r:04x}\"", end=', ')
    if (i[0] + 1) % 8 == 0:
        print('')

# HDL concept check
#print(interpol)
hdl_impl = np.zeros(len(x) * L)
for i in range(L):
    i_filt = fir[i::L]
    hdl_impl[i::L] = signal.lfilter(i_filt, 1, incoming_sig)

for k in range(len(x) * L):
    ref = quantize(interpol[k], Q)
    hdl = quantize(hdl_impl[k], Q)
    #print(k, ref, hdl, ref == hdl)
    if (ref != hdl):
        print("Check failed")
        break



plt.show()
