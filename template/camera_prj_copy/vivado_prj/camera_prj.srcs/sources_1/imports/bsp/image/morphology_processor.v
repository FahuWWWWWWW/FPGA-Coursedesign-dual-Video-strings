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
wire fifo1_rd_en = data_valid && (pix_cnt >= H_PIXEL);
wire fifo2_wr_en = data_valid && (pix_cnt >= H_PIXEL);
wire fifo2_rd_en = data_valid && (pix_cnt >= H_PIXEL * 2);

assign line1_data = line2_fifo_out;
assign line2_data = line1_fifo_out;
assign line3_data = binary_in;

// 像素计数
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pix_cnt <= 24'd0;
    end else begin
        if (!vsync) begin
            pix_cnt <= 24'd0;
        end else if (data_valid) begin
            pix_cnt <= pix_cnt + 1'b1;
        end
    end
end

// 3x3 窗口
reg [7:0] p11, p12, p13;
reg [7:0] p21, p22, p23;
reg [7:0] p31, p32, p33;

// 形态学运算
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
    end else if (data_valid) begin
        // 移位窗口
        {p13, p12, p11} <= {p12, p11, line1_data};
        {p23, p22, p21} <= {p22, p21, line2_data};
        {p33, p32, p31} <= {p32, p31, line3_data};
        
        // 形态学处理
        if (pix_cnt >= H_PIXEL * 2) begin
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

// FIFO 实例
wire [7:0] line1_fifo_out, line2_fifo_out;

line_buffer_fifo #(.DATA_WIDTH(8), .DEPTH(H_PIXEL)) morph_line1_fifo (
    .clk(clk),
    .rst_n(rst_n && vsync),
    .wr_en(fifo1_wr_en),
    .din(line3_data),
    .rd_en(fifo1_rd_en),
    .dout(line1_fifo_out)
);

line_buffer_fifo #(.DATA_WIDTH(8), .DEPTH(H_PIXEL)) morph_line2_fifo (
    .clk(clk),
    .rst_n(rst_n && vsync),
    .wr_en(fifo2_wr_en),
    .din(line2_data),
    .rd_en(fifo2_rd_en),
    .dout(line2_fifo_out)
);

endmodule
