module tft_pic_scope
(
    input   wire            tft_clk,
    input   wire            rst_n,
    input   wire    [10:0]  pix_x,
    input   wire    [10:0]  pix_y,
    
    input   wire    [7:0]   wave_data,   // RAM数据 (0-255)
    input   wire    [15:0]  v_bcd,       // 电压BCD
    input   wire    [23:0]  f_bcd,       // 频率BCD
    
    output  wire    [9:0]   ram_rd_addr, // 读地址连接到 pix_x
    output  reg     [15:0]  pix_data     // 输出颜色
);

// 颜色定义
localparam BLACK = 16'h0000;
localparam BLUE  = 16'h001F;
localparam GRID  = 16'h4208; // 灰色网格
localparam WHITE = 16'hFFFF;
localparam YELLOW= 16'hFFE0;

//-----------------------------------------------------------
// 1. 波形计算逻辑
//-----------------------------------------------------------
// 只在屏幕前800列显示波形
assign ram_rd_addr = (pix_x < 800) ? pix_x[9:0] : 10'd0;

// 计算当前像素列对应的波形高度 Y
// 屏幕高度480，中线240。ADC数据 0对应底部，255对应顶部(反向或正向取决于电路)
// 这里假设 128 是中点。 
// 公式：Y = 240 - (wave_data - 128)
wire [10:0] wave_y;
assign wave_y = 11'd240 + (11'd128 - {3'b0, wave_data});

wire is_wave;
// 简单的画点：如果当前扫描行 Y == 波形 Y，点亮
// 为了看得更清楚，可以画粗一点 (Y-1, Y, Y+1)
assign is_wave = (pix_x < 800) && (pix_y >= wave_y - 1) && (pix_y <= wave_y + 1);

//-----------------------------------------------------------
// 2. 字符/UI 显示逻辑
//-----------------------------------------------------------
wire is_char;
char_display char_disp_inst (
    .pix_x(pix_x),
    .pix_y(pix_y),
    .v_bcd(v_bcd),
    .f_bcd(f_bcd),
    .pixel_on(is_char)
);

//-----------------------------------------------------------
// 3. 像素合成
//-----------------------------------------------------------
always @(*) begin
    // 优先级：字符 > 波形 > 网格 > 背景
    if(is_char) 
        pix_data = WHITE;  // 文字白色
    else if(is_wave) 
        pix_data = YELLOW; // 波形黄色
    else begin
        // 画虚线网格 (每50像素)
        if((pix_x % 50 == 0) || (pix_y % 50 == 0))
            pix_data = GRID;
        else
            pix_data = BLUE; // 背景蓝色
    end
end

endmodule