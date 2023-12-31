<!---
Markdown description for SystemRDL register map.

Don't override. Generated from: openht
  - openht.rdl
-->

## openht address map

- Absolute Address: 0x0
- Base Offset: 0x0
- Size: 0xE00A

<p>APB registers</p>

|Offset| Identifier |        Name        |
|------|------------|--------------------|
|0x0000| common_regs| OpenHT common regs |
|0x1000|   tx_regs  |   OpenHT TX regs   |
|0x2000|   tx_fir0  |     OpenHT FIR     |
|0x3000|  tx_ctcss  |OpenHT TX CTCSS regs|
|0x4000|   tx_fir1  |     OpenHT FIR     |
|0x5000|   tx_fir2  |     OpenHT FIR     |
|0x6000|   tx_fir3  |     OpenHT FIR     |
|0x7000|  tx_iq_bal |OpenHT TX IQ Balance|
|0x8000|tx_iq_offset| OpenHT TX IQ Offset|
|0x9000|   rx_fir0  |     OpenHT FIR     |
|0xA000|   rx_fir1  |     OpenHT FIR     |
|0xB000|   rx_fir2  |     OpenHT FIR     |
|0xC000|  rx_demod  |   OpenHT RX Demod  |
|0xD000|   rx_fir3  |     OpenHT FIR     |
|0xE000|   rx_rssi  |   OpenHT RX RSSI   |

## common_regs register file

- Absolute Address: 0x0
- Base Offset: 0x0
- Size: 0x10

<p>Common APB registers for RX and TX side of OpenHT</p>

|Offset|  Identifier  |           Name          |
|------|--------------|-------------------------|
|  0x0 |    VERSION   |     Version Register    |
|  0x2 |    STATUS    |     Status Register     |
|  0x4 |     CTRL     |     Control Register    |
|  0x6 |      IO      |IO configuration register|
|  0x8 |    TX_FIFO   |       TX data fifo      |
|  0xA |TX_FIFO_STATUS|   TX data fifo status   |
|  0xC |    RX_FIFO   |       TX data fifo      |
|  0xE |RX_FIFO_STATUS|   RX data fifo status   |

### VERSION register

- Absolute Address: 0x0
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 7:0|   MINOR  |   r  |  —  |  — |
|15:8|   MAJOR  |   r  |  —  |  — |

#### MINOR field

<p>Minor Version</p>

#### MAJOR field

<p>Major Version</p>

### STATUS register

- Absolute Address: 0x2
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 | PLL_LOCK |   r  |  —  |  — |

#### PLL_LOCK field

<p>PLL lock</p>

### CTRL register

- Absolute Address: 0x4
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 1:0|   RXTX   |  rw  |  —  |  — |
|  2 |   BAND   |  rw  |  —  |  — |

#### RXTX field

<p>RX or TX</p>

#### BAND field

<p>Band Selection</p>

### IO register

- Absolute Address: 0x6
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 2:0|    IO3   |  rw  |  —  |  — |
| 5:3|    IO4   |  rw  |  —  |  — |
| 8:6|    IO5   |  rw  |  —  |  — |
|11:9|    IO6   |  rw  |  —  |  — |

#### IO3 field

<p>IO3 configuration</p>

#### IO4 field

<p>IO4 configuration</p>

#### IO5 field

<p>IO5 configuration</p>

#### IO6 field

<p>IO6 configuration</p>

### TX_FIFO register

- Absolute Address: 0x8
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|  TX_DATA |   w  |  —  |  — |

#### TX_DATA field

<p>Transmit data</p>

### TX_FIFO_STATUS register

- Absolute Address: 0xA
- Base Offset: 0xA
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 7:0|   COUNT  |   r  |  —  |  — |
|  8 |    AF    |   r  |  —  |  — |
|  9 |    AE    |   r  |  —  |  — |
| 10 |   FULL   |   r  |  —  |  — |
| 11 |   EMPTY  |   r  |  —  |  — |

#### COUNT field

<p>Data count</p>

#### AF field

<p>Data FIFO almost full</p>

#### AE field

<p>Data FIFO almost empty</p>

#### FULL field

<p>Data FIFO full</p>

#### EMPTY field

