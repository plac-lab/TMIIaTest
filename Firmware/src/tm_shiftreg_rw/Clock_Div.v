//% @file Clock_Div.v
//% @brief Clock generator with tunable frequency f_in / 2**n.
//% @author pyxiong
//%
//% This module is used to divide the frequency of clk_in,
//% clk_out's ferequency can be adjusted by input signal div.
//%
`timescale 1ns / 1ps

module Clock_Div #(
    parameter COUNT_WIDTH=16 //% Width of internal counter, which sets the maximum division factor.
  )(
    input clk_in, //% reference clock input
    input rst,    //% module reset
    input [COUNT_WIDTH-1:0] div, //% division factor 2**div
    output clk_out               //% output of divided clock
  );

reg [COUNT_WIDTH-1:0] count;

/*always@(clk_in or rst or count)
begin
 if(rst)
  begin 
    clk_out<=0;
    count<=0;
  end
 else
  begin
    count<=count+1;
    clk_out<=count[COUNT_WIDTH];
  end
end
*/

always@(posedge clk_in)
begin
  if(rst)
    begin
      count <= 0;
    end
  else
    begin
      count <= count+1;
    end
end

assign clk_out = (div==0) ? clk_in : count[div-1];  

endmodule
