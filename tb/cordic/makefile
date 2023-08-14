GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) ../../source/impl_1/cordic.vhd ../../source/impl_1/cordic_sincos.vhd cordic_test.vhd
	@$(GHDL) -e $(FLAGS) cordic_test
	@$(GHDL) -r $(FLAGS) cordic_test --wave=cordic_test.ghw --stop-time=2ms

clean:
	rm -f *.o *.ghw cordic_test *.cf
