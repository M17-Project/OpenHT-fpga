GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) local_osc_test.vhd local_osc.vhd
	@$(GHDL) -e $(FLAGS) local_osc_test
	@$(GHDL) -r $(FLAGS) local_osc_test --wave=local_osc_test.ghw --stop-time=30ms
