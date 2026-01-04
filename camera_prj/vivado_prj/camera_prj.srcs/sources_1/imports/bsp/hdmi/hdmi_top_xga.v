//****************************************************************************************//
module  hdmi_top_xga(
    input           pixel_clk,
    input           pixel_clk_5x,    
    input           sys_rst_n,
    //hdmi接口 
    output          tmds_clk_p,     // TMDS 时钟通道
    output          tmds_clk_n,
    output [2:0]    tmds_data_p,    // TMDS 数据通道
    output [2:0]    tmds_data_n,
    //用户接口 
    output          video_vs,       //HDMI场信号      
    output  [10:0]  pixel_xpos,     //像素点横坐标
    output  [10:0]  pixel_ypos,     //像素点纵坐标      
    input   [15:0]  data_in,        //输入数据
    output          data_req        //请求数据输入   
);

//wire define
wire          video_hs;
wire          video_de;
wire  [23:0]  video_rgb;
wire  [15:0]  video_rgb_565; // 从driver出来的565数据 (16bit)

//*****************************************************
//**                    main code
//*****************************************************

//例化视频显示驱动模块 (使用修改版 XGA 居中驱动)
video_driver_hdmi u_video_driver(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n),

    .video_hs       (video_hs),
    .video_vs       (video_vs),
    .video_de       (video_de),
    .video_rgb      (video_rgb_565), // 连接到 16bit wire
    .pixel_data     (data_in),       // 输入源数据
     
    .data_req       (data_req),
    .pixel_xpos     (pixel_xpos),
    .pixel_ypos     (pixel_ypos)
    );
       
//例化HDMI驱动模块
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (sys_rst_n),
                
    .video_din      (video_rgb), // 接 24bit
    .video_hsync    (video_hs), 
    .video_vsync    (video_vs),
    .video_de       (video_de), 
                                
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n)
    );

    // 将 16bit RGB565 (带黑色门控) 转换为 24bit RGB888
    assign video_rgb = {video_rgb_565[15:11],3'b000, video_rgb_565[10:5],2'b00, video_rgb_565[4:0],3'b000};


endmodule
