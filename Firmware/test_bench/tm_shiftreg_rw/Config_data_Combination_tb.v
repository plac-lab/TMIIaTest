`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/09/2017 04:52:27 PM
// Design Name: 
// Module Name: Config_data_Combination_tb
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


module Config_data_Combination_tb#(parameter DATA_WIDTH=50, //% @ param Width of data sent TM shift register.
                                   parameter CNT_WIDTH=8, //% @param Width of internal counter.
                                   parameter TMP_WIDTH=(DATA_WIDTH/16+1)*16)();
reg clk_in,rst,pulse;
reg [15:0] data_in;
wire [DATA_WIDTH-1:0] data_out;

Config_data_Combination#(.DATA_WIDTH(DATA_WIDTH), .CNT_WIDTH(CNT_WIDTH))
 Config_Comb_DUT(
  .clk_in(clk_in), //% control clock
  .rst(rst), //% module reset
  .data_in(data_in), //% data from config_reg
  .pulse(pulse), //% pulse from pulse_reg
  .data_out(data_out) 
  );
initial begin
$dumpfile("config_comb.dump");
$dumpvars(0, Config_data_Combination);
end
  
initial begin
clk_in=0;
forever #25 clk_in=~clk_in;
end
   
initial begin
rst=0;
#100 rst=1;
#100 rst=0;
end

initial begin
data_in=16'b1001_0010_1011_1110;
pulse=0;
#325 pulse=1;
#50 pulse=0;
#100 data_in=16'b1010_1011_0011_1001;
#50 pulse=1;
#50 pulse=0;
#100 data_in=16'b1010_1011_0011_1001;
#50 pulse=1;
#50 pulse=0;
#100 data_in=16'b1010_1011_0011_1001;
#50 pulse=1;
#50 pulse=0;
end

endmodule
