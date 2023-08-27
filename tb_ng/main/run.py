#!/usr/bin/env python3
# Have lattice libs compiled in the directory ../lattice_libs
# compile using "cmpl_libs -sim_path /home/seb/intelFPGA/20.1/modelsim_ase/bin -device lifcl -target_path /home/seb/devel/OpenHT-fpga/tb_ng/lattice_libs"
# in radiantc
from vunit import VUnit
from os.path import join, dirname, abspath

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv(compile_builtins=False)

root = join(dirname(__file__), '../')
print(root)

# Optionally add VUnit's builtin HDL utilities for checking, logging, communication...
# See http://vunit.github.io/hdl_libraries.html.
vu.add_vhdl_builtins()
vu.add_verification_components()
# or
# vu.add_verilog_builtins()

# Create library 'lib'
lib = vu.add_library("lib")
# Add lifcl library
vu.add_external_library('lifcl', root+'/lattice_libs/lifcl')

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("*.vhd")
lib.add_source_files(root+"/../source/impl_1/*.vhd")
lib.add_source_files(root+"/../source/tx_chain/*.vhd")
lib.add_source_file(root+"/../ddr_tx/rtl/ddr_tx.v")
lib.add_source_file(root+"/../ddr_rx/rtl/ddr_rx.v")
lib.add_source_file(root+"/../pll_osc/rtl/pll_osc.v")

# Run vunit function
vu.main()
