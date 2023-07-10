GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) dpd_test.vhd dpd.vhd
	@$(GHDL) -e $(FLAGS) dpd_test
	@$(GHDL) -r $(FLAGS) dpd_test --wave=dpd_test.ghw --stop-time=65536us
