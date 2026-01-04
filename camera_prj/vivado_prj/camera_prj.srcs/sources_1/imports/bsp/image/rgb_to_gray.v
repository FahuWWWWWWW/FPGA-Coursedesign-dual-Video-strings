`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: rgb_to_gray
// Description: RGB565 转灰度图像
// 使用标准灰度转换公式: Gray = 0.299*R + 0.587*G + 0.114*B
//////////////////////////////////////////////////////////////////////////////////

module rgb_to_gray(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_valid,
    input  wire [15:0] rgb565_in,    // RGB565 输入
    output reg         gray_valid,
    output reg  [7:0]  gray_out      // 8位灰度输出
);

// RGB565 分量提取
wire [4:0] r5 = rgb565_in[15:11];
wire [5:0] g6 = rgb565_in[10:5];
wire [4:0] b5 = rgb565_in[4:0];

// 扩展到 8 位
wire [7:0] r8 = {r5, r5[4:2]};
wire [7:0] g8 = {g6, g6[5:4]};
wire [7:0] b8 = {b5, b5[4:2]};

// 灰度计算 (定点运算)
// Gray = (R*77 + G*150 + B*29) >> 8
wire [15:0] gray_temp = (r8 * 8'd77) + (g8 * 8'd150) + (b8 * 8'd29);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray_out <= 8'd0;
        gray_valid <= 1'b0;
    end else begin
        gray_valid <= data_valid;
        if (data_valid) begin
            gray_out <= gray_temp[15:8];  // 右移 8 位
        end
    end
end

endmodule
