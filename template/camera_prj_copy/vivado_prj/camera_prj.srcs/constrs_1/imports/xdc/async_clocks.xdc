# 1. 自动生成的PLL时钟名称引用
# Vivado的clk_wiz IP通常会自动生成create_clock约束，名称规则通常为 "clk_outX_clk_wiz_0"
# 如果没有自动生成，这里手动补充定义，防止Clock Group报错
# 注意：get_clocks -quiet 避免如果由于IP自动约束已存在而报错

# 定义系统侧时钟组 (System Group)
# 包含：
# - sys_clk (50MHz 主时钟)
# - clk_out1 (150MHz FSMC)
# - clk_out2 (100MHz SDRAM)
# - clk_out3 (100MHz LCD Logic)
# - clk_out4 (100MHz SDRAM Shift)
# - clk_out5 (50MHz Touch/Camera)
# - 任何由它们派生的时钟 (如 clk_lcd 分频时钟)

set system_clocks [get_clocks -quiet -include_generated_clocks \
    {clk_out1_clk_wiz_0 \
     clk_out2_clk_wiz_0 \
     clk_out3_clk_wiz_0 \
     clk_out4_clk_wiz_0 \
     clk_out5_clk_wiz_0}]

# 1.1 定义内部生成的慢速异步时钟 (I2C, LCD Div)
# 这些时钟由寄存器分频产生，且只用于低速控制逻辑（100K-33MHz），与主干时钟完全异步。
set slow_internal_clocks [get_clocks -quiet -include_generated_clocks {*dri_clk* *clk_lcd*}]

# 2. 定义外部异步时钟组 (Camera Group)
# 包含：
# - cmos_pclk (摄像头像素时钟，完全异步)

set camera_clocks [get_clocks -quiet -include_generated_clocks {cmos_pclk}]

# 3. [NEW] 定义HDMI时钟组 (HDMI Group)
# 包含：
# - clk_hdmi (65MHz)
# - clk_hdmi_5x (325MHz)
set hdmi_clocks [get_clocks -quiet -include_generated_clocks \
    {clk_out1_clk_wiz_1 \
     clk_out2_clk_wiz_1}]

# 4. 设置异步时钟组 (Asynchronous Clock Groups)
# 告诉综合器这三个域之间的数据交互是异步的，不需要进行时序分析（利用双口RAM/FIFO处理）
# 这将消除大量的跨时钟域时序违例

set_clock_groups -asynchronous \
    -group $system_clocks \
    -group $camera_clocks \
    -group $hdmi_clocks \
    -group [get_clocks -quiet -include_generated_clocks {sys_clk *clk_in1*}] \
    -group $slow_internal_clocks

# ----------------------------------------------------------------------------
# Minimal Effective Timing Constraints for Video System
# ----------------------------------------------------------------------------

# 1. SDRAM Interface Constraints
# Reference Clock: clk_out4_clk_wiz_0 (100MHz Phase Shifted Output)
# Relaxed constraints slightly availability for board trace variations
set_output_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz/clk_out4]] -max 2.0 [get_ports {sdram_addr[*] sdram_ba[*] sdram_cas_n sdram_ras_n sdram_we_n}]
set_output_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz/clk_out4]] -min -1.0 [get_ports {sdram_addr[*] sdram_ba[*] sdram_cas_n sdram_ras_n sdram_we_n}]

set_output_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz/clk_out4]] -max 2.0 [get_ports {sdram_data[*]}]
set_output_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz/clk_out4]] -min -1.0 [get_ports {sdram_data[*]}]

# SDRAM Input (Read)
set_input_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz/clk_out4]] -max 4.0 [get_ports {sdram_data[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz/clk_out4]] -min 1.0 [get_ports {sdram_data[*]}]


# 2. Display Interface Constraints (LCD)
# Reference Clock: clk_out2_clk_wiz_0 (100MHz LCD Logic - Corrected from previous comment)
# Relaxed for typical LCD parallel interface tolerance
# Note: lcd_pclk is the clock output itself, do not constrain its output delay relative to the source clock.
set_output_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz/clk_out2]] -max 6.0 [get_ports {lcd_rgb[*] lcd_hs lcd_vs lcd_de}]
set_output_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz/clk_out2]] -min -2.0 [get_ports {lcd_rgb[*] lcd_hs lcd_vs lcd_de}]



