`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/30/2017 01:18:01 AM
// Design Name: 
// Module Name: top_new
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


module top_new#(parameter WIDTH=170, //% @param Width of data input and output
                parameter CNT_WIDTH=8, //% @param WIDTH must be no greater than 2**CNT_WIDTH 
                parameter DIV_WIDTH=6,  //% @param width of division factor.
                parameter SHIFT_DIRECTION=1, //% @param 1: MSB out first, 0: LSB out first  
                parameter READ_TRIG_SRC=0, //% @param 0:start act as trig, 1: load_sr act as trig   
                parameter READ_DELAY=0 //% @param state machine delay period 
        )(
    input clk_in, //% clock input is synchronised with input signals control clock.
    input rst, //% module reset 
    //input start, //% start signal 
    input [WIDTH-1:0] din, //% 170-bit data input to config shift register
    input data_in_p, //% data from shift register
    input data_in_n, //% data from shift register
    input [DIV_WIDTH-1:0] div, //% division factor 2**div
    input pulse_in,
    output clk, //% sub modules' control clock
    output clk_sr_p, //% control clock send to shift register
    output clk_sr_n, //% control clock send to shift register
    output data_out_p, //% data send to shift register
    output data_out_n, //% data send to shift register
    output load_sr_p, //% load signal send to shift register
    output load_sr_n, //% load signal send to shift register
    output valid, //% valid is asserted when 170-bit dout is on the output port
    output [WIDTH-1:0] dout 
    );
wire start;    
Top_SR top_sr_inst(
    .clk_in(clk_in), //% clock input is synchronised with input signals control clock.
    .rst(rst), //% module reset 
    .start(start), //% start signal 
    .din(din), //% 170-bit data input to config shift register
    .data_in_p(data_in_p), //% data from shift register
    .data_in_n(data_in_n), //% data from shift register
    .div(div), //% division factor 2**div
    .clk(clk), //% sub modules' control clock
    .clk_sr_p(clk_sr_p), //% control clock send to shift register
    .clk_sr_n(clk_sr_n), //% control clock send to shift register
    .data_out_p(data_out_p), //% data send to shift register
    .data_out_n(data_out_n), //% data send to shift register
    .load_sr_p(load_sr_p), //% load signal send to shift register
    .load_sr_n(load_sr_n), //% load signal send to shift register
    .valid(valid), //% valid is asserted when 170-bit dout is on the output port
    .dout(dout) 
    );  
    
pulse_synchronise pulse_synchronise_inst(
    .pulse_in(pulse_in), //% input pulse 
    .clk_in(clk_in), //% pulse_in control clock
    .clk_out(clk), //% pulse_out control clock
    .rst(rst), //% module reset
    .pulse_out(start)
    );  
endmodule
