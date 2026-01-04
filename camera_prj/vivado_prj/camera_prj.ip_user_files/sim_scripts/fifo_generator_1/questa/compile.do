vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/fifo_generator_v13_2_13
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap fifo_generator_v13_2_13 questa_lib/msim/fifo_generator_v13_2_13
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../../../../../../Vivado/XILINX/2025.1/Vivado/data/rsb/busdef" \
"A:/Vivado/XILINX/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"A:/Vivado/XILINX/2025.1/Vivado/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"A:/Vivado/XILINX/2025.1/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work fifo_generator_v13_2_13  -incr -mfcu  "+incdir+../../../../../../../../Vivado/XILINX/2025.1/Vivado/data/rsb/busdef" \
"../../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_13  -93  \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_13  -incr -mfcu  "+incdir+../../../../../../../../Vivado/XILINX/2025.1/Vivado/data/rsb/busdef" \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../../../../../Vivado/XILINX/2025.1/Vivado/data/rsb/busdef" \
"../../../../camera_prj.gen/sources_1/ip/fifo_generator_1/sim/fifo_generator_1.v" \

vlog -work xil_defaultlib \
"glbl.v"