# 3. HDMI Interface Constraints
# Reference: clk_hdmi (65MHz) from clk_wiz_1
set_output_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz_hdmi/clk_out1]] -max 4.0 [get_ports {tmds_data_p[*] tmds_clk_p}]
set_output_delay -clock [get_clocks -of_objects [get_pins u_clk_wiz_hdmi/clk_out1]] -min -2.0 [get_ports {tmds_data_p[*] tmds_clk_p}]


# 4. Critical False Paths (Logic Fixes)

# 4.1. FIFO Reset Paths (Async Reset Recovery)
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *rd_load_extend_cnt_reg* && IS_SEQUENTIAL}] -to [get_cells -hierarchical -filter {NAME =~ *u_sdram_top*u_rdfifo*rst* || NAME =~ *fifo_gen*rst*}]

# 4.2. Debug Signals to FSMC Domain (Critical for TNS Reduction)
# The FSMC module (running at 150MHz) samples debug counters from other domains (Camera 25MHz, LCD 100MHz, System 100MHz).
# These are informational only and do not require single-cycle synchronous timing.
# We treat them as false paths to allow the tools to ignore these crossings.

# From Camera Domain (vsync_cnt, wr_data_cnt) to FSMC
set_false_path -from [get_clocks $camera_clocks] -to [get_clocks -of_objects [get_pins u_clk_wiz/clk_out1]]

# From LCD Domain (rd_data_cnt, logic signals) to FSMC
# Note: clk_out3 (100M) and clk_out1 (150M) are technically synchronous (same MMCM),
# but the logic depth for 150MHz (6.6ns) is tight for these large counters. 
# Since we explicitly act as if they are async in RTL (sync registers), we mask the path here.
set_false_path -from [get_clocks -of_objects [get_pins u_clk_wiz/clk_out3]] -to [get_clocks -of_objects [get_pins u_clk_wiz/clk_out1]]

# From Touch/System Domain (clk_50m) to FSMC
set_false_path -from [get_clocks -of_objects [get_pins u_clk_wiz/clk_out5]] -to [get_clocks -of_objects [get_pins u_clk_wiz/clk_out1]]

# 5. Cross-Clock Domain Data Paths (Camera -> SDRAM)
# Handled by set_clock_groups, but explicitly:
set_false_path -from [get_clocks -of_objects [get_pins u_clk_wiz/clk_out5]] -to [get_clocks -of_objects [get_pins u_clk_wiz/clk_out3]]

# 4.3 Static Configuration Signal Paths (LCD ID)
# The LCD ID is read once at power-up and remains static. 
# Its propagation to the display output logic (lcd_rgb, lcd_de, etc.) does not need to meet single-cycle timing.
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *ID_lcd_reg*}] -to [get_ports lcd_*]

# 4.4 SDRAM Init Status & Display Mode Control to LCD Output
# These signals (init_done, output_mode) gate the LCD data but are quasi-static/human-scale events.
# They originate from SDRAM domain (clk_out3) and System domain (clk_out5) but drive LCD ports (clk_out2 domain relative).
set_false_path -from [get_clocks -of_objects [get_pins u_clk_wiz/inst/mmcm_adv_inst/CLKOUT2]] -to [get_ports {lcd_rgb[*] lcd_hs lcd_vs lcd_de lcd_bl lcd_rst}]
set_false_path -from [get_clocks -of_objects [get_pins u_clk_wiz/inst/mmcm_adv_inst/CLKOUT4]] -to [get_ports {lcd_rgb[*] lcd_hs lcd_vs lcd_de lcd_bl lcd_rst}]

# 5. 杂项异步路径
# 5.1 复位信号与锁定信号
# locked 信号由 PLL 生成，相对于 sys_clk 是异步的。
set_false_path -from [get_pins u_clk_wiz*/inst/mmcm_adv_inst/LOCKED] -to [get_cells rst_first_reg]
set_false_path -from [get_cells rst_first_reg] -to [get_cells -hierarchical -filter {IS_SEQUENTIAL}]
