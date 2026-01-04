create_clock -period 20.000 -name sys_clk [get_ports sys_clk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sys_clk]
set_property PACKAGE_PIN J19 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_n]
set_property PACKAGE_PIN K19 [get_ports sys_rst_n]

#控制信号及时钟
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[7]}]
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[6]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[5]}]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[4]}]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[3]}]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[2]}]
set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[1]}]
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[0]}]

set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[15]}]
set_property -dict {PACKAGE_PIN K6 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[14]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[13]}]
set_property -dict {PACKAGE_PIN L6 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[12]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[11]}]
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[10]}]
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[9]}]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[8]}]

set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS33} [get_ports lcd_hs]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports lcd_vs]
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS33} [get_ports lcd_de]
set_property -dict {PACKAGE_PIN AA6  IOSTANDARD LVCMOS33} [get_ports lcd_bl]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports lcd_pclk]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports lcd_rst]


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









