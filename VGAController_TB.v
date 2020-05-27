`timescale 1ns/1ps
`define clktemp 10

module VGAController_TB;
reg CLK, ARST_L;
wire rollover_i, aclr_i;
wire Hrollover_i, Vrollover_i;
wire [17:0] SREG;
wire [11:0] CSEL;
reg [9:0] HCOORD, VCOORD;
wire [9:0] XPos, YPos;
wire [5:0] XSpeed, YSpeed;

VGAController DUT(.CLK(CLK), .ARST_L(ARST_L), .SREG(SREG), .rollover_i(rollover_i), .HCOORD(HCOORD), .VCOORD(VCOORD), .CSEL(CSEL), .XPos(XPos), .YPos(YPos), .XSpeed(XSpeed), .YSpeed(YSpeed));
assign aclr_i = ~ARST_L;

initial CLK <= 1'b0;
always  #`clktemp CLK <= ~CLK;                
initial
begin
  ARST_L <= 1'b0;    
  #25 ARST_L <= 1'b1; 
end


assign Hrollover_i = (HCOORD[9] & HCOORD[8] & HCOORD[5]) ? 1'b1 : 1'b0;  
assign Vrollover_i = (VCOORD[9] & VCOORD[3] & VCOORD[2] & VCOORD[0]) ? 1'b1 : 1'b0;  


always @(posedge CLK or posedge aclr_i) begin
    if(aclr_i) begin
        HCOORD <= 10'b0000000000; 
    end              
    else if(Hrollover_i)
        HCOORD <= 10'b0000000000;
    else
        HCOORD <= HCOORD + 1;
end


always @(posedge CLK or posedge aclr_i) begin
    if(aclr_i) begin
        VCOORD <= 10'b0000000000; 
    end              
    else if(Vrollover_i)
        VCOORD <= 10'b0000000000;
    else if(Hrollover_i)
        VCOORD <= VCOORD + 1;
end

endmodule