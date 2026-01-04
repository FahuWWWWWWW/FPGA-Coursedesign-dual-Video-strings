`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: morphology_processor
// Description: 形态学处理 (腐蚀/膨胀)
// 使用 3x3 结构元素
//////////////////////////////////////////////////////////////////////////////////

module morphology_processor #(
    parameter H_PIXEL = 10'd800,
    parameter V_PIXEL = 10'd480
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        vsync,
    input  wire        data_valid,
    input  wire [12:0] h_pixel,         // 动态行宽输入
    input  wire [7:0]  binary_in,       // 二值图像输入
    input  wire        mode,            // 0=腐蚀, 1=膨胀
    output reg         morph_valid,
    output reg  [7:0]  morph_out
);

// 行缓存
reg [23:0] pix_cnt;
wire [7:0] line1_data, line2_data, line3_data;

// FIFO 控制
wire fifo1_wr_en = data_valid;
wire fifo1_rd_en = data_valid && (pix_cnt >= h_pixel);
wire fifo2_wr_en = data_valid && (pix_cnt >= h_pixel);
wire fifo2_rd_en = data_valid && (pix_cnt >= {h_pixel, 1'b0}); // h_pixel * 2

assign line1_data = line2_fifo_out;
assign line2_data = line1_fifo_out;
assign line3_data = binary_in;

// 像素计数和 FIFO 复位控制
reg cam_vsync_d;
reg fifo_rst;
reg [4:0] rst_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pix_cnt <= 24'd0;
        cam_vsync_d <= 1'b0;
        fifo_rst <= 1'b1;
        rst_cnt <= 5'd0;
    end else begin
        cam_vsync_d <= vsync;
        
        // vsync 上升沿产生宽复位脉冲
        if (vsync && !cam_vsync_d) begin
            rst_cnt <= 5'd31;
            fifo_rst <= 1'b1;
            pix_cnt <= 24'd0;
        end else begin
            if (rst_cnt > 0) begin
                rst_cnt <= rst_cnt - 1'b1;
                fifo_rst <= 1'b1;
            end else begin
                fifo_rst <= 1'b0;
                if (data_valid)
                    pix_cnt <= pix_cnt + 1'b1;
            end
        end
    end
end

// 延迟匹配逻辑
reg [7:0] binary_in_d1;
reg data_valid_d1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        binary_in_d1 <= 8'd0;
        data_valid_d1 <= 1'b0;
    end else begin
        binary_in_d1 <= binary_in;
        data_valid_d1 <= data_valid;
    end
end

// 3x3 窗口
reg [7:0] p11, p12, p13;
reg [7:0] p21, p22, p23;
reg [7:0] p31, p32, p33;

// 形态学运算 (组合逻辑，放在 always 块外面)
wire [8:0] sum = p11[7] + p12[7] + p13[7] + 
                 p21[7] + p22[7] + p23[7] + 
                 p31[7] + p32[7] + p33[7];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {p11, p12, p13} <= 24'd0;
        {p21, p22, p23} <= 24'd0;
        {p31, p32, p33} <= 24'd0;
        morph_out <= 8'd0;
        morph_valid <= 1'b0;
    end else if (data_valid_d1) begin // 使用延迟后的 valid
        // 移位窗口
        {p13, p12, p11} <= {p12, p11, line1_data};
        {p23, p22, p21} <= {p22, p21, line2_data};
        {p33, p32, p31} <= {p32, p31, binary_in_d1};
        
        // 形态学处理
        if (pix_cnt >= {h_pixel, 1'b0}) begin
            if (mode == 1'b0) begin
                // 腐蚀: 所有像素都是白色才输出白色
                morph_out <= (sum == 9'd9) ? 8'd255 : 8'd0;
            end else begin
                // 膨胀: 任意像素是白色就输出白色
                morph_out <= (sum > 9'd0) ? 8'd255 : 8'd0;
            end
            morph_valid <= 1'b1;
        end else begin
            morph_out <= 8'd0;
            morph_valid <= 1'b0;
        end
    end else begin
        morph_valid <= 1'b0;
    end
end

// FIFO 实例 - 使用 Xilinx IP 核
wire [7:0] line1_fifo_out, line2_fifo_out;

fifo_generator_1 morph_line1_fifo (
    .clk(clk),              // input wire clk
    .srst(~rst_n | fifo_rst), // input wire srst (系统复位或帧复位)
    .din(line3_data),       // input wire [7:0] din
    .wr_en(fifo1_wr_en),    // input wire wr_en
    .rd_en(fifo1_rd_en),    // input wire rd_en
    .dout(line1_fifo_out),  // output wire [7:0] dout
    .full(),                // output wire full
    .empty()                // output wire empty
);

fifo_generator_1 morph_line2_fifo (
    .clk(clk),
    .srst(~rst_n | fifo_rst), // input wire srst (系统复位或帧复位)
    .din(line2_data),
    .wr_en(fifo2_wr_en),
    .rd_en(fifo2_rd_en),
    .dout(line2_fifo_out),
    .full(),
    .empty()
);

endmodule
