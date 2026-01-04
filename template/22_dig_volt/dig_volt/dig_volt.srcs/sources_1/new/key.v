module key_filter
#(
    parameter CNT_MAX = 20'd999_999 // 20ms @ 50MHz
)
(
    input   wire    sys_clk     ,
    input   wire    sys_rst_n   ,
    input   wire    key_in      , // 按键输入（低电平有效）
    
    output  reg     key_flag      // 消抖后的按键脉冲
);

reg [19:0] cnt_20ms;
reg        key_r0, key_r1; // 同步打拍

// 消除亚稳态
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        key_r0 <= 1'b1;
        key_r1 <= 1'b1;
    end else begin
        key_r0 <= key_in;
        key_r1 <= key_r0;
    end
end

// 计数消抖
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        cnt_20ms <= 20'b0;
    else if(key_r1 == 1'b1) // 按键未按下
        cnt_20ms <= 20'b0;
    else if(cnt_20ms < CNT_MAX)
        cnt_20ms <= cnt_20ms + 1'b1;
    else 
        cnt_20ms <= cnt_20ms;
end

// 输出脉冲
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        key_flag <= 1'b0;
    else if(cnt_20ms == CNT_MAX - 1'b1)
        key_flag <= 1'b1;
    else
        key_flag <= 1'b0;
end

endmodule