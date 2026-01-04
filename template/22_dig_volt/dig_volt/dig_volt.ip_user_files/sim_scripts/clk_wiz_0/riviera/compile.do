transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../ipstatic" "+incdir+../../../../../../../../Vivado/XILINX/2025.1/Vivado/data/rsb/busdef" -l xpm -l xil_defaultlib \
"A:/Vivado/XILINX/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  -incr \
"A:/Vivado/XILINX/2025.1/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../ipstatic" "+incdir+../../../../../../../../Vivado/XILINX/2025.1/Vivado/data/rsb/busdef" -l xpm -l xil_defaultlib \
"../../../../dig_volt.gen/sources_1/new/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../../dig_volt.gen/sources_1/new/ip/clk_wiz_0/clk_wiz_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

