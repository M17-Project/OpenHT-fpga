GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) iq_offset_test.vhd iq_offset.vhd
	@$(GHDL) -e $(FLAGS) iq_offset_test
	@$(GHDL) -r $(FLAGS) iq_offset_test --wave=iq_offset_test.ghw --stop-time=100ms
