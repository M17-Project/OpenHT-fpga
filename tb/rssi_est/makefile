GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) rssi_est_test.vhd rssi_est.vhd
	@$(GHDL) -e $(FLAGS) rssi_est_test
	@$(GHDL) -r $(FLAGS) rssi_est_test --wave=rssi_est_test.ghw --stop-time=100ms
