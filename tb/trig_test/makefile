GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) trig_test_test.vhd trig_test.vhd
	@$(GHDL) -e $(FLAGS) trig_test_test
	@$(GHDL) -r $(FLAGS) trig_test_test --wave=trig_test_test.ghw --stop-time=100ms
