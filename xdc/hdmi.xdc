#控制信号及时钟
set_property PACKAGE_PIN K21 [get_ports {tmds_data_p[0]}]
set_property PACKAGE_PIN J20 [get_ports {tmds_data_p[1]}]
set_property PACKAGE_PIN J22 [get_ports {tmds_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {tmds_data_p[0]}]
set_property PACKAGE_PIN M21 [get_ports tmds_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports tmds_clk_p]
set_property PACKAGE_PIN L21 [get_ports tmds_clk_n]
set_property IOSTANDARD TMDS_33 [get_ports tmds_clk_n]









