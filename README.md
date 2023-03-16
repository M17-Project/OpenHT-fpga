# OpenHT-fpga
OpenHT FPGA design - a complete Lattice Radiant project for the **LIFCL-40-7SG72C**.

## Functionality
### Generic modulators:
- [x] frequency modulator
- [x] amplitude modulator
- [ ] phase modulator
- [x] single sideband (SSB)
- [x] 16QAM (Gray-coded)
- [ ] 32APSK
- [x] arbitrary I/Q

### Generic demodulators:
- [x] frequency demodulator
- [x] amplitude demodulator
- [ ] phase demodulator
- [ ] single sideband (SSB)
- [ ] arbitrary constellation map

### Other:
- [x] I/Q raw sample access over SPI
- [x] optional phase dither for the frequency/phase modulator
- [ ] symbol recovery, clock sync

### Supported modes<br>
Analog: FM, AM, SSB, OOK<br>
Digital: M17, FreeDV, crude "4FSK", SSTV, 16QAM

**Note:** automatic gain control (AGC) is done by the RF transceiver chip.

## Block diagram
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/OpenHT-fpga.drawio.png" width="800">

## Register map
The register map is listed in `/docs/OpenHT_reg_map.pdf`.

## Gallery
Transmitting M17...<br>
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/4FSK_M17_test.png" width="800">

... and 16QAM (unfiltered, "staircase" baseband)<br>
<img src="https://github.com/M17-Project/OpenHT-fpga/blob/main/docs/16QAM_test.png" width="800">
