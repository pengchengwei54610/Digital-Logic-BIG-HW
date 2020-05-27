`timescale 1ns / 1ps
//将按钮按下作为信号并释放单个脉冲
//对于每一个按下的按钮，都会反跳。
module SwitchDB(
input CLK,//4倍分频后时钟
input SW,//是否读取到键的信息，1为读取到
input ACLR_L,//控制信号
output reg SWDB//去抖信号
);

wire aclr_i;
reg [1:0] Q_CURR;//状态机的状态
parameter [1:0] SW_OFF = 2'b00; //状态机定义
parameter [1:0] SW_EDGE = 2'b01;
parameter [1:0] SW_VERF = 2'b10;
parameter [1:0] SW_HOLD = 2'b11;
assign aclr_i = ~ACLR_L;

//状态转移
always @(posedge CLK or posedge aclr_i) begin
    SWDB <= 1'b0;   //默认为0

    if(aclr_i) begin
        Q_CURR <= SW_OFF;
    end
    else begin
        case(Q_CURR)   
            SW_OFF: if(SW) begin
                        Q_CURR <= SW_EDGE;
                    end
                    else begin
                        Q_CURR <= SW_OFF;
                    end
                    
            SW_EDGE: if(SW) begin
                        Q_CURR <= SW_VERF;
                        SWDB <= 1'b1;   //去抖信号仅在当前状态为SW_VERF时为高
                     end
                     else begin
                        Q_CURR <= SW_OFF;
                     end
                     
             SW_VERF: Q_CURR <= SW_HOLD;
                      
             SW_HOLD: if(SW) begin
                          Q_CURR <= SW_HOLD;
                      end
                      else begin
                          Q_CURR <= SW_OFF;
                      end
        endcase              
    end
end
endmodule
