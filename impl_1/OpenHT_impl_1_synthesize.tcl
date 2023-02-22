if {[catch {

# define run engine funtion
source [file join {C:/Radiant} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) 1
set para(prj_dir) "C:/Users/SP5WWP/Documents/Radiant/OpenHT"
# synthesize IPs
# synthesize VMs
# propgate constraints
file delete -force -- OpenHT_impl_1_cpe.ldc
run_engine_newmsg cpe -f "OpenHT_impl_1.cprj" "pll_osc.cprj" "ddr_rx.cprj" "ddr_tx.cprj" -a "LIFCL"  -o OpenHT_impl_1_cpe.ldc
# synthesize top design
file delete -force -- OpenHT_impl_1.vm OpenHT_impl_1.ldc
run_engine_newmsg synthesis -f "OpenHT_impl_1_lattice.synproj"
run_postsyn [list -a LIFCL -p LIFCL-40 -t QFN72 -sp 7_High-Performance_1.0V -oc Industrial -top -w -o OpenHT_impl_1_syn.udb OpenHT_impl_1.vm] "C:/Users/SP5WWP/Documents/Radiant/OpenHT/impl_1/OpenHT_impl_1.ldc"

} out]} {
   runtime_log $out
   exit 1
}
