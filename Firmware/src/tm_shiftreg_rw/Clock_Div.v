//% @file Clock_Div.v
//% @brief Clock generator with tunable frequency f_in / 2**n.
//% @author pyxiong
//%
//% This module is used to divide the frequency of clk_in,
//% clk_out's ferequency can be adjusted by input signal div.
//%
`timescale 1ns / 1ps

module Clock_Div #(
    parameter DIV_WIDTH=6,  //% @param width of division factor
    parameter COUNT_WIDTH=64 //% @param Width of internal counter, it must be greater than 2**DIV_WIDTH.
  )(
    input clk_in, //% reference clock input
    input rst,    //% module reset
    input [DIV_WIDTH-1:0] div, //% division factor 2**div
    output reg [COUNT_WIDTH-1:0] counter, //% internal counter.
    output clk_out  //% output of divided clock
  );

//reg [COUNT_WIDTH-1:0] count;


always@(posedge clk_in or posedge rst)
begin
  if(rst)
    begin
      counter <= 0;
    end
  else
    begin
      counter <= counter+1;
    end
end

assign clk_out = (div==0) ? clk_in : counter[div-1];  

endmodule
