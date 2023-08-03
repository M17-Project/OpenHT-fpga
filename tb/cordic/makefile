GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) cordic_test.vhd ../../source/impl_1/cordic.vhd
	@$(GHDL) -e $(FLAGS) cordic_test
	@$(GHDL) -r $(FLAGS) cordic_test --wave=cordic_test.ghw --stop-time=2000ms
