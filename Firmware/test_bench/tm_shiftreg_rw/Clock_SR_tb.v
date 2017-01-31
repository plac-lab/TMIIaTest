`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ccnu
// Engineer: Poyi Xiong
// 
// Create Date: 01/12/2017 12:00:21 PM
// Design Name: 
// Module Name: Clock_SR_tb
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


module Clock_SR_tb #(parameter WIDTH=170, CNT_WIDTH=8)();
reg clk;
reg rst;
reg start;
reg [CNT_WIDTH-1:0] count;
wire clk_sr;

Clock_SR #(.WIDTH(WIDTH), .CNT_WIDTH(CNT_WIDTH))
  DUT1(
    .clk(clk),
    .rst(rst),
    .start(start),
    .count(count),
    .clk_sr(clk_sr)
    );

initial begin
$dumpfile("Clock_SR.dump");
$dumpvars(0, Clock_SR);
end

initial begin
clk=0;
forever #50 clk=~clk;
end

initial begin
rst=1'b1;
#200 rst=1'b0;
end


initial begin
count=8'b0;
#50 count=8'b0;
forever #100 count=count+1'b1;
end

initial begin
start=1'b0;
#250 start=1'b1;
#100 start=1'b0;
#17600 start=1'b1;
#100 start=1'b0;
end

endmodule
