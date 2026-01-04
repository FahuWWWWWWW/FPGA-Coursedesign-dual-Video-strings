`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: image_pixel_processor
// Description: 图像处理顶层模块
// 集成多种图像处理算法: 灰度化、二值化、Sobel边缘检测、形态学处理
//////////////////////////////////////////////////////////////////////////////////

module image_pixel_processor #(
    parameter H_PIXEL = 10'd800,
    parameter V_PIXEL = 10'd480
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        vsync,
    input  wire        data_valid,
    input  wire [15:0] rgb565_in,       // RGB565 输入
    
    // 控制信号
    input  wire [2:0]  algo_mode,       // 算法选择: 
                                        // 000=原始图像
                                        // 001=灰度化
                                        // 010=二值化
                                        // 011=Sobel边缘检测
                                        // 100=腐蚀
                                        // 101=膨胀
    input  wire [7:0]  threshold,       // 二值化阈值 (默认128)
    
    // 输出
    output reg         pixel_valid,
    output reg  [15:0] pixel_out        // RGB565 输出
);

//==============================================================================
// 内部信号
//==============================================================================

// 灰度化模块
wire       gray_valid;
wire [7:0] gray_data;

// 二值化模块
wire       binary_valid;
wire [7:0] binary_data;

// Sobel 模块
wire       sobel_valid;
wire [7:0] sobel_data;

// 形态学模块
wire       morph_valid;
wire [7:0] morph_data;

//==============================================================================
// 模块实例化
//==============================================================================

// 1. 灰度化
rgb_to_gray u_rgb_to_gray (
    .clk        (clk),
    .rst_n      (rst_n),
    .data_valid (data_valid),
    .rgb565_in  (rgb565_in),
    .gray_valid (gray_valid),
    .gray_out   (gray_data)
);

// 2. 二值化
binary_threshold u_binary_threshold (
    .clk          (clk),
    .rst_n        (rst_n),
    .data_valid   (gray_valid),
    .gray_in      (gray_data),
    .threshold    (threshold),
    .binary_valid (binary_valid),
    .binary_out   (binary_data)
);

// 3. Sobel 边缘检测
sobel_edge_detector #(
    .H_PIXEL (H_PIXEL),
    .V_PIXEL (V_PIXEL)
) u_sobel (
    .clk         (clk),
    .rst_n       (rst_n),
    .vsync       (vsync),
    .data_valid  (gray_valid),
    .gray_in     (gray_data),
    .sobel_valid (sobel_valid),
    .sobel_out   (sobel_data)
);

// 4. 形态学处理 (腐蚀/膨胀)
morphology_processor #(
    .H_PIXEL (H_PIXEL),
    .V_PIXEL (V_PIXEL)
) u_morphology (
    .clk         (clk),
    .rst_n       (rst_n),
    .vsync       (vsync),
    .data_valid  (binary_valid),
    .binary_in   (binary_data),
    .mode        (algo_mode[0]),  // 0=腐蚀, 1=膨胀
    .morph_valid (morph_valid),
    .morph_out   (morph_data)
);

//==============================================================================
// 输出选择逻辑
//==============================================================================

// 灰度/二值/边缘 转 RGB565 (灰度值作为 R=G=B)
function [15:0] gray_to_rgb565;
    input [7:0] gray;
    begin
        gray_to_rgb565 = {gray[7:3], gray[7:2], gray[7:3]};
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_out <= 16'd0;
        pixel_valid <= 1'b0;
    end else begin
        case (algo_mode)
            3'b000: begin  // 原始图像
                pixel_out <= rgb565_in;
                pixel_valid <= data_valid;
            end
            3'b001: begin  // 灰度化
                pixel_out <= gray_to_rgb565(gray_data);
                pixel_valid <= gray_valid;
            end
            3'b010: begin  // 二值化
                pixel_out <= gray_to_rgb565(binary_data);
                pixel_valid <= binary_valid;
            end
            3'b011: begin  // Sobel 边缘检测
                pixel_out <= gray_to_rgb565(sobel_data);
                pixel_valid <= sobel_valid;
            end
            3'b100: begin  // 腐蚀
                pixel_out <= gray_to_rgb565(morph_data);
                pixel_valid <= morph_valid;
            end
            3'b101: begin  // 膨胀
                pixel_out <= gray_to_rgb565(morph_data);
                pixel_valid <= morph_valid;
            end
            default: begin  // 默认原始图像
                pixel_out <= rgb565_in;
                pixel_valid <= data_valid;
            end
        endcase
    end
end

endmodule
