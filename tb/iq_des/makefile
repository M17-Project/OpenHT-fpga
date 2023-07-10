GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) iq_des_test.vhd iq_des.vhd
	@$(GHDL) -e $(FLAGS) iq_des_test
	@$(GHDL) -r $(FLAGS) iq_des_test --wave=iq_des_test.ghw --stop-time=100ms