<p>Data FIFO empty</p>

### RX_FIFO register

- Absolute Address: 0xC
- Base Offset: 0xC
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|  RX_DATA |   r  |  —  |  — |

#### RX_DATA field

<p>Receive data</p>

### RX_FIFO_STATUS register

- Absolute Address: 0xE
- Base Offset: 0xE
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 7:0|   COUNT  |   r  |  —  |  — |
|  8 |    AF    |   r  |  —  |  — |
|  9 |    AE    |   r  |  —  |  — |
| 10 |   FULL   |   r  |  —  |  — |
| 11 |   EMPTY  |   r  |  —  |  — |

#### COUNT field

<p>Data count</p>

#### AF field

<p>Data FIFO almost full</p>

#### AE field

<p>Data FIFO almost empty</p>

#### FULL field

<p>Data FIFO full</p>

#### EMPTY field

<p>Data FIFO empty</p>

## tx_regs register file

- Absolute Address: 0x1000
- Base Offset: 0x1000
- Size: 0x2

<p>APB registers for TX side of OpenHT</p>

|Offset|Identifier|      Name      |
|------|----------|----------------|
|  0x0 |   CTRL   |Control Register|

### CTRL register

- Absolute Address: 0x1000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 2:0|   MODE   |  rw  |  —  |  — |
|  3 |    FMW   |  rw  |  —  |  — |
|  4 |    SSB   |  rw  |  —  |  — |

#### MODE field

<p>Mode</p>

#### FMW field

<p>FM narrow/wide</p>

#### SSB field

<p>LSB/USB</p>

## tx_fir0 register file

- Absolute Address: 0x2000
- Base Offset: 0x2000
- Size: 0x10

<p>APB registers for FIR filter</p>

|Offset|Identifier|        Name       |
|------|----------|-------------------|
|  0x0 |   CTRL   |  Control Register |
|  0x2 |   TAPS   |        Taps       |
|  0x4 |     L    |   Interpolation   |
|  0x6 |     M    |     Decimation    |
|  0x8 | TAPS_ADDR|    Taps address   |
|  0xA | TAPS_DATA|     Taps data     |
|  0xC |  I_SHIFT |I Accumulator shift|
|  0xE |  Q_SHIFT |Q Accumulator shift|

### CTRL register

- Absolute Address: 0x2000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |  ENABLED |  rw  |  —  |  — |
|  1 | DUPLICATE|  rw  |  —  |  — |

#### ENABLED field

<p>Enabled</p>

#### DUPLICATE field

<p>Copy I value into Q</p>

### TAPS register

- Absolute Address: 0x2002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   COUNT  |  rw  |  —  |  — |

#### COUNT field

<p>Taps count</p>

### L register

- Absolute Address: 0x2004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Interpolation</p>

### M register

- Absolute Address: 0x2006
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Decimation</p>

### TAPS_ADDR register

- Absolute Address: 0x2008
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   ADDR   |  rw  |  —  |  — |

#### ADDR field

<p>Address</p>

### TAPS_DATA register

- Absolute Address: 0x200A
- Base Offset: 0xA
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   DATA   |   w  |  —  |  — |

#### DATA field

<p>Data</p>

### I_SHIFT register

- Absolute Address: 0x200C
- Base Offset: 0xC
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

### Q_SHIFT register

- Absolute Address: 0x200E
- Base Offset: 0xE
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

## tx_ctcss register file

- Absolute Address: 0x3000
- Base Offset: 0x3000
- Size: 0x6

<p>APB registers for CTCSS of OpenHT</p>

|Offset|Identifier|        Name        |
|------|----------|--------------------|
|  0x0 |   CTRL   |  Control Register  |
|  0x2 | AMPLITUDE| Amplitude Register |
|  0x4 | TUNING_W |Tuning word Register|

### CTRL register

- Absolute Address: 0x3000
- Base Offset: 0x0
- Size: 0x2

|Bits| Identifier|Access|Reset|Name|
|----|-----------|------|-----|----|
|  0 |   ENABLE  |  rw  |  —  |  — |
|  1 |  IN_MODE  |  rw  |  —  |  — |
|  2 |ADD_REPLACE|  rw  |  —  |  — |

#### ENABLE field

