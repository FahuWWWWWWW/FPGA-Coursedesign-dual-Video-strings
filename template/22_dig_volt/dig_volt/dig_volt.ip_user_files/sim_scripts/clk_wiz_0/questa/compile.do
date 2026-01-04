vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../ipstatic" "+incdir+../../../../../../../../Vivado/XILINX/2025.1/Vivado/data/rsb/busdef" \
"A:/Vivado/XILINX/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm  -93  \
"A:/Vivado/XILINX/2025.1/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../ipstatic" "+incdir+../../../../../../../../Vivado/XILINX/2025.1/Vivado/data/rsb/busdef" \
"../../../../dig_volt.gen/sources_1/new/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../../dig_volt.gen/sources_1/new/ip/clk_wiz_0/clk_wiz_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

