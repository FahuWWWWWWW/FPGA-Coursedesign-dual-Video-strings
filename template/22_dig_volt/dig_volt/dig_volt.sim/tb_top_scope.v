`timescale 1ns/1ns

module tb_top_scope;

    //==========================================================================
    // 1. 信号定义
    //==========================================================================
    reg             sys_clk;
    reg             sys_rst_n;
    reg     [7:0]   ad_data;    // 模拟ADC输入
    reg             key_start;  // 按键1
    reg             key_mode;   // 按键2

    wire            ad_clk;     // 输出给ADC的时钟
    wire    [5:0]   sel;        // 数码管位选
    wire    [7:0]   seg;        // 数码管段选

    // 辅助变量：用于生成三角波
    reg             dir;        // 0: 计数增加, 1: 计数减少
    
    //==========================================================================
    // 2. 模块实例化 (DUT - Device Under Test)
    //==========================================================================
    top_scope uut (
        .sys_clk    (sys_clk),
        .sys_rst_n  (sys_rst_n),
        .ad_data    (ad_data),
        .key_start  (key_start),
        .key_mode   (key_mode),
        .ad_clk     (ad_clk),
        .sel        (sel),
        .seg        (seg)
    );

    //==========================================================================
    // 3. 参数重写 (为了让仿真跑得快，必须修改这些计数器)
    //==========================================================================
    // 注意：这里的路径必须和你的模块实例化名称一致
    
    // 缩短按键消抖时间 (原20ms -> 改为4个时钟周期)
    defparam uut.key_start_inst.CNT_MAX = 20'd4;
    defparam uut.key_mode_inst.CNT_MAX  = 20'd4;
    
    // 缩短ADC校准时间 (原1024次 -> 改为64次)
    defparam uut.adc_inst.CNT_DATA_MAX  = 11'd64;

    // 缩短峰值检测刷新时间 (原0.3秒 -> 改为2000个时钟)
    defparam uut.CNT_PEAK_MAX           = 25'd2000;
    
    // 缩短频率计闸门时间 (原1秒 -> 改为4000个时钟)
    defparam uut.freq_meter_inst.CNT_1S_MAX = 26'd4000;

    //==========================================================================
    // 4. 时钟生成 (50MHz)
    //==========================================================================
    initial begin
        sys_clk = 0;
        forever #10 sys_clk = ~sys_clk; // 20ns周期
    end

    //==========================================================================
    // 5. 数据发生器：产生三角波 (模拟变化的电压)
    //==========================================================================
    // 逻辑：在 ad_clk 的下降沿更新数据，模拟 ADC 芯片行为
    always @(negedge ad_clk or negedge sys_rst_n) begin
        if(!sys_rst_n) begin
            ad_data <= 8'd128; // 复位输出中值
            dir     <= 0;
        end 
        else if (uut.adc_inst.median_en == 1'b0) begin
            // 校准期间，保持稳定的中值输入 (模拟0V)
            ad_data <= 8'd128;
        end
        else begin
            // 校准完成后，生成三角波 (0 -> 255 -> 0)
            if(dir == 0) begin
                if(ad_data >= 8'd254) dir <= 1;
                else ad_data <= ad_data + 1;
            end else begin
                if(ad_data <= 8'd1)   dir <= 0;
                else ad_data <= ad_data - 1;
            end
        end
    end

    //==========================================================================
    // 6. 测试流程 (主线剧情)
    //==========================================================================
    initial begin
        // --- 初始化 ---
        sys_rst_n = 0;
        key_start = 1; // 按键未按下(高电平)
        key_mode  = 1;
        $display("--------------------------------------------------");
        $display("Simulation Start: System Reset");
        $display("--------------------------------------------------");

        // --- 释放复位 ---
        #200;
        sys_rst_n = 1;
        
        // --- 等待 ADC 自动校准完成 ---
        $display("Status: Waiting for ADC Auto-Calibration...");
        wait(uut.adc_inst.median_en == 1'b1);
        $display("Status: ADC Calibration Done! Zero-point set at %d", uut.adc_inst.data_median);
        
        // --- 此时虽然有波形输入，但系统处于PAUSE状态，数码管应显示0或不更新 ---
        #1000;

        // --- 动作1：按下开始键 (Start) ---
        $display("Action: Pressing START Key...");
        key_start = 0; #100; // 按下
        key_start = 1; #100; // 释放
        
        // --- 运行一段时间，观察峰值保持 ---
        // 输入是三角波(0~255)，峰值应该被捕捉并显示
        $display("Status: System Running... Monitoring Peak Voltage...");
        #60000; 

        // --- 动作2：按下模式键 (Mode Switch) ---
        $display("Action: Pressing MODE Key (Switch to Frequency)...");
        key_mode = 0; #100;
        key_mode = 1; #100;

        // --- 运行一段时间，观察频率显示 ---
        $display("Status: Mode Switched. Measuring Frequency...");
        #60000;

        // --- 结束仿真 ---
        $display("--------------------------------------------------");
        $display("Simulation Finished.");
        $display("--------------------------------------------------");
        $stop; 
    end

    //==========================================================================
    // 7. 实时监控打印 (Debug helper)
    //==========================================================================
    // 每隔 5000ns 打印一次关键状态，防止你盯着空白屏幕发呆
    always begin
        #5000;
        if($time > 200) begin
            $display("Time: %t | State: %s | ADC_Raw: %d | Volt_Inst: %d mV | Disp_Peak: %d mV | Freq: %d Hz", 
                     $time, 
                     (uut.run_state ? "RUN " : "STOP"), 
                     ad_data, 
                     uut.volt_inst, 
                     uut.volt_display,
                     uut.freq_val);
        end
    end

endmodule