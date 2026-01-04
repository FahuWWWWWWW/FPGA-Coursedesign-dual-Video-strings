#CAMERA
#摄像头接口的时钟
create_clock -period 40.000 -name cmos_pclk [get_ports cam_pclk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk_IBUF]
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports cam_pclk]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports cam_rst_n]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports cam_sgm_ctrl]
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