<p>Enabled</p>

#### IN_MODE field

<p>Input Mode</p>

#### ADD_REPLACE field

<p>Add or replace stream</p>

### AMPLITUDE register

- Absolute Address: 0x3002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0| AMPLITUDE|  rw  |  —  |  — |

#### AMPLITUDE field

<p>CTCSS generator amplitude</p>

### TUNING_W register

- Absolute Address: 0x3004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|    TW    |  rw  |  —  |  — |

#### TW field

<p>Tuning word</p>

## tx_fir1 register file

- Absolute Address: 0x4000
- Base Offset: 0x4000
- Size: 0x10

<p>APB registers for FIR filter</p>

|Offset|Identifier|        Name       |
|------|----------|-------------------|
|  0x0 |   CTRL   |  Control Register |
|  0x2 |   TAPS   |        Taps       |
|  0x4 |     L    |   Interpolation   |
|  0x6 |     M    |     Decimation    |
|  0x8 | TAPS_ADDR|    Taps address   |
|  0xA | TAPS_DATA|     Taps data     |
|  0xC |  I_SHIFT |I Accumulator shift|
|  0xE |  Q_SHIFT |Q Accumulator shift|

### CTRL register

- Absolute Address: 0x4000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |  ENABLED |  rw  |  —  |  — |
|  1 | DUPLICATE|  rw  |  —  |  — |

#### ENABLED field

<p>Enabled</p>

#### DUPLICATE field

<p>Copy I value into Q</p>

### TAPS register

- Absolute Address: 0x4002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   COUNT  |  rw  |  —  |  — |

#### COUNT field

<p>Taps count</p>

### L register

- Absolute Address: 0x4004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Interpolation</p>

### M register

- Absolute Address: 0x4006
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Decimation</p>

### TAPS_ADDR register

- Absolute Address: 0x4008
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   ADDR   |  rw  |  —  |  — |

#### ADDR field

<p>Address</p>

### TAPS_DATA register

- Absolute Address: 0x400A
- Base Offset: 0xA
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   DATA   |   w  |  —  |  — |

#### DATA field

<p>Data</p>

### I_SHIFT register

- Absolute Address: 0x400C
- Base Offset: 0xC
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

### Q_SHIFT register

- Absolute Address: 0x400E
- Base Offset: 0xE
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

## tx_fir2 register file

- Absolute Address: 0x5000
- Base Offset: 0x5000
- Size: 0x10

<p>APB registers for FIR filter</p>

|Offset|Identifier|        Name       |
|------|----------|-------------------|
|  0x0 |   CTRL   |  Control Register |
|  0x2 |   TAPS   |        Taps       |
|  0x4 |     L    |   Interpolation   |
|  0x6 |     M    |     Decimation    |
|  0x8 | TAPS_ADDR|    Taps address   |
|  0xA | TAPS_DATA|     Taps data     |
|  0xC |  I_SHIFT |I Accumulator shift|
|  0xE |  Q_SHIFT |Q Accumulator shift|

### CTRL register

- Absolute Address: 0x5000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |  ENABLED |  rw  |  —  |  — |
|  1 | DUPLICATE|  rw  |  —  |  — |

#### ENABLED field

<p>Enabled</p>

#### DUPLICATE field

<p>Copy I value into Q</p>

### TAPS register

- Absolute Address: 0x5002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   COUNT  |  rw  |  —  |  — |

#### COUNT field

<p>Taps count</p>

### L register

- Absolute Address: 0x5004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Interpolation</p>

### M register

- Absolute Address: 0x5006
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Decimation</p>

### TAPS_ADDR register

- Absolute Address: 0x5008
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   ADDR   |  rw  |  —  |  — |

#### ADDR field

<p>Address</p>

### TAPS_DATA register

- Absolute Address: 0x500A
- Base Offset: 0xA
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   DATA   |   w  |  —  |  — |

#### DATA field

<p>Data</p>

### I_SHIFT register

- Absolute Address: 0x500C
- Base Offset: 0xC
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

### Q_SHIFT register

- Absolute Address: 0x500E
- Base Offset: 0xE
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

## tx_fir3 register file

- Absolute Address: 0x6000
- Base Offset: 0x6000
- Size: 0x10

