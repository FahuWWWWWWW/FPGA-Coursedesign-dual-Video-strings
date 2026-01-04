module ov5640_rgb565_lcd#
(
	parameter SDR_BA_WIDTH           = 2  ,
	parameter SDR_ROW_WIDTH          = 11  ,
	parameter SDR_COL_WIDTH          = 8  ,
	parameter MEM_DATA_BITS          = 16  ,        //external memory user interface data width
	parameter ADDR_BITS              = 19  ,        //external memory user interface address width
	parameter BUSRT_BITS             = 10  ,        //external memory user interface burst width
	parameter BURST_SIZE             = 128         //burst size
)
(
    input         sys_clk    ,  //系统时钟
    input         sys_rst_n  ,  //系统复位，低电平有效
    input         clk_100m   ,  //SDRAM操作时钟
    input         clk_100m_shift, //SDRAM相位偏移时钟
    input         clk_100m_lcd,   //LCD顶层模块时钟
    input         locked      ,   //PLL锁定信号
    input         cam_active  ,   //摄像头采集使能（高有效）
    //摄像头
    input         cam_pclk   ,  //cmos 数据像素时钟
    input         cam_vsync  ,  //cmos 场同步信号
    input         cam_href   ,  //cmos 行同步信号
    input  [7:0]  cam_data   ,  //cmos 数据
    output        cam_rst_n  ,  //cmos 复位信号，低电平有效
    output        cam_pwdn   ,  //cmos 电源休眠模式选择信号
    output        cam_scl    ,  //cmos SCCB_SCL线
    inout         cam_sda    ,  //cmos SCCB_SDA线
    //SDRAM
    output        sdram_clk  ,  //SDRAM 时钟
//    output        sdram_cke  ,  //SDRAM 时钟有效
//    output        sdram_cs_n ,  //SDRAM 片选
    output        sdram_ras_n,  //SDRAM 行有效
    output        sdram_cas_n,  //SDRAM 列有效
    output        sdram_we_n ,  //SDRAM 写有效
    output [1:0]  sdram_ba   ,  //SDRAM Bank地址
//    output [1:0]  sdram_dqm  ,  //SDRAM 数据掩码
    output [10:0] sdram_addr ,  //SDRAM 地址
    inout  [MEM_DATA_BITS - 1:0] sdram_data ,  //SDRAM 数据
    //---------------------------------------------------------
    // SDRAM 读端口多路复用器 (LCD vs HDMI)
    //---------------------------------------------------------
    input         hdmi_pclk,      // HDMI 像素时钟
    input         hdmi_rd_req,    // HDMI 读请求
    input         output_mode,    // 0:LCD, 1:HDMI (从Top传入)
    input         hdmi_vs,        // HDMI 场同步

    //LCD接口
    output        lcd_hs     ,  //LCD 行同步信号
    output        lcd_vs     ,  //LCD 场同步信号
    output        lcd_de     ,  //LCD 数据输入使能
    inout  [23:0] lcd_rgb    ,  //LCD RGB888颜色数据
    output        lcd_bl     ,  //LCD 背光控制信号
    output        lcd_rst    ,  //LCD 复位信号
    output        lcd_pclk   ,  //LCD 采样时钟

    // 调试信号
    output [15:0] ID_lcd     ,  //LCD ID
    output [12:0] cmos_h_pixel, //CMOS水平方向像素个数
    output [12:0] cmos_v_pixel, //CMOS垂直方向像素个数
    output [12:0] total_h_pixel,//水平总像素大小
    output [12:0] total_v_pixel,//垂直总像素大小
    output [23:0] sdram_max_addr,//sdram读写的最大地址
    output        sdram_init_done,//SDRAM初始化完成
    output        cam_init_done  ,//摄像头初始化完成
    output        wr_en,
    output [15:0] wr_data,
    output        rd_en,
    output [15:0] rd_data,
    
    // 图像处理控制
    input  [2:0]  image_algo_mode,   // 图像处理算法模式
    input  [7:0]  image_threshold,   // 二值化阈值
    output [63:0] debug_out          // 新增调试输出
    );

