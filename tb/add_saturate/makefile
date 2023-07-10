GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) add_saturate_test.vhd add_saturate.vhd
	@$(GHDL) -e $(FLAGS) add_saturate_test
	@$(GHDL) -r $(FLAGS) add_saturate_test --wave=add_saturate_test.ghw --stop-time=33000ms
