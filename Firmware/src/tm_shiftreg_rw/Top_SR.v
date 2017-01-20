`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ccnu
// Engineer: Poyi Xiong
// 
// Create Date: 01/13/2017 02:15:00 PM
// Design Name: 
// Module Name: Top_SR
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


module Top_SR #(parameter WIDTH=170, COUNT_WIDTH=16) (
    input clk_in,
    input rst,
    input start,
    input [WIDTH-1:0] din,
    input dout_sr_p,
    input dout_sr_n,
    input [COUNT_WIDTH-1:0] div,
    output clk,
    output clk_sr_p,
    output clk_sr_n, 
    output din_sr_p,
    output din_sr_n,
    output load_sr_p,
    output load_sr_n,
    output [WIDTH-1:0] dout
    );
 
wire dout_sr;
wire din_sr;
wire clk_sr;
wire load_sr;

IBUFDS IBUFDS_inst (
  .O(dout_sr),
  .I(dout_sr_p),
  .IB(dout_sr_n)
  );
  
OBUFDS OBUFDS_inst1 (
  .I(din_sr),
  .O(din_sr_p),
  .OB(din_sr_n)
  );

OBUFDS OBUFDS_inst2 (
  .I(clk_sr),
  .O(clk_sr_p),
  .OB(clk_sr_n)
  );
OBUFDS OBUFDS_inst3 (
  .I(load_sr),
  .O(load_sr_p),
  .OB(load_sr_n)
  );


Clock_Div #(.COUNT_WIDTH(16))
     clock_div_0(
        .clk_in(clk_in),
        .rst(rst),
        .div(div),
        .clk_out(clk)
        );
            
SR_Control #(.DATA_WIDTH(170), .CNT_WIDTH(8))
     sr_control_0(
         .din(din),
         .clk(clk),
         .rst(rst),
         .start(start),
         .din_sr(din_sr),
         .load_sr(load_sr),
         .clk_sr(clk_sr)
        );
        
Recieve_Data #(.DATA_WIDTH(170), .CNT_WIDTH(8))
     recieve_data_0(
        .dout_sr(dout_sr),
        .clk(clk),
        .rst(rst),
        .load_sr(load_sr),
        .dout(dout)
        );                         
endmodule
