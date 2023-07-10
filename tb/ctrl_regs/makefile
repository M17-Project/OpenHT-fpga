GHDL=ghdl
FLAGS="--std=08"

all:
	@$(GHDL) -a $(FLAGS) ctrl_regs_test.vhd ctrl_regs.vhd
	@$(GHDL) -e $(FLAGS) ctrl_regs_test
	@$(GHDL) -r $(FLAGS) ctrl_regs_test --wave=ctrl_regs_test.ghw --stop-time=10ms
