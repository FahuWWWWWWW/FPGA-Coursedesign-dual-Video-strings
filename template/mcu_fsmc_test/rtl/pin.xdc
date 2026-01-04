
set_property PACKAGE_PIN J19 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports reset_n]
set_property PACKAGE_PIN K19 [get_ports reset_n]

set_property -dict {PACKAGE_PIN T1 IOSTANDARD LVCMOS33} [get_ports {mcu_data[7]}]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS33} [get_ports {mcu_data[6]}]
set_property -dict {PACKAGE_PIN K3 IOSTANDARD LVCMOS33} [get_ports {mcu_data[5]}]
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports {mcu_data[4]}]
set_property -dict {PACKAGE_PIN L4 IOSTANDARD LVCMOS33} [get_ports {mcu_data[3]}]
set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS33} [get_ports {mcu_data[2]}]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {mcu_data[1]}]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS33} [get_ports {mcu_data[0]}]


set_property -dict {PACKAGE_PIN W1 IOSTANDARD LVCMOS33} [get_ports cs_n]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports wr_n]
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS33} [get_ports rs]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes [current_design]


