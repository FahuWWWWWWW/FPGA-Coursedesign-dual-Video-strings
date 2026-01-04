module freq_meter
(
    input   wire            sys_clk     , // 50MHz
    input   wire            sys_rst_n   ,
    input   wire            sign        , // 来自ADC模块的符号位（方波）
    
    output  reg     [19:0]  freq_out      // 计算出的频率值(Hz)
);

// 参数定义
parameter   CNT_1S_MAX = 26'd49_999_999; // 1秒闸门时间

reg [25:0]  cnt_gate;     // 闸门计数器
reg [19:0]  cnt_freq;     // 频率脉冲计数器
reg         sign_reg;     // 信号打拍

wire        sign_posedge; // 符号位上升沿检测

// 边沿检测
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        sign_reg <= 1'b0;
    else
        sign_reg <= sign;
end
assign sign_posedge = sign & (~sign_reg);

// 频率计数逻辑
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        cnt_gate <= 26'd0;
        cnt_freq <= 20'd0;
        freq_out <= 20'd0;
    end else begin
        if(cnt_gate == CNT_1S_MAX) begin
            // 闸门时间到，更新输出，清空计数
            freq_out <= cnt_freq;
            cnt_freq <= 20'd0;
            cnt_gate <= 26'd0;
        end else begin
            cnt_gate <= cnt_gate + 1'b1;
            if(sign_posedge) // 检测到一次信号周期
                cnt_freq <= cnt_freq + 1'b1;
        end
    end
end

endmodule