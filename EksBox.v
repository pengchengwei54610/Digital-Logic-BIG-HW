`timescale 1ns / 1ps
//顶层模块
module EksBox(
    input CLK,//输入的原时钟
    input ARST_L,//控制信号，switch[15]为高电平时游戏运行
    input SCLK,//usb时钟
    input SDATA,//usb数据
    output HSYNC,//帧同步信号
    output VSYNC,//行同步信号
    output [3:0] RED,//输出红色
    output [3:0] GREEN,//输出绿色
    output [3:0] BLUE,//输出蓝色
    output kbstrobe_i//去抖信号
    );
    
wire clk25mhz_i, synctop_i, syncbot_i, keyup_i;//4倍分频后时钟，同步后的usb信号，同步后的usb数据，是否读取到键的信息（1为读取到）
wire [3:0] hex1_i, hex0_i;//16进制键码高位，16进制键码低位
wire [9:0] hcoord_i, vcoord_i;//帧坐标，行坐标
wire [11:0] csel_i; //颜色r,g,b值
    
Sync2           U1 (.CLK(CLK), .ASYNC(SCLK), .ACLR_L(ARST_L), .SYNC(synctop_i));
Sync2           U2 (.CLK(CLK), .ASYNC(SDATA), .ACLR_L(ARST_L), .SYNC(syncbot_i));
Clk25Mhz        U3 (.CLKIN(CLK), .ACLR_L(ARST_L), .CLKOUT(clk25mhz_i));
KBDecoder       U4 (.CLK(synctop_i), .SDATA(syncbot_i), .ARST_L(ARST_L), .HEX1(hex1_i), .HEX0(hex0_i), .KEYUP(keyup_i));
SwitchDB        U5 (.CLK(clk25mhz_i), .SW(keyup_i), .ACLR_L(ARST_L), .SWDB(kbstrobe_i));
VGAController   U6 (.CLK(clk25mhz_i), .KBCODE({hex1_i, hex0_i}), .HCOORD(hcoord_i), .VCOORD(vcoord_i), .KBSTROBE(kbstrobe_i), .ARST_L(ARST_L), .CSEL(csel_i));
VGAEncoder      U7 (.CLK(clk25mhz_i), .CSEL(csel_i), .ARST_L(ARST_L), .HSYNC(HSYNC), .VSYNC(VSYNC), .RED(RED), .GREEN(GREEN), .BLUE(BLUE), .HCOORD(hcoord_i), .VCOORD(vcoord_i));
    
endmodule
