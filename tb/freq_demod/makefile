GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) freq_demod_test.vhd freq_demod.vhd
	@$(GHDL) -e $(FLAGS) freq_demod_test
	@$(GHDL) -r $(FLAGS) freq_demod_test --wave=freq_demod_test.ghw --stop-time=500ms
