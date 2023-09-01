#!/usr/bin/env python3
from vunit import VUnit

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv(compile_builtins=False)

# Optionally add VUnit's builtin HDL utilities for checking, logging, communication...
# See http://vunit.github.io/hdl_libraries.html.
vu.add_vhdl_builtins()
vu.add_verification_components()
vu.add_osvvm()

# or
# vu.add_verilog_builtins()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("../../source/impl_1/axi_stream_pkg.vhd")
lib.add_source_files("../../source/impl_1/cordic*.vhd")
lib.add_source_files("../../source/tx_chain/FM_modulator.vhd")
lib.add_source_files("*.vhd")

# Run vunit function
vu.main()