//parameter define
parameter SLAVE_ADDR = 7'h3c          ; //OV5640的器件地址7'h3c
parameter BIT_CTRL   = 1'b1           ; //OV5640的字节地址为16位  0:8位 1:16位
parameter CLK_FREQ   = 27'd100_000_000; //i2c_dri模块的驱动时钟频率 
parameter I2C_FREQ   = 18'd250_000    ; //I2C的SCL时钟频率,不超过400KHz

//wire define
wire        clk_lcd        ;
wire        rst_n          ;
wire        sys_init_done  ;  //系统初始化完成(sdram初始化+摄像头初始化)
wire        lcd_frame_sync ;  // [NEW] 内部 LCD 场同步信号

// 最终送给SDRAM的读信号 (MUX)
wire sdram_rd_clk_mux;
wire sdram_rd_req_mux;

// 根据 output_mode 选择读时钟和请求源
// 使用同步后的 mode_d1 以减少亚稳态抖动风险
assign sdram_rd_clk_mux = (mode_d1 == 1'b1) ? hdmi_pclk : clk_lcd;
assign sdram_rd_req_mux = (mode_d1 == 1'b1) ? hdmi_rd_req : rd_en_int;


wire        i2c_exec       ;  //I2C触发执行信号
wire [23:0] i2c_data       ;  //I2C要配置的地址与数据(高8位地址,低8位数据)
wire        i2c_done       ;  //I2C寄存器配置完成信号
wire        i2c_dri_clk    ;  //I2C操作时钟
wire [ 7:0] i2c_data_r     ;  //I2C读出的数据
wire        i2c_rh_wl      ;  //I2C读写控制信号

// 将内部wire信号改为output连接
wire [15:0] ID_lcd_int         ;  //LCD的ID (内部)
wire [12:0] cmos_h_pixel_int   ;  //CMOS水平方向像素个数 (内部)
wire [12:0] cmos_v_pixel_int   ;  //CMOS垂直方向像素个数 (内部)
wire [12:0] total_h_pixel_int  ;  //水平总像素大小 (内部)
wire [12:0] total_v_pixel_int  ;  //垂直总像素大小 (内部)
wire [23:0] sdram_max_addr_int ;  //sdram读写的最大地址 (内部)

wire        wr_en_int          ;  //sdram_ctrl模块写使能 (内部)
wire [15:0] wr_data_int        ;  //sdram_ctrl模块写数据 (内部)
wire        rd_en_int          ;  //sdram_ctrl模块读使能 (内部)
wire [15:0] rd_data_int        ;  //sdram_ctrl模块读数据 (内部)
wire        sdram_init_done_int;  //SDRAM初始化完成 (内部)
wire        cam_init_done_int  ;  //摄像头初始化完成 (内部)

// 将内部信号连接到输出端口
assign ID_lcd = ID_lcd_int;
assign cmos_h_pixel = cmos_h_pixel_int;
assign cmos_v_pixel = cmos_v_pixel_int;
assign total_h_pixel = total_h_pixel_int;
assign total_v_pixel = total_v_pixel_int;
assign sdram_max_addr = sdram_max_addr_int;
assign sdram_init_done = sdram_init_done_int;
assign cam_init_done = cam_init_done_int;
assign wr_en = wr_en_int;
assign wr_data = wr_data_int;
assign rd_en = rd_en_int;

// [FIX] HDMI 输出数据门控：当在 LCD 模式时或系统初始化未完成时，HDMI 收到全黑数据 (防止花屏)
assign rd_data = ((output_mode == 1'b1) && sys_init_done) ? rd_data_int : 16'd0;

// [FIX] 模式切换边沿检测 (用于复位 SDRAM FIFO)
(* ASYNC_REG = "TRUE" *) reg mode_d0, mode_d1;
wire mode_change_pulse;

    always @(posedge clk_100m or negedge sys_rst_n) begin
        if(!sys_rst_n) begin
            mode_d0 <= 1'b0;
            mode_d1 <= 1'b0;
        end else begin
            mode_d0 <= output_mode;
            mode_d1 <= mode_d0;
        end
    end
    assign mode_change_pulse = mode_d0 ^ mode_d1; // 检测模式切换的边沿 (双眼检测)
// [FIX] 统一显示区域同步框架 (Unified Display Sync Framework)
// 1. 解决 hdmi_vs_d 的多驱动冲突信号 (Multiple Driver Fix)
// 2. 统一边沿检测：HDMI(低有效脉冲)检测上升沿, LCD(高有效脉冲)检测下降沿 -> 均对应"脉冲结束/有效显示开始"
// 3. 简化逻辑，提高硬件稳定性

(* ASYNC_REG = "TRUE" *) reg [1:0] sync_hdmi_vs;
(* ASYNC_REG = "TRUE" *) reg [1:0] sync_lcd_vs;
wire display_frame_start; // 统一的帧开始对齐脉冲

always @(posedge clk_100m or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        sync_hdmi_vs <= 2'b11; // HDMI VS 默认高电平，设为11避免复位瞬间误发脉冲
        sync_lcd_vs  <= 2'b00; // LCD frame_sync 默认低电平
    end else begin
        sync_hdmi_vs <= {sync_hdmi_vs[0], hdmi_vs};
        sync_lcd_vs  <= {sync_lcd_vs[0], lcd_frame_sync};
    end
end

// HDMI 上升沿 = 脉冲结束 = 图像开始
wire hdmi_frame_start = (sync_hdmi_vs == 2'b01);
// LCD 下降沿 = 脉冲结束 = 图像开始 (lcd_frame_sync 是高脉冲)
wire lcd_frame_start  = (sync_lcd_vs == 2'b10);

assign display_frame_start = (output_mode == 1'b1) ? hdmi_frame_start : lcd_frame_start;

// 状态机：等待 VSYNC 到来以解除模式切换时的输出锁定
reg switch_wait_vsync; 

always @(posedge clk_100m or negedge sys_rst_n) begin
    if(!sys_rst_n)
        switch_wait_vsync <= 1'b0;
    else if(mode_change_pulse) 
        switch_wait_vsync <= 1'b1; // 切换模式时启动保护
    else if(switch_wait_vsync && display_frame_start)
        switch_wait_vsync <= 1'b0; // 等到下一个完整帧开始时，解除保护
end

// 定期校正逻辑 (约 10 秒/600 帧校正一次 FIFO 偏移)
reg [9:0] frame_counter;
reg periodic_sync_pending;

always @(posedge clk_100m or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        frame_counter <= 10'd0;
        periodic_sync_pending <= 1'b0;
    end else begin
        if(display_frame_start) begin
            if(frame_counter >= 10'd199) begin
                frame_counter <= 10'd0;
                periodic_sync_pending <= 1'b1;
            end else begin
                frame_counter <= frame_counter + 10'd1;
            end
        end
        // 当校正脉冲发出（在 final_rd_load 中使用）后，清除状态位
        if(periodic_sync_pending && display_frame_start)
            periodic_sync_pending <= 1'b0;
    end
end

// 最终控制信号生成
// 触发 FIFO 同步加载：系统复位 | 模式切换同步中 | 触发定期校正脉冲
wire final_rd_load = ~rst_n | switch_wait_vsync | (periodic_sync_pending & display_frame_start);

// 最终读请求屏蔽：仅在模式切换等待期间阻塞读取，且必须在系统初始化完成后
wire final_rd_en = sdram_rd_req_mux & (~switch_wait_vsync) & sys_init_done;

// [FIX] LCD 数据输入门控：当在 HDMI 模式时或系统未初始化时，LCD 收到全黑数据
wire [15:0] lcd_pixel_data_gated;
assign lcd_pixel_data_gated = ((output_mode == 1'b0) && sys_init_done) ? rd_data_int : 16'd0;

reg        	rst_first    ;
reg  [12:0]    rst_first_cnt;  

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n) begin
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

assign  rst_n = sys_rst_n & locked &rst_first;
//系统初始化完成：SDRAM和摄像头都初始化完成
//避免了在SDRAM初始化过程中向里面写入数据
assign  sys_init_done = sdram_init_done_int & cam_init_done_int;
//电源休眠模式选择 0：正常模式 1：电源休眠模式
assign  cam_pwdn  = 1'b0;
assign  cam_rst_n = 1'b1;

//例化LCD顶层模块
lcd u_lcd(
    .clk                (clk_100m_lcd),
    .rst_n              (rst_n),

    .lcd_hs             (lcd_hs),
    .lcd_vs             (lcd_vs),
    .lcd_de             (lcd_de),
    .lcd_rgb            (lcd_rgb),
    .lcd_bl             (lcd_bl),
    .lcd_rst            (lcd_rst),
    .lcd_pclk           (lcd_pclk),

    .pixel_data         (lcd_pixel_data_gated), // [FIX] Gated data
    .rd_en              (rd_en_int),
    .clk_lcd            (clk_lcd),          //LCD驱动时钟

    .ID_lcd             (ID_lcd_int),       //LCD ID
    .frame_sync         (lcd_frame_sync)    // [NEW] 内部 Sync 连接
    );

//摄像头图像分辨率设置模块
picture_size u_picture_size (
    .rst_n              (rst_n),
    .ID_lcd             (ID_lcd_int),           //LCD的ID，用于配置摄像头的图像大小
    .output_mode        (output_mode),          // [NEW] 双击切换输入 (0:LCD, 1:HDMI)

    .cmos_h_pixel       (cmos_h_pixel_int  ),   //摄像头水平方向分辨率
    .cmos_v_pixel       (cmos_v_pixel_int  ),   //摄像头垂直方向分辨率
    .total_h_pixel      (total_h_pixel_int ),   //用于配置HTS寄存器
    .total_v_pixel      (total_v_pixel_int ),   //用于配置VTS寄存器
    .sdram_max_addr     (sdram_max_addr_int)    //sdram读写的最大地址
    );

// [FIX] I2C 重配置复位逻辑 - 简化版
reg i2c_config_rst_n;
reg [15:0] reset_counter;

always @(posedge clk_100m or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        i2c_config_rst_n <= 1'b0;
        reset_counter <= 16'd0;
    end else begin
        // 模式切换检测 -> 触发复位脉冲
        if(mode_change_pulse) begin
            i2c_config_rst_n <= 1'b0;
            reset_counter <= 16'd50000; // 500us @ 100MHz
        end
        // 复位计数中
        else if(reset_counter > 0) begin
            reset_counter <= reset_counter - 1'b1;
            i2c_config_rst_n <= 1'b0;
        end
        // 正常运行 - 跟随系统复位
        else begin
            i2c_config_rst_n <= rst_n;
        end
    end
end

//I2C配置模块
i2c_ov5640_rgb565_cfg u_i2c_cfg(
    .clk                (i2c_dri_clk),
    .rst_n              (i2c_config_rst_n), // [RESTORED] 使用受控复位信号支持模式切换

    .i2c_exec           (i2c_exec),
    .i2c_data           (i2c_data),
    .i2c_rh_wl          (i2c_rh_wl),        //I2C读写控制信号
    .i2c_done           (i2c_done),
    .i2c_data_r         (i2c_data_r),

    .cmos_h_pixel       (cmos_h_pixel_int),     //CMOS水平方向像素个数
    .cmos_v_pixel       (cmos_v_pixel_int) ,    //CMOS垂直方向像素个数
    .total_h_pixel      (total_h_pixel_int),    //水平总像素大小
    .total_v_pixel      (total_v_pixel_int),    //垂直总像素大小

    .init_done          (cam_init_done_int)
    );    

//I2C驱动模块
i2c_dri #(
    .SLAVE_ADDR         (SLAVE_ADDR),       //参数传递
    .CLK_FREQ           (CLK_FREQ  ),              
    .I2C_FREQ           (I2C_FREQ  ) 
    )
u_i2c_dr(
    .clk                (clk_100m_lcd),
    .rst_n              (rst_n     ),

    .i2c_exec           (i2c_exec  ),   
    .bit_ctrl           (BIT_CTRL  ),   
    .i2c_rh_wl          (i2c_rh_wl),        //固定为0，只用到了IIC驱动的写操作   
    .i2c_addr           (i2c_data[23:8]),   
    .i2c_data_w         (i2c_data[7:0]),   
    .i2c_data_r         (i2c_data_r),   
    .i2c_done           (i2c_done  ),
    
    .scl                (cam_scl   ),   
    .sda                (cam_sda   ),   

    .dri_clk            (i2c_dri_clk)       //I2C操作时钟
    );

//CMOS图像数据采集模块
cmos_capture_data u_cmos_capture_data(      //系统初始化完成之后再开始采集数据
    .rst_n              (rst_n & sys_init_done),

    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),

    .cmos_frame_vsync   (),
    .cmos_frame_href    (),
    .cmos_frame_valid   (cmos_wr_en_raw),       //数据有效使能信号
    .cmos_frame_data    (cmos_wr_data_raw)      //有效数据
    );

// 图像处理中间信号
wire cmos_wr_en_raw;
wire [15:0] cmos_wr_data_raw;
wire processed_valid;
wire [15:0] processed_data;

// CDC 同步: 图像处理控制信号 (来自 clk_50m, 同步到 cam_pclk)
(* ASYNC_REG = "TRUE" *) reg [2:0] image_algo_mode_sync0, image_algo_mode_sync1;
(* ASYNC_REG = "TRUE" *) reg [7:0] image_threshold_sync0, image_threshold_sync1;

always @(posedge cam_pclk or negedge rst_n) begin
    if (!rst_n) begin
        image_algo_mode_sync0 <= 3'd0;
        image_algo_mode_sync1 <= 3'd0;
        image_threshold_sync0 <= 8'd128;
        image_threshold_sync1 <= 8'd128;
    end else begin
        image_algo_mode_sync0 <= image_algo_mode;
        image_algo_mode_sync1 <= image_algo_mode_sync0;
        image_threshold_sync0 <= image_threshold;
        image_threshold_sync1 <= image_threshold_sync0;
    end
end

// 图像处理模块实例化 (使用同步后的控制信号)
image_pixel_processor #(
    .H_PIXEL(13'd2048),  // 最大支持宽度 (FIFO深度)
    .V_PIXEL(13'd2048)   // 最大支持高度
) u_image_processor (
    .clk        (cam_pclk),
    .rst_n      (rst_n & sys_init_done),
    .vsync      (cam_vsync),
    .data_valid (cmos_wr_en_raw),
    .h_pixel    (measured_h_pixel),        // [FIX] 使用实时测量的行宽，而非配置值
    .rgb565_in  (cmos_wr_data_raw),
    .algo_mode  (image_algo_mode_sync1),   // 使用同步后的信号
    .threshold  (image_threshold_sync1),   // 使用同步后的信号
    .pixel_valid(processed_valid),
    .pixel_out  (processed_data)
);

//---------------------------------------------------------
// 调试计数器逻辑
//---------------------------------------------------------
reg [15:0] frame_cnt;
reg [31:0] pixel_cnt_current;
reg [31:0] pixel_cnt_last;
reg vsync_d_debug;

always @(posedge cam_pclk or negedge rst_n) begin
    if (!rst_n) begin
        frame_cnt <= 16'd0;
        pixel_cnt_current <= 32'd0;
        pixel_cnt_last <= 32'd0;
        vsync_d_debug <= 1'b0;
    end else begin
        vsync_d_debug <= cam_vsync;
        
        // VSYNC 上升沿 (新帧开始)
        if (cam_vsync && !vsync_d_debug) begin
            frame_cnt <= frame_cnt + 1'b1;
            pixel_cnt_last <= pixel_cnt_current; // 锁存上一帧的有效像素数
            pixel_cnt_current <= 32'd0;          // 清零当前帧计数
        end else begin
            // 统计处理后的有效像素
            if (processed_valid) begin
                pixel_cnt_current <= pixel_cnt_current + 1'b1;
            end
        end
    end
end

// debug_out 格式: [63:48]保留, [47:16]上一帧有效像素数, [15:0]帧计数器
assign debug_out = {16'd0, pixel_cnt_last, frame_cnt};

// 选择原始数据或处理后的数据
assign wr_en_int   = (image_algo_mode_sync1 == 3'd0) ? cmos_wr_en_raw : processed_valid;
assign wr_data_int = (image_algo_mode_sync1 == 3'd0) ? cmos_wr_data_raw : processed_data;

    //---------------------------------------------------------
    // VSYNC同步所在的采集控制逻辑 (防撕裂关键)
    // 改为同步逻辑，避免将VSYNC用作时钟，解决BUFG布线错误
    //---------------------------------------------------------
    //---------------------------------------------------------
    // VSYNC同步所在的采集控制逻辑 (防撕裂关键)
    // 改为同步逻辑，避免将VSYNC用作时钟，解决BUFG布线错误
    //---------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) reg cam_active_d0, cam_active_d1; // CDC 同步寄存器
    reg cam_active_sync;
    (* ASYNC_REG = "TRUE" *) reg cam_vsync_d0;
    (* ASYNC_REG = "TRUE" *) reg cam_vsync_d1;
    wire cam_vsync_pos;

    // 1. 同步 cam_active (来自 clk_50m) 到 cam_pclk 域
    always @(posedge cam_pclk or negedge rst_n) begin
        if(!rst_n) begin
            cam_active_d0 <= 1'b0;
            cam_active_d1 <= 1'b0;
        end else begin
            cam_active_d0 <= cam_active;
            cam_active_d1 <= cam_active_d0;
        end
    end

    // 2. VSYNC 边沿检测 (在 PCLK 域)
    always @(posedge cam_pclk or negedge rst_n) begin
        if(!rst_n) begin
            cam_vsync_d0 <= 1'b0;
            cam_vsync_d1 <= 1'b0;
        end else begin
            cam_vsync_d0 <= cam_vsync;
            cam_vsync_d1 <= cam_vsync_d0;
        end
    end

    assign cam_vsync_pos = cam_vsync_d0 & ~cam_vsync_d1; // 上升沿检测

    // 3. 在VSYNC上升沿到来时更新使能状态
    always @(posedge cam_pclk or negedge rst_n) begin
        if(!rst_n)
            cam_active_sync <= 1'b0;
        else if(cam_vsync_pos)
            cam_active_sync <= cam_active_d1; // 使用同步后的信号
    end
    
    // 只有当全局使能有效，且同步后的状态有效时，才允许写入SDRAM
    // 这样LCD就会不断读取SDRAM中最后完整的一帧数据，实现静止画面
    wire sdram_wr_en_gated = wr_en_int & cam_active_sync;

//SDRAM 控制器顶层模块,封装成FIFO接口
//SDRAM 控制器地址组成: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top #
(
	.MEM_DATA_BITS  (MEM_DATA_BITS)
) u_sdram_top(
    .ref_clk            (clk_100m),         //sdram 控制器参考时钟
    .out_clk            (clk_100m_shift),   //用于输出的相位偏移时钟
    .rst_n              (rst_n),            //系统复位

    //用户写端口
    .wr_clk             (cam_pclk),         //写端口FIFO: 写时钟
    .wr_en              (sdram_wr_en_gated),//写端口FIFO: 写使能 (受控)
    .wr_data            (wr_data_int),      //写端口FIFO: 写数据
    .wr_min_addr        (24'd0),            //写SDRAM的起始地址
    .wr_max_addr        (sdram_max_addr_int),   //写SDRAM的结束地址
    .wr_len             (BURST_SIZE),       //写SDRAM时的数据突发长度
    .wr_load            (~rst_n | switch_wait_vsync),           //写端口复位: 复位写地址,清空写FIFO

    //用户读端口
    .rd_clk             (sdram_rd_clk_mux), //读端口FIFO: 读时钟 (MUX)
    .rd_en              (final_rd_en),      //读端口FIFO: 读使能 (受 vsync 同步控制)
    .rd_data            (rd_data_int),      //读端口FIFO: 读数据

    .rd_min_addr        (24'd0),            //读SDRAM的起始地址
    .rd_max_addr        (sdram_max_addr_int),   //读SDRAM的结束地址
    .rd_len             (BURST_SIZE),       //从SDRAM中读数据时的突发长度
    // [FIX] 使用新的同步复位信号
    .rd_load            (final_rd_load),    // 复位读FIFO

    //用户控制端口
    .sdram_read_valid   (1'b1),             //SDRAM 读使能
    .sdram_pingpang_en  (1'b1),             //SDRAM 乒乓操作使能
    .sdram_init_done    (sdram_init_done_int),  //SDRAM 初始化完成标志

    //SDRAM 芯片接口
    .sdram_clk          (sdram_clk),        //SDRAM 芯片时钟
    .sdram_cke          (),                 //SDRAM 时钟有效
    .sdram_cs_n         (),                 //SDRAM 片选
    .sdram_ras_n        (sdram_ras_n),      //SDRAM 行有效
    .sdram_cas_n        (sdram_cas_n),      //SDRAM 列有效
    .sdram_we_n         (sdram_we_n),       //SDRAM 写有效
    .sdram_ba           (sdram_ba),         //SDRAM Bank地址
    .sdram_addr         (sdram_addr),       //SDRAM 行/列地址
    .sdram_data         (sdram_data),       //SDRAM 数据
    .sdram_dqm          ()                  //SDRAM 数据掩码
    );

endmodule 