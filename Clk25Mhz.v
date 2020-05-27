`timescale 1ns / 1ps
//分频4倍得到一个25mhz的时钟
module Clk25Mhz(
    input CLKIN,//原时钟
    input ACLR_L,//控制开关
    output reg CLKOUT//分频后时钟
    );
    
reg SREG;    
wire aclr_i;
assign aclr_i = ~ACLR_L;

//两次分频达到4倍分频的效果，一旦控制开关置0即僵尸中时钟重置
always @(posedge CLKIN or posedge aclr_i) begin
    if(aclr_i) begin
        SREG <= 1'b0;
    end
    else begin
        SREG <= ~SREG;
    end
end

//Output clock generation, divide by 4
always @(posedge CLKIN or posedge aclr_i) begin
    if(aclr_i) begin
        CLKOUT <= 1'b0;
    end
    else if(SREG) begin
        CLKOUT <= ~CLKOUT;
    end
end

endmodule