<p>APB registers for FIR filter</p>

|Offset|Identifier|        Name       |
|------|----------|-------------------|
|  0x0 |   CTRL   |  Control Register |
|  0x2 |   TAPS   |        Taps       |
|  0x4 |     L    |   Interpolation   |
|  0x6 |     M    |     Decimation    |
|  0x8 | TAPS_ADDR|    Taps address   |
|  0xA | TAPS_DATA|     Taps data     |
|  0xC |  I_SHIFT |I Accumulator shift|
|  0xE |  Q_SHIFT |Q Accumulator shift|

### CTRL register

- Absolute Address: 0x6000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |  ENABLED |  rw  |  —  |  — |
|  1 | DUPLICATE|  rw  |  —  |  — |

#### ENABLED field

<p>Enabled</p>

#### DUPLICATE field

<p>Copy I value into Q</p>

### TAPS register

- Absolute Address: 0x6002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   COUNT  |  rw  |  —  |  — |

#### COUNT field

<p>Taps count</p>

### L register

- Absolute Address: 0x6004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Interpolation</p>

### M register

- Absolute Address: 0x6006
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Decimation</p>

### TAPS_ADDR register

- Absolute Address: 0x6008
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   ADDR   |  rw  |  —  |  — |

#### ADDR field

<p>Address</p>

### TAPS_DATA register

- Absolute Address: 0x600A
- Base Offset: 0xA
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   DATA   |   w  |  —  |  — |

#### DATA field

<p>Data</p>

### I_SHIFT register

- Absolute Address: 0x600C
- Base Offset: 0xC
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

### Q_SHIFT register

- Absolute Address: 0x600E
- Base Offset: 0xE
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

## tx_iq_bal register file

- Absolute Address: 0x7000
- Base Offset: 0x7000
- Size: 0x4

<p>IQ Balance</p>

|Offset|Identifier| Name |
|------|----------|------|
|  0x0 |  I_GAIN  |I gain|
|  0x2 |  Q_GAIN  |Q gain|

### I_GAIN register

- Absolute Address: 0x7000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   GAIN   |  rw  |  —  |  — |

#### GAIN field

<p>I Gain</p>

### Q_GAIN register

- Absolute Address: 0x7002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   GAIN   |  rw  |  —  |  — |

#### GAIN field

<p>Q gain</p>

## tx_iq_offset register file

- Absolute Address: 0x8000
- Base Offset: 0x8000
- Size: 0x4

<p>IQ Offset</p>

|Offset|Identifier|  Name  |
|------|----------|--------|
|  0x0 | I_OFFSET |I offset|
|  0x2 | Q_OFFSET |Q offset|

### I_OFFSET register

- Absolute Address: 0x8000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|  OFFSET  |  rw  |  —  |  — |

#### OFFSET field

<p>I Offset</p>

### Q_OFFSET register

- Absolute Address: 0x8002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|  OFFSET  |  rw  |  —  |  — |

#### OFFSET field

<p>Q Offset</p>

## rx_fir0 register file

- Absolute Address: 0x9000
- Base Offset: 0x9000
- Size: 0x10

<p>APB registers for FIR filter</p>

|Offset|Identifier|        Name       |
|------|----------|-------------------|
|  0x0 |   CTRL   |  Control Register |
|  0x2 |   TAPS   |        Taps       |
|  0x4 |     L    |   Interpolation   |
|  0x6 |     M    |     Decimation    |
|  0x8 | TAPS_ADDR|    Taps address   |
|  0xA | TAPS_DATA|     Taps data     |
|  0xC |  I_SHIFT |I Accumulator shift|
|  0xE |  Q_SHIFT |Q Accumulator shift|

### CTRL register

- Absolute Address: 0x9000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |  ENABLED |  rw  |  —  |  — |
|  1 | DUPLICATE|  rw  |  —  |  — |

#### ENABLED field

<p>Enabled</p>

#### DUPLICATE field

<p>Copy I value into Q</p>

### TAPS register

- Absolute Address: 0x9002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   COUNT  |  rw  |  —  |  — |

#### COUNT field

<p>Taps count</p>

### L register

- Absolute Address: 0x9004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Interpolation</p>

### M register

