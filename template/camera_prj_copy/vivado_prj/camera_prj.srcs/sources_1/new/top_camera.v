`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/07 21:01:53
// Design Name: 
// Module Name: top_camera
// Project Name: 
// Target Devices: 
// Tool Versions:
// Revision:
// Revision 3.1 - 简化版本，修复显示错乱问题
// Additional Comments:
// 1. 移除画面冻结功能（freeze_frame固定为0）
// 2. 移除显示模式切换功能（flip信号固定为0）
// 3. 保留触摸坐标输出到FSMC（不影响显示）
// 4. 修复时钟域问题
// 5. 专注于稳定的摄像头采集和LCD显示
//////////////////////////////////////////////////////////////////////////////////

module top_camera(
    input sys_clk,					//	时钟
    input sys_rst_n,					//	复位
    output  [1:0]  led ,        //LED灯
    output  [3:0]  exio ,        //扩展IO（指示触摸状态）
    input FSMC_NL_NADV,		//	地址复用有效信号
    input FSMC_CS_NEL,		//	片选
    input FSMC_WR_NWE,		//	写使能
    input FSMC_RD_NOE,		//	读使能
    inout [15:0] FSMC_DB,	//	双向地址/数据总线
    
    //摄像头接口
    input         cam_pclk   ,  //cmos 数据像素时钟
    input         cam_vsync  ,  //cmos 场同步信号
    input         cam_href   ,  //cmos 行同步信号
    input  [7:0]  cam_data   ,  //cmos 数据
    output        cam_rst_n  ,  //cmos 复位信号，低电平有效
    output        cam_pwdn   ,  //cmos 电源休眠模式选择信号
    output        cam_scl    ,  //cmos SCCB_SCL线
    inout         cam_sda    ,  //cmos SCCB_SDA线
    
    //SDRAM接口
    output        sdram_clk  ,  //SDRAM 时钟
    output        sdram_ras_n,  //SDRAM 行有效
    output        sdram_cas_n,  //SDRAM 列有效
    output        sdram_we_n ,  //SDRAM 写有效
    output [1:0]  sdram_ba   ,  //SDRAM Bank地址
    output [10:0] sdram_addr ,  //SDRAM 地址
    inout  [MEM_DATA_BITS - 1:0] sdram_data ,  //SDRAM 数据
    
    //LCD接口
    output        lcd_hs     ,  //LCD 行同步信号
    output        lcd_vs     ,  //LCD 场同步信号
    output        lcd_de     ,  //LCD 数据输入使能
    inout  [23:0] lcd_rgb    ,  //LCD RGB888颜色数据
    output        lcd_bl     ,  //LCD 背光控制信号
    output        lcd_rst    ,  //LCD 复位信号
    output        lcd_pclk,      //LCD 采样时钟
    
    //LCD显示控制信号（由双击触摸驱动，外部输入失效）
    input         ctrl_flip_horizontal, //预留（实际由触摸控制）
    input         ctrl_flip_vertical,   //预留（实际由触摸控制）
    input         ctrl_flip_color,      //预留（实际由触摸控制）  
    
    //TOUCH 接口（基础版本）
    inout         touch_sda,  //TOUCH IIC数据
    output        touch_scl,  //TOUCH IIC时钟
    inout         touch_int,  //TOUCH INT信号
    output        touch_rst_n, //TOUCH 复位信号

    //HDMI接口 (XGA)
    output        tmds_clk_p,
    output        tmds_clk_n,
    output [2:0]  tmds_data_p,
    output [2:0]  tmds_data_n
);

//参数定义
parameter SDR_BA_WIDTH           = 2  ;
parameter SDR_ROW_WIDTH          = 11  ;
parameter SDR_COL_WIDTH          = 8  ;
parameter MEM_DATA_BITS          = 16  ;        //external memory user interface data width
parameter ADDR_BITS              = 19  ;        //external memory user interface address width
parameter BUSRT_BITS             = 10  ;        //external memory user interface burst width
parameter BURST_SIZE             = 128  ;       //burst size

parameter SLAVE_ADDR = 7'h3c          ; //OV5640的器件地址7'h3c
parameter BIT_CTRL   = 1'b1           ; //OV5640的字节地址为16位  0:8位 1:16位
parameter CLK_FREQ   = 27'd100_000_000; //i2c_dri模块的驱动时钟频率
parameter I2C_FREQ   = 18'd250_000    ; //I2C的SCL时钟频率,不超过400KHz

//FSMC核心修复：拆分发送/接收信号（彻底解决多驱动）
// FPGA → STM32（发送数据，仅FPGA驱动）
reg [15:0] fsmc_tx_data_0;
reg [15:0] fsmc_tx_data_1; // 触摸X坐标
reg [15:0] fsmc_tx_data_2; // 触摸Y坐标
reg [15:0] fsmc_tx_data_3;
reg [15:0] fsmc_tx_data_4;
reg [15:0] fsmc_tx_data_5;
reg [15:0] fsmc_tx_data_6;
reg [15:0] fsmc_tx_data_7;
reg [15:0] fsmc_tx_data_8;
reg [15:0] fsmc_tx_data_9;
reg [15:0] fsmc_tx_data_10;
reg [15:0] fsmc_tx_data_11;
reg [15:0] fsmc_tx_data_12;
reg [15:0] fsmc_tx_data_13;
reg [15:0] fsmc_tx_data_14;
reg [15:0] fsmc_tx_data_15;

// STM32 → FPGA（接收数据，仅FSMC驱动）
wire [15:0] fsmc_rx_data_0;
wire [15:0] fsmc_rx_data_1;
wire [15:0] fsmc_rx_data_2;
wire [15:0] fsmc_rx_data_3;
wire [15:0] fsmc_rx_data_4;
wire [15:0] fsmc_rx_data_5;
wire [15:0] fsmc_rx_data_6;
wire [15:0] fsmc_rx_data_7;
wire [15:0] fsmc_rx_data_8;
wire [15:0] fsmc_rx_data_9;
wire [15:0] fsmc_rx_data_10;
wire [15:0] fsmc_rx_data_11;
wire [15:0] fsmc_rx_data_12;
wire [15:0] fsmc_rx_data_13;
wire [15:0] fsmc_rx_data_14;
wire [15:0] fsmc_rx_data_15;

// FSMC读写方向判断
wire fsmc_stm32_write = ~FSMC_WR_NWE;  // STM32写FPGA（低有效）
wire fsmc_stm32_read  = ~FSMC_RD_NOE;  // STM32读FPGA（低有效）

//其他核心信号
wire                  locked          ;
wire                  rst_n           ;
wire FSMC_CLK;
wire [31:0] point_data;

//摄像头和LCD相关信号
wire        clk_100m       ;  //100mhz时钟,SDRAM操作时钟
wire        clk_100m_shift ;  //100mhz时钟,SDRAM相位偏移时钟
wire        clk_100m_lcd   ;  //100mhz时钟,LCD顶层模块时钟
wire        clk_50m        ;  //50mhz时钟,触摸驱动时钟
wire        sys_init_done  ;  //系统初始化完成(sdram初始化+摄像头初始化)

wire        i2c_exec       ;  //I2C触发执行信号
wire [23:0] i2c_data       ;  //I2C要配置的地址与数据(高8位地址,低8位数据)
wire        i2c_done       ;  //I2C寄存器配置完成信号
wire        i2c_dri_clk    ;  //I2C操作时钟
wire [ 7:0] i2c_data_r     ;  //I2C读出的数据
wire        i2c_rh_wl      ;  //I2C读写控制信号
wire        cam_init_done  ;  //摄像头初始化完成

wire        wr_en          ;  //sdram_ctrl模块写使能
wire [15:0] wr_data        ;  //sdram_ctrl模块写数据
wire        rd_en          ;  //sdram_ctrl模块读使能
wire [15:0] rd_data        ;  //sdram_ctrl模块读数据
wire        sdram_init_done;  //SDRAM初始化完成

wire [15:0] ID_lcd         ;  //LCD的ID
wire [12:0] cmos_h_pixel   ;  //CMOS水平方向像素个数
wire [12:0] cmos_v_pixel   ;  //CMOS垂直方向像素个数
wire [12:0] total_h_pixel  ;  //水平总像素大小
wire [12:0] total_v_pixel  ;  //垂直总像素大小
wire [23:0] sdram_max_addr ;  //sdram读写的最大地址

// 调试计数器：监控数据流
reg [15:0] wr_data_cnt;   // 摄像头写入计数器
reg [15:0] rd_data_cnt;   // LCD读取计数器
reg [15:0] vsync_cnt;     // 场同步计数器

always @(posedge cam_pclk or negedge rst_n) begin
    if (!rst_n)
        wr_data_cnt <= 16'd0;
    else if (wr_en)
        wr_data_cnt <= wr_data_cnt + 1'd1;
end

always @(posedge clk_100m_lcd or negedge rst_n) begin
    if (!rst_n)
        rd_data_cnt <= 16'd0;
    else if (rd_en)
        rd_data_cnt <= rd_data_cnt + 1'd1;
end

// VSYNC 计数改进：使用边沿检测，防止电平计数
reg cam_vsync_reg;
always @(posedge cam_pclk or negedge rst_n) begin
    if (!rst_n) begin
        vsync_cnt <= 16'd0;
        cam_vsync_reg <= 1'b0;
    end else begin
        cam_vsync_reg <= cam_vsync;
        if (cam_vsync && !cam_vsync_reg) // 上升沿
            vsync_cnt <= vsync_cnt + 1'd1;
    end
end

//基础触摸相关信号（来自touch_dri）
wire          touch_int_in ;
wire          touch_int_dir;
wire          touch_int_out;
wire          touch_sda_in ;
wire          touch_sda_out;
wire          touch_sda_dir;

wire          touch_valid  ;  //触摸有效信号（来自touch_dri）
wire  [15:0]  tp_x_coord   ;  //触摸X坐标（来自touch_dri）
wire  [15:0]  tp_y_coord   ;  //触摸Y坐标（来自touch_dri）

//手势识别信号（来自重构版touch_event）
wire          single_click ;  //单击事件（单周期脉冲）
wire          double_click ;  //双击事件（单周期脉冲）
wire          long_press   ;  //长按事件（持续高电平）
wire  [15:0]  gesture_x    ;  //手势识别坐标X (同步touch_dri)
wire  [15:0]  gesture_y    ;  //手势识别坐标Y (同步touch_dri)
//复位延迟逻辑
reg [12:0] rst_first_cnt; 
reg        rst_first;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)begin
        rst_first <= 1'b0;
        rst_first_cnt <= 13'd0;
    end
    else begin
        if(rst_first_cnt < 13'h1FFF)
            rst_first_cnt <= rst_first_cnt + 1'd1;
        else
            rst_first <= 1'b1;
    end
end

assign  rst_n = sys_rst_n & locked & rst_first;

//触摸接口信号处理
assign touch_sda = touch_sda_dir ? touch_sda_out : 1'bz;
assign touch_sda_in = touch_sda;
assign touch_int = touch_int_dir ? touch_int_out : 1'bz;
assign touch_int_in = touch_int;

//------------------------------------------
// 2.5 STM32 控制寄存器同步 (FSMC RX -> clk_50m)
//------------------------------------------
// STM32 控制寄存器 0x0000 位定义:
// bit[0]: stm32_ctrl_enable   - 1=STM32接管控制, 0=触摸控制
// bit[1]: stm32_output_mode   - HDMI模式 (仅stm32_ctrl_enable=1有效)
// bit[2]: stm32_display_active- 动态显示 (仅stm32_ctrl_enable=1有效)
// bit[3]: stm32_cam_restart   - 重启摄像头采集 (脉冲)
// bit[15]: stm32_soft_reset   - 软复位脉冲

// 控制寄存器 0x0001 位定义 (扩展):
// bit[7:0]: stm32_brightness  - 亮度参数 (预留)

// 控制寄存器 0x0002 位定义 (扩展):
// bit[7:0]: stm32_contrast    - 对比度参数 (预留)

(* ASYNC_REG = "TRUE" *) reg [15:0] stm32_ctrl_reg_sync0, stm32_ctrl_reg_sync1;
(* ASYNC_REG = "TRUE" *) reg [15:0] stm32_param1_sync0, stm32_param1_sync1;
(* ASYNC_REG = "TRUE" *) reg [15:0] stm32_param2_sync0, stm32_param2_sync1;

// 提取控制信号
wire stm32_ctrl_enable;
wire stm32_output_mode;
wire stm32_display_active;
wire stm32_cam_restart;
wire stm32_soft_reset;
wire [7:0] stm32_brightness;
wire [7:0] stm32_contrast;

assign stm32_ctrl_enable    = stm32_ctrl_reg_sync1[0];
assign stm32_output_mode    = stm32_ctrl_reg_sync1[1];
assign stm32_display_active = stm32_ctrl_reg_sync1[2];
assign stm32_cam_restart    = stm32_ctrl_reg_sync1[3];
assign stm32_soft_reset     = stm32_ctrl_reg_sync1[15];
assign stm32_brightness     = stm32_param1_sync1[7:0];
assign stm32_contrast       = stm32_param2_sync1[7:0];

// CDC 同步: FSMC_CLK -> clk_50m
always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        stm32_ctrl_reg_sync0 <= 16'd0;
        stm32_ctrl_reg_sync1 <= 16'd0;
        stm32_param1_sync0   <= 16'd0;
        stm32_param1_sync1   <= 16'd0;
        stm32_param2_sync0   <= 16'd0;
        stm32_param2_sync1   <= 16'd0;
    end else begin
        stm32_ctrl_reg_sync0 <= fsmc_rx_data_0;
        stm32_ctrl_reg_sync1 <= stm32_ctrl_reg_sync0;
        stm32_param1_sync0   <= fsmc_rx_data_1;
        stm32_param1_sync1   <= stm32_param1_sync0;
        stm32_param2_sync0   <= fsmc_rx_data_2;
        stm32_param2_sync1   <= stm32_param2_sync0;
    end
end

//------------------------------------------
// 3. 触摸坐标同步到FSMC发送寄存器
//------------------------------------------
// FSMC发送寄存器更新 - 增加诊断功能 (带 CDC 同步)
(* ASYNC_REG = "TRUE" *) reg [15:0] touch_valid_sync;
(* ASYNC_REG = "TRUE" *) reg [15:0] gesture_x_sync, gesture_y_sync;
(* ASYNC_REG = "TRUE" *) reg [15:0] rd_cnt_sync, wr_cnt_sync, vs_cnt_sync;

always @(posedge FSMC_CLK or negedge rst_n) begin
    if (!rst_n) begin
        touch_valid_sync <= 16'd0;
        gesture_x_sync   <= 16'd0;
        gesture_y_sync   <= 16'd0;
        rd_cnt_sync      <= 16'd0;
        wr_cnt_sync      <= 16'd0;
        vs_cnt_sync      <= 16'd0;
        // 初始化所有发送寄存器
        fsmc_tx_data_0  <= 16'd0;
        fsmc_tx_data_1  <= 16'd0;
        fsmc_tx_data_2  <= 16'd0;
        fsmc_tx_data_3  <= 16'd0;
        fsmc_tx_data_4  <= 16'd0;
        fsmc_tx_data_5  <= 16'd0;
        fsmc_tx_data_6  <= 16'd0;
        fsmc_tx_data_7  <= 16'd0;
        fsmc_tx_data_8  <= 16'd0;
        fsmc_tx_data_9  <= 16'd0;
        fsmc_tx_data_10 <= 16'd0;
        fsmc_tx_data_11 <= 16'd0;
        fsmc_tx_data_12 <= 16'd0;
        fsmc_tx_data_13 <= 16'd0;
        fsmc_tx_data_14 <= 16'd0;
        fsmc_tx_data_15 <= 16'd0;
    end else begin
        // 采样同步（虽然不是标准的格雷码或握手，但对于监控计数器至少保证采样时刻不被打断太剧烈）
        touch_valid_sync <= {15'd0, touch_valid};
        gesture_x_sync   <= gesture_x;
        gesture_y_sync   <= gesture_y;
        rd_cnt_sync      <= rd_data_cnt;
        wr_cnt_sync      <= wr_data_cnt;
        vs_cnt_sync      <= vsync_cnt;

        fsmc_tx_data_0 <= touch_valid_sync;
        fsmc_tx_data_1 <= gesture_x_sync;         // 触摸X坐标
        fsmc_tx_data_2 <= gesture_y_sync;         // 触摸Y坐标
        fsmc_tx_data_3 <= ID_lcd;            // [0x0003] LCD ID
        fsmc_tx_data_4 <= cmos_h_pixel;      // [0x0004] 摄像头宽度
        fsmc_tx_data_5 <= cmos_v_pixel;      // [0x0005] 摄像头高度
        fsmc_tx_data_6 <= rd_cnt_sync;       // [0x0006] LCD读取计数值
        fsmc_tx_data_7 <= wr_cnt_sync;       // [0x0007] 摄像头写入计数值
        fsmc_tx_data_8 <= vs_cnt_sync;       // [0x0008] 帧计数

        // [0x0009] 系统状态寄存器
        // bit0: sys_init_done (系统初始化完成)
        // bit1: output_mode_hdmi (当前输出模式)
        // bit2: display_active (非冻结状态)
        // bit3: stm32_ctrl_enable (STM32控制使能)
        // bit4: cam_init_done (摄像头初始化完成)
        // bit5: sdram_init_done (SDRAM初始化完成)
        // bit6: touch_valid (触摸有效)
        fsmc_tx_data_9 <= {9'd0,
                           touch_valid,
                           sdram_init_done,
                           cam_init_done,
                           stm32_ctrl_enable,
                           display_active,
                           output_mode_hdmi,
                           sys_init_done};
                           
        // [0x000A] 回读STM32控制寄存器 (调试用)
        fsmc_tx_data_10 <= stm32_ctrl_reg_sync1;
        // [0x000B] 亮度参数回读
        fsmc_tx_data_11 <= stm32_param1_sync1;
        // [0x000C] 对比度参数回读
        fsmc_tx_data_12 <= stm32_param2_sync1;
    end
end

          

//------------------------------------------
// 4. LED/EXIO状态指示 & 画面静止逻辑 & 输出切换逻辑
//------------------------------------------
reg display_active;      // 1: 动态显示 (默认), 0: 静止画面
reg output_mode_hdmi;    // 0: LCD, 1: HDMI

// 双控制源逻辑:
// - stm32_ctrl_enable=1 时, STM32 接管控制
// - stm32_ctrl_enable=0 时, 触摸手势控制
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        display_active   <= 1'b1;
        output_mode_hdmi <= 1'b0;
    end else begin
        if (stm32_ctrl_enable) begin
            // STM32 控制模式: 直接使用 STM32 设置的值
            display_active   <= stm32_display_active;
            output_mode_hdmi <= stm32_output_mode;
        end else begin
            // 触摸控制模式 (原有逻辑)
            if(single_click)
                display_active <= ~display_active;
            
            if(double_click)
                output_mode_hdmi <= ~output_mode_hdmi;
        end
    end
end

assign led[0] = output_mode_hdmi;
assign led[1] = display_active;       // 冻结指示
assign exio[0] = touch_valid;     // HDMI 模式指示
assign exio[3:1] = 3'b000;             // 未使用 IO 置零防止悬空

//------------------------------------------
// 时钟PLL 0 (原有)
//------------------------------------------
clk_wiz_0 u_clk_wiz (
    .reset              (~sys_rst_n),
    .clk_in1            (sys_clk),
    .clk_out1           (FSMC_CLK),           //150MHz
    .clk_out2           (clk_100m_lcd),       //100MHz
    .clk_out3           (clk_100m),           //100MHz
    .clk_out4           (clk_100m_shift),     //100MHz
    .clk_out5           (clk_50m),            //50MHz
    .locked             (locked)
    );

//------------------------------------------
// [NEW] 时钟PLL 1 (HDMI专用)
//------------------------------------------
wire clk_hdmi;    // 65MHz
wire clk_hdmi_5x; // 325MHz
wire locked_hdmi;

clk_wiz_1 u_clk_wiz_hdmi (
    .reset              (~sys_rst_n),
    .clk_in1            (sys_clk),
    .clk_out1           (clk_hdmi),      // 65MHz (XGA)
    .clk_out2           (clk_hdmi_5x),   // 325MHz
    .locked             (locked_hdmi)
);

//------------------------------------------
// FMC控制模块
//------------------------------------------
fmc_control fmc_control1(
     .clk(FSMC_CLK),
     .rst(rst_n),
     .fpga_nl_nadv(FSMC_NL_NADV),
     .fpga_cs_ne1(FSMC_CS_NEL),
     .fpga_wr_nwe(FSMC_WR_NWE),
     .fpga_rd_noe(FSMC_RD_NOE),
     .fpga_db(FSMC_DB),
     // 发送寄存器
     .write_data_0   (fsmc_tx_data_0 ),
     .write_data_1   (fsmc_tx_data_1 ),
     .write_data_2   (fsmc_tx_data_2 ),
     .write_data_3   (fsmc_tx_data_3 ),
     .write_data_4   (fsmc_tx_data_4 ),
     .write_data_5   (fsmc_tx_data_5 ),
     .write_data_6   (fsmc_tx_data_6 ),
     .write_data_7   (fsmc_tx_data_7 ),
     .write_data_8   (fsmc_tx_data_8), // [0x0008] 输出模式状态
     .write_data_9   (fsmc_tx_data_9 ),
     .write_data_10  (fsmc_tx_data_10),
     .write_data_11  (fsmc_tx_data_11),
     .write_data_12  (fsmc_tx_data_12),
     .write_data_13  (fsmc_tx_data_13),
     .write_data_14  (fsmc_tx_data_14),
     .write_data_15  (fsmc_tx_data_15),
     // 接收寄存器
     .read_data_0    (fsmc_rx_data_0 ),
     .read_data_1    (fsmc_rx_data_1 ),
     .read_data_2    (fsmc_rx_data_2 ),
     .read_data_3    (fsmc_rx_data_3 ),
     .read_data_4    (fsmc_rx_data_4 ),
     .read_data_5    (fsmc_rx_data_5 ),
     .read_data_6    (fsmc_rx_data_6 ),
     .read_data_7    (fsmc_rx_data_7 ),
     .read_data_8    (fsmc_rx_data_8 ),
     .read_data_9    (fsmc_rx_data_9 ),
     .read_data_10   (fsmc_rx_data_10),
     .read_data_11   (fsmc_rx_data_11),
     .read_data_12   (fsmc_rx_data_12),
     .read_data_13   (fsmc_rx_data_13),
     .read_data_14   (fsmc_rx_data_14),
     .read_data_15   (fsmc_rx_data_15)
);

//------------------------------------------
// 基础触摸驱动模块
//------------------------------------------
touch_top u_touch_top(
    .clk            (clk_50m),
    .rst_n          (rst_n),
    .touch_rst_n    (touch_rst_n  ),
    .touch_int_in   (touch_int_in ),
    .touch_int_dir  (touch_int_dir),
    .touch_int_out  (touch_int_out),
    .touch_scl      (touch_scl    ),
    .touch_sda_in   (touch_sda_in ),
    .touch_sda_out  (touch_sda_out),
    .touch_sda_dir  (touch_sda_dir),
    .lcd_id         (ID_lcd    ), 
    .touch_valid    (touch_valid),
    .tp_x_coord     (tp_x_coord ),
    .tp_y_coord     (tp_y_coord ),
    .single_click   (single_click),
    .double_click   (double_click),
    .long_press     (long_press),
    .gesture_x      (gesture_x),
    .gesture_y      (gesture_y)
);

//------------------------------------------
// HDMI 模块例化 (XGA 1024x768)
//------------------------------------------
wire hdmi_vs;
wire hdmi_req;
wire [15:0] hdmi_data_in; // connect to rd_data (MUXed)

// HDMI 模块需要的数据 (rd_data) 由后面 OV5640 模块统一输出
// 我们需要把 HDMI 产生的 req 信号送给 OV5640

hdmi_top_xga u_hdmi_top(
    .pixel_clk      (clk_hdmi),
    .pixel_clk_5x   (clk_hdmi_5x),
    .sys_rst_n      (rst_n & locked_hdmi),
    
    // HDMI Output Pins
    .tmds_clk_p     (tmds_clk_p), 
    .tmds_clk_n     (tmds_clk_n), 
    .tmds_data_p    (tmds_data_p), 
    .tmds_data_n    (tmds_data_n), 
    
    .video_vs       (hdmi_vs),
    .pixel_xpos     (),
    .pixel_ypos     (),
    .data_in        (rd_data), // 共享数据总线
    .data_req       (hdmi_req)
);

//------------------------------------------
// OV5640+LCD+SDRAM集成（触摸控制显示模式）
//------------------------------------------
ov5640_rgb565_lcd u_ov5640 (
    .sys_clk        (sys_clk),
    .sys_rst_n      (sys_rst_n),
    .clk_100m       (clk_100m),
    .clk_100m_shift (clk_100m_shift),
    .clk_100m_lcd   (clk_100m_lcd),
    .locked         (locked),
    .cam_active     (display_active), // 连接到双击控制的使能信号
    
    // [NEW] HDMI MUX Port
    .hdmi_pclk      (clk_hdmi),
    .hdmi_rd_req    (hdmi_req),
    .output_mode    (output_mode_hdmi),
    .hdmi_vs        (hdmi_vs), // [FIX] 同步信号
    
    // 摄像头接口
    .cam_pclk       (cam_pclk),
    .cam_vsync      (cam_vsync),
    .cam_href       (cam_href),
    .cam_data       (cam_data),
    .cam_rst_n      (cam_rst_n),
    .cam_pwdn       (cam_pwdn),
    .cam_scl        (cam_scl),
    .cam_sda        (cam_sda),
    // SDRAM 接口
    .sdram_clk      (sdram_clk),
    .sdram_ras_n    (sdram_ras_n),
    .sdram_cas_n    (sdram_cas_n),
    .sdram_we_n     (sdram_we_n),
    .sdram_ba       (sdram_ba),
    .sdram_addr     (sdram_addr),
    .sdram_data     (sdram_data),
    // LCD 接口
    .lcd_hs         (lcd_hs),
    .lcd_vs         (lcd_vs),
    .lcd_de         (lcd_de),
    .lcd_rgb        (lcd_rgb),
    .lcd_bl         (lcd_bl),
    .lcd_rst        (lcd_rst),
    .lcd_pclk       (lcd_pclk),

    // 🔍 调试信号输出（用于黑屏诊断）
    .ID_lcd         (ID_lcd),            // LCD ID输出
    .cmos_h_pixel   (cmos_h_pixel),      // 摄像头宽度
    .cmos_v_pixel   (cmos_v_pixel),      // 摄像头高度
    .total_h_pixel  (total_h_pixel),     // 水平总像素
    .total_v_pixel  (total_v_pixel),     // 垂直总像素
    .sdram_max_addr (sdram_max_addr),    // SDRAM最大地址
    .sdram_init_done(sdram_init_done),   // SDRAM初始化完成
    .cam_init_done  (cam_init_done),     // 摄像头初始化完成
    .wr_en          (wr_en),             // 摄像头写使能
    .wr_data        (wr_data),           // 摄像头写数据
    .rd_en          (rd_en),             // LCD读使能
    .rd_data        (rd_data)            // LCD读数据
    );
    
endmodule