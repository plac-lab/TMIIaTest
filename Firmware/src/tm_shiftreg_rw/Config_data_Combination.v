//% @file Config_data_Combination.v
//% @brief This module combines several short-width datas from config_reg 
//% into a long width data which will be sent to TM shift register.
//% @author pyxiong
//%
//%

`timescale 1ns / 1ps

module Config_data_Combination #(parameter DATA_WIDTH=170, //% @ param Width of data sent TM shift register.
                                 parameter CNT_WIDTH=8, //% @param Width of internal counter.
                                 parameter TMP_WIDTH=((DATA_WIDTH+15)/16)*16 //% Width of internal data register
//                                 parameter CONFIG_DIRECTION=0 //% @param 1: first data_in's MSB is MSB, 0: first dasta_in's LSB is LSB
   ) (
   input clk_in, //% control clock
   input rst, //% module reset
   input [15:0] data_in, //% data from config_reg
   input pulse, //% pulse from pulse_reg
   output reg [DATA_WIDTH-1:0] data_out //% data sent to Tm shift register
   );
   
reg [CNT_WIDTH-1:0] counter;
reg [TMP_WIDTH-1:0] data_tmp;
reg [2:0] current_state, next_state;
parameter s0=3'b001;
parameter s1=3'b010;
parameter s2=3'b100;

// state machine
always@(posedge clk_in or posedge rst)
begin
  if(rst)
    begin
    current_state<=s0;
    end
  else
    begin
    current_state<=next_state;
    end
end                                 

always@(current_state or rst or pulse or counter)
begin
 if(rst)
  begin
  next_state<=s0;
  end
 else
  begin
  case(current_state)
    s0:next_state=(pulse==1)?s1:s0;
    s1:next_state=(counter>=DATA_WIDTH)?s2:s0;
    s2:next_state=s0;
    default:next_state=s0;   
  endcase
  end
end

always@(posedge clk_in or posedge rst)
begin
  if(rst)
   begin
    data_tmp<=0;
    counter<=0;
   end
  else
   begin
    case(next_state)
      s0:
       begin
        data_tmp<=data_tmp;
        counter<=counter;       
       end
      s1:
       begin   //% first data input is LSB of data_tmp
       data_tmp<=data_tmp + (data_in << counter);
       counter=counter+16;
       end
      s2:
       begin
       data_tmp<=0;
       counter<=0;
       end       
      default:
       begin
       data_tmp<=0;
       counter<=0;       
       end      
    endcase
   end
end

always@(posedge clk_in or posedge rst)
begin
 if(rst)
  begin
  data_out<=0;
  end
 else
  begin
  if(counter>=DATA_WIDTH)
   begin
   data_out<=data_tmp[DATA_WIDTH-1:0];
   end
  else
   begin
   data_out<=data_out;
   end
  end
end
endmodule