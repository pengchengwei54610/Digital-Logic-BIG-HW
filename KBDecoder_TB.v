`timescale 1ns/1ps
`define clktemp 200

module KBDecoderTestBench;
reg CLK, ARST_L, SDATA;
wire KEYUP, rollover;
wire [3:0] HEX0, HEX1;
reg [21:0] in_seq;
wire [4:0] SREG;

KBDecoder DUT(.CLK(CLK), .ARST_L(ARST_L), .SDATA(SDATA), .KEYUP(KEYUP), .HEX0(HEX0), .HEX1(HEX1), .SREG(SREG), .rollover_i(rollover));

initial in_seq <= 22'b1100000100111111100001;    

initial CLK <= 1'b0;
always  #`clktemp CLK <= ~CLK;                

initial
begin
  ARST_L <= 1'b0;    
  #25 ARST_L <= 1'b1; 
end

always @(posedge CLK)
  if(ARST_L == 1'b0)
    SDATA <= #1 1'b0;
  else
    SDATA <= #1 in_seq[0];

always @(posedge CLK)
  if(ARST_L == 1'b0)
    in_seq <= #1 in_seq;
  else
    in_seq <= #1 {1'b0, in_seq[21:1]};

endmodule