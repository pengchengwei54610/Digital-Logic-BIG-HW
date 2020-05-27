`timescale 1ns / 1ps
//将异步信号同步
module Sync2(
    input CLK,//原时钟
    input ASYNC,//usb时钟或usb数据
    input ACLR_L,//
    output SYNC//与原时钟同步的信号或数据
    );
    
reg [1:0] SREG;
wire aclr_i;

assign aclr_i = ~ACLR_L; 
assign SYNC = SREG[1];

//用两个D触发器将异步信号转为同步信号，即将原时钟和usb时钟或usb数据同步
always @(posedge CLK or posedge aclr_i) begin        
        if(aclr_i) begin
            SREG <= 2'b00;
        end
        else begin
            SREG[0] <= ASYNC;//usb当前信号或数据
            SREG[1] <= SREG[0];//上一个原时钟下降沿时usb信号或数据
        end
end
   
endmodule
