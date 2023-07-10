GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) mag_est_test.vhd mag_est.vhd
	@$(GHDL) -e $(FLAGS) mag_est_test
	@$(GHDL) -r $(FLAGS) mag_est_test --wave=mag_est_test.ghw --stop-time=100ms
