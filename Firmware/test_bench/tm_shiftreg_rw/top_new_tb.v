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


module top_sr_tb #(parameter WIDTH=170,
                   parameter CNT_WIDTH=8,
                   parameter DIV_WIDTH=6,
                   parameter SHIFT_DIRECTION=1,
                   parameter READ_TRIG_SRC=0,
                   parameter READ_DELAY=0)();
reg clk_in;
reg rst;
reg start;
reg [WIDTH-1:0] din;
reg data_in_p;
reg data_in_n;
reg [DIV_WIDTH-1:0] div;
wire clk_sr_p, clk_sr_n;
wire data_out_p, data_out_n;
wire load_sr_p,load_sr_n;
wire [WIDTH-1:0] dout;
wire clk;
wire valid;

top_new #(.WIDTH(WIDTH), .CNT_WIDTH(CNT_WIDTH), .DIV_WIDTH(DIV_WIDTH),.SHIFT_DIRECTION(SHIFT_DIRECTION),.READ_TRIG_SRC(READ_TRIG_SRC),.READ_DELAY(READ_DELAY))
  DUT4(
    .clk_in(clk_in),
    .rst(rst),
    .pulse_in(start),
    .din(din),
    .div(div),
    .data_in_p(data_in_p),
    .data_in_n(data_in_n),
    .clk_sr_p(clk_sr_p),
    .clk_sr_n(clk_sr_n),
    .data_out_p(data_out_p),
    .data_out_n(data_out_n),
    .load_sr_p(load_sr_p),
    .load_sr_n(load_sr_n),
    .dout(dout),
    .clk(clk),
    .valid(valid)
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
div=6'b1;
start=0;
#675 start=1;
#50 start=0;
#19500 start=1;
#50 start=0;
end

initial begin
data_in_p=0;
data_in_n=1;
#1125
data_in_p=1;
data_in_n=0;  
#200 
data_in_p=0;
data_in_n=1;
#200 
data_in_p=1;
data_in_n=0;
end

endmodule