- Absolute Address: 0x9006
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Decimation</p>

### TAPS_ADDR register

- Absolute Address: 0x9008
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   ADDR   |  rw  |  —  |  — |

#### ADDR field

<p>Address</p>

### TAPS_DATA register

- Absolute Address: 0x900A
- Base Offset: 0xA
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   DATA   |   w  |  —  |  — |

#### DATA field

<p>Data</p>

### I_SHIFT register

- Absolute Address: 0x900C
- Base Offset: 0xC
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

### Q_SHIFT register

- Absolute Address: 0x900E
- Base Offset: 0xE
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

## rx_fir1 register file

- Absolute Address: 0xA000
- Base Offset: 0xA000
- Size: 0x10

<p>APB registers for FIR filter</p>

|Offset|Identifier|        Name       |
|------|----------|-------------------|
|  0x0 |   CTRL   |  Control Register |
|  0x2 |   TAPS   |        Taps       |
|  0x4 |     L    |   Interpolation   |
|  0x6 |     M    |     Decimation    |
|  0x8 | TAPS_ADDR|    Taps address   |
|  0xA | TAPS_DATA|     Taps data     |
|  0xC |  I_SHIFT |I Accumulator shift|
|  0xE |  Q_SHIFT |Q Accumulator shift|

### CTRL register

- Absolute Address: 0xA000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |  ENABLED |  rw  |  —  |  — |
|  1 | DUPLICATE|  rw  |  —  |  — |

#### ENABLED field

<p>Enabled</p>

#### DUPLICATE field

<p>Copy I value into Q</p>

### TAPS register

- Absolute Address: 0xA002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   COUNT  |  rw  |  —  |  — |

#### COUNT field

<p>Taps count</p>

### L register

- Absolute Address: 0xA004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Interpolation</p>

### M register

- Absolute Address: 0xA006
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Decimation</p>

### TAPS_ADDR register

- Absolute Address: 0xA008
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   ADDR   |  rw  |  —  |  — |

#### ADDR field

<p>Address</p>

### TAPS_DATA register

- Absolute Address: 0xA00A
- Base Offset: 0xA
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   DATA   |   w  |  —  |  — |

#### DATA field

<p>Data</p>

### I_SHIFT register

- Absolute Address: 0xA00C
- Base Offset: 0xC
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

### Q_SHIFT register

- Absolute Address: 0xA00E
- Base Offset: 0xE
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

## rx_fir2 register file

- Absolute Address: 0xB000
- Base Offset: 0xB000
- Size: 0x10

<p>APB registers for FIR filter</p>

|Offset|Identifier|        Name       |
|------|----------|-------------------|
|  0x0 |   CTRL   |  Control Register |
|  0x2 |   TAPS   |        Taps       |
|  0x4 |     L    |   Interpolation   |
|  0x6 |     M    |     Decimation    |
|  0x8 | TAPS_ADDR|    Taps address   |
|  0xA | TAPS_DATA|     Taps data     |
|  0xC |  I_SHIFT |I Accumulator shift|
|  0xE |  Q_SHIFT |Q Accumulator shift|

### CTRL register

- Absolute Address: 0xB000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |  ENABLED |  rw  |  —  |  — |
|  1 | DUPLICATE|  rw  |  —  |  — |

#### ENABLED field

<p>Enabled</p>

#### DUPLICATE field

<p>Copy I value into Q</p>

### TAPS register

- Absolute Address: 0xB002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   COUNT  |  rw  |  —  |  — |

#### COUNT field

<p>Taps count</p>

### L register

- Absolute Address: 0xB004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Interpolation</p>

### M register

- Absolute Address: 0xB006
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Decimation</p>

### TAPS_ADDR register

- Absolute Address: 0xB008
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   ADDR   |  rw  |  —  |  — |

#### ADDR field

<p>Address</p>

### TAPS_DATA register

- Absolute Address: 0xB00A
- Base Offset: 0xA
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   DATA   |   w  |  —  |  — |

#### DATA field

<p>Data</p>

### I_SHIFT register

- Absolute Address: 0xB00C
- Base Offset: 0xC
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

### Q_SHIFT register

- Absolute Address: 0xB00E
- Base Offset: 0xE
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

