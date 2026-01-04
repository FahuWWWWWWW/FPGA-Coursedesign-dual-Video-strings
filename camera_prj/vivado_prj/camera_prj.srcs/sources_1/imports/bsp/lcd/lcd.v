module lcd(
    input              clk     ,
    input              rst_n   ,
    //RGB LCD接口 
    output             lcd_hs  ,       //LCD 行同步信号
    output             lcd_vs  ,       //LCD 场同步信号
    output             lcd_de  ,       //LCD 数据输入使能
    inout      [23:0]  lcd_rgb ,       //LCD RGB888颜色数据
    output             lcd_bl  ,       //LCD 背光控制信号
    output             lcd_rst ,       //LCD 复位信号
    output             lcd_pclk,       //LCD 采样时钟
       
    output             clk_lcd,
    input      [15:0]  pixel_data,     //像素点数据(RGB565)
    output             rd_en  ,        //请求像素点颜色数据输入 

    output     [15:0]  ID_lcd,         //LCD的ID
    output             frame_sync      // [NEW] 内部场同步信号
);

//*****************************************************
//**                    main code
//*****************************************************

//RGB565 -> RGB888数据输出
// R565[4:0] -> R888[7:3], G565[5:0] -> G888[7:2], B565[4:0] -> B888[7:3]
assign lcd_rgb = lcd_de ? {pixel_data[15:11], 3'd0, pixel_data[10:5], 2'd0, pixel_data[4:0], 3'd0} : 24'dz;

//读rgb lcd ID 模块
rd_id    u_rd_id(
    .clk          (clk),
    .rst_n        (rst_n),
    
    .lcd_rgb      (lcd_rgb),
    .ID_lcd       (ID_lcd)

);

//分频模块，根据不同的LCD ID输出相应的频率的驱动时钟
clk_div  u_clk_div(
    .clk          (clk),
    .rst_n        (rst_n),
    
    .ID_lcd       (ID_lcd),
    .clk_lcd      (clk_lcd)
);

//lcd驱动模块    
lcd_driver u_lcd_driver(                      
    .lcd_clk        (clk_lcd),    
    .sys_rst_n      (rst_n),    

    .lcd_hs         (lcd_hs),       
    .lcd_vs         (lcd_vs),       
    .lcd_de         (lcd_de),       
    .lcd_bl         (lcd_bl),
    .lcd_rst        (lcd_rst),
    .lcd_pclk       (lcd_pclk),
    
    .data_req       (rd_en),                 //请求像素点颜色数据输入
    .pixel_xpos     (), 
    .pixel_ypos     (),

    .frame_sync     (frame_sync),             // [NEW]
    .ID_lcd         (ID_lcd)
    ); 

endmodule
