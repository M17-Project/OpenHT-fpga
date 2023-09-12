#!/usr/bin/env python3
import math

N=16
AMPL = 0x4000
for i in range(N):
    angle = hex(int(2**16 * i / N))
    angle_rad = 2*math.pi*i/N
    c = hex(int(AMPL * math.cos(angle_rad)))
    s = hex(int(AMPL * math.sin(angle_rad)))
    print(angle, c, s)