## rx_demod register file

- Absolute Address: 0xC000
- Base Offset: 0xC000
- Size: 0x2

<p>RX demodulator</p>

|Offset|Identifier|      Name      |
|------|----------|----------------|
|  0x0 |   CTRL   |Control register|

### CTRL register

- Absolute Address: 0xC000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |  ENABLE  |  rw  |  —  |  — |
| 2:1|   MODE   |  rw  |  —  |  — |

#### ENABLE field

<p>Enabled</p>

#### MODE field

<p>Mode</p>

## rx_fir3 register file

- Absolute Address: 0xD000
- Base Offset: 0xD000
- Size: 0x10

<p>APB registers for FIR filter</p>

|Offset|Identifier|        Name       |
|------|----------|-------------------|
|  0x0 |   CTRL   |  Control Register |
|  0x2 |   TAPS   |        Taps       |
|  0x4 |     L    |   Interpolation   |
|  0x6 |     M    |     Decimation    |
|  0x8 | TAPS_ADDR|    Taps address   |
|  0xA | TAPS_DATA|     Taps data     |
|  0xC |  I_SHIFT |I Accumulator shift|
|  0xE |  Q_SHIFT |Q Accumulator shift|

### CTRL register

- Absolute Address: 0xD000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |  ENABLED |  rw  |  —  |  — |
|  1 | DUPLICATE|  rw  |  —  |  — |

#### ENABLED field

<p>Enabled</p>

#### DUPLICATE field

<p>Copy I value into Q</p>

### TAPS register

- Absolute Address: 0xD002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   COUNT  |  rw  |  —  |  — |

#### COUNT field

<p>Taps count</p>

### L register

- Absolute Address: 0xD004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Interpolation</p>

### M register

- Absolute Address: 0xD006
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 3:0|   VALUE  |  rw  |  —  |  — |

#### VALUE field

<p>Decimation</p>

### TAPS_ADDR register

- Absolute Address: 0xD008
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 9:0|   ADDR   |  rw  |  —  |  — |

#### ADDR field

<p>Address</p>

### TAPS_DATA register

- Absolute Address: 0xD00A
- Base Offset: 0xA
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   DATA   |   w  |  —  |  — |

#### DATA field

<p>Data</p>

### I_SHIFT register

- Absolute Address: 0xD00C
- Base Offset: 0xC
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

### Q_SHIFT register

- Absolute Address: 0xD00E
- Base Offset: 0xE
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
| 4:0|   SHIFT  |  rw  |  —  |  — |

#### SHIFT field

<p>SHIFT</p>

## rx_rssi register file

- Absolute Address: 0xE000
- Base Offset: 0xE000
- Size: 0xA

<p>RSSI computation</p>

|Offset|Identifier|        Name       |
|------|----------|-------------------|
|  0x0 |   CTRL   |  Control register |
|  0x2 |  ATTACK  |  Attack register  |
|  0x4 |   DECAY  |   Decay register  |
|  0x6 |   HOLD   |Hold delay register|
|  0x8 |   RSSI   |        RSSI       |

### CTRL register

- Absolute Address: 0xE000
- Base Offset: 0x0
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|  0 |   CLEAR  |   w  |  —  |  — |

#### CLEAR field

<p>Clear result</p>

### ATTACK register

- Absolute Address: 0xE002
- Base Offset: 0x2
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|  ATTACK  |  rw  |  —  |  — |

#### ATTACK field

<p>Attack increment value at each sample</p>

### DECAY register

- Absolute Address: 0xE004
- Base Offset: 0x4
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   DECAY  |  rw  |  —  |  — |

#### DECAY field

<p>Decay decrement value at each sample</p>

### HOLD register

- Absolute Address: 0xE006
- Base Offset: 0x6
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   HOLD   |  rw  |  —  |  — |

#### HOLD field

<p>Sample count where value is lower than current RSSI before decaying</p>

### RSSI register

- Absolute Address: 0xE008
- Base Offset: 0x8
- Size: 0x2

|Bits|Identifier|Access|Reset|Name|
|----|----------|------|-----|----|
|15:0|   RSSI   |   r  |  —  |  — |

#### RSSI field

<p>RSSI</p>
