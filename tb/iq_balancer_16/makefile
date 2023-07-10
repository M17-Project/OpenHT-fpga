GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) iq_balancer_16_test.vhd iq_balancer_16.vhd
	@$(GHDL) -e $(FLAGS) iq_balancer_16_test
	@$(GHDL) -r $(FLAGS) iq_balancer_16_test --wave=iq_balancer_16_test.ghw --stop-time=100ms
