`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           touch_event_simple
// Last modified Date:  2025/12/11
// Last Version:        V1.0
// Descriptions:        简化版触摸手势识别模块 - 专为初学者设计
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module touch_event #(
    parameter CLK_FREQ          = 50_000_000,  // 时钟频率(Hz)
    parameter SINGLE_CLICK_DELAY= 750_000,     // 单击判定延时(15ms@50MHz) - 优化响应速度
    parameter DOUBLE_CLICK_WINDOW= 20_000_000, // 双击检测窗口(400ms@50MHz) - 放宽判定时间
    parameter LONG_PRESS_THRESH = 25_000_000,  // 长按阈值(500ms@50MHz)
    parameter COORD_OFFSET      = 100          // 双击坐标偏差阈值 - 增加容错范围
)(
    input        clk,               // 时钟信号（与touch_dri同频）
    input        rst_n,             // 复位信号(低有效)
    input        touch_valid,       // 触摸有效（按下高/松手低）
    input [15:0] tp_x_coord,        // 触摸X坐标（来自touch_dri）
    input [15:0] tp_y_coord,        // 触摸Y坐标（来自touch_dri）
    
    output reg   single_click,      // 单击事件（单周期脉冲）
    output reg   double_click,      // 双击事件（单周期脉冲）
    output reg   long_press,        // 长按事件（持续高电平）
    output reg [15:0] current_x,    // 当前触摸X坐标（同步touch_dri）
    output reg [15:0] current_y,    // 当前触摸Y坐标（同步touch_dri）
    output reg [3:0]  gesture_state,// 状态编码（调试用）
    output reg        gesture_busy  // 手势识别中
);

// 状态定义（使用易读的名称）
localparam STATE_IDLE          = 4'b0001; // 空闲状态 - 无触摸
localparam STATE_PRESSED       = 4'b0010; // 按下状态 - 触摸被按下
localparam STATE_RELEASED      = 4'b0100; // 释放状态 - 等待双击或确认单击
localparam STATE_LONGPRESS     = 4'b1000; // 长按状态 - 检测到长按

// 内部信号声明
reg [3:0]  state;               // 当前状态
reg [3:0]  next_state;          // 下一状态
reg [31:0] timer_counter;       // 计时器计数器
reg [15:0] first_touch_x;       // 第一次触摸的X坐标
reg [15:0] first_touch_y;       // 第一次触摸的Y坐标
reg [15:0] previous_touch_x;    // 上一次触摸的X坐标（用于双击检测）
reg [15:0] previous_touch_y;    // 上一次触摸的Y坐标（用于双击检测）
reg        timer_reset;         // 计时器复位信号
reg        timer_enable;        // 计时器使能信号
reg [2:0]  touch_sync;          // 触摸信号同步寄存器（用于跨时钟域处理）
reg        touch_pressed_edge;  // 触摸按下边沿检测信号
reg        touch_released_edge; // 触摸释放边沿检测信号

// 1. 触摸信号同步处理（防止亚稳态）
// 作用：将异步的touch_valid信号同步到clk时钟域
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        touch_sync <= 3'b000;
    end else begin
        touch_sync <= {touch_sync[1:0], touch_valid};
    end
end

// 2. 触摸边沿检测
// 作用：检测触摸按下和释放的边沿
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        touch_pressed_edge  <= 1'b0;
        touch_released_edge <= 1'b0;
    end else begin
        // 检测触摸按下边沿（从无触摸到有触摸）
        touch_pressed_edge  <= (touch_sync[2:1] == 2'b01);
        // 检测触摸释放边沿（从有触摸到无触摸）
        touch_released_edge <= (touch_sync[2:1] == 2'b10);
    end
end

// 3. 计时器模块
// 作用：提供精确的时间测量功能
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        timer_counter <= 32'd0;
    end else if(timer_reset) begin
        // 当timer_reset为高时，清零计数器
        timer_counter <= 32'd0;
    end else if(timer_enable) begin
        // 当timer_enable为高时，递增计数器
        timer_counter <= timer_counter + 1'b1;
    end
end

// 4. 坐标存储模块
// 作用：保存触摸坐标信息
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        current_x         <= 16'd0;
        current_y         <= 16'd0;
        first_touch_x     <= 16'd0;
        first_touch_y     <= 16'd0;
        previous_touch_x  <= 16'd0;
        previous_touch_y  <= 16'd0;
    end else begin
        // 实时更新当前坐标
        current_x <= tp_x_coord;
        current_y <= tp_y_coord;
        
        // 在触摸按下时保存第一次触摸坐标
        if(touch_pressed_edge) begin
            first_touch_x <= tp_x_coord;
            first_touch_y <= tp_y_coord;
        end
        
        // 在单击或双击事件发生时保存坐标用于下次比较
        if(single_click || double_click) begin
            previous_touch_x <= first_touch_x;
            previous_touch_y <= first_touch_y;
        end
    end
end

// 5. 状态寄存器
// 作用：保存当前状态
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= STATE_IDLE;
    end else begin
        state <= next_state;
    end
end

// 6. 状态转移逻辑
// 作用：根据当前状态和输入信号决定下一状态
always @(*) begin
    // 默认值设置（防止锁存器推断）
    next_state     = state;
    timer_reset    = 1'b1;  // 默认复位计时器
    timer_enable   = 1'b0;  // 默认禁用计时器
    single_click   = 1'b0;  // 默认无单击事件
    double_click   = 1'b0;  // 默认无双击事件
    gesture_busy   = 1'b0;  // 默认不忙
    
    case(state)
        // 空闲状态：等待触摸按下
        STATE_IDLE: begin
            gesture_busy = 1'b0;  // 不忙
            
            // 如果检测到触摸按下边沿，转移到按下状态
            if(touch_pressed_edge) begin
                next_state   = STATE_PRESSED;
                timer_reset  = 1'b1;  // 复位计时器
            end
        end

        // 按下状态：触摸被按下，正在判断是单击还是长按
        STATE_PRESSED: begin
            gesture_busy = 1'b1;  // 忙碌
            timer_reset  = 1'b0;  // 不复位计时器
            timer_enable = 1'b1;  // 启用计时器，开始计时
            
            // 如果按下时间超过长按阈值，判定为长按
            if(timer_counter >= LONG_PRESS_THRESH) begin
                next_state = STATE_LONGPRESS;
            end
            // 如果检测到触摸释放且按下时间足够长（达到单击阈值），转移到释放状态
            else if(touch_released_edge && timer_counter >= SINGLE_CLICK_DELAY) begin
                next_state   = STATE_RELEASED;
                timer_reset  = 1'b1;  // 复位计时器，准备双击检测计时
            end
            // 如果检测到触摸释放但按下时间太短，判定为无效触摸，回到空闲状态
            else if(touch_released_edge && timer_counter < SINGLE_CLICK_DELAY) begin
                next_state = STATE_IDLE;
            end
        end

        // 释放状态：触摸已释放，等待可能的双击或确认单击
        STATE_RELEASED: begin
            gesture_busy = 1'b1;  // 忙碌
            timer_reset  = 1'b0;  // 不复位计时器
            timer_enable = 1'b1;  // 启用计时器，开始双击窗口计时
            
            // 如果在双击窗口期内再次按下触摸
            if(touch_pressed_edge) begin
                // 检查第二次触摸与第一次触摸的坐标偏差是否在允许范围内
                if((tp_x_coord >= previous_touch_x - COORD_OFFSET && 
                    tp_x_coord <= previous_touch_x + COORD_OFFSET) &&
                   (tp_y_coord >= previous_touch_y - COORD_OFFSET && 
                    tp_y_coord <= previous_touch_y + COORD_OFFSET)) begin
                    // 坐标偏差在允许范围内，判定为双击
                    double_click = 1'b1;  // 产生双击脉冲信号
                    next_state   = STATE_IDLE;  // 回到空闲状态
                end else begin
                    // 坐标偏差超出范围，视为新的触摸操作
                    next_state = STATE_PRESSED;
                end
            end
            // 如果双击窗口期超时，判定为单击
            else if(timer_counter >= DOUBLE_CLICK_WINDOW) begin
                single_click = 1'b1;  // 产生单击脉冲信号
                next_state   = STATE_IDLE;  // 回到空闲状态
            end
        end

        // 长按状态：已确认长按操作
        STATE_LONGPRESS: begin
            gesture_busy = 1'b1;  // 忙碌
            
            // 当触摸释放时，回到空闲状态
            if(touch_released_edge) begin
                next_state   = STATE_IDLE;
                timer_reset  = 1'b1;  // 复位计时器
            end
        end

        // 默认情况：回到空闲状态
        default: next_state = STATE_IDLE;
    endcase
end

// 7. 长按输出信号控制
// 作用：控制long_press信号的输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        long_press <= 1'b0;
    end else if(state == STATE_LONGPRESS) begin
        // 当处于长按状态时，输出高电平
        long_press <= 1'b1;
    end else begin
        // 其他状态下输出低电平
        long_press <= 1'b0;
    end
end

// 8. 调试状态输出
// 作用：输出当前状态用于调试
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        gesture_state <= STATE_IDLE;
    end else begin
        gesture_state <= state;
    end
end

endmodule