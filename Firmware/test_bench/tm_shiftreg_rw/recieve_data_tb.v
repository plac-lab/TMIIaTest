`timescale 1ns / 1ps
`define WIDTH 170
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/13/2017 01:30:56 PM
// Design Name: 
// Module Name: recieve_data_tb
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


module recieve_data_tb();
reg dout_sr;
reg clk;
reg rst;
reg load_sr;
wire [`WIDTH-1:0] dout;

Recieve_Data DUT3(
    .dout_sr(dout_sr),
    .clk(clk),
    .rst(rst),
    .load_sr(load_sr),
    .dout(dout)
    );
    
initial begin
$dumpfile("recieve_data.dump");
$dumpvars(0, Recieve_Data);
end

initial begin
clk=0;
forever #50 clk=~clk;
end

initial begin
rst=1;
#200 rst=0;
end

initial begin
load_sr=0;
#400 load_sr=1;
#100 load_sr=0;
end

initial begin
dout_sr=0;
#500 dout_sr=1;
#100 dout_sr=0;
#100 dout_sr=1;
#200 dout_sr=0;
end

endmodule
