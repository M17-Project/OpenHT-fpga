GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) unpack_test.vhd unpack.vhd
	@$(GHDL) -e $(FLAGS) unpack_test
	@$(GHDL) -r $(FLAGS) unpack_test --wave=unpack_test.ghw --stop-time=100ms
