create_clock -period 20.000 -name sys_clk [get_ports sys_clk]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sys_clk]
set_property PACKAGE_PIN J19 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_n]
set_property PACKAGE_PIN K19 [get_ports sys_rst_n]

#控制信号及时钟
set_property PACKAGE_PIN K21 [get_ports {tmds_data_p[0]}]
set_property PACKAGE_PIN J20 [get_ports {tmds_data_p[1]}]
set_property PACKAGE_PIN J22 [get_ports {tmds_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[0]}]
set_property PACKAGE_PIN M21 [get_ports tmds_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports tmds_clk_p]


#CAMERA

#摄像头接口的时钟
create_clock -period 40.000 -name cmos_pclk [get_ports cam_pclk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk_IBUF]
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports cam_pclk]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports cam_rst_n]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports cam_pwdn]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[0]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[1]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[2]}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[3]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[4]}]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[5]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[6]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[7]}]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports cam_vsync]
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports cam_href]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports cam_scl]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports cam_sda]


set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes [current_design]









