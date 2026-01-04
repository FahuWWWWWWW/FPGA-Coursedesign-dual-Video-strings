`timescale 1ns/1ns

module top_scope_lcd
(
    input   wire            sys_clk     ,   // 系统时钟 50MHz
    input   wire            sys_rst_n   ,   // 复位
    input   wire    [7:0]   ad_data     ,   // ADC数据
    input   wire            key_start   ,   // 暂停/开始按键(可选)

    // ADC控制
    output  wire            ad_clk      ,
    
    // LCD接口
    output  wire    [15:0]  rgb_tft     ,   // RGB565数据
    output  wire            hsync       ,   // 行同步
    output  wire            vsync       ,   // 场同步
    output  wire            tft_clk     ,   // 像素时钟
    output  wire            tft_de      ,   // 数据使能
    output  wire            tft_bl          // 背光
);

//-------------------------------------------------------
// 参数定义
//-------------------------------------------------------
// 1秒定时计数 (ad_clk = 12.5MHz)
parameter   CNT_1S_MAX  = 24'd1_250_000; 
// 屏幕显示波形宽度
parameter   WAVE_WIDTH  = 10'd800;

//-------------------------------------------------------
// 内部信号
//-------------------------------------------------------
wire            clk_33m;    // LCD像素时钟
wire            locked;     // PLL锁定
wire            rst_n_sys;  // 系统复位

wire    [15:0]  volt_inst;  // ADC转换出的瞬时电压(mV)
wire    [19:0]  freq_inst;  // 频率计测量的频率(Hz)
wire            sign_signal;// 符号位

// RAM 信号
reg     [9:0]   ram_wr_addr;
reg             ram_wr_en;
reg     [7:0]   ram_wr_data;
wire    [9:0]   ram_rd_addr;
wire    [7:0]   ram_rd_data;

// 显示数值缓存
reg     [15:0]  disp_volt;  // LCD显示的电压幅值
reg     [19:0]  disp_freq;  // LCD显示的频率

// BCD码
wire    [3:0]   v_unit, v_ten, v_hun, v_tho;
wire    [3:0]   f_unit, f_ten, f_hun, f_tho, f_t_tho, f_h_hun;

// 坐标
wire    [10:0]  pix_x;
wire    [10:0]  pix_y;

wire    [15:0]  pix_data_wire; 

reg [15:0] v_buf1, v_buf2, v_buf3, v_buf4; // 4级缓存
wire [15:0] volt_filtered;                 // 滤波后的电压

assign  rst_n_sys = sys_rst_n & locked;

//-------------------------------------------------------
// 1. 时钟生成 (PLL)
//-------------------------------------------------------
clk_wiz_0 clk_gen_inst (
    .clk_in1    (sys_clk),
    .reset      (~sys_rst_n),
    .clk_out1   (clk_33m), // 33MHz
    .locked     (locked)
);

//-------------------------------------------------------
// 2. ADC 采集与频率计算
//-------------------------------------------------------
adc adc_inst (
    .sys_clk    (sys_clk),
    .sys_rst_n  (sys_rst_n),
    .ad_data    (ad_data),
    .ad_clk     (ad_clk),   // 输出 12.5MHz
    .sign       (sign_signal),
    .volt       (volt_inst)
);

freq_meter freq_meter_inst (
    .sys_clk    (sys_clk),
    .sys_rst_n  (sys_rst_n),
    .sign       (sign_signal),
    .freq_out   (freq_inst)
);

//-------------------------------------------------------
// 3. 采样控制状态机 (核心修改：1s刷新 + 触发锁定)
//-------------------------------------------------------
// 在 ad_clk 域工作
reg [2:0]   state;
reg [23:0]  timer_cnt;
reg [7:0]   ad_data_d0; // 用于检测边沿
reg [15:0]  volt_max_temp; // 临时峰值

localparam S_IDLE       = 0; // 初始/暂停
localparam S_WAIT_TIME  = 1; // 等待1秒时间到
localparam S_WAIT_TRIG  = 2; // 等待波形过零触发(X轴防抖动)
localparam S_SAMPLE     = 3; // 采集800个点

//-------------------------------------------------------
// 新增：滑动平均滤波逻辑 (在 ad_clk 时钟域)
//-------------------------------------------------------
// 作用：将连续4个采样点取平均值，平滑掉方波边沿的尖峰噪声
always @(posedge ad_clk or negedge rst_n_sys) begin
    if(!rst_n_sys) begin
        v_buf1 <= 0; v_buf2 <= 0; v_buf3 <= 0; v_buf4 <= 0;
    end else begin
        v_buf1 <= volt_inst;
        v_buf2 <= v_buf1;
        v_buf3 <= v_buf2;
        v_buf4 <= v_buf3;
    end
end

// 计算平均值 (相加除以4，即右移2位)
assign volt_filtered = (v_buf1 + v_buf2 + v_buf3 + v_buf4) >> 2;

always @(posedge ad_clk or negedge rst_n_sys) begin
    if(!rst_n_sys) begin
        state       <= S_WAIT_TIME;
        timer_cnt   <= 0;
        ram_wr_en   <= 0;
        ram_wr_addr <= 0;
        ad_data_d0  <= 0;
        disp_volt   <= 0;
        disp_freq   <= 0;
        volt_max_temp <= 0;
    end else begin
        ad_data_d0 <= ad_data; // 打一拍，用于边沿检测
        
        if(timer_cnt == 0) 
            volt_max_temp <= 0; 
        else if(volt_filtered > volt_max_temp) 
            volt_max_temp <= volt_filtered; 

        case(state)
            S_WAIT_TIME: begin
                ram_wr_en <= 0;
                // 1. 计数 1秒
                if(timer_cnt >= CNT_1S_MAX) begin
                    timer_cnt <= 0;
                    state <= S_WAIT_TRIG;
                    
                    // 1秒时间到，更新要显示的数值 (频率和幅值)
                    disp_freq <= freq_inst;
                    disp_volt <= volt_max_temp; // 将这一秒统计的峰值更新到屏幕
                end else begin
                    timer_cnt <= timer_cnt + 1'b1;
                end
            end

            S_WAIT_TRIG: begin
                // 2. 软件触发：寻找上升沿过零点 (从 <128 变成 >=128)
                // 这样能保证波形每次都从屏幕最左边的 0点 开始画，不会左右乱跑
                if(ad_data_d0 < 128 && ad_data >= 128) begin
                    state <= S_SAMPLE;
                    ram_wr_addr <= 0;
                    ram_wr_en <= 1'b1;
                end
                // 防止死等：如果长时间没触发(比如直流)，强制采集
                else if(timer_cnt > 20000) begin 
                    state <= S_SAMPLE;
                    ram_wr_addr <= 0;
                    ram_wr_en <= 1'b1;
                end
                else begin
                    timer_cnt <= timer_cnt + 1'b1;
                end
            end

            S_SAMPLE: begin
                // 3. 突发采集：连续写入800个点
                ram_wr_data <= ad_data;
                if(ram_wr_addr == WAVE_WIDTH - 1) begin
                    ram_wr_en <= 0;
                    state <= S_WAIT_TIME; // 采满一屏，回去等待下一秒
                end else begin
                    ram_wr_addr <= ram_wr_addr + 1'b1;
                end
            end
            
            default: state <= S_WAIT_TIME;
        endcase
    end
end

//-------------------------------------------------------
// 4. 双口RAM (波形显存)
//-------------------------------------------------------
video_ram waveform_buffer (
    .wr_clk     (ad_clk),
    .wr_en      (ram_wr_en),
    .wr_addr    (ram_wr_addr),
    .wr_data    (ram_wr_data),
    
    .rd_clk     (clk_33m),      // LCD读取时钟
    .rd_addr    (ram_rd_addr),  // LCD当前X坐标
    .rd_data    (ram_rd_data)   // 输出给绘图模块
);

//-------------------------------------------------------
// 5. 数值转BCD码 (用于LCD字符显示)
//-------------------------------------------------------
bcd_8421 bcd_volt (
    .sys_clk(sys_clk), .sys_rst_n(sys_rst_n), .data({4'b0, disp_volt}),
    .unit(v_unit), .ten(v_ten), .hun(v_hun), .tho(v_tho),
    .t_tho(), .h_hun()
);

bcd_8421 bcd_freq (
    .sys_clk(sys_clk), .sys_rst_n(sys_rst_n), .data(disp_freq),
    .unit(f_unit), .ten(f_ten), .hun(f_hun), .tho(f_tho), 
    .t_tho(f_t_tho), .h_hun(f_h_hun)
);

//-------------------------------------------------------
// 6. LCD 显示控制 & 绘图
//-------------------------------------------------------
tft_ctrl tft_ctrl_inst (
    .clk_in     (clk_33m),
    .sys_rst_n  (rst_n_sys),
    .data_in    (pix_data_wire), 
    .pix_x      (pix_x),
    .pix_y      (pix_y),
    .hsync      (hsync),
    .vsync      (vsync),
    .tft_clk    (tft_clk),
    .tft_de     (tft_de),
    .tft_bl     (tft_bl),
    .data_req   (), .rgb_tft_16b(rgb_tft), .rgb_tft_24b()
);

tft_pic_scope tft_pic_inst (
    .tft_clk    (clk_33m),
    .rst_n      (rst_n_sys),
    .pix_x      (pix_x),
    .pix_y      (pix_y),
    
    .wave_data  (ram_rd_data), // RAM读出的波形值
    .ram_rd_addr(ram_rd_addr), // 输出读地址
    
    // BCD数值输入
    .v_bcd      ({v_tho, v_hun, v_ten, v_unit}),
    .f_bcd      ({f_h_hun, f_t_tho, f_tho, f_hun, f_ten, f_unit}),
    
    .pix_data   (pix_data_wire)      // 输出像素颜色
);

endmodule