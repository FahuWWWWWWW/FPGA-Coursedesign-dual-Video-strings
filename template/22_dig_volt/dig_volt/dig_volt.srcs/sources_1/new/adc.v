`timescale  1ns/1ns

module  adc
(
    input   wire            sys_clk     ,   // 系统时钟 50MHz
    input   wire            sys_rst_n   ,   
    input   wire    [7:0]   ad_data     ,   // AD数据
    input   wire            cal_flag    ,   // 【新增】校准触发信号(脉冲)

    output  wire            ad_clk      ,   // AD时钟
    output  wire            sign        ,   // 符号位(带迟滞)
    output  wire    [15:0]  volt            // 电压值(mV)
);

//-------------------------------------------------------
// 参数与信号定义
//-------------------------------------------------------
parameter   CNT_DATA_MAX = 11'd1024;    
parameter   HYSTERESIS   = 8'd6;        // 【新增】迟滞阈值，过滤噪声

wire    [27:0]  data_p;   
wire    [27:0]  data_n;   

reg             median_en;      // 中值校准完成标志
reg     [10:0]  cnt_median;     // 校准计数器
reg     [18:0]  data_sum_m;     // 累加和
reg     [7:0]   data_median;    // 零点(中值)
reg     [1:0]   cnt_sys_clk;    
reg             clk_sample;     
reg     [27:0]  volt_reg;       
reg             sign_r;         // 符号位寄存器

//-------------------------------------------------------
// 逻辑实现
//-------------------------------------------------------

assign  ad_clk = ~clk_sample;

// 【重点修改】带迟滞的符号位生成，解决频率乱跳
always @(posedge clk_sample or negedge sys_rst_n) begin
    if(!sys_rst_n)
        sign_r <= 1'b0;
    else if(median_en) begin
        // 只有当信号 明显大于 (中值+阈值) 才变0
        if(ad_data > (data_median + HYSTERESIS))
            sign_r <= 1'b0;
        // 只有当信号 明显小于 (中值-阈值) 才变1
        else if(ad_data < (data_median - HYSTERESIS))
            sign_r <= 1'b1;
        // 中间区域保持原状态
    end
end
assign sign = sign_r;

// 时钟分频 (12.5MHz)
always@(posedge sys_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0) begin
        cnt_sys_clk <= 2'd0;
        clk_sample  <= 1'b0;
    end else begin
        cnt_sys_clk <= cnt_sys_clk + 1'b1;
        if(cnt_sys_clk == 2'd1) begin
            cnt_sys_clk <= 2'd0;
            clk_sample  <= ~clk_sample;
        end
    end
end

// 【重点修改】中值使能信号 (支持按键重新校准)
always@(posedge clk_sample or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        median_en <= 1'b0;
    else if(cal_flag == 1'b1) // 检测到校准按键，强制重新开始
        median_en <= 1'b0;
    else if(cnt_median == CNT_DATA_MAX)
        median_en <= 1'b1;
end

// 中值累加计数器
always@(posedge clk_sample or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        cnt_median <= 11'd0;
    else if(cal_flag == 1'b1) // 重置
        cnt_median <= 11'd0;
    else if(median_en == 1'b0)
        cnt_median <= cnt_median + 1'b1;
end

// 累加求和
always@(posedge clk_sample or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        data_sum_m <= 19'd0;
    else if(cal_flag == 1'b1) // 重置
        data_sum_m <= 19'd0;
    else if(cnt_median == CNT_DATA_MAX)
        data_sum_m <= 19'd0;
    else if(median_en == 1'b0)
        data_sum_m <= data_sum_m + ad_data;
end

// 计算中值
always@(posedge clk_sample or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        data_median <= 8'd128; // 默认给中间值
    else if(cnt_median == CNT_DATA_MAX)
        data_median <= data_sum_m / CNT_DATA_MAX;
end

// 计算电压系数 (如果发现幅值比例不对，修改这里的 8192_0000)
assign  data_p = (median_en == 1'b1) ? 8192_0000 / ((255 - data_median) * 2) : 0;
assign  data_n = (median_en == 1'b1) ? 8192_0000 / ((data_median + 1) * 2) : 0;

// 电压计算
always@(posedge clk_sample or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        volt_reg <= 'd0;
    else if(median_en == 1'b1) begin
        // 死区处理：如果输入非常接近零点，直接显示0
        if((ad_data >= (data_median - 2)) && (ad_data <= (data_median + 2)))
            volt_reg <= 'd0;
        else if(ad_data < data_median)
            volt_reg <= (data_n * (data_median - ad_data)) >> 13;
        else
            volt_reg <= (data_p * (ad_data - data_median)) >> 13;
    end else
        volt_reg <= 'd0;
end

assign volt = volt_reg[15:0];

endmodule