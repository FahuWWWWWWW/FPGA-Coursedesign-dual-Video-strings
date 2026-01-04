

module FMC(
	input sys_clk,					//	时钟
	input sys_rst_n,					//	复位
    output  [1:0]  led ,        //LED灯
    output  [3:0]  exio ,        //LED灯
	input FSMC_NL_NADV,		//	地址复用有效信号
    input FSMC_CS_NEL,		//	片选
    input FSMC_WR_NWE,		//	写使能
    input FSMC_RD_NOE,		//	读使能	
    inout [15:0] FSMC_DB	//	双向地址/数据总线
);

wire                  locked          ;
wire                  rst_n           ;

wire FSMC_CLK;
wire [15:0] data_0;		// 数据0
wire [15:0] data_1;		// 数据1
wire [15:0] data_2;		// 数据2
wire [15:0] data_3;		// 数据3
wire [15:0] data_4;		// 数据4
wire [15:0] data_5;		// 数据5
wire [15:0] data_6;		// 数据6
wire [15:0] data_7;		// 数据7
wire [15:0] data_8;		// 数据8
wire [15:0] data_9;		// 数据9
wire [15:0] data_10;		// 数据10
wire [15:0] data_11;		// 数据11
wire [15:0] data_12;		// 数据12
wire [15:0] data_13;		// 数据13
wire [15:0] data_14;		// 数据14
wire [15:0] data_15;		// 数据15

assign  rst_n = sys_rst_n & locked;

assign  led[0] = data_0[0];
assign  led[1] = data_0[1];

assign  exio[0] = data_1[0];
assign  exio[1] = ~data_1[0];
assign  exio[2] = data_1[1];
assign  exio[3] = ~data_1[1];

//时钟PLL
clk_wiz_0 u_clk_wiz (
	.reset(~sys_rst_n),
    .clk_in1(sys_clk),
    .clk_out1(FSMC_CLK),
    .locked(locked)
);

ila_0 debug_ila (
    .clk(FSMC_CLK),
    .probe0(rst_n),
    .probe1(FSMC_NL_NADV),
    .probe2(FSMC_CS_NEL),
    .probe3(FSMC_WR_NWE),
    .probe4(FSMC_RD_NOE)
);
//FMC控制
fmc_control fmc_control1(
	 .clk(FSMC_CLK),					// 系统时钟
	 .rst(rst_n),							// 复位
	 .fpga_nl_nadv(FSMC_NL_NADV),	//	地址复用有效信号		
    .fpga_cs_ne1(FSMC_CS_NEL),	//	片选		
    .fpga_wr_nwe(FSMC_WR_NWE),	//	写使能		
    .fpga_rd_noe(FSMC_RD_NOE),	//	读使能			
    .fpga_db(FSMC_DB),				//	双向地址/数据总线
	 
	 .write_data_0	(data_0 ),		// FPGA  -> STM32 通道0
	 .write_data_1	(data_1 ),     // FPGA  -> STM32 通道1
	 .write_data_2	(data_2 ),     // FPGA  -> STM32 通道2
	 .write_data_3	(data_3 ),     // FPGA  -> STM32 通道3
	 .write_data_4	(data_4 ),     // FPGA  -> STM32 通道4
	 .write_data_5	(data_5 ),     // FPGA  -> STM32 通道5
	 .write_data_6	(data_6 ),     // FPGA  -> STM32 通道6
	 .write_data_7	(data_7 ),     // FPGA  -> STM32 通道7
	 .write_data_8	(data_8 ),     // FPGA  -> STM32 通道8
	 .write_data_9	(data_9 ),     // FPGA  -> STM32 通道9
	 .write_data_10(data_10),     // FPGA  -> STM32 通道10
	 .write_data_11(data_11),     // FPGA  -> STM32 通道11
	 .write_data_12(data_12),     // FPGA  -> STM32 通道12
	 .write_data_13(data_13),     // FPGA  -> STM32 通道13
	 .write_data_14(data_14),     // FPGA  -> STM32 通道14
	 .write_data_15(data_15),     // FPGA  -> STM32 通道15
	                              
	 .read_data_0 (data_0 ),      // STM32 -> FPGA  通道0
	 .read_data_1 (data_1 ),      // STM32 -> FPGA  通道1
	 .read_data_2 (data_2 ),      // STM32 -> FPGA  通道2
	 .read_data_3 (data_3 ),      // STM32 -> FPGA  通道3
	 .read_data_4 (data_4 ),      // STM32 -> FPGA  通道4
	 .read_data_5 (data_5 ),      // STM32 -> FPGA  通道5
	 .read_data_6 (data_6 ),      // STM32 -> FPGA  通道6
	 .read_data_7 (data_7 ),      // STM32 -> FPGA  通道7
	 .read_data_8 (data_8 ),      // STM32 -> FPGA  通道8
	 .read_data_9 (data_9 ),      // STM32 -> FPGA  通道9
	 .read_data_10(data_10),      // STM32 -> FPGA  通道10
	 .read_data_11(data_11),      // STM32 -> FPGA  通道11
	 .read_data_12(data_12),      // STM32 -> FPGA  通道12
	 .read_data_13(data_13),      // STM32 -> FPGA  通道13
	 .read_data_14(data_14),      // STM32 -> FPGA  通道14
	 .read_data_15(data_15)       // STM32 -> FPGA  通道15
);

endmodule 