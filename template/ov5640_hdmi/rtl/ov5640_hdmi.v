//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ov5640_hdmi
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        OV5640摄像头HDMI显示
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ov5640_hdmi #
(
	parameter SDR_BA_WIDTH           = 2  ,
	parameter SDR_ROW_WIDTH          = 11  ,
	parameter SDR_COL_WIDTH          = 8  ,	
	parameter MEM_DATA_BITS          = 16  ,        //external memory user interface data width
	parameter ADDR_BITS              = 19  ,        //external memory user interface address width
	parameter BUSRT_BITS             = 10  ,        //external memory user interface burst width
	parameter BURST_SIZE             = 128         //burst size
)
(    
    input                 sys_clk      ,  //系统时钟
    input                 sys_rst_n    ,  //系统复位，低电平有效
    //摄像头接口                       
    input                 cam_pclk     ,  //cmos 数据像素时钟
    input                 cam_vsync    ,  //cmos 场同步信号
    input                 cam_href     ,  //cmos 行同步信号
    input   [7:0]         cam_data     ,  //cmos 数据
    output                cam_rst_n    ,  //cmos 复位信号，低电平有效
    output                cam_pwdn     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl      ,  //cmos SCCB_SCL线
    inout                 cam_sda      ,  //cmos SCCB_SDA线       
    //SDRAM接口
    output                sdram_clk   ,  //SDRAM 时钟
//    output                sdram_cke   ,  //SDRAM 时钟有效
//    output                sdram_cs_n  ,  //SDRAM 片选
    output                sdram_ras_n ,  //SDRAM 行有效
    output                sdram_cas_n ,  //SDRAM 列有效
    output                sdram_we_n  ,  //SDRAM 写有效
    output       [1:0]    sdram_ba    ,  //SDRAM Bank地址
//    output       [1:0]    sdram_dqm   ,  //SDRAM 数据掩码
    output       [10:0]   sdram_addr  ,  //SDRAM 地址
    inout        [MEM_DATA_BITS - 1:0]   sdram_data  ,  //SDRAM 数据  									                            
    //hdmi接口                           
    output                tmds_clk_p   ,  // TMDS 时钟通道
    output                tmds_clk_n   ,
    output  [2:0]         tmds_data_p  ,  // TMDS 数据通道
    output  [2:0]         tmds_data_n  
    );     

//parameter define                                
parameter  V_CMOS_DISP = 11'd768;                  //CMOS分辨率--行
parameter  H_CMOS_DISP = 11'd1024;                 //CMOS分辨率--列	
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; 
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504;    										   
							   
//wire define                          
wire         clk_50m                   ;  //50mhz时钟,提供给lcd驱动时钟
wire         locked                    ;  //时钟锁定信号
wire         rst_n                     ;  //全局复位 								           
wire         cam_init_done             ;  //摄像头初始化完成							    
wire         wr_en                     ;  //DDR3控制器模块写使能
wire  [15:0] wrdata                    ;  //DDR3控制器模块写数据
wire         rdata_req                 ;  //DDR3控制器模块读使能
wire  [15:0] rddata                    ;  //DDR3控制器模块读数据
wire         rd_vsync                  ;  //输出源更新信号
wire         cmos_frame_valid          ;  //数据有效使能信号
wire                  sdram_init_done ;  //SDRAM初始化完成
wire         sys_init_done             ;  //系统初始化完成(DDR初始化+摄像头初始化)
wire                  clk_100m        ;  //100mhz时钟,SDRAM操作时钟
wire                  clk_100m_shift  ;  //100mhz时钟,SDRAM相位偏移时钟
wire         cmos_frame_vsync          ;  //输出帧有效场同步信号
wire         cmos_frame_href           ;  //输出帧有效行同步信号 
wire  [27:0] app_addr_rd_min           ;  //读DDR3的起始地址
wire  [27:0] app_addr_rd_max           ;  //读DDR3的结束地址
wire  [7:0]  rd_bust_len               ;  //从DDR3中读数据时的突发长度
wire  [27:0] app_addr_wr_min           ;  //写DDR3的起始地址
wire  [27:0] app_addr_wr_max           ;  //写DDR3的结束地址
wire  [7:0]  wr_bust_len               ;  //从DDR3中写数据时的突发长度 

//*****************************************************
//**                    main code
//*****************************************************

//待时钟锁定后产生复位结束信号
assign  rst_n = sys_rst_n & locked;

//系统初始化完成：DDR3初始化完成
assign  sys_init_done = sdram_init_done;

 //ov5640 驱动
