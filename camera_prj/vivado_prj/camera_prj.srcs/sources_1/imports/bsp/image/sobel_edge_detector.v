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
    input  wire [12:0] h_pixel,         // 动态行宽输入
    input  wire [7:0]  gray_in,         // 灰度输入
    output reg         sobel_valid,
    output reg  [7:0]  sobel_out        // 边缘强度输出
);

// 行缓存
reg [23:0] pix_cnt;
wire [7:0] line1_data, line2_data, line3_data;

// FIFO 控制信号
wire fifo1_wr_en = data_valid;
wire fifo1_rd_en = data_valid && (pix_cnt >= h_pixel);
wire fifo2_wr_en = data_valid && (pix_cnt >= h_pixel);
wire fifo2_rd_en = data_valid && (pix_cnt >= {h_pixel, 1'b0}); // h_pixel * 2

assign line1_data = line2_fifo_out;
assign line2_data = line1_fifo_out;
assign line3_data = gray_in; // FIFO 写入仍使用原始数据 (无延迟)

// 像素计数器和 FIFO 复位控制
reg cam_vsync_d;
reg fifo_rst;
reg [4:0] rst_cnt; // 复位计数器

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pix_cnt <= 24'd0;
        cam_vsync_d <= 1'b0;
        fifo_rst <= 1'b1;
        rst_cnt <= 5'd0;
    end else begin
        cam_vsync_d <= vsync;
        
        // vsync 上升沿产生宽复位脉冲 (避免复位不完全)
        if (vsync && !cam_vsync_d) begin
            rst_cnt <= 5'd31; // 复位持续 32 个周期
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

// 延迟匹配逻辑 (适配标准FIFO的1周期读延迟)
reg [7:0] gray_in_d1;
reg data_valid_d1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray_in_d1 <= 8'd0;
        data_valid_d1 <= 1'b0;
    end else begin
        gray_in_d1 <= gray_in;
        data_valid_d1 <= data_valid;
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
    end else if (data_valid_d1) begin // 使用延迟后的有效信号
        // 移位窗口 (使用延迟后的输入和FIFO输出)
        // 注意：line1_fifo_out 和 line2_fifo_out 已经是延迟后的数据(FIFO特性)
        // gray_in_d1 是手动延迟的输入，三者现在对齐了
        {p13, p12, p11} <= {p12, p11, line1_data}; // line1_data = line2_fifo_out
        {p23, p22, p21} <= {p22, p21, line2_data}; // line2_data = line1_fifo_out
        {p33, p32, p31} <= {p32, p31, gray_in_d1}; // 使用延迟后的输入
        
        // Sobel 卷积
        // Gx = [-1  0  1]     Gy = [-1 -2 -1]
        //      [-2  0  2]          [ 0  0  0]
        //      [-1  0  1]          [ 1  2  1]
        gx <= (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);
        gy <= (p11 + (p12 << 1) + p13) - (p31 + (p32 << 1) + p33);
        
        // 输出边缘强度 (限幅到 255)
        sobel_out <= (pix_cnt >= {h_pixel, 1'b0}) ? 
                     ((gradient > 14'd255) ? 8'd255 : gradient[7:0]) : 8'd0;
        sobel_valid <= (pix_cnt >= {h_pixel, 1'b0});
    end else begin
        sobel_valid <= 1'b0;
    end
end

// FIFO 实例 (行缓存) - 使用 Xilinx IP 核
wire [7:0] line1_fifo_out, line2_fifo_out;

fifo_generator_1 sobel_line1_fifo (
    .clk(clk),              // input wire clk
    .srst(~rst_n | fifo_rst), // input wire srst (系统复位或帧复位)
    .din(line3_data),       // input wire [7:0] din
    .wr_en(fifo1_wr_en),    // input wire wr_en
    .rd_en(fifo1_rd_en),    // input wire rd_en
    .dout(line1_fifo_out),  // output wire [7:0] dout
    .full(),                // output wire full
    .empty()                // output wire empty
);

fifo_generator_1 sobel_line2_fifo (
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
