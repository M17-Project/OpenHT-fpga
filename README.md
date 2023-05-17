# OpenHT-fpga
OpenHT FPGA design - a complete Lattice Radiant project for the **LIFCL-40-7SG72C**.

## Functionality
### Generic modulators:
- [x] frequency modulator
- [x] amplitude modulator
- [x] phase modulator
- [x] single sideband (SSB)
- [x] 16QAM (Gray-coded)
- [x] arbitrary I/Q
- [ ] 32APSK

### Generic demodulators:
- [x] frequency demodulator
- [x] amplitude demodulator
- [ ] phase demodulator
- [ ] single sideband (SSB)
- [ ] arbitrary constellation map

### Other:
- [x] I/Q raw sample access over SPI
- [x] optional phase dither for the frequency/phase modulator
- [x] Received Signal Strength Indicator (RSSI) estimation
- [ ] symbol recovery, clock sync

### Supported modes<br>
Analog: FM, AM, SSB, OOK (CW)<br>
Digital: M17, FreeDV, crude "4FSK", SSTV, 16QAM, BPSK/QPSK/DQPSK, OFDM, AFSK, APRS

**Note:** automatic gain control (AGC) is done by the RF transceiver chip. Not all modes are yet implemented in the firmware.

## Block diagram
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/OpenHT-fpga.drawio.png" width="800">

## Register map
The register map is listed in `/docs/OpenHT_reg_map.pdf`.

## Gallery
### Transmission
M17 (baseband via SPI)<br>
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/4FSK_M17_test.png" width="800">

SSB (USB) - FreeDV (baseband via SPI)<br>
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/USB_FreeDV_test.png" width="800">

16QAM (unfiltered, internally generated, pseudorandom "staircase" baseband)<br>
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/16QAM_test.png" width="800">

BPSK/QPSK (unfiltered, internally generated, pseudorandom "staircase" baseband)<br>
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/BPSK_test.png" width="800">
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/QPSK_test.png" width="800">

### Reception
M17<br>
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/4FSK_M17_test_RX.png" width="800">
