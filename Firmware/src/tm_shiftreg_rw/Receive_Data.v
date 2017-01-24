//% @file Receive_Data.v
//% @brief This module is used to receive data from TMIIa shift register.
//% @author pyxiong
//% 
//% When start is asserted, new data will be sent to shift register one by one, 
//% at the same time , the orginal data stored in shift register will be sent to 
//% this module, when 170-bit data are received, a 170-bit width data will come 
//% to the output port of this module.
//% 
`timescale 1ns / 1ps

module Receive_Data #(parameter DATA_WIDTH=170,  //% @param width of data
                      parameter CNT_WIDTH=8 //% @param width of internal counter.
   ) (
    input dout_sr, //% original data stored in shift register
    input clk, //% control clock
    input rst, //% module reset
    input start, //% start signal
    output reg [DATA_WIDTH-1:0] dout //% origianl 170-bit data stored in shift register 
    );
reg [2:0] current_state_in, next_state_in;
reg [DATA_WIDTH-1:0] dout_tmp;
reg [CNT_WIDTH:0] cnt;    

parameter s0=3'b001;
parameter s1=3'b010;
parameter s2=3'b100;


//state machine 2, used to recieve data from SR
always@(negedge clk or posedge rst)
begin
if(rst)
 begin
 current_state_in<=s0;
 end
else
 begin
 current_state_in<=next_state_in;
 end
end

always@(current_state_in or rst or start or cnt)
begin
if(rst)
 begin
 next_state_in=s0;
 end
else
 begin
  case(current_state_in)
    s0: next_state_in=(start==1'b1)?s1:s0; 
    s1: next_state_in=s2;     
    s2: next_state_in=(cnt==DATA_WIDTH)?s0:s2;
    default: next_state_in=s0;
  endcase
 end
end

always@(negedge clk or posedge rst)
begin
 if(rst)
 begin
  cnt<=0;
  dout_tmp<=0;
 end
 else
 begin
  case(next_state_in)
   s0:
     begin
     cnt<=0;
     dout_tmp<=0;
     end
   s1:
     begin
     cnt<=0;
     dout_tmp<=0;
     end
   s2:
     begin
     cnt<=cnt+1'b1;
     dout_tmp[cnt]<=dout_sr;
     end
   default:
     begin
     cnt<=0;
     dout_tmp<=0;
     end
   endcase
 end
end

always@(negedge clk or posedge rst)
begin
 if(rst)
  begin
   dout<=0;
  end
 else
  begin
   if(cnt==DATA_WIDTH)
    begin
     dout<=dout_tmp;
    end
   else
    begin
     dout<=dout;
    end
  end
end

endmodule
