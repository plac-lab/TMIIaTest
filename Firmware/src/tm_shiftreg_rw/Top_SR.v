//% @file Top_SR.v
//% @brief TMIIa shift register control module.
//% @author pyxiong
//% 
//% This module is used to generate shift register control signals,
//% and receive the output data of TMIIa shift register .
//%
`timescale 1ns / 1ps

module Top_SR #(parameter WIDTH=170, //% @param Width of data input and output
                parameter DIV_WIDTH=6  //% @param width of division factor.
   ) (
    input clk_in, //% clock input is synchronised with input signals control clock.
    input rst, //% module reset 
    input start, //% start signal 
    input [WIDTH-1:0] din, //% 170-bit data input to config shift register
    input dout_sr_p, //% data from shift register
    input dout_sr_n, //% data from shift register
    input [DIV_WIDTH-1:0] div, //% division factor 2**div
    output clk, //% sub modules' control clock
    output clk_sr_p, //% control clock send to shift register
    output clk_sr_n, //% control clock send to shift register
    output din_sr_p, //% data send to shift register
    output din_sr_n, //% data send to shift register
    output load_sr_p, //% load signal send to shift register
    output load_sr_n, //% load signal send to shift register
    output [WIDTH-1:0] dout //% original data stored in shift register
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


Clock_Div clock_div_0(
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
        
Receive_Data #(.DATA_WIDTH(170), .CNT_WIDTH(8))
     receive_data_0(
        .dout_sr(dout_sr),
        .clk(clk),
        .rst(rst),
        .start(start),
        .dout(dout)
        );                         
endmodule
