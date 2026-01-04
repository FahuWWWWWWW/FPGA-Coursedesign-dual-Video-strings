`timescale 1ns/1ns

module tb_top_scope_lcd();

    //==========================================================================
    // 1. 信号定义
    //==========================================================================
    reg             sys_clk;
    reg             sys_rst_n;
    reg     [7:0]   ad_data;    // 模拟ADC输入
    reg             key_start;  // 暂停/开始按键

    // LCD 输出信号
    wire    [15:0]  rgb_tft;
    wire            hsync;
    wire            vsync;
    wire            tft_clk;
    wire            tft_de;
    wire            tft_bl;
    wire            ad_clk;     // FPGA输出给ADC的时钟

    // 辅助变量：用于生成正弦波
    real            PI = 3.1415926;
    real            sin_val;
    integer         angle_cnt;
    integer         frame_cnt;

    //==========================================================================
    // 2. 模块实例化 (DUT)
    //==========================================================================
    top_scope_lcd uut (
        .sys_clk    (sys_clk),
        .sys_rst_n  (sys_rst_n),
        .ad_data    (ad_data),
        .key_start  (key_start),
        
        .ad_clk     (ad_clk),
        .rgb_tft    (rgb_tft),
        .hsync      (hsync),
        .vsync      (vsync),
        .tft_clk    (tft_clk),
        .tft_de     (tft_de),
        .tft_bl     (tft_bl)
    );

    //==========================================================================
    // 3. 参数重载 (关键：加速仿真)
    //==========================================================================
    // 修改内部参数，缩短等待时间
    
    // 3.1 加速 ADC 校准 (原1024次 -> 改为 64次)
    // 这样仿真开始后很快就能完成零点校准
    defparam uut.adc_inst.CNT_DATA_MAX = 11'd64;

    // 3.2 加速频率计测量周期 (原1秒 -> 改为 4000个时钟周期)
    // 这样频率数值能快速更新
    defparam uut.freq_meter_inst.CNT_1S_MAX = 26'd4000;

    //==========================================================================
    // 4. 时钟与复位生成
    //==========================================================================
    initial begin
        sys_clk = 0;
        forever #10 sys_clk = ~sys_clk; // 50MHz (周期20ns)
    end

    initial begin
        sys_rst_n = 0;
        key_start = 1; // 按键未按下(高电平)
        frame_cnt = 0;
        #200;
        sys_rst_n = 1; // 释放复位
        $display("System Reset Released at %t", $time);
    end

    //==========================================================================
    // 5. 模拟 ADC 信号输入 (正弦波发生器)
    //==========================================================================
    // 在 FPGA 输出的 ad_clk 下降沿更新数据，模拟真实 ADC 芯片行为
    always @(negedge ad_clk) begin
        if(!sys_rst_n) begin
            ad_data   <= 8'd128; // 复位输出中点
            angle_cnt <= 0;
        end
        // 阶段1: 等待 ADC 模块内部完成校准 (median_en 为 0 时)
        // 此时必须输入稳定的 0V (即数字量128)，否则校准会出错
        else if (uut.adc_inst.median_en == 1'b0) begin
            ad_data   <= 8'd128; 
            angle_cnt <= 0;
        end
        // 阶段2: 校准完成，开始输出正弦波
        else begin
            // 产生一个幅度为 100 的正弦波 (范围 28~228)
            // 调整分母可以改变正弦波的频率
            sin_val = $sin(angle_cnt * 2 * PI / 200.0); 
            ad_data <= 128 + integer(sin_val * 100.0);
            
            angle_cnt <= angle_cnt + 1;
        end
    end

    //==========================================================================
    // 6. 监控与流程控制
    //==========================================================================
    
    // 监控帧同步信号，打印帧数
    always @(negedge vsync) begin
        if(sys_rst_n) begin
            frame_cnt = frame_cnt + 1;
            $display("Time: %t | Frame %d Finished | Current Volt: %d mV | Freq: %d Hz", 
                     $time, frame_cnt, uut.volt_val, uut.freq_val);
        end
    end

    initial begin
        // 1. 等待复位
        #500;
        
        // 2. 监测 ADC 校准状态
        wait(uut.adc_inst.median_en == 1'b1);
        $display("Time: %t | ADC Auto-Calibration Done.", $time);
        
        // 3. 运行一段时间，让波形 RAM 填满数据
        // 由于仿真 LCD 非常慢 (一帧约 16ms = 16,000,000ns)，
        // 我们这里只跑 2 帧左右，足以在波形窗口看到 HSYNC, VSYNC 和 RGB 数据变化
        
        // 这里的延时取决于你的电脑性能和仿真器，
        // 跑完一帧 (800x480) 大约需要 34ms 的仿真时间。
        // 如果只是看波形逻辑，不需要跑完一整帧。
        
        #500_000; // 跑 500us，足够看几十行扫描线
        
        $display("Time: %t | Simulation Paused via Key logic test...", $time);
        // 模拟按下暂停键
        key_start = 0; 
        #500;
        key_start = 1;
        
        #200_000;
        
        $display("End of simplified simulation. Please view waveform.");
        $stop;
    end

endmodule