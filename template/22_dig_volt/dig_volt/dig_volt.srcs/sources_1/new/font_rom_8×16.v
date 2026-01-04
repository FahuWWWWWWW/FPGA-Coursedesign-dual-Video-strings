`timescale 1ns/1ns

module font_rom_8x16
(
    input   wire    [7:0]   char_code,  // ASCII 字符代码 (例如 'A' = 65)
    input   wire    [3:0]   row,        // 当前扫描的行 (0-15)
    output  reg     [7:0]   row_data    // 输出的 8位 像素点阵数据
);

    //========================================================================
    // 内存定义: 96个字符(ASCII 32~127) * 16字节/字符 = 1536 字节
    //========================================================================
    reg [7:0] rom_mem [0:1535];

    //========================================================================
    // 地址计算与读取逻辑
    //========================================================================
    wire [10:0] addr;
    
    // 提供的字库是从 空格(ASCII 32) 开始的
    // 地址 = (ASCII码 - 32) * 16 + 当前行号
    // 如果输入的字符小于32(不可见字符)，默认读取地址0(空格)
    assign addr = (char_code >= 8'd32 && char_code <= 8'd127) ? 
                  ((char_code - 8'd32) * 11'd16 + row) : 11'd0;

    always @(*) begin
        row_data = rom_mem[addr];
    end

    //========================================================================
    // 字库数据初始化
    //========================================================================
    initial begin
        //--  MS Gothic12;  宽x高=8x16   --// 
        
        // ASCII 32: Space (空格) - Offset 0
        rom_mem[0]=8'h00; rom_mem[1]=8'h00; rom_mem[2]=8'h00; rom_mem[3]=8'h00;
        rom_mem[4]=8'h00; rom_mem[5]=8'h00; rom_mem[6]=8'h00; rom_mem[7]=8'h00;
        rom_mem[8]=8'h00; rom_mem[9]=8'h00; rom_mem[10]=8'h00; rom_mem[11]=8'h00;
        rom_mem[12]=8'h00; rom_mem[13]=8'h00; rom_mem[14]=8'h00; rom_mem[15]=8'h00;

        // ASCII 33: ! - Offset 16
        rom_mem[16]=8'h00; rom_mem[17]=8'h10; rom_mem[18]=8'h10; rom_mem[19]=8'h10;
        rom_mem[20]=8'h10; rom_mem[21]=8'h10; rom_mem[22]=8'h10; rom_mem[23]=8'h10;
        rom_mem[24]=8'h10; rom_mem[25]=8'h10; rom_mem[26]=8'h00; rom_mem[27]=8'h00;
        rom_mem[28]=8'h18; rom_mem[29]=8'h18; rom_mem[30]=8'h00; rom_mem[31]=8'h00;

        // ASCII 34: "
        rom_mem[32]=8'h36; rom_mem[33]=8'h24; rom_mem[34]=8'h48; rom_mem[35]=8'h00;
        rom_mem[36]=8'h00; rom_mem[37]=8'h00; rom_mem[38]=8'h00; rom_mem[39]=8'h00;
        rom_mem[40]=8'h00; rom_mem[41]=8'h00; rom_mem[42]=8'h00; rom_mem[43]=8'h00;
        rom_mem[44]=8'h00; rom_mem[45]=8'h00; rom_mem[46]=8'h00; rom_mem[47]=8'h00;

        // ASCII 35: #
        rom_mem[48]=8'h00; rom_mem[49]=8'h00; rom_mem[50]=8'h00; rom_mem[51]=8'h24;
        rom_mem[52]=8'h24; rom_mem[53]=8'h24; rom_mem[54]=8'hFE; rom_mem[55]=8'h48;
        rom_mem[56]=8'h48; rom_mem[57]=8'h48; rom_mem[58]=8'hFE; rom_mem[59]=8'h48;
        rom_mem[60]=8'h48; rom_mem[61]=8'h48; rom_mem[62]=8'h00; rom_mem[63]=8'h00;

        // ASCII 36: $
        rom_mem[64]=8'h10; rom_mem[65]=8'h38; rom_mem[66]=8'h54; rom_mem[67]=8'h92;
        rom_mem[68]=8'h92; rom_mem[69]=8'h50; rom_mem[70]=8'h30; rom_mem[71]=8'h18;
        rom_mem[72]=8'h14; rom_mem[73]=8'h12; rom_mem[74]=8'h92; rom_mem[75]=8'h92;
        rom_mem[76]=8'h54; rom_mem[77]=8'h38; rom_mem[78]=8'h10; rom_mem[79]=8'h00;

        // ASCII 37: %
        rom_mem[80]=8'h00; rom_mem[81]=8'h62; rom_mem[82]=8'h92; rom_mem[83]=8'h94;
        rom_mem[84]=8'h94; rom_mem[85]=8'h68; rom_mem[86]=8'h08; rom_mem[87]=8'h10;
        rom_mem[88]=8'h20; rom_mem[89]=8'h2C; rom_mem[90]=8'h52; rom_mem[91]=8'h52;
        rom_mem[92]=8'h92; rom_mem[93]=8'h8C; rom_mem[94]=8'h00; rom_mem[95]=8'h00;

        // ASCII 38: &
        rom_mem[96]=8'h00; rom_mem[97]=8'h30; rom_mem[98]=8'h48; rom_mem[99]=8'h48;
        rom_mem[100]=8'h48; rom_mem[101]=8'h48; rom_mem[102]=8'h30; rom_mem[103]=8'h20;
        rom_mem[104]=8'h54; rom_mem[105]=8'h94; rom_mem[106]=8'h88; rom_mem[107]=8'h88;
        rom_mem[108]=8'h94; rom_mem[109]=8'h62; rom_mem[110]=8'h00; rom_mem[111]=8'h00;

        // ASCII 39: '
        rom_mem[112]=8'h30; rom_mem[113]=8'h30; rom_mem[114]=8'h10; rom_mem[115]=8'h20;
        rom_mem[116]=8'h00; rom_mem[117]=8'h00; rom_mem[118]=8'h00; rom_mem[119]=8'h00;
        rom_mem[120]=8'h00; rom_mem[121]=8'h00; rom_mem[122]=8'h00; rom_mem[123]=8'h00;
        rom_mem[124]=8'h00; rom_mem[125]=8'h00; rom_mem[126]=8'h00; rom_mem[127]=8'h00;

        // ASCII 40: (
        rom_mem[128]=8'h04; rom_mem[129]=8'h08; rom_mem[130]=8'h10; rom_mem[131]=8'h10;
        rom_mem[132]=8'h20; rom_mem[133]=8'h20; rom_mem[134]=8'h20; rom_mem[135]=8'h20;
        rom_mem[136]=8'h20; rom_mem[137]=8'h20; rom_mem[138]=8'h20; rom_mem[139]=8'h10;
        rom_mem[140]=8'h10; rom_mem[141]=8'h08; rom_mem[142]=8'h04; rom_mem[143]=8'h00;

        // ASCII 41: )
        rom_mem[144]=8'h40; rom_mem[145]=8'h20; rom_mem[146]=8'h10; rom_mem[147]=8'h10;
        rom_mem[148]=8'h08; rom_mem[149]=8'h08; rom_mem[150]=8'h08; rom_mem[151]=8'h08;
        rom_mem[152]=8'h08; rom_mem[153]=8'h08; rom_mem[154]=8'h08; rom_mem[155]=8'h10;
        rom_mem[156]=8'h10; rom_mem[157]=8'h20; rom_mem[158]=8'h40; rom_mem[159]=8'h00;

        // ASCII 42: *
        rom_mem[160]=8'h00; rom_mem[161]=8'h00; rom_mem[162]=8'h00; rom_mem[163]=8'h10;
        rom_mem[164]=8'h92; rom_mem[165]=8'h54; rom_mem[166]=8'h38; rom_mem[167]=8'h10;
        rom_mem[168]=8'h38; rom_mem[169]=8'h54; rom_mem[170]=8'h92; rom_mem[171]=8'h10;
        rom_mem[172]=8'h00; rom_mem[173]=8'h00; rom_mem[174]=8'h00; rom_mem[175]=8'h00;

        // ASCII 43: +
        rom_mem[176]=8'h00; rom_mem[177]=8'h00; rom_mem[178]=8'h00; rom_mem[179]=8'h00;
        rom_mem[180]=8'h10; rom_mem[181]=8'h10; rom_mem[182]=8'h10; rom_mem[183]=8'hFE;
        rom_mem[184]=8'h10; rom_mem[185]=8'h10; rom_mem[186]=8'h10; rom_mem[187]=8'h00;
        rom_mem[188]=8'h00; rom_mem[189]=8'h00; rom_mem[190]=8'h00; rom_mem[191]=8'h00;

        // ASCII 44: ,
        rom_mem[192]=8'h00; rom_mem[193]=8'h00; rom_mem[194]=8'h00; rom_mem[195]=8'h00;
        rom_mem[196]=8'h00; rom_mem[197]=8'h00; rom_mem[198]=8'h00; rom_mem[199]=8'h00;
        rom_mem[200]=8'h00; rom_mem[201]=8'h00; rom_mem[202]=8'h00; rom_mem[203]=8'h30;
        rom_mem[204]=8'h30; rom_mem[205]=8'h10; rom_mem[206]=8'h20; rom_mem[207]=8'h00;

        // ASCII 45: -
        rom_mem[208]=8'h00; rom_mem[209]=8'h00; rom_mem[210]=8'h00; rom_mem[211]=8'h00;
        rom_mem[212]=8'h00; rom_mem[213]=8'h00; rom_mem[214]=8'h00; rom_mem[215]=8'h7C;
        rom_mem[216]=8'h00; rom_mem[217]=8'h00; rom_mem[218]=8'h00; rom_mem[219]=8'h00;
        rom_mem[220]=8'h00; rom_mem[221]=8'h00; rom_mem[222]=8'h00; rom_mem[223]=8'h00;

        // ASCII 46: .
        rom_mem[224]=8'h00; rom_mem[225]=8'h00; rom_mem[226]=8'h00; rom_mem[227]=8'h00;
        rom_mem[228]=8'h00; rom_mem[229]=8'h00; rom_mem[230]=8'h00; rom_mem[231]=8'h00;
        rom_mem[232]=8'h00; rom_mem[233]=8'h00; rom_mem[234]=8'h00; rom_mem[235]=8'h00;
        rom_mem[236]=8'h30; rom_mem[237]=8'h30; rom_mem[238]=8'h00; rom_mem[239]=8'h00;

        // ASCII 47: /
        rom_mem[240]=8'h00; rom_mem[241]=8'h02; rom_mem[242]=8'h02; rom_mem[243]=8'h04;
        rom_mem[244]=8'h04; rom_mem[245]=8'h08; rom_mem[246]=8'h08; rom_mem[247]=8'h10;
        rom_mem[248]=8'h20; rom_mem[249]=8'h20; rom_mem[250]=8'h40; rom_mem[251]=8'h40;
        rom_mem[252]=8'h80; rom_mem[253]=8'h80; rom_mem[254]=8'h00; rom_mem[255]=8'h00;

        // ASCII 48: 0
        rom_mem[256]=8'h00; rom_mem[257]=8'h30; rom_mem[258]=8'h48; rom_mem[259]=8'h84;
        rom_mem[260]=8'h84; rom_mem[261]=8'h84; rom_mem[262]=8'h84; rom_mem[263]=8'h84;
        rom_mem[264]=8'h84; rom_mem[265]=8'h84; rom_mem[266]=8'h84; rom_mem[267]=8'h84;
        rom_mem[268]=8'h48; rom_mem[269]=8'h30; rom_mem[270]=8'h00; rom_mem[271]=8'h00;

        // ASCII 49: 1
        rom_mem[272]=8'h00; rom_mem[273]=8'h10; rom_mem[274]=8'h70; rom_mem[275]=8'h10;
        rom_mem[276]=8'h10; rom_mem[277]=8'h10; rom_mem[278]=8'h10; rom_mem[279]=8'h10;
        rom_mem[280]=8'h10; rom_mem[281]=8'h10; rom_mem[282]=8'h10; rom_mem[283]=8'h10;
        rom_mem[284]=8'h10; rom_mem[285]=8'h10; rom_mem[286]=8'h00; rom_mem[287]=8'h00;

        // ASCII 50: 2
        rom_mem[288]=8'h00; rom_mem[289]=8'h30; rom_mem[290]=8'h48; rom_mem[291]=8'h84;
        rom_mem[292]=8'h84; rom_mem[293]=8'h04; rom_mem[294]=8'h08; rom_mem[295]=8'h08;
        rom_mem[296]=8'h10; rom_mem[297]=8'h20; rom_mem[298]=8'h20; rom_mem[299]=8'h40;
        rom_mem[300]=8'h80; rom_mem[301]=8'hFC; rom_mem[302]=8'h00; rom_mem[303]=8'h00;

        // ASCII 51: 3
        rom_mem[304]=8'h00; rom_mem[305]=8'h30; rom_mem[306]=8'h48; rom_mem[307]=8'h84;
        rom_mem[308]=8'h84; rom_mem[309]=8'h04; rom_mem[310]=8'h08; rom_mem[311]=8'h30;
        rom_mem[312]=8'h08; rom_mem[313]=8'h04; rom_mem[314]=8'h84; rom_mem[315]=8'h84;
        rom_mem[316]=8'h48; rom_mem[317]=8'h30; rom_mem[318]=8'h00; rom_mem[319]=8'h00;

        // ASCII 52: 4
        rom_mem[320]=8'h00; rom_mem[321]=8'h08; rom_mem[322]=8'h08; rom_mem[323]=8'h18;
        rom_mem[324]=8'h18; rom_mem[325]=8'h28; rom_mem[326]=8'h28; rom_mem[327]=8'h48;
        rom_mem[328]=8'h48; rom_mem[329]=8'h88; rom_mem[330]=8'hFC; rom_mem[331]=8'h08;
        rom_mem[332]=8'h08; rom_mem[333]=8'h08; rom_mem[334]=8'h00; rom_mem[335]=8'h00;

        // ASCII 53: 5
        rom_mem[336]=8'h00; rom_mem[337]=8'hFC; rom_mem[338]=8'h80; rom_mem[339]=8'h80;
        rom_mem[340]=8'h80; rom_mem[341]=8'hB0; rom_mem[342]=8'hC8; rom_mem[343]=8'h84;
        rom_mem[344]=8'h04; rom_mem[345]=8'h04; rom_mem[346]=8'h04; rom_mem[347]=8'h84;
        rom_mem[348]=8'h48; rom_mem[349]=8'h30; rom_mem[350]=8'h00; rom_mem[351]=8'h00;

        // ASCII 54: 6
        rom_mem[352]=8'h00; rom_mem[353]=8'h30; rom_mem[354]=8'h48; rom_mem[355]=8'h84;
        rom_mem[356]=8'h84; rom_mem[357]=8'h80; rom_mem[358]=8'hB0; rom_mem[359]=8'hC8;
        rom_mem[360]=8'h84; rom_mem[361]=8'h84; rom_mem[362]=8'h84; rom_mem[363]=8'h84;
        rom_mem[364]=8'h48; rom_mem[365]=8'h30; rom_mem[366]=8'h00; rom_mem[367]=8'h00;

        // ASCII 55: 7
        rom_mem[368]=8'h00; rom_mem[369]=8'hFC; rom_mem[370]=8'h04; rom_mem[371]=8'h04;
        rom_mem[372]=8'h08; rom_mem[373]=8'h08; rom_mem[374]=8'h08; rom_mem[375]=8'h10;
        rom_mem[376]=8'h10; rom_mem[377]=8'h10; rom_mem[378]=8'h20; rom_mem[379]=8'h20;
        rom_mem[380]=8'h20; rom_mem[381]=8'h20; rom_mem[382]=8'h00; rom_mem[383]=8'h00;

        // ASCII 56: 8
        rom_mem[384]=8'h00; rom_mem[385]=8'h30; rom_mem[386]=8'h48; rom_mem[387]=8'h84;
        rom_mem[388]=8'h84; rom_mem[389]=8'h84; rom_mem[390]=8'h48; rom_mem[391]=8'h30;
        rom_mem[392]=8'h48; rom_mem[393]=8'h84; rom_mem[394]=8'h84; rom_mem[395]=8'h84;
        rom_mem[396]=8'h48; rom_mem[397]=8'h30; rom_mem[398]=8'h00; rom_mem[399]=8'h00;

        // ASCII 57: 9
        rom_mem[400]=8'h00; rom_mem[401]=8'h30; rom_mem[402]=8'h48; rom_mem[403]=8'h84;
        rom_mem[404]=8'h84; rom_mem[405]=8'h84; rom_mem[406]=8'h84; rom_mem[407]=8'h4C;
        rom_mem[408]=8'h34; rom_mem[409]=8'h04; rom_mem[410]=8'h84; rom_mem[411]=8'h84;
        rom_mem[412]=8'h48; rom_mem[413]=8'h30; rom_mem[414]=8'h00; rom_mem[415]=8'h00;

        // ASCII 58: :
        rom_mem[416]=8'h00; rom_mem[417]=8'h00; rom_mem[418]=8'h00; rom_mem[419]=8'h00;
        rom_mem[420]=8'h00; rom_mem[421]=8'h30; rom_mem[422]=8'h30; rom_mem[423]=8'h00;
        rom_mem[424]=8'h00; rom_mem[425]=8'h00; rom_mem[426]=8'h00; rom_mem[427]=8'h30;
        rom_mem[428]=8'h30; rom_mem[429]=8'h00; rom_mem[430]=8'h00; rom_mem[431]=8'h00;

        // ASCII 59: ;
        rom_mem[432]=8'h00; rom_mem[433]=8'h00; rom_mem[434]=8'h00; rom_mem[435]=8'h00;
        rom_mem[436]=8'h00; rom_mem[437]=8'h30; rom_mem[438]=8'h30; rom_mem[439]=8'h00;
        rom_mem[440]=8'h00; rom_mem[441]=8'h00; rom_mem[442]=8'h00; rom_mem[443]=8'h30;
        rom_mem[444]=8'h30; rom_mem[445]=8'h10; rom_mem[446]=8'h20; rom_mem[447]=8'h00;

        // ASCII 60: <
        rom_mem[448]=8'h00; rom_mem[449]=8'h00; rom_mem[450]=8'h04; rom_mem[451]=8'h08;
        rom_mem[452]=8'h10; rom_mem[453]=8'h20; rom_mem[454]=8'h40; rom_mem[455]=8'h80;
        rom_mem[456]=8'h40; rom_mem[457]=8'h20; rom_mem[458]=8'h10; rom_mem[459]=8'h08;
        rom_mem[460]=8'h04; rom_mem[461]=8'h00; rom_mem[462]=8'h00; rom_mem[463]=8'h00;

        // ASCII 61: =
        rom_mem[464]=8'h00; rom_mem[465]=8'h00; rom_mem[466]=8'h00; rom_mem[467]=8'h00;
        rom_mem[468]=8'h00; rom_mem[469]=8'h7C; rom_mem[470]=8'h00; rom_mem[471]=8'h00;
        rom_mem[472]=8'h00; rom_mem[473]=8'h7C; rom_mem[474]=8'h00; rom_mem[475]=8'h00;
        rom_mem[476]=8'h00; rom_mem[477]=8'h00; rom_mem[478]=8'h00; rom_mem[479]=8'h00;

        // ASCII 62: >
        rom_mem[480]=8'h00; rom_mem[481]=8'h00; rom_mem[482]=8'h80; rom_mem[483]=8'h40;
        rom_mem[484]=8'h20; rom_mem[485]=8'h10; rom_mem[486]=8'h08; rom_mem[487]=8'h04;
        rom_mem[488]=8'h08; rom_mem[489]=8'h10; rom_mem[490]=8'h20; rom_mem[491]=8'h40;
        rom_mem[492]=8'h80; rom_mem[493]=8'h00; rom_mem[494]=8'h00; rom_mem[495]=8'h00;

        // ASCII 63: ?
        rom_mem[496]=8'h00; rom_mem[497]=8'h30; rom_mem[498]=8'h48; rom_mem[499]=8'h84;
        rom_mem[500]=8'h84; rom_mem[501]=8'h04; rom_mem[502]=8'h08; rom_mem[503]=8'h10;
        rom_mem[504]=8'h20; rom_mem[505]=8'h20; rom_mem[506]=8'h00; rom_mem[507]=8'h00;
        rom_mem[508]=8'h30; rom_mem[509]=8'h30; rom_mem[510]=8'h00; rom_mem[511]=8'h00;

        // ASCII 64: @
        rom_mem[512]=8'h00; rom_mem[513]=8'h38; rom_mem[514]=8'h44; rom_mem[515]=8'h82;
        rom_mem[516]=8'h9A; rom_mem[517]=8'hAA; rom_mem[518]=8'hAA; rom_mem[519]=8'hAA;
        rom_mem[520]=8'hAA; rom_mem[521]=8'hAA; rom_mem[522]=8'h9C; rom_mem[523]=8'h80;
        rom_mem[524]=8'h42; rom_mem[525]=8'h3C; rom_mem[526]=8'h00; rom_mem[527]=8'h00;

        // ASCII 65: A
        rom_mem[528]=8'h00; rom_mem[529]=8'h10; rom_mem[530]=8'h10; rom_mem[531]=8'h28;
        rom_mem[532]=8'h28; rom_mem[533]=8'h28; rom_mem[534]=8'h28; rom_mem[535]=8'h44;
        rom_mem[536]=8'h44; rom_mem[537]=8'h44; rom_mem[538]=8'h7C; rom_mem[539]=8'h82;
        rom_mem[540]=8'h82; rom_mem[541]=8'h82; rom_mem[542]=8'h00; rom_mem[543]=8'h00;

        // ASCII 66: B
        rom_mem[544]=8'h00; rom_mem[545]=8'hF8; rom_mem[546]=8'h84; rom_mem[547]=8'h82;
        rom_mem[548]=8'h82; rom_mem[549]=8'h82; rom_mem[550]=8'h84; rom_mem[551]=8'hF8;
        rom_mem[552]=8'h84; rom_mem[553]=8'h82; rom_mem[554]=8'h82; rom_mem[555]=8'h82;
        rom_mem[556]=8'h84; rom_mem[557]=8'hF8; rom_mem[558]=8'h00; rom_mem[559]=8'h00;

        // ASCII 67: C
        rom_mem[560]=8'h00; rom_mem[561]=8'h38; rom_mem[562]=8'h44; rom_mem[563]=8'h82;
        rom_mem[564]=8'h82; rom_mem[565]=8'h80; rom_mem[566]=8'h80; rom_mem[567]=8'h80;
        rom_mem[568]=8'h80; rom_mem[569]=8'h80; rom_mem[570]=8'h82; rom_mem[571]=8'h82;
        rom_mem[572]=8'h44; rom_mem[573]=8'h38; rom_mem[574]=8'h00; rom_mem[575]=8'h00;

        // ASCII 68: D
        rom_mem[576]=8'h00; rom_mem[577]=8'hF8; rom_mem[578]=8'h84; rom_mem[579]=8'h82;
        rom_mem[580]=8'h82; rom_mem[581]=8'h82; rom_mem[582]=8'h82; rom_mem[583]=8'h82;
        rom_mem[584]=8'h82; rom_mem[585]=8'h82; rom_mem[586]=8'h82; rom_mem[587]=8'h82;
        rom_mem[588]=8'h84; rom_mem[589]=8'hF8; rom_mem[590]=8'h00; rom_mem[591]=8'h00;

        // ASCII 69: E
        rom_mem[592]=8'h00; rom_mem[593]=8'hFE; rom_mem[594]=8'h80; rom_mem[595]=8'h80;
        rom_mem[596]=8'h80; rom_mem[597]=8'h80; rom_mem[598]=8'h80; rom_mem[599]=8'hFC;
        rom_mem[600]=8'h80; rom_mem[601]=8'h80; rom_mem[602]=8'h80; rom_mem[603]=8'h80;
        rom_mem[604]=8'h80; rom_mem[605]=8'hFE; rom_mem[606]=8'h00; rom_mem[607]=8'h00;

        // ASCII 70: F
        rom_mem[608]=8'h00; rom_mem[609]=8'hFE; rom_mem[610]=8'h80; rom_mem[611]=8'h80;
        rom_mem[612]=8'h80; rom_mem[613]=8'h80; rom_mem[614]=8'h80; rom_mem[615]=8'hFC;
        rom_mem[616]=8'h80; rom_mem[617]=8'h80; rom_mem[618]=8'h80; rom_mem[619]=8'h80;
        rom_mem[620]=8'h80; rom_mem[621]=8'h80; rom_mem[622]=8'h00; rom_mem[623]=8'h00;

        // ASCII 71: G
        rom_mem[624]=8'h00; rom_mem[625]=8'h38; rom_mem[626]=8'h44; rom_mem[627]=8'h82;
        rom_mem[628]=8'h82; rom_mem[629]=8'h80; rom_mem[630]=8'h80; rom_mem[631]=8'h80;
        rom_mem[632]=8'h8E; rom_mem[633]=8'h82; rom_mem[634]=8'h82; rom_mem[635]=8'h82;
        rom_mem[636]=8'h46; rom_mem[637]=8'h3A; rom_mem[638]=8'h00; rom_mem[639]=8'h00;

        // ASCII 72: H
        rom_mem[640]=8'h00; rom_mem[641]=8'h82; rom_mem[642]=8'h82; rom_mem[643]=8'h82;
        rom_mem[644]=8'h82; rom_mem[645]=8'h82; rom_mem[646]=8'h82; rom_mem[647]=8'hFE;
        rom_mem[648]=8'h82; rom_mem[649]=8'h82; rom_mem[650]=8'h82; rom_mem[651]=8'h82;
        rom_mem[652]=8'h82; rom_mem[653]=8'h82; rom_mem[654]=8'h00; rom_mem[655]=8'h00;

        // ASCII 73: I
        rom_mem[656]=8'h00; rom_mem[657]=8'h38; rom_mem[658]=8'h10; rom_mem[659]=8'h10;
        rom_mem[660]=8'h10; rom_mem[661]=8'h10; rom_mem[662]=8'h10; rom_mem[663]=8'h10;
        rom_mem[664]=8'h10; rom_mem[665]=8'h10; rom_mem[666]=8'h10; rom_mem[667]=8'h10;
        rom_mem[668]=8'h10; rom_mem[669]=8'h38; rom_mem[670]=8'h00; rom_mem[671]=8'h00;

        // ASCII 74: J
        rom_mem[672]=8'h00; rom_mem[673]=8'h04; rom_mem[674]=8'h04; rom_mem[675]=8'h04;
        rom_mem[676]=8'h04; rom_mem[677]=8'h04; rom_mem[678]=8'h04; rom_mem[679]=8'h04;
        rom_mem[680]=8'h04; rom_mem[681]=8'h04; rom_mem[682]=8'h84; rom_mem[683]=8'h84;
        rom_mem[684]=8'h48; rom_mem[685]=8'h30; rom_mem[686]=8'h00; rom_mem[687]=8'h00;

        // ASCII 75: K
        rom_mem[688]=8'h00; rom_mem[689]=8'h82; rom_mem[690]=8'h84; rom_mem[691]=8'h84;
        rom_mem[692]=8'h88; rom_mem[693]=8'h90; rom_mem[694]=8'h90; rom_mem[695]=8'hA0;
        rom_mem[696]=8'hD0; rom_mem[697]=8'h88; rom_mem[698]=8'h88; rom_mem[699]=8'h84;
        rom_mem[700]=8'h82; rom_mem[701]=8'h82; rom_mem[702]=8'h00; rom_mem[703]=8'h00;

        // ASCII 76: L
        rom_mem[704]=8'h00; rom_mem[705]=8'h80; rom_mem[706]=8'h80; rom_mem[707]=8'h80;
        rom_mem[708]=8'h80; rom_mem[709]=8'h80; rom_mem[710]=8'h80; rom_mem[711]=8'h80;
        rom_mem[712]=8'h80; rom_mem[713]=8'h80; rom_mem[714]=8'h80; rom_mem[715]=8'h80;
        rom_mem[716]=8'h80; rom_mem[717]=8'hFE; rom_mem[718]=8'h00; rom_mem[719]=8'h00;

        // ASCII 77: M
        rom_mem[720]=8'h00; rom_mem[721]=8'h82; rom_mem[722]=8'h82; rom_mem[723]=8'hC6;
        rom_mem[724]=8'hC6; rom_mem[725]=8'hC6; rom_mem[726]=8'hC6; rom_mem[727]=8'hAA;
        rom_mem[728]=8'hAA; rom_mem[729]=8'hAA; rom_mem[730]=8'hAA; rom_mem[731]=8'h92;
        rom_mem[732]=8'h92; rom_mem[733]=8'h92; rom_mem[734]=8'h00; rom_mem[735]=8'h00;

        // ASCII 78: N
        rom_mem[736]=8'h00; rom_mem[737]=8'h82; rom_mem[738]=8'h82; rom_mem[739]=8'hC2;
        rom_mem[740]=8'hC2; rom_mem[741]=8'hA2; rom_mem[742]=8'hA2; rom_mem[743]=8'h92;
        rom_mem[744]=8'h92; rom_mem[745]=8'h8A; rom_mem[746]=8'h8A; rom_mem[747]=8'h86;
        rom_mem[748]=8'h86; rom_mem[749]=8'h82; rom_mem[750]=8'h00; rom_mem[751]=8'h00;

        // ASCII 79: O
        rom_mem[752]=8'h00; rom_mem[753]=8'h38; rom_mem[754]=8'h44; rom_mem[755]=8'h82;
        rom_mem[756]=8'h82; rom_mem[757]=8'h82; rom_mem[758]=8'h82; rom_mem[759]=8'h82;
        rom_mem[760]=8'h82; rom_mem[761]=8'h82; rom_mem[762]=8'h82; rom_mem[763]=8'h82;
        rom_mem[764]=8'h44; rom_mem[765]=8'h38; rom_mem[766]=8'h00; rom_mem[767]=8'h00;

        // ASCII 80: P
        rom_mem[768]=8'h00; rom_mem[769]=8'hF8; rom_mem[770]=8'h84; rom_mem[771]=8'h82;
        rom_mem[772]=8'h82; rom_mem[773]=8'h82; rom_mem[774]=8'h84; rom_mem[775]=8'hF8;
        rom_mem[776]=8'h80; rom_mem[777]=8'h80; rom_mem[778]=8'h80; rom_mem[779]=8'h80;
        rom_mem[780]=8'h80; rom_mem[781]=8'h80; rom_mem[782]=8'h00; rom_mem[783]=8'h00;

        // ASCII 81: Q
        rom_mem[784]=8'h00; rom_mem[785]=8'h38; rom_mem[786]=8'h44; rom_mem[787]=8'h82;
        rom_mem[788]=8'h82; rom_mem[789]=8'h82; rom_mem[790]=8'h82; rom_mem[791]=8'h82;
        rom_mem[792]=8'h82; rom_mem[793]=8'h82; rom_mem[794]=8'h92; rom_mem[795]=8'h8A;
        rom_mem[796]=8'h44; rom_mem[797]=8'h3A; rom_mem[798]=8'h00; rom_mem[799]=8'h00;

        // ASCII 82: R
        rom_mem[800]=8'h00; rom_mem[801]=8'hF8; rom_mem[802]=8'h84; rom_mem[803]=8'h82;
        rom_mem[804]=8'h82; rom_mem[805]=8'h82; rom_mem[806]=8'h84; rom_mem[807]=8'hF8;
        rom_mem[808]=8'h88; rom_mem[809]=8'h88; rom_mem[810]=8'h84; rom_mem[811]=8'h84;
        rom_mem[812]=8'h82; rom_mem[813]=8'h82; rom_mem[814]=8'h00; rom_mem[815]=8'h00;

        // ASCII 83: S
        rom_mem[816]=8'h00; rom_mem[817]=8'h38; rom_mem[818]=8'h44; rom_mem[819]=8'h82;
        rom_mem[820]=8'h82; rom_mem[821]=8'h80; rom_mem[822]=8'h60; rom_mem[823]=8'h18;
        rom_mem[824]=8'h04; rom_mem[825]=8'h02; rom_mem[826]=8'h82; rom_mem[827]=8'h82;
        rom_mem[828]=8'h44; rom_mem[829]=8'h38; rom_mem[830]=8'h00; rom_mem[831]=8'h00;

        // ASCII 84: T
        rom_mem[832]=8'h00; rom_mem[833]=8'hFE; rom_mem[834]=8'h10; rom_mem[835]=8'h10;
        rom_mem[836]=8'h10; rom_mem[837]=8'h10; rom_mem[838]=8'h10; rom_mem[839]=8'h10;
        rom_mem[840]=8'h10; rom_mem[841]=8'h10; rom_mem[842]=8'h10; rom_mem[843]=8'h10;
        rom_mem[844]=8'h10; rom_mem[845]=8'h10; rom_mem[846]=8'h00; rom_mem[847]=8'h00;

        // ASCII 85: U
        rom_mem[848]=8'h00; rom_mem[849]=8'h82; rom_mem[850]=8'h82; rom_mem[851]=8'h82;
        rom_mem[852]=8'h82; rom_mem[853]=8'h82; rom_mem[854]=8'h82; rom_mem[855]=8'h82;
        rom_mem[856]=8'h82; rom_mem[857]=8'h82; rom_mem[858]=8'h82; rom_mem[859]=8'h82;
        rom_mem[860]=8'h44; rom_mem[861]=8'h38; rom_mem[862]=8'h00; rom_mem[863]=8'h00;

        // ASCII 86: V
        rom_mem[864]=8'h00; rom_mem[865]=8'h82; rom_mem[866]=8'h82; rom_mem[867]=8'h82;
        rom_mem[868]=8'h44; rom_mem[869]=8'h44; rom_mem[870]=8'h44; rom_mem[871]=8'h44;
        rom_mem[872]=8'h28; rom_mem[873]=8'h28; rom_mem[874]=8'h28; rom_mem[875]=8'h10;
        rom_mem[876]=8'h10; rom_mem[877]=8'h10; rom_mem[878]=8'h00; rom_mem[879]=8'h00;

        // ASCII 87: W
        rom_mem[880]=8'h00; rom_mem[881]=8'h92; rom_mem[882]=8'h92; rom_mem[883]=8'h92;
        rom_mem[884]=8'h92; rom_mem[885]=8'hAA; rom_mem[886]=8'hAA; rom_mem[887]=8'hAA;
        rom_mem[888]=8'hAA; rom_mem[889]=8'h44; rom_mem[890]=8'h44; rom_mem[891]=8'h44;
        rom_mem[892]=8'h44; rom_mem[893]=8'h44; rom_mem[894]=8'h00; rom_mem[895]=8'h00;

        // ASCII 88: X
        rom_mem[896]=8'h00; rom_mem[897]=8'h82; rom_mem[898]=8'h82; rom_mem[899]=8'h44;
        rom_mem[900]=8'h44; rom_mem[901]=8'h28; rom_mem[902]=8'h28; rom_mem[903]=8'h10;
        rom_mem[904]=8'h28; rom_mem[905]=8'h28; rom_mem[906]=8'h44; rom_mem[907]=8'h44;
        rom_mem[908]=8'h82; rom_mem[909]=8'h82; rom_mem[910]=8'h00; rom_mem[911]=8'h00;

        // ASCII 89: Y
        rom_mem[912]=8'h00; rom_mem[913]=8'h82; rom_mem[914]=8'h82; rom_mem[915]=8'h44;
        rom_mem[916]=8'h44; rom_mem[917]=8'h28; rom_mem[918]=8'h28; rom_mem[919]=8'h10;
        rom_mem[920]=8'h10; rom_mem[921]=8'h10; rom_mem[922]=8'h10; rom_mem[923]=8'h10;
        rom_mem[924]=8'h10; rom_mem[925]=8'h10; rom_mem[926]=8'h00; rom_mem[927]=8'h00;

        // ASCII 90: Z
        rom_mem[928]=8'h00; rom_mem[929]=8'hFE; rom_mem[930]=8'h02; rom_mem[931]=8'h04;
        rom_mem[932]=8'h04; rom_mem[933]=8'h08; rom_mem[934]=8'h08; rom_mem[935]=8'h10;
        rom_mem[936]=8'h20; rom_mem[937]=8'h20; rom_mem[938]=8'h40; rom_mem[939]=8'h40;
        rom_mem[940]=8'h80; rom_mem[941]=8'hFE; rom_mem[942]=8'h00; rom_mem[943]=8'h00;

        // ASCII 91: [
        rom_mem[944]=8'h7C; rom_mem[945]=8'h40; rom_mem[946]=8'h40; rom_mem[947]=8'h40;
        rom_mem[948]=8'h40; rom_mem[949]=8'h40; rom_mem[950]=8'h40; rom_mem[951]=8'h40;
        rom_mem[952]=8'h40; rom_mem[953]=8'h40; rom_mem[954]=8'h40; rom_mem[955]=8'h40;
        rom_mem[956]=8'h40; rom_mem[957]=8'h40; rom_mem[958]=8'h7C; rom_mem[959]=8'h00;

        // ASCII 92: \
        rom_mem[960]=8'h00; rom_mem[961]=8'h82; rom_mem[962]=8'h82; rom_mem[963]=8'h44;
        rom_mem[964]=8'h44; rom_mem[965]=8'h28; rom_mem[966]=8'h28; rom_mem[967]=8'h7C;
        rom_mem[968]=8'h10; rom_mem[969]=8'h10; rom_mem[970]=8'h7C; rom_mem[971]=8'h10;
        rom_mem[972]=8'h10; rom_mem[973]=8'h10; rom_mem[974]=8'h00; rom_mem[975]=8'h00;

        // ASCII 93: ]
        rom_mem[976]=8'h7C; rom_mem[977]=8'h04; rom_mem[978]=8'h04; rom_mem[979]=8'h04;
        rom_mem[980]=8'h04; rom_mem[981]=8'h04; rom_mem[982]=8'h04; rom_mem[983]=8'h04;
        rom_mem[984]=8'h04; rom_mem[985]=8'h04; rom_mem[986]=8'h04; rom_mem[987]=8'h04;
        rom_mem[988]=8'h04; rom_mem[989]=8'h04; rom_mem[990]=8'h7C; rom_mem[991]=8'h00;

        // ASCII 94: ^
        rom_mem[992]=8'h10; rom_mem[993]=8'h28; rom_mem[994]=8'h44; rom_mem[995]=8'h00;
        rom_mem[996]=8'h00; rom_mem[997]=8'h00; rom_mem[998]=8'h00; rom_mem[999]=8'h00;
        rom_mem[1000]=8'h00; rom_mem[1001]=8'h00; rom_mem[1002]=8'h00; rom_mem[1003]=8'h00;
        rom_mem[1004]=8'h00; rom_mem[1005]=8'h00; rom_mem[1006]=8'h00; rom_mem[1007]=8'h00;

        // ASCII 95: _
        rom_mem[1008]=8'h00; rom_mem[1009]=8'h00; rom_mem[1010]=8'h00; rom_mem[1011]=8'h00;
        rom_mem[1012]=8'h00; rom_mem[1013]=8'h00; rom_mem[1014]=8'h00; rom_mem[1015]=8'h00;
        rom_mem[1016]=8'h00; rom_mem[1017]=8'h00; rom_mem[1018]=8'h00; rom_mem[1019]=8'h00;
        rom_mem[1020]=8'h00; rom_mem[1021]=8'h00; rom_mem[1022]=8'h00; rom_mem[1023]=8'hFF;

        // ASCII 96: `
        rom_mem[1024]=8'h20; rom_mem[1025]=8'h10; rom_mem[1026]=8'h08; rom_mem[1027]=8'h00;
        rom_mem[1028]=8'h00; rom_mem[1029]=8'h00; rom_mem[1030]=8'h00; rom_mem[1031]=8'h00;
        rom_mem[1032]=8'h00; rom_mem[1033]=8'h00; rom_mem[1034]=8'h00; rom_mem[1035]=8'h00;
        rom_mem[1036]=8'h00; rom_mem[1037]=8'h00; rom_mem[1038]=8'h00; rom_mem[1039]=8'h00;

        // ASCII 97: a
        rom_mem[1040]=8'h00; rom_mem[1041]=8'h00; rom_mem[1042]=8'h00; rom_mem[1043]=8'h00;
        rom_mem[1044]=8'h00; rom_mem[1045]=8'h00; rom_mem[1046]=8'h78; rom_mem[1047]=8'h84;
        rom_mem[1048]=8'h04; rom_mem[1049]=8'h3C; rom_mem[1050]=8'h44; rom_mem[1051]=8'h84;
        rom_mem[1052]=8'h8C; rom_mem[1053]=8'h76; rom_mem[1054]=8'h00; rom_mem[1055]=8'h00;

        // ASCII 98: b
        rom_mem[1056]=8'h00; rom_mem[1057]=8'h80; rom_mem[1058]=8'h80; rom_mem[1059]=8'h80;
        rom_mem[1060]=8'h80; rom_mem[1061]=8'h80; rom_mem[1062]=8'hB8; rom_mem[1063]=8'hC4;
        rom_mem[1064]=8'h82; rom_mem[1065]=8'h82; rom_mem[1066]=8'h82; rom_mem[1067]=8'h82;
        rom_mem[1068]=8'hC4; rom_mem[1069]=8'hB8; rom_mem[1070]=8'h00; rom_mem[1071]=8'h00;

        // ASCII 99: c
        rom_mem[1072]=8'h00; rom_mem[1073]=8'h00; rom_mem[1074]=8'h00; rom_mem[1075]=8'h00;
        rom_mem[1076]=8'h00; rom_mem[1077]=8'h00; rom_mem[1078]=8'h3C; rom_mem[1079]=8'h42;
        rom_mem[1080]=8'h80; rom_mem[1081]=8'h80; rom_mem[1082]=8'h80; rom_mem[1083]=8'h80;
        rom_mem[1084]=8'h42; rom_mem[1085]=8'h3C; rom_mem[1086]=8'h00; rom_mem[1087]=8'h00;

        // ASCII 100: d
        rom_mem[1088]=8'h00; rom_mem[1089]=8'h02; rom_mem[1090]=8'h02; rom_mem[1091]=8'h02;
        rom_mem[1092]=8'h02; rom_mem[1093]=8'h02; rom_mem[1094]=8'h3A; rom_mem[1095]=8'h46;
        rom_mem[1096]=8'h82; rom_mem[1097]=8'h82; rom_mem[1098]=8'h82; rom_mem[1099]=8'h82;
        rom_mem[1100]=8'h46; rom_mem[1101]=8'h3A; rom_mem[1102]=8'h00; rom_mem[1103]=8'h00;

        // ASCII 101: e
        rom_mem[1104]=8'h00; rom_mem[1105]=8'h00; rom_mem[1106]=8'h00; rom_mem[1107]=8'h00;
        rom_mem[1108]=8'h00; rom_mem[1109]=8'h00; rom_mem[1110]=8'h38; rom_mem[1111]=8'h44;
        rom_mem[1112]=8'h82; rom_mem[1113]=8'hFE; rom_mem[1114]=8'h80; rom_mem[1115]=8'h80;
        rom_mem[1116]=8'h42; rom_mem[1117]=8'h3C; rom_mem[1118]=8'h00; rom_mem[1119]=8'h00;

        // ASCII 102: f
        rom_mem[1120]=8'h00; rom_mem[1121]=8'h18; rom_mem[1122]=8'h20; rom_mem[1123]=8'h20;
        rom_mem[1124]=8'h20; rom_mem[1125]=8'h20; rom_mem[1126]=8'hF8; rom_mem[1127]=8'h20;
        rom_mem[1128]=8'h20; rom_mem[1129]=8'h20; rom_mem[1130]=8'h20; rom_mem[1131]=8'h20;
        rom_mem[1132]=8'h20; rom_mem[1133]=8'h20; rom_mem[1134]=8'h00; rom_mem[1135]=8'h00;

        // ASCII 103: g
        rom_mem[1136]=8'h00; rom_mem[1137]=8'h00; rom_mem[1138]=8'h00; rom_mem[1139]=8'h00;
        rom_mem[1140]=8'h00; rom_mem[1141]=8'h00; rom_mem[1142]=8'h3A; rom_mem[1143]=8'h44;
        rom_mem[1144]=8'h44; rom_mem[1145]=8'h38; rom_mem[1146]=8'h40; rom_mem[1147]=8'h7C;
        rom_mem[1148]=8'h82; rom_mem[1149]=8'h82; rom_mem[1150]=8'h7C; rom_mem[1151]=8'h00;

        // ASCII 104: h
        rom_mem[1152]=8'h00; rom_mem[1153]=8'h80; rom_mem[1154]=8'h80; rom_mem[1155]=8'h80;
        rom_mem[1156]=8'h80; rom_mem[1157]=8'h80; rom_mem[1158]=8'hB8; rom_mem[1159]=8'hC4;
        rom_mem[1160]=8'h82; rom_mem[1161]=8'h82; rom_mem[1162]=8'h82; rom_mem[1163]=8'h82;
        rom_mem[1164]=8'h82; rom_mem[1165]=8'h82; rom_mem[1166]=8'h00; rom_mem[1167]=8'h00;

        // ASCII 105: i
        rom_mem[1168]=8'h00; rom_mem[1169]=8'h00; rom_mem[1170]=8'h10; rom_mem[1171]=8'h10;
        rom_mem[1172]=8'h00; rom_mem[1173]=8'h00; rom_mem[1174]=8'h10; rom_mem[1175]=8'h10;
        rom_mem[1176]=8'h10; rom_mem[1177]=8'h10; rom_mem[1178]=8'h10; rom_mem[1179]=8'h10;
        rom_mem[1180]=8'h10; rom_mem[1181]=8'h10; rom_mem[1182]=8'h00; rom_mem[1183]=8'h00;

        // ASCII 106: j
        rom_mem[1184]=8'h00; rom_mem[1185]=8'h00; rom_mem[1186]=8'h10; rom_mem[1187]=8'h10;
        rom_mem[1188]=8'h00; rom_mem[1189]=8'h00; rom_mem[1190]=8'h10; rom_mem[1191]=8'h10;
        rom_mem[1192]=8'h10; rom_mem[1193]=8'h10; rom_mem[1194]=8'h10; rom_mem[1195]=8'h10;
        rom_mem[1196]=8'h10; rom_mem[1197]=8'h10; rom_mem[1198]=8'h60; rom_mem[1199]=8'h00;

        // ASCII 107: k
        rom_mem[1200]=8'h00; rom_mem[1201]=8'h80; rom_mem[1202]=8'h80; rom_mem[1203]=8'h80;
        rom_mem[1204]=8'h80; rom_mem[1205]=8'h80; rom_mem[1206]=8'h84; rom_mem[1207]=8'h88;
        rom_mem[1208]=8'h90; rom_mem[1209]=8'hA0; rom_mem[1210]=8'hD0; rom_mem[1211]=8'h88;
        rom_mem[1212]=8'h84; rom_mem[1213]=8'h82; rom_mem[1214]=8'h00; rom_mem[1215]=8'h00;

        // ASCII 108: l
        rom_mem[1216]=8'h00; rom_mem[1217]=8'h10; rom_mem[1218]=8'h10; rom_mem[1219]=8'h10;
        rom_mem[1220]=8'h10; rom_mem[1221]=8'h10; rom_mem[1222]=8'h10; rom_mem[1223]=8'h10;
        rom_mem[1224]=8'h10; rom_mem[1225]=8'h10; rom_mem[1226]=8'h10; rom_mem[1227]=8'h10;
        rom_mem[1228]=8'h10; rom_mem[1229]=8'h10; rom_mem[1230]=8'h00; rom_mem[1231]=8'h00;

        // ASCII 109: m
        rom_mem[1232]=8'h00; rom_mem[1233]=8'h00; rom_mem[1234]=8'h00; rom_mem[1235]=8'h00;
        rom_mem[1236]=8'h00; rom_mem[1237]=8'h00; rom_mem[1238]=8'hAC; rom_mem[1239]=8'hD2;
        rom_mem[1240]=8'h92; rom_mem[1241]=8'h92; rom_mem[1242]=8'h92; rom_mem[1243]=8'h92;
        rom_mem[1244]=8'h92; rom_mem[1245]=8'h92; rom_mem[1246]=8'h00; rom_mem[1247]=8'h00;

        // ASCII 110: n
        rom_mem[1248]=8'h00; rom_mem[1249]=8'h00; rom_mem[1250]=8'h00; rom_mem[1251]=8'h00;
        rom_mem[1252]=8'h00; rom_mem[1253]=8'h00; rom_mem[1254]=8'hB8; rom_mem[1255]=8'hC4;
        rom_mem[1256]=8'h82; rom_mem[1257]=8'h82; rom_mem[1258]=8'h82; rom_mem[1259]=8'h82;
        rom_mem[1260]=8'h82; rom_mem[1261]=8'h82; rom_mem[1262]=8'h00; rom_mem[1263]=8'h00;

        // ASCII 111: o
        rom_mem[1264]=8'h00; rom_mem[1265]=8'h00; rom_mem[1266]=8'h00; rom_mem[1267]=8'h00;
        rom_mem[1268]=8'h00; rom_mem[1269]=8'h00; rom_mem[1270]=8'h38; rom_mem[1271]=8'h44;
        rom_mem[1272]=8'h82; rom_mem[1273]=8'h82; rom_mem[1274]=8'h82; rom_mem[1275]=8'h82;
        rom_mem[1276]=8'h44; rom_mem[1277]=8'h38; rom_mem[1278]=8'h00; rom_mem[1279]=8'h00;

        // ASCII 112: p
        rom_mem[1280]=8'h00; rom_mem[1281]=8'h00; rom_mem[1282]=8'h00; rom_mem[1283]=8'h00;
        rom_mem[1284]=8'h00; rom_mem[1285]=8'h00; rom_mem[1286]=8'hB8; rom_mem[1287]=8'hC4;
        rom_mem[1288]=8'h82; rom_mem[1289]=8'h82; rom_mem[1290]=8'h82; rom_mem[1291]=8'hC4;
        rom_mem[1292]=8'hB8; rom_mem[1293]=8'h80; rom_mem[1294]=8'h80; rom_mem[1295]=8'h00;

        // ASCII 113: q
        rom_mem[1296]=8'h00; rom_mem[1297]=8'h00; rom_mem[1298]=8'h00; rom_mem[1299]=8'h00;
        rom_mem[1300]=8'h00; rom_mem[1301]=8'h00; rom_mem[1302]=8'h3A; rom_mem[1303]=8'h46;
        rom_mem[1304]=8'h82; rom_mem[1305]=8'h82; rom_mem[1306]=8'h82; rom_mem[1307]=8'h46;
        rom_mem[1308]=8'h3A; rom_mem[1309]=8'h02; rom_mem[1310]=8'h02; rom_mem[1311]=8'h00;

        // ASCII 114: r
        rom_mem[1312]=8'h00; rom_mem[1313]=8'h00; rom_mem[1314]=8'h00; rom_mem[1315]=8'h00;
        rom_mem[1316]=8'h00; rom_mem[1317]=8'h00; rom_mem[1318]=8'h2E; rom_mem[1319]=8'h30;
        rom_mem[1320]=8'h20; rom_mem[1321]=8'h20; rom_mem[1322]=8'h20; rom_mem[1323]=8'h20;
        rom_mem[1324]=8'h20; rom_mem[1325]=8'h20; rom_mem[1326]=8'h00; rom_mem[1327]=8'h00;

        // ASCII 115: s
        rom_mem[1328]=8'h00; rom_mem[1329]=8'h00; rom_mem[1330]=8'h00; rom_mem[1331]=8'h00;
        rom_mem[1332]=8'h00; rom_mem[1333]=8'h00; rom_mem[1334]=8'h7C; rom_mem[1335]=8'h82;
        rom_mem[1336]=8'h80; rom_mem[1337]=8'h60; rom_mem[1338]=8'h1C; rom_mem[1339]=8'h02;
        rom_mem[1340]=8'h82; rom_mem[1341]=8'h7C; rom_mem[1342]=8'h00; rom_mem[1343]=8'h00;

        // ASCII 116: t
        rom_mem[1344]=8'h00; rom_mem[1345]=8'h00; rom_mem[1346]=8'h20; rom_mem[1347]=8'h20;
        rom_mem[1348]=8'h20; rom_mem[1349]=8'h20; rom_mem[1350]=8'hF8; rom_mem[1351]=8'h20;
        rom_mem[1352]=8'h20; rom_mem[1353]=8'h20; rom_mem[1354]=8'h20; rom_mem[1355]=8'h20;
        rom_mem[1356]=8'h20; rom_mem[1357]=8'h18; rom_mem[1358]=8'h00; rom_mem[1359]=8'h00;

        // ASCII 117: u
        rom_mem[1360]=8'h00; rom_mem[1361]=8'h00; rom_mem[1362]=8'h00; rom_mem[1363]=8'h00;
        rom_mem[1364]=8'h00; rom_mem[1365]=8'h00; rom_mem[1366]=8'h82; rom_mem[1367]=8'h82;
        rom_mem[1368]=8'h82; rom_mem[1369]=8'h82; rom_mem[1370]=8'h82; rom_mem[1371]=8'h82;
        rom_mem[1372]=8'h46; rom_mem[1373]=8'h3A; rom_mem[1374]=8'h00; rom_mem[1375]=8'h00;

        // ASCII 118: v
        rom_mem[1376]=8'h00; rom_mem[1377]=8'h00; rom_mem[1378]=8'h00; rom_mem[1379]=8'h00;
        rom_mem[1380]=8'h00; rom_mem[1381]=8'h00; rom_mem[1382]=8'h82; rom_mem[1383]=8'h82;
        rom_mem[1384]=8'h44; rom_mem[1385]=8'h44; rom_mem[1386]=8'h28; rom_mem[1387]=8'h28;
        rom_mem[1388]=8'h10; rom_mem[1389]=8'h10; rom_mem[1390]=8'h00; rom_mem[1391]=8'h00;

        // ASCII 119: w
        rom_mem[1392]=8'h00; rom_mem[1393]=8'h00; rom_mem[1394]=8'h00; rom_mem[1395]=8'h00;
        rom_mem[1396]=8'h00; rom_mem[1397]=8'h00; rom_mem[1398]=8'h92; rom_mem[1399]=8'h92;
        rom_mem[1400]=8'h92; rom_mem[1401]=8'hAA; rom_mem[1402]=8'hAA; rom_mem[1403]=8'h44;
        rom_mem[1404]=8'h44; rom_mem[1405]=8'h44; rom_mem[1406]=8'h00; rom_mem[1407]=8'h00;

        // ASCII 120: x
        rom_mem[1408]=8'h00; rom_mem[1409]=8'h00; rom_mem[1410]=8'h00; rom_mem[1411]=8'h00;
        rom_mem[1412]=8'h00; rom_mem[1413]=8'h00; rom_mem[1414]=8'h82; rom_mem[1415]=8'h44;
        rom_mem[1416]=8'h28; rom_mem[1417]=8'h10; rom_mem[1418]=8'h10; rom_mem[1419]=8'h28;
        rom_mem[1420]=8'h44; rom_mem[1421]=8'h82; rom_mem[1422]=8'h00; rom_mem[1423]=8'h00;

        // ASCII 121: y
        rom_mem[1424]=8'h00; rom_mem[1425]=8'h00; rom_mem[1426]=8'h00; rom_mem[1427]=8'h00;
        rom_mem[1428]=8'h00; rom_mem[1429]=8'h00; rom_mem[1430]=8'h82; rom_mem[1431]=8'h82;
        rom_mem[1432]=8'h44; rom_mem[1433]=8'h44; rom_mem[1434]=8'h28; rom_mem[1435]=8'h28;
        rom_mem[1436]=8'h10; rom_mem[1437]=8'h20; rom_mem[1438]=8'hC0; rom_mem[1439]=8'h00;

        // ASCII 122: z
        rom_mem[1440]=8'h00; rom_mem[1441]=8'h00; rom_mem[1442]=8'h00; rom_mem[1443]=8'h00;
        rom_mem[1444]=8'h00; rom_mem[1445]=8'h00; rom_mem[1446]=8'hFE; rom_mem[1447]=8'h04;
        rom_mem[1448]=8'h08; rom_mem[1449]=8'h10; rom_mem[1450]=8'h20; rom_mem[1451]=8'h40;
        rom_mem[1452]=8'h80; rom_mem[1453]=8'hFE; rom_mem[1454]=8'h00; rom_mem[1455]=8'h00;

        // ASCII 123: {
        rom_mem[1456]=8'h1C; rom_mem[1457]=8'h10; rom_mem[1458]=8'h10; rom_mem[1459]=8'h10;
        rom_mem[1460]=8'h10; rom_mem[1461]=8'h10; rom_mem[1462]=8'h10; rom_mem[1463]=8'h20;
        rom_mem[1464]=8'h10; rom_mem[1465]=8'h10; rom_mem[1466]=8'h10; rom_mem[1467]=8'h10;
        rom_mem[1468]=8'h10; rom_mem[1469]=8'h10; rom_mem[1470]=8'h1C; rom_mem[1471]=8'h00;

        // ASCII 124: |
        rom_mem[1472]=8'h10; rom_mem[1473]=8'h10; rom_mem[1474]=8'h10; rom_mem[1475]=8'h10;
        rom_mem[1476]=8'h10; rom_mem[1477]=8'h10; rom_mem[1478]=8'h10; rom_mem[1479]=8'h10;
        rom_mem[1480]=8'h10; rom_mem[1481]=8'h10; rom_mem[1482]=8'h10; rom_mem[1483]=8'h10;
        rom_mem[1484]=8'h10; rom_mem[1485]=8'h10; rom_mem[1486]=8'h10; rom_mem[1487]=8'h10;

        // ASCII 125: }
        rom_mem[1488]=8'h70; rom_mem[1489]=8'h10; rom_mem[1490]=8'h10; rom_mem[1491]=8'h10;
        rom_mem[1492]=8'h10; rom_mem[1493]=8'h10; rom_mem[1494]=8'h10; rom_mem[1495]=8'h08;
        rom_mem[1496]=8'h10; rom_mem[1497]=8'h10; rom_mem[1498]=8'h10; rom_mem[1499]=8'h10;
        rom_mem[1500]=8'h10; rom_mem[1501]=8'h10; rom_mem[1502]=8'h70; rom_mem[1503]=8'h00;

        // ASCII 126: ~
        rom_mem[1504]=8'h64; rom_mem[1505]=8'h98; rom_mem[1506]=8'h00; rom_mem[1507]=8'h00;
        rom_mem[1508]=8'h00; rom_mem[1509]=8'h00; rom_mem[1510]=8'h00; rom_mem[1511]=8'h00;
        rom_mem[1512]=8'h00; rom_mem[1513]=8'h00; rom_mem[1514]=8'h00; rom_mem[1515]=8'h00;
        rom_mem[1516]=8'h00; rom_mem[1517]=8'h00; rom_mem[1518]=8'h00; rom_mem[1519]=8'h00;

        // Filler
        rom_mem[1520]=8'h00; rom_mem[1521]=8'h00; rom_mem[1522]=8'h00; rom_mem[1523]=8'h00;
        rom_mem[1524]=8'h00; rom_mem[1525]=8'h00; rom_mem[1526]=8'h00; rom_mem[1527]=8'h00;
        rom_mem[1528]=8'h00; rom_mem[1529]=8'h00; rom_mem[1530]=8'h00; rom_mem[1531]=8'h00;
        rom_mem[1532]=8'h00; rom_mem[1533]=8'h00; rom_mem[1534]=8'h00; rom_mem[1535]=8'h00;

    end

endmodule