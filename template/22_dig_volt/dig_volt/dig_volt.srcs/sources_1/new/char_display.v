`timescale 1ns/1ns

module char_display
(
    input   wire    [10:0]  pix_x,      // 当前扫描的X坐标
    input   wire    [10:0]  pix_y,      // 当前扫描的Y坐标
    input   wire    [15:0]  v_bcd,      // 电压BCD码
    input   wire    [23:0]  f_bcd,      // 频率BCD码
    
    output  reg             pixel_on    // 输出：像素点亮信号
);

    //========================================================================
    // 1. 内部信号定义
    //========================================================================
    reg     [7:0]   char_code;      // 当前字符的 ASCII 码
    wire    [3:0]   row_addr;       // 字模行索引
    wire    [7:0]   row_data;       // 字模行数据
    
    // 区域判断
    wire            in_volt_area;
    wire            in_freq_area;
    
    // 相对坐标与索引
    wire    [10:0]  rel_x;          // 相对起始位置的X坐标
    wire    [10:0]  rel_y;          // 【新增】相对起始位置的Y坐标
    
    wire    [3:0]   char_index;     // 当前是第几个字符
    wire    [2:0]   bit_index;      // 当前是字符内的第几列
    
    //========================================================================
    // 2. 常用字符定义
    //========================================================================
    localparam CHAR_SPACE = 8'd32;
    localparam CHAR_DOT   = 8'd46;  // .
    localparam CHAR_COLON = 8'd58;  // :
    localparam CHAR_V     = 8'd86;  // V
    localparam CHAR_o     = 8'd111; // o
    localparam CHAR_l     = 8'd108; // l
    localparam CHAR_t     = 8'd116; // t
    localparam CHAR_F     = 8'd70;  // F
    localparam CHAR_r     = 8'd114; // r
    localparam CHAR_e     = 8'd101; // e
    localparam CHAR_q     = 8'd113; // q
    localparam CHAR_H     = 8'd72;  // H
    localparam CHAR_z     = 8'd122; // z
    
    //========================================================================
    // 3. 坐标计算 (XY轴双重修复)
    //========================================================================
    
    // 电压行: (20, 20) -> (124, 36)
    assign in_volt_area = (pix_y >= 11'd20 && pix_y < 11'd36) && 
                          (pix_x >= 11'd20 && pix_x < 11'd124);

    // 频率行: (20, 40) -> (140, 56)
    assign in_freq_area = (pix_y >= 11'd40 && pix_y < 11'd56) && 
                          (pix_x >= 11'd20 && pix_x < 11'd140);
    
    // --- X轴相对坐标 ---
    // 两个区域 X 起始点都是 20
    assign rel_x = pix_x - 11'd20;
    
    // --- Y轴相对坐标 (【修复重点】) ---
    // 根据当前是在 电压区 还是 频率区，减去不同的起始 Y 值
    assign rel_y = (in_volt_area) ? (pix_y - 11'd20) : 
                   (in_freq_area) ? (pix_y - 11'd40) : 11'd0;
    
    // 计算当前是第几个字符 (X / 8)
    assign char_index = rel_x[6:3]; 
    
    // 计算当前是字符内的第几位 (X % 8，高位在前)
    assign bit_index  = 3'd7 - rel_x[2:0];
    
    // 字模行索引 (使用相对 Y 坐标)
    // 现在 Y=20 时，rel_y=0，row_addr=0，显示正确！
    assign row_addr = rel_y[3:0];

    //========================================================================
    // 4. Font ROM 实例化
    //========================================================================
    font_rom_8x16 u_font_rom (
        .char_code  (char_code),
        .row        (row_addr),
        .row_data   (row_data)
    );

    //========================================================================
    // 5. 字符选择逻辑
    //========================================================================
    always @(*) begin
        char_code = CHAR_SPACE;

        if (in_volt_area) begin
            case (char_index)
                4'd0: char_code = CHAR_V;     
                4'd1: char_code = CHAR_o;     
                4'd2: char_code = CHAR_l;     
                4'd3: char_code = CHAR_t;     
                4'd4: char_code = CHAR_COLON; 
                4'd5: char_code = CHAR_SPACE; 
                // Volt: 1.234
                4'd6: char_code = 8'd48 + v_bcd[15:12]; 
                4'd7: char_code = CHAR_DOT;             
                4'd8: char_code = 8'd48 + v_bcd[11:8];  
                4'd9: char_code = 8'd48 + v_bcd[7:4];   
                4'd10:char_code = 8'd48 + v_bcd[3:0];   
                
                4'd11:char_code = CHAR_SPACE; 
                4'd12:char_code = CHAR_V;     
                default: char_code = CHAR_SPACE;
            endcase
        end
        else if (in_freq_area) begin
            case (char_index)
                4'd0: char_code = CHAR_F;     
                4'd1: char_code = CHAR_r;     
                4'd2: char_code = CHAR_e;     
                4'd3: char_code = CHAR_q;     
                4'd4: char_code = CHAR_COLON; 
                4'd5: char_code = CHAR_SPACE; 
                // Freq: 001000
                4'd6: char_code = 8'd48 + f_bcd[23:20]; 
                4'd7: char_code = 8'd48 + f_bcd[19:16]; 
                4'd8: char_code = 8'd48 + f_bcd[15:12]; 
                4'd9: char_code = 8'd48 + f_bcd[11:8];  
                4'd10:char_code = 8'd48 + f_bcd[7:4];   
                4'd11:char_code = 8'd48 + f_bcd[3:0];   
                
                4'd12:char_code = CHAR_SPACE; 
                4'd13:char_code = CHAR_H;     
                4'd14:char_code = CHAR_z;     
                default: char_code = CHAR_SPACE;
            endcase
        end
    end

    //========================================================================
    // 6. 输出逻辑
    //========================================================================
    always @(*) begin
        if (in_volt_area || in_freq_area)
            pixel_on = row_data[bit_index];
        else
            pixel_on = 1'b0;
    end

endmodule