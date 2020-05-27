`timescale 1ns / 1ps
//实现了一个移位寄存器来保存22位数据，
//根据移位寄存器的某些位输出两个十六进制值，
//从KB移入SDATA并在读取" F0"时发出选通信号
module KBDecoder(
    input CLK,//同步后usb信号
    input SDATA,//同步后usb数据
    input ARST_L,//控制信号
    output [3:0] HEX0,//16进制键码
    output [3:0] HEX1,//16进制键码
    output reg KEYUP//返回是否读取到键的信息，1为读取到
    );
    
wire arst_i, rollover_i;
reg [21:0] Shift;

assign arst_i = ~ARST_L;
// 从移位寄存器中不停取值
assign HEX0[3:0] = Shift[15:12];
assign HEX1[3:0] = Shift[19:16];

// 移入一次需要22个同步后的时钟周期（按下与放开各11个，信息为FOXX,XX为按下键的键码）
always @(negedge CLK or posedge arst_i) begin;
    if(arst_i)begin
        Shift <= 22'b0000000000000000000000;
    end
    else begin
        Shift <= {SDATA, Shift[21:1]}; //从最后一位移入
    end
end

//找到F0即代表找到了一个码，发送一个1的值
always @(posedge CLK) begin
    if(Shift[8:1] == 8'hF0) begin
        KEYUP <= 1'b1;
    end
    else begin
        KEYUP <= 1'b0;
    end    
end    

endmodule
