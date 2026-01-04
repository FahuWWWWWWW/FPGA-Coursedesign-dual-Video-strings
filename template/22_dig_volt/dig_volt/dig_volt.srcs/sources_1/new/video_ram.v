module video_ram
(
    input   wire            wr_clk,
    input   wire            wr_en,
    input   wire    [9:0]   wr_addr,
    input   wire    [7:0]   wr_data,
    
    input   wire            rd_clk,
    input   wire    [9:0]   rd_addr,
    output  reg     [7:0]   rd_data
);

// 定义 1024 深度，8位宽的 RAM
reg [7:0] mem [0:1023];

// 写端口
always @(posedge wr_clk) begin
    if(wr_en)
        mem[wr_addr] <= wr_data;
end

// 读端口
always @(posedge rd_clk) begin
    rd_data <= mem[rd_addr];
end

endmodule