`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: sobel_edge_detector
// Description: Sobel 边缘检测算法
// 使用 3x3 卷积核检测图像边缘
//////////////////////////////////////////////////////////////////////////////////

module sobel_edge_detector #(
    parameter H_PIXEL = 10'd800,
    parameter V_PIXEL = 10'd480
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        vsync,           // 场同步信号
    input  wire        data_valid,
    input  wire [7:0]  gray_in,         // 灰度输入
    output reg         sobel_valid,
    output reg  [7:0]  sobel_out        // 边缘强度输出
);

// 行缓存
reg [23:0] pix_cnt;
wire [7:0] line1_data, line2_data, line3_data;

// FIFO 控制信号
wire fifo1_wr_en = data_valid;
wire fifo1_rd_en = data_valid && (pix_cnt >= H_PIXEL);
wire fifo2_wr_en = data_valid && (pix_cnt >= H_PIXEL);
wire fifo2_rd_en = data_valid && (pix_cnt >= H_PIXEL * 2);

assign line1_data = line2_fifo_out;
assign line2_data = line1_fifo_out;
assign line3_data = gray_in;

// 像素计数器
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

// 3x3 窗口寄存器
reg [7:0] p11, p12, p13;
reg [7:0] p21, p22, p23;
reg [7:0] p31, p32, p33;

// Sobel 算子
reg signed [12:0] gx, gy;
wire [12:0] gx_abs = gx[12] ? (~gx + 1'b1) : gx;
wire [12:0] gy_abs = gy[12] ? (~gy + 1'b1) : gy;
wire [13:0] gradient = gx_abs + gy_abs;

// 移位寄存器和 Sobel 计算
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {p11, p12, p13} <= 24'd0;
        {p21, p22, p23} <= 24'd0;
        {p31, p32, p33} <= 24'd0;
        gx <= 13'd0;
        gy <= 13'd0;
        sobel_out <= 8'd0;
        sobel_valid <= 1'b0;
    end else if (data_valid) begin
        // 移位窗口
        {p13, p12, p11} <= {p12, p11, line1_data};
        {p23, p22, p21} <= {p22, p21, line2_data};
        {p33, p32, p31} <= {p32, p31, line3_data};
        
        // Sobel 卷积
        // Gx = [-1  0  1]     Gy = [-1 -2 -1]
        //      [-2  0  2]          [ 0  0  0]
        //      [-1  0  1]          [ 1  2  1]
        gx <= (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);
        gy <= (p11 + (p12 << 1) + p13) - (p31 + (p32 << 1) + p33);
        
        // 输出边缘强度 (限幅到 255)
        sobel_out <= (pix_cnt >= H_PIXEL * 2) ? 
                     ((gradient > 14'd255) ? 8'd255 : gradient[7:0]) : 8'd0;
        sobel_valid <= (pix_cnt >= H_PIXEL * 2);
    end else begin
        sobel_valid <= 1'b0;
    end
end

// FIFO 实例 (行缓存)
wire [7:0] line1_fifo_out, line2_fifo_out;

line_buffer_fifo #(.DATA_WIDTH(8), .DEPTH(H_PIXEL)) line1_fifo (
    .clk(clk),
    .rst_n(rst_n && vsync),
    .wr_en(fifo1_wr_en),
    .din(line3_data),
    .rd_en(fifo1_rd_en),
    .dout(line1_fifo_out)
);

line_buffer_fifo #(.DATA_WIDTH(8), .DEPTH(H_PIXEL)) line2_fifo (
    .clk(clk),
    .rst_n(rst_n && vsync),
    .wr_en(fifo2_wr_en),
    .din(line2_data),
    .rd_en(fifo2_rd_en),
    .dout(line2_fifo_out)
);

endmodule

// 简化的行缓存 FIFO
module line_buffer_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 800
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] dout
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr <= 'd0;
        rd_ptr <= 'd0;
        dout <= 'd0;
    end else begin
        if (wr_en) begin
            mem[wr_ptr] <= din;
            wr_ptr <= (wr_ptr == DEPTH-1) ? 'd0 : wr_ptr + 1'b1;
        end
        if (rd_en) begin
            dout <= mem[rd_ptr];
            rd_ptr <= (rd_ptr == DEPTH-1) ? 'd0 : rd_ptr + 1'b1;
        end
    end
end

endmodule
