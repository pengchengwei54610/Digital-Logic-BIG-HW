`timescale 1ns / 1ps
//控制何时显示什么颜色
//处理青蛙的位置以及必要的计数器和命中检测
module VGAController(
    input CLK,//4倍分频后时钟
    input [7:0] KBCODE,//按下键的键值
    input [9:0] HCOORD,//横坐标
    input [9:0] VCOORD,//纵坐标
    input KBSTROBE,//去抖信号
    input ARST_L,//控制信号
    output reg [11:0] CSEL,//rgb值，可任意改
    output rollover_i,
    output reg [9:0] XPos, 
    output reg [9:0] YPos,
    output reg [3:0] XSpeed,
    output reg [3:0] YSpeed,
    output reg [17:0] SREG
    );
 
wire arst_i, left_hit_i, right_hit_i, top_hit_i, bot_hit_i, advance_i, YDirection, barrier1hit_i, barrier2hit_2, barrier3hit_i, hitbarrier_i, win_rollover_i;
reg [9:0] Barrier1XPos, Barrier1YPos, Barrier2XPos, Barrier2YPos, Barrier3XPos, Barrier3YPos, Barrier4XPos, Barrier4YPos, Barrier5XPos, Barrier5YPos, Barrier6XPos, Barrier6YPos;
wire [9:0] temp1_i, temp2_i, temp3_i, temp4_i, temp5_i, temp6_i, wave_tide_i;
reg [3:0] WinCount;//障碍物等级
reg [7:0] WaveCount;
reg TurnGold;

// 保存青蛙成功到达时右侧保存青蛙的坐标值，最高等级为12
parameter SAVED_FROG_YCOORD_1 = 40;
parameter SAVED_FROG_YCOORD_2 = 80;
parameter SAVED_FROG_YCOORD_3 = 120;
parameter SAVED_FROG_YCOORD_4 = 160;
parameter SAVED_FROG_YCOORD_5 = 200;
parameter SAVED_FROG_YCOORD_6 = 240;
parameter SAVED_FROG_YCOORD_7 = 280;
parameter SAVED_FROG_YCOORD_8 = 320;
parameter SAVED_FROG_YCOORD_9 = 360;
parameter SAVED_FROG_YCOORD_10 = 400;
parameter SAVED_FROG_YCOORD_11 = 440;
parameter SAVED_FROG_XCOORD = 612;

assign arst_i = ~ARST_L;
assign rollover_i = (SREG == 250000) ? 1'b1 : 1'b0;
assign left_hit_i = (XPos < 5) ? 1'b1 : 1'b0;//左端到达边界
assign right_hit_i = (XPos > 634) ? 1'b1 : 1'b0;//右端到达边界
assign top_hit_i = (YPos < 5) ? 1'b1 : 1'b0;//下端到达边界
assign bot_hit_i = (YPos > 474) ? 1'b1 : 1'b0;//上端到达边界
assign advance_i = (XPos > wave_tide_i) ? 1'b1 : 1'b0;//是否到达水边
assign YDirection = ~YSpeed[3];
assign temp1_i = (Barrier1YPos < 201) ? 0 : Barrier1YPos - 200; // 允许6辆卡车滚出屏幕而不是在一端碰到屏幕就完全消失
assign temp2_i = (Barrier2YPos < 201) ? 0 : Barrier2YPos - 200; 
assign temp3_i = (Barrier3YPos < 201) ? 0 : Barrier3YPos - 200;
assign temp4_i = (Barrier4YPos < 201) ? 0 : Barrier4YPos - 200;
assign temp5_i = (Barrier5YPos < 201) ? 0 : Barrier5YPos - 200;
assign temp6_i = (Barrier6YPos < 201) ? 0 : Barrier6YPos - 200;
//监视青蛙和卡车的碰撞
assign barrier1hit = ((XPos > Barrier1XPos - 10)&&(XPos < Barrier1XPos + 10)&&(YPos > temp1_i)&&(YPos < Barrier1YPos)) ? 1'b1 : 1'b0;
assign barrier2hit = ((XPos > Barrier2XPos - 10)&&(XPos < Barrier2XPos + 10)&&(YPos > temp2_i)&&(YPos < Barrier2YPos)) ? 1'b1 : 1'b0;
assign barrier3hit = ((XPos > Barrier3XPos - 10)&&(XPos < Barrier3XPos + 10)&&(YPos > temp3_i)&&(YPos < Barrier3YPos)) ? 1'b1 : 1'b0;
assign barrier4hit = ((XPos > Barrier4XPos - 10)&&(XPos < Barrier4XPos + 10)&&(YPos > temp4_i)&&(YPos < Barrier4YPos)) ? 1'b1 : 1'b0;
assign barrier5hit = ((XPos > Barrier5XPos - 10)&&(XPos < Barrier5XPos + 10)&&(YPos > temp5_i)&&(YPos < Barrier5YPos)) ? 1'b1 : 1'b0;
assign barrier6hit = ((XPos > Barrier6XPos - 10)&&(XPos < Barrier6XPos + 10)&&(YPos > temp6_i)&&(YPos < Barrier6YPos)) ? 1'b1 : 1'b0;
assign hitbarrier_i = (barrier1hit||barrier2hit||barrier3hit||barrier4hit||barrier5hit||barrier6hit) ? 1'b1 : 1'b0;
assign wave_tide_i = (WaveCount[7]) ? 577 : 573;
assign win_rollover_i = (WinCount == 12) ? 1'b1 : 1'b0;

//完成所有部件的着色，通过改变csel的
// by changing the current output of CSEL
always @(posedge CLK or posedge arst_i) begin
    if(arst_i)
        CSEL <= 12'h000;
    else if(((HCOORD > XPos - 5)&&(HCOORD < XPos + 5)&&(VCOORD > YPos - 4)&&(VCOORD < YPos + 4))
            ||((((HCOORD > XPos - 10)&&(HCOORD < XPos - 2))||((HCOORD > XPos + 2)&&(HCOORD < XPos + 10)))&&((VCOORD == YPos + 6)||(VCOORD == YPos - 6)))
            ||((((VCOORD > YPos + 4)&&(VCOORD < YPos + 6))||((VCOORD > YPos - 6)&&(VCOORD < YPos - 4)))&&((HCOORD == XPos + 2)||(HCOORD == XPos - 2))))
        // 画移动的青蛙和保存的青蛙，隐藏奖励为金色青蛙
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase 
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_1 - 4)&&(VCOORD < SAVED_FROG_YCOORD_1 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_1 + 6)||(VCOORD == SAVED_FROG_YCOORD_1 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_1 + 4)&&(VCOORD < SAVED_FROG_YCOORD_1 + 6))||((VCOORD > SAVED_FROG_YCOORD_1 - 6)&&(VCOORD < SAVED_FROG_YCOORD_1 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 0))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_2 - 4)&&(VCOORD < SAVED_FROG_YCOORD_2 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_2 + 6)||(VCOORD == SAVED_FROG_YCOORD_2 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_2 + 4)&&(VCOORD < SAVED_FROG_YCOORD_2 + 6))||((VCOORD > SAVED_FROG_YCOORD_2 - 6)&&(VCOORD < SAVED_FROG_YCOORD_2 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 1))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_3 - 4)&&(VCOORD < SAVED_FROG_YCOORD_3 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_3 + 6)||(VCOORD == SAVED_FROG_YCOORD_3 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_3 + 4)&&(VCOORD < SAVED_FROG_YCOORD_3 + 6))||((VCOORD > SAVED_FROG_YCOORD_3 - 6)&&(VCOORD < SAVED_FROG_YCOORD_3 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 2))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_4 - 4)&&(VCOORD < SAVED_FROG_YCOORD_4 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_4 + 6)||(VCOORD == SAVED_FROG_YCOORD_4 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_4 + 4)&&(VCOORD < SAVED_FROG_YCOORD_4 + 6))||((VCOORD > SAVED_FROG_YCOORD_4 - 6)&&(VCOORD < SAVED_FROG_YCOORD_4 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 3))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_5 - 4)&&(VCOORD < SAVED_FROG_YCOORD_5 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_5 + 6)||(VCOORD == SAVED_FROG_YCOORD_5 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_5 + 4)&&(VCOORD < SAVED_FROG_YCOORD_5 + 6))||((VCOORD > SAVED_FROG_YCOORD_5 - 6)&&(VCOORD < SAVED_FROG_YCOORD_5 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 4))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_6 - 4)&&(VCOORD < SAVED_FROG_YCOORD_6 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_6 + 6)||(VCOORD == SAVED_FROG_YCOORD_6 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_6 + 4)&&(VCOORD < SAVED_FROG_YCOORD_6 + 6))||((VCOORD > SAVED_FROG_YCOORD_6 - 6)&&(VCOORD < SAVED_FROG_YCOORD_6 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 5))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_7 - 4)&&(VCOORD < SAVED_FROG_YCOORD_7 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_7 + 6)||(VCOORD == SAVED_FROG_YCOORD_7 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_7 + 4)&&(VCOORD < SAVED_FROG_YCOORD_7 + 6))||((VCOORD > SAVED_FROG_YCOORD_7 - 6)&&(VCOORD < SAVED_FROG_YCOORD_7 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 6))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_8 - 4)&&(VCOORD < SAVED_FROG_YCOORD_8 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_8 + 6)||(VCOORD == SAVED_FROG_YCOORD_8 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_8 + 4)&&(VCOORD < SAVED_FROG_YCOORD_8 + 6))||((VCOORD > SAVED_FROG_YCOORD_8 - 6)&&(VCOORD < SAVED_FROG_YCOORD_8 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 7))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_9 - 4)&&(VCOORD < SAVED_FROG_YCOORD_9 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_9 + 6)||(VCOORD == SAVED_FROG_YCOORD_9 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_9 + 4)&&(VCOORD < SAVED_FROG_YCOORD_9 + 6))||((VCOORD > SAVED_FROG_YCOORD_9 - 6)&&(VCOORD < SAVED_FROG_YCOORD_9 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 8))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_10 - 4)&&(VCOORD < SAVED_FROG_YCOORD_10 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_10 + 6)||(VCOORD == SAVED_FROG_YCOORD_10 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_10 + 4)&&(VCOORD < SAVED_FROG_YCOORD_10 + 6))||((VCOORD > SAVED_FROG_YCOORD_10 - 6)&&(VCOORD < SAVED_FROG_YCOORD_10 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 9))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if((((HCOORD > SAVED_FROG_XCOORD - 5)&&(HCOORD < SAVED_FROG_XCOORD + 5)&&(VCOORD > SAVED_FROG_YCOORD_11 - 4)&&(VCOORD < SAVED_FROG_YCOORD_11 + 4))
            ||((((HCOORD > SAVED_FROG_XCOORD - 10)&&(HCOORD < SAVED_FROG_XCOORD - 2))||((HCOORD > SAVED_FROG_XCOORD + 2)&&(HCOORD < SAVED_FROG_XCOORD + 10)))&&((VCOORD == SAVED_FROG_YCOORD_11 + 6)||(VCOORD == SAVED_FROG_YCOORD_11 - 6)))
            ||((((VCOORD > SAVED_FROG_YCOORD_11 + 4)&&(VCOORD < SAVED_FROG_YCOORD_11 + 6))||((VCOORD > SAVED_FROG_YCOORD_11 - 6)&&(VCOORD < SAVED_FROG_YCOORD_11 - 4)))&&((HCOORD == SAVED_FROG_XCOORD + 2)||(HCOORD == SAVED_FROG_XCOORD - 2))))&&(WinCount > 10))
        case(TurnGold)
            0 : CSEL <= 12'h0F0; 
            1 : CSEL <= 12'hFF2;
        endcase
    else if(HCOORD > wave_tide_i)
        //草右边的浪，蓝色
        CSEL <= 12'h3BF;
    else if(HCOORD > 540)
        //画右侧的草，绿色
        CSEL <= 12'h2D2;
    else if((HCOORD > 310)&&(HCOORD < 320))
        //画黄色三根线
        CSEL <= 12'hFF0;
    else if((HCOORD > 135)&&(HCOORD < 145))
        CSEL <= 12'hFF0;
    else if((HCOORD > 485)&&(HCOORD < 495))
        CSEL <= 12'hFF0;
    else if((HCOORD > Barrier1XPos - 10)&&(HCOORD < Barrier1XPos + 10)&&(VCOORD > temp1_i)&&(VCOORD < Barrier1YPos))
        // 障碍物颜色根据等级来变化
        case(WinCount)
            4'b0000 : CSEL <= 12'h0F0;//绿色
            4'b0001 : CSEL <= 12'h3F0;
            4'b0010 : CSEL <= 12'h6F0;
            4'b0011 : CSEL <= 12'h9F0;
            4'b0100 : CSEL <= 12'hBF0;
            4'b0101 : CSEL <= 12'hDF0;
            4'b0110 : CSEL <= 12'hFF0;//金色
            4'b0111 : CSEL <= 12'hFC0;
            4'b1000 : CSEL <= 12'hF90;
            4'b1001 : CSEL <= 12'hF60;
            4'b1010 : CSEL <= 12'hF30;
            4'b1011 : CSEL <= 12'hF00;//红色
        endcase
    else if((HCOORD > Barrier2XPos - 10)&&(HCOORD < Barrier2XPos + 10)&&(VCOORD > temp2_i)&&(VCOORD < Barrier2YPos))
        case(WinCount)
            4'b0000 : CSEL <= 12'h0F0;
            4'b0001 : CSEL <= 12'h3F0;
            4'b0010 : CSEL <= 12'h6F0;
            4'b0011 : CSEL <= 12'h9F0;
            4'b0100 : CSEL <= 12'hBF0;
            4'b0101 : CSEL <= 12'hDF0;
            4'b0110 : CSEL <= 12'hFF0;
            4'b0111 : CSEL <= 12'hFC0;
            4'b1000 : CSEL <= 12'hF90;
            4'b1001 : CSEL <= 12'hF60;
            4'b1010 : CSEL <= 12'hF30;
            4'b1011 : CSEL <= 12'hF00;
        endcase
    else if((HCOORD > Barrier3XPos - 10)&&(HCOORD < Barrier3XPos + 10)&&(VCOORD > temp3_i)&&(VCOORD < Barrier3YPos))
        case(WinCount)
            4'b0000 : CSEL <= 12'h0F0;
            4'b0001 : CSEL <= 12'h3F0;
            4'b0010 : CSEL <= 12'h6F0;
            4'b0011 : CSEL <= 12'h9F0;
            4'b0100 : CSEL <= 12'hBF0;
            4'b0101 : CSEL <= 12'hDF0;
            4'b0110 : CSEL <= 12'hFF0;
            4'b0111 : CSEL <= 12'hFC0;
            4'b1000 : CSEL <= 12'hF90;
            4'b1001 : CSEL <= 12'hF60;
            4'b1010 : CSEL <= 12'hF30;
            4'b1011 : CSEL <= 12'hF00;
        endcase
    else if((HCOORD > Barrier4XPos - 10)&&(HCOORD < Barrier4XPos + 10)&&(VCOORD > temp4_i)&&(VCOORD < Barrier4YPos))
        case(WinCount)
            4'b0000 : CSEL <= 12'h0F0;
            4'b0001 : CSEL <= 12'h3F0;
            4'b0010 : CSEL <= 12'h6F0;
            4'b0011 : CSEL <= 12'h9F0;
            4'b0100 : CSEL <= 12'hBF0;
            4'b0101 : CSEL <= 12'hDF0;
            4'b0110 : CSEL <= 12'hFF0;
            4'b0111 : CSEL <= 12'hFC0;
            4'b1000 : CSEL <= 12'hF90;
            4'b1001 : CSEL <= 12'hF60;
            4'b1010 : CSEL <= 12'hF30;
            4'b1011 : CSEL <= 12'hF00;
        endcase
    else if((HCOORD > Barrier5XPos - 10)&&(HCOORD < Barrier5XPos + 10)&&(VCOORD > temp5_i)&&(VCOORD < Barrier5YPos))
        case(WinCount)
            4'b0000 : CSEL <= 12'h0F0;
            4'b0001 : CSEL <= 12'h3F0;
            4'b0010 : CSEL <= 12'h6F0;
            4'b0011 : CSEL <= 12'h9F0;
            4'b0100 : CSEL <= 12'hBF0;
            4'b0101 : CSEL <= 12'hDF0;
            4'b0110 : CSEL <= 12'hFF0;
            4'b0111 : CSEL <= 12'hFC0;
            4'b1000 : CSEL <= 12'hF90;
            4'b1001 : CSEL <= 12'hF60;
            4'b1010 : CSEL <= 12'hF30;
            4'b1011 : CSEL <= 12'hF00;
        endcase
    else if((HCOORD > Barrier6XPos - 10)&&(HCOORD < Barrier6XPos + 10)&&(VCOORD > temp6_i)&&(VCOORD < Barrier6YPos))
        case(WinCount)
            4'b0000 : CSEL <= 12'h0F0;
            4'b0001 : CSEL <= 12'h3F0;
            4'b0010 : CSEL <= 12'h6F0;
            4'b0011 : CSEL <= 12'h9F0;
            4'b0100 : CSEL <= 12'hBF0;
            4'b0101 : CSEL <= 12'hDF0;
            4'b0110 : CSEL <= 12'hFF0;
            4'b0111 : CSEL <= 12'hFC0;
            4'b1000 : CSEL <= 12'hF90;
            4'b1001 : CSEL <= 12'hF60;
            4'b1010 : CSEL <= 12'hF30;
            4'b1011 : CSEL <= 12'hF00;
        endcase   
    else
        //背景路面,黑色
        CSEL <= 12'h333; 
end

// 当前控制青蛙位置的处理
always @(posedge CLK or posedge arst_i) begin    
    if(arst_i) begin
        XPos <= 50;
        YPos <= 239;
    end
    else if(advance_i||hitbarrier_i) begin
        XPos <= 50;
        YPos <= 239;
    end    
    else if(rollover_i) begin
        //为了保持刷新率恒定并保持在100Hz
        //位置在刷新计数器翻转时刷新
        XPos <= XPos + XSpeed;        
        case(YDirection)
            //Y坐标移动有两个方向，而X坐标移动只有一个方向
            1'b1 : YPos <= YPos - YSpeed;
            1'b0 : YPos <= YPos + ({~YSpeed[3], ~YSpeed[2], ~YSpeed[1], ~YSpeed[0]} + 1);
        endcase
    end    
end

//卡车位置的处理
always @(posedge CLK or posedge arst_i) begin
    if(arst_i) begin
        Barrier1XPos <= 365;
        Barrier1YPos <= 200;
        Barrier2XPos <= 415;
        Barrier2YPos <= 340;
        Barrier3XPos <= 465;
        Barrier3YPos <= 480;
        Barrier4XPos <= 165;
        Barrier4YPos <= 200;
        Barrier5XPos <= 215;
        Barrier5YPos <= 340;
        Barrier6XPos <= 265;
        Barrier6YPos <= 480;
    end
    else if(rollover_i) begin
        // 设置刷新率，每个卡车的速度不同
        // updated based on both level and a "random" value of 1 or 0
        Barrier1YPos <= Barrier1YPos - (3 + (WinCount >> 1));
        Barrier2YPos <= Barrier2YPos - (2 + (WinCount >> 1));
        Barrier3YPos <= Barrier3YPos - (1 + (WinCount >> 1));
        Barrier4YPos <= Barrier4YPos + (1 + (WinCount >> 1));
        Barrier5YPos <= Barrier5YPos + (2 + (WinCount >> 1));
        Barrier6YPos <= Barrier6YPos + (3 + (WinCount >> 1));
    end      
end

//根据用户去抖处理后的值来改变青蛙的移动速度
always @(posedge CLK or posedge arst_i) begin
    if(arst_i) begin
        XSpeed <= 0;
        YSpeed <= 0;
    end 
    else if(KBSTROBE)begin
            case(KBCODE)
                // 根据输入的键码确定素的的改变
                8'h1C : begin if(XSpeed > 0)//A，向左(仅减速，无法后退)
                                XSpeed <= XSpeed - 1; end                          
                8'h23 : begin if(XSpeed < 10)//D，向右（速度上限为10）
                                XSpeed <= XSpeed + 1; end
                8'h1B : YSpeed <= YSpeed - 1;//S，向下
                8'h1D : YSpeed <= YSpeed + 1;//W，向上          
            endcase
    end
    else if(advance_i||hitbarrier_i) begin
        XSpeed <= 0;
        YSpeed <= 0;
    end   
    else if((top_hit_i && YDirection)||(bot_hit_i && !YDirection))
        //到达上下边界
        YSpeed <= 0;
end


always @(posedge CLK or posedge arst_i) begin
    // SREG使刷新率稳定在100hz
    if(arst_i)
        SREG <= 18'h00000;
    else if(rollover_i)
        SREG <= 18'h00000;
    else
        SREG <= SREG + 1;
    
    // WinCount记录了通过青蛙数
    // 死亡时减1，直到12只青蛙均保存时变金
    if(arst_i) begin
        WinCount <= 3'b000;
        TurnGold <= 1'b0;
    end
    else if(hitbarrier_i)begin
        if(WinCount>0)
            WinCount <=WinCount-1;
        else
            WinCount <= 3'b000;
    end

    else if(win_rollover_i) begin
        WinCount <= 3'b000;
        TurnGold <= 1'b1;
    end
    else if(advance_i)
        WinCount <= WinCount + 1;
    
    // 控制变化的海浪
    if(arst_i)
        WaveCount <= 3'b000;
    else if(rollover_i)
        WaveCount <= WaveCount + 1;
end 
 
endmodule