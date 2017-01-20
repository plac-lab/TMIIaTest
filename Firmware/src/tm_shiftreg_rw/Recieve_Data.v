`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/13/2017 01:06:46 PM
// Design Name: 
// Module Name: Recieve_Data
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


module Recieve_Data #(parameter DATA_WIDTH=170, CNT_WIDTH=8) (
    input dout_sr,
    input clk,
    input rst,
    input load_sr,
    output reg [DATA_WIDTH-1:0] dout
    );
reg [2:0] current_state_in, next_state_in;
//reg load_tmp;
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

always@(current_state_in or rst or load_sr or cnt)
begin
if(rst)
 begin
 next_state_in=s0;
 end
else
 begin
  case(current_state_in)
    s0: next_state_in=(load_sr==1'b1)?s1:s0; 
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
