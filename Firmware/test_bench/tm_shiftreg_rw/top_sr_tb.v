`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ccnu
// Engineer: Poyi Xiong
// 
// Create Date: 01/13/2017 04:41:05 PM
// Design Name: 
// Module Name: top_sr_tb
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


module top_sr_tb #(parameter WIDTH=170)();
reg clk_in;
reg rst;
reg start;
reg [WIDTH-1:0] din;
reg dout_sr_p;
reg dout_sr_n;
wire clk_sr_p, clk_sr_n;
wire din_sr_p, din_sr_n;
wire load_sr_p,load_sr_n;
wire [WIDTH-1:0] dout;

Top_SR #(.COUNT_WIDTH(1))DUT4(
    .clk_in(clk_in),
    .rst(rst),
    .start(start),
    .din(din),
    .dout_sr_p(dout_sr_p),
    .dout_sr_n(dout_sr_n),
    .clk_sr_p(clk_sr_p),
    .clk_sr_n(clk_sr_n),
    .din_sr_p(din_sr_p),
    .din_sr_n(din_sr_n),
    .load_sr_p(load_sr_p),
    .load_sr_n(load_sr_n),
    .dout(dout)
    );
    
initial begin
$dumpfile("top_sr.dump");
$dumpvars(0, Top_SR);
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
din={1'b1,169'b1011};
start=0;
#675 start=1;
#100 start=0;
end

initial begin
dout_sr_p=0;
dout_sr_n=1;
#35125 
dout_sr_p=1;
dout_sr_n=0;  
#200 
dout_sr_p=1;
dout_sr_n=0;
#200 
dout_sr_p=0;
dout_sr_n=1;
#200 
dout_sr_p=1;
dout_sr_n=0;
end

endmodule
