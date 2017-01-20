`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2017 08:42:46 PM
// Design Name: 
// Module Name: pulse_synchronise_tb
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


module pulse_synchronise_tb();

 reg clk_in;
 reg clk_out;
 reg pulse_in;
 reg rst;
 wire pulse_out;
 
 pulse_synchronise DUT0(
     .clk_in(clk_in),
     .clk_out(clk_out),
     .rst(rst),
     .pulse_in(pulse_in),
     .pulse_out(pulse_out)
     );
 initial begin
  $dumpfile("snychronise.dump");
  $dumpvars(0,pulse_synchronise);
 end
 
 initial begin
  clk_in=0;
  repeat(200) #10 clk_in=~clk_in;
  repeat(100) #20 clk_in=~clk_in;
 end
 
 initial begin
  clk_out=0;
  repeat(100) #20 clk_out=~clk_out;
  repeat(200) #10 clk_out=~clk_out;
 end
 
 initial begin
 rst=1;
 #50 rst=0;
 end
 
 initial begin
  pulse_in=0;
  #110 pulse_in=1;
  #20 pulse_in=0;
  #260 pulse_in=1;
  #20 pulse_in=0;
  #1650 pulse_in=1;
  #40 pulse_in=0;
  #200 pulse_in=1;
  #40 pulse_in=0;
  end

endmodule
