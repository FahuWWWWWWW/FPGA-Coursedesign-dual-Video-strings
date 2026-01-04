//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2022-2032
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           touch_top
// Last modified Date:  2025/12/10
// Last Version:        V3.1
// Descriptions:        LCD触摸顶层模块 - 适配重构版touch_event
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2022/04/22
// Version:             V3.1
// Descriptions:        适配重构后的touch_event模块
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module touch_top(
    input             clk          ,
    input             rst_n        ,
    //LCD触摸相关信号              
    output            touch_rst_n  , //触摸屏复位
    input             touch_int_in , //INT输入信号
    output            touch_int_dir, //INT方向控制信号
    output            touch_int_out, //INT输出信号    
    output            touch_scl    , //I2C的SCL时钟信号
    input             touch_sda_in , //I2C的SDA输入信号
    output            touch_sda_out, //I2C的SDA输出信号
    output            touch_sda_dir, //I2C的SDA方向控制   
    //用户端口
    input     [15:0]  lcd_id       , //LCD ID
    output            touch_valid  , //触摸标志（来自touch_dri）
    output    [15:0]  tp_x_coord   , //X方向触摸点的坐标
    output    [15:0]  tp_y_coord   , //Y方向触摸点的坐标
    
    // 手势识别输出（重构版）
    output            single_click , // 单击事件
    output            double_click , // 双击事件
    output            long_press   , // 长按事件
    output    [15:0]  gesture_x    , // 手势识别坐标X
    output    [15:0]  gesture_y      // 手势识别坐标Y
);

//参数定义
parameter CLK_FREQ     = 50_000_000   ;  //i2c_dri模块的驱动时钟频率
parameter I2C_FREQ     = 250_000      ;  //I2C的SCL时钟频率
parameter REG_NUM_WID  = 8            ;  //一次读写寄存器的个数的位宽

//wire define                        
wire  [6:0]             slave_addr;  //器件地址
wire                    i2c_exec  ;  //I2C触发执行信号
wire                    i2c_rh_wl ;  //I2C读写控制信号
wire  [15:0]            i2c_addr  ;  //I2C器件内地址
wire  [7:0]             i2c_data_w;  //I2C要写的数据
wire                    bit_ctrl  ;  //字地址位控制(0:8b,1:16b)
wire  [REG_NUM_WID-1:0] reg_num   ;  //一次读写寄存器的个数  
wire  [7:0]             i2c_data_r;  //I2C读出的数据
wire                    i2c_done  ;  //I2C操作完成
wire                    once_done ;  //一次读写操作完成
wire                    i2c_ack   ;  //应答标志
wire                    dri_clk   ;  //I2C驱动时钟

//*****************************************************
//**                    main code
//*****************************************************

//I2C驱动模块
i2c_dri_m  #(
    .CLK_FREQ      (CLK_FREQ),       
    .I2C_FREQ      (I2C_FREQ),       
    .WIDTH         (REG_NUM_WID)     
    )                             
    u_i2c_dri_m(   
    .clk           (clk          ),  
    .rst_n         (rst_n        ),  
    .slave_addr    (slave_addr   ),  
    .i2c_exec      (i2c_exec     ),  
    .i2c_rh_wl     (i2c_rh_wl    ),  
    .i2c_addr      (i2c_addr     ),  
    .i2c_data_w    (i2c_data_w   ),  
    .bit_ctrl      (bit_ctrl     ),  
    .reg_num       (reg_num      ),          
    .i2c_data_r    (i2c_data_r   ),  
    .i2c_done      (i2c_done     ),  
    .once_done     (once_done    ),  
    .scl           (touch_scl    ),  
    .sda_in        (touch_sda_in ),  
    .sda_out       (touch_sda_out),  
    .sda_dir       (touch_sda_dir),  
    .ack           (i2c_ack      ),  
    .dri_clk       (dri_clk      )   
    );

//触摸驱动模块（原版，输出touch_valid/坐标）
touch_dri  #(
    .WIDTH   (REG_NUM_WID)  
     )
    u_touch_dri(
    .clk           (dri_clk       ),  
    .rst_n         (rst_n         ),  
    .slave_addr    (slave_addr    ),  
    .i2c_exec      (i2c_exec      ),  
    .i2c_rh_wl     (i2c_rh_wl     ),  
    .i2c_addr      (i2c_addr      ),  
    .i2c_data_w    (i2c_data_w    ),  
    .bit_ctrl      (bit_ctrl      ),  
    .reg_num       (reg_num       ),  
    .i2c_data_r    (i2c_data_r    ),  
    .i2c_ack       (i2c_ack       ),  
    .i2c_done      (i2c_done      ),  
    .once_done     (once_done     ),  
    .lcd_id        (lcd_id        ),  
    .touch_valid   (touch_valid   ),  // 直接输出到顶层
    .tp_x_coord    (tp_x_coord    ),  // 直接输出到顶层
    .tp_y_coord    (tp_y_coord    ),  // 直接输出到顶层
    .touch_rst_n   (touch_rst_n   ),  
    .touch_int_in  (touch_int_in  ),  
    .touch_int_dir (touch_int_dir ),  
    .touch_int_out (touch_int_out )   
    );

// 重构版触摸手势识别模块
touch_event #(
   .CLK_FREQ          (CLK_FREQ),           
   .SINGLE_CLICK_DELAY(1_000_000),         // 修改为60ms单击判定，避免误触发
   .DOUBLE_CLICK_WINDOW(10_000_000),       // 100ms双击窗口
   .LONG_PRESS_THRESH (25_000_000),         // 500ms长按阈值
   .COORD_OFFSET      (30)           // 双击坐标偏差阈值
) u_touch_event (
   .clk           (clk           ),  
   .rst_n         (rst_n         ),  
   .touch_valid   (touch_valid   ),  // 直接接入touch_dri的输出
   .tp_x_coord    (tp_x_coord    ),  // 直接接入touch_dri的输出
   .tp_y_coord    (tp_y_coord    ),  // 直接接入touch_dri的输出
   .single_click  (single_click  ),  // 单击事件
   .double_click  (double_click  ),  // 双击事件
   .long_press    (long_press    ),  // 长按事件
   .current_x     (gesture_x     ),  // 手势坐标X
   .current_y     (gesture_y     ),  // 手势坐标Y
   .gesture_state (              ),  // 调试端口（可选）
   .gesture_busy  (              )   // 忙状态（可选）
);

endmodule