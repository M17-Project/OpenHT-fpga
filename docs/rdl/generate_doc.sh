#!/bin/bash

# Requires python packages peakrdl peakrdl-markdown
peakrdl markdown openht.rdl -o ../fpga_registers.md
peakrdl html openht.rdl -o html


