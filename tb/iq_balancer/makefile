GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) iq_balancer_test.vhd iq_balancer.vhd
	@$(GHDL) -e $(FLAGS) iq_balancer_test
	@$(GHDL) -r $(FLAGS) iq_balancer_test --wave=iq_test.ghw --stop-time=350ms
