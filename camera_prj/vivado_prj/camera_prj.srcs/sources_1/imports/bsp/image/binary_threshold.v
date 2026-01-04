`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: binary_threshold
// Description: 二值化处理
// 输入灰度图像，输出二值图像 (0 或 255)
//////////////////////////////////////////////////////////////////////////////////

module binary_threshold #(
    parameter THRESHOLD = 8'd128  // 默认阈值
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       data_valid,
    input  wire [7:0] gray_in,       // 灰度输入
    input  wire [7:0] threshold,     // 可调阈值
    output reg        binary_valid,
    output reg  [7:0] binary_out     // 二值输出 (0 或 255)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        binary_out <= 8'd0;
        binary_valid <= 1'b0;
    end else begin
        binary_valid <= data_valid;
        if (data_valid) begin
            binary_out <= (gray_in >= threshold) ? 8'd255 : 8'd0;
        end
    end
end

endmodule
