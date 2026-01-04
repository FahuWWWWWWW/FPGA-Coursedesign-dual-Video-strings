set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports led[0]]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports led[1]]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports led[2]]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports led[3]]

set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports key[0]]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports key[1]]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports key[2]]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports key[3]]

set_property -dict {PACKAGE_PIN M22 IOSTANDARD LVCMOS33} [get_ports beep]
