//% @file Top_SR.v
//% @brief TMIIa shift register control module.
//% @author pyxiong
//% 
//% This module is used to generate shift register control signals,
//% and receive the output data of TMIIa shift register .
//%
`timescale 1ns / 1ps

module Top_SR #(parameter WIDTH=170, //% @param Width of data input and output
                parameter CNT_WIDTH=8, //% @param WIDTH must be no greater than 2**CNT_WIDTH 
                parameter DIV_WIDTH=6,  //% @param width of division factor.
                parameter SHIFT_DIRECTION=1, //% @param 1: MSB out first, 0: LSB out first  
                parameter READ_TRIG_SRC=0, //% @param 0:start act as trig, 1: load_sr act as trig   
                parameter READ_DELAY=0 //% @param state machine delay period             
   ) (
    input clk_in, //% clock input is synchronised with input signals control clock.
    input rst, //% module reset 
    input start, //% start signal 
    input [WIDTH-1:0] din, //% 170-bit data input to config shift register
    input data_in_p, //% data from shift register
    input data_in_n, //% data from shift register
    input [DIV_WIDTH-1:0] div, //% division factor 2**div
    output clk, //% sub modules' control clock
    output clk_sr_p, //% control clock send to shift register
    output clk_sr_n, //% control clock send to shift register
    output data_out_p, //% data send to shift register
    output data_out_n, //% data send to shift register
    output load_sr_p, //% load signal send to shift register
    output load_sr_n, //% load signal send to shift register
    output valid, //% valid is asserted when 170-bit dout is on the output port
    output [WIDTH-1:0] dout //% original data stored in shift register
    );
 
wire data_in;
wire data_out;
wire clk_sr;
wire load_sr;
wire trig;
wire [CNT_WIDTH-1:0] count;

IBUFDS #(.DIFF_TERM("TRUE"))
  IBUFDS_inst (
  .O(data_in),
  .I(data_in_p),
  .IB(data_in_n)
  );
  
OBUFDS OBUFDS_inst1 (
  .I(data_out),
  .O(data_out_p),
  .OB(data_out_n)
  );

OBUFDS OBUFDS_inst2 (
  .I(clk_sr),
  .O(clk_sr_p),
  .OB(clk_sr_n)
  );
OBUFDS OBUFDS_inst3 (
  .I(load_sr),
 // .I(start),
  .O(load_sr_p),
  .OB(load_sr_n)
  );


Clock_Div clock_div_0(
        .clk_in(clk_in),
        .rst(rst),
        .div(div),
        .clk_out(clk)
        );
            
SR_Control #(.DATA_WIDTH(WIDTH), .CNT_WIDTH(CNT_WIDTH), .SHIFT_DIRECTION(SHIFT_DIRECTION))
     sr_control_0(
         .din(din),
         .clk(clk),
         .rst(rst),
         .start(start),
         .data_out(data_out),
         .load_sr(load_sr),
         .count(count)
         //.clk_sr(clk_sr)
        );

Clock_SR #(.WIDTH(WIDTH), .CNT_WIDTH(CNT_WIDTH))        
   clock_sr_0(
        .clk(clk),
        .rst(rst),
        .count(count),
        .start(start),
        .clk_sr(clk_sr)
   );
assign trig= (READ_TRIG_SRC==1)? load_sr: start;
        
Receive_Data #(.DATA_WIDTH(WIDTH), .CNT_WIDTH(CNT_WIDTH), .SHIFT_DIRECTION(SHIFT_DIRECTION), .READ_DELAY(READ_DELAY))
     receive_data_0(
        .data_in(data_in),
        .clk(clk),
        .rst(rst),
        .start(trig),
        .valid(valid),
        .dout(dout)
        );                         
endmodule
