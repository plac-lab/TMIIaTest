`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/20/2017 09:46:54 PM
// Design Name: 
// Module Name: fifo2shiftreg_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo2shiftreg_tb #(parameter WIDTH=32,
                          parameter CLK_DIV=2)();
reg CLK;
reg RESET;
reg WR_CLK;
reg [15:0] DIN;
reg WR_EN;
reg WR_PULSE;
wire FULL;
wire SCLK;
wire DOUT;
wire SYNCn;
                          
fifo2shiftreg #(.WIDTH(WIDTH), .CLK_DIV(CLK_DIV))
  uut(
    .CLK(CLK),             // clock
    .RESET(RESET),         // reset
    // input data interface
    .WR_CLK(WR_CLK),       // FIFO write clock
    .DIN(DIN),
    .WR_EN(WR_EN),
    .WR_PULSE(WR_PULSE),   // one pulse writes one word, regardless of pulse duration
    .FULL(FULL),
    // output
    .SCLK(SCLK),
    .DOUT(DOUT),
    .SYNCn(SYNCn)
  );

//initial begin
//$dumpfile("fifo2shiftreg.dump");
//$dumpvars(0, fifo2shiftreg);
//end

initial begin
CLK=0;
forever #20 CLK=~CLK;
end

initial begin 
WR_CLK=0;
forever #20 WR_CLK=~WR_CLK;
end

initial begin
RESET=0;
WR_EN=0;
#100 RESET=1;
#100 RESET=0;
end

initial begin
DIN=16'b1101_0100_1011_1001;
WR_PULSE=0;
#340 WR_PULSE=1;
#40 WR_PULSE=0;
#40 DIN=16'b1101_0101_1011_1001;
#40 WR_PULSE=1;
#40 WR_PULSE=0;
#40 DIN=16'b1101_0101_1011_1011;
#11960 WR_PULSE=1;
#40 WR_PULSE=0;
#40 DIN=16'b1101_0101_1001_1011;
#40 WR_PULSE=1;
#40 WR_PULSE=0;
end

endmodule