ov5640_dri u_ov5640_dri(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk ),
    .cam_vsync         (cam_vsync),
    .cam_href          (cam_href ),
    .cam_data          (cam_data ),
    .cam_rst_n         (cam_rst_n),
    .cam_pwdn          (cam_pwdn ),
    .cam_scl           (cam_scl  ),
    .cam_sda           (cam_sda  ),
    
    .capture_start     (sdram_init_done),
    .cmos_h_pixel      (H_CMOS_DISP),
    .cmos_v_pixel      (V_CMOS_DISP),
    .total_h_pixel     (TOTAL_H_PIXEL),
    .total_v_pixel     (TOTAL_V_PIXEL),
    .cmos_frame_vsync  (cmos_frame_vsync),
    .cmos_frame_href   (),
    .cmos_frame_valid  (cmos_frame_valid),
    .cmos_frame_data   (wrdata)
    );   
                  

//SDRAM 控制器顶层模块,封装成FIFO接口
//SDRAM 控制器地址组成: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top #
(
	.MEM_DATA_BITS  (MEM_DATA_BITS)
)u_sdram_top(
    .ref_clk            (clk_100m),                   //sdram 控制器参考时钟
    .out_clk            (clk_100m_shift),             //用于输出的相位偏移时钟
    .rst_n              (rst_n),                      //系统复位
                                                        
    //用户写端口                                        
    .wr_clk             (cam_pclk),                   //写端口FIFO: 写时钟
    .wr_en              (cmos_frame_valid),                      //写端口FIFO: 写使能
    .wr_data            (wrdata),                    //写端口FIFO: 写数据
    .wr_min_addr        (24'd0),                      //写SDRAM的起始地址
    .wr_max_addr        (H_CMOS_DISP*V_CMOS_DISP),  //写SDRAM的结束地址
    .wr_len             (BURST_SIZE),                    //写SDRAM时的数据突发长度
    .wr_load            (~rst_n),                     //写端口复位: 复位写地址,清空写FIFO
                                                        
    //用户读端口                                        
    .rd_clk             (pixel_clk),                    //读端口FIFO: 读时钟
    .rd_en              (rdata_req),                      //读端口FIFO: 读使能
    .rd_data            (rddata),                    //读端口FIFO: 读数据
    .rd_min_addr        (24'd0),                      //读SDRAM的起始地址
    .rd_max_addr        (H_CMOS_DISP*V_CMOS_DISP),  //读SDRAM的结束地址
    .rd_len             (BURST_SIZE),                    //从SDRAM中读数据时的突发长度
    .rd_load            (~rst_n),                     //读端口复位: 复位读地址,清空读FIFO
                                                
    //用户控制端口                                
    .sdram_read_valid   (1'b1),                       //SDRAM 读使能
    .sdram_pingpang_en  (1'b1),                       //SDRAM 乒乓操作使能
    .sdram_init_done    (sdram_init_done),            //SDRAM 初始化完成标志
                                                
    //SDRAM 芯片接口                                
    .sdram_clk          (sdram_clk),                  //SDRAM 芯片时钟
    .sdram_cke          (),                  //SDRAM 时钟有效
    .sdram_cs_n         (),                 //SDRAM 片选
    .sdram_ras_n        (sdram_ras_n),                //SDRAM 行有效
    .sdram_cas_n        (sdram_cas_n),                //SDRAM 列有效
    .sdram_we_n         (sdram_we_n),                 //SDRAM 写有效
    .sdram_ba           (sdram_ba),                   //SDRAM Bank地址
    .sdram_addr         (sdram_addr),                 //SDRAM 行/列地址
    .sdram_data         (sdram_data),                 //SDRAM 数据
    .sdram_dqm          ()                   //SDRAM 数据掩码
    );

 clk_wiz_0 u_clk_wiz_0
   (
    // Clock out ports
    .clk_out1              (clk_100m),  
    .clk_out2              (clk_100m_shift),  
    .clk_out3              (clk_50m),
    .clk_out4              (pixel_clk_5x),
    .clk_out5              (pixel_clk),
    // Status and control signals
    .reset                 (~sys_rst_n), 
    .locked                (locked),       
   // Clock in ports
    .clk_in1               (sys_clk)
    );     
 
//HDMI驱动显示模块    
hdmi_top u_hdmi_top(
    .pixel_clk            (pixel_clk),
    .pixel_clk_5x         (pixel_clk_5x),    
    .sys_rst_n            (sys_init_done & rst_n),
    //hdmi接口                   
    .tmds_clk_p           (tmds_clk_p   ),   // TMDS 时钟通道
    .tmds_clk_n           (tmds_clk_n   ),
    .tmds_data_p          (tmds_data_p  ),   // TMDS 数据通道
    .tmds_data_n          (tmds_data_n  ),
    //用户接口 
    .video_vs             (rd_vsync     ),   //HDMI场信号  
    .pixel_xpos           (),
    .pixel_ypos           (),      
    .data_in              (rddata),          //数据输入 
    .data_req             (rdata_req)        //请求数据输入   
);   

endmodule