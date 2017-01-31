//% @file Clock_SR.v
//% @brief This module generate shift register's control clock.
//% @author pyxiong
//%
//% After the last bit is written into shift register, clock clk_sr
//% must stop until start is asserted.
`timescale 1ns / 1ps
module Clock_SR #(parameter WIDTH=170,//% @param input data's width controls thestatus of state machine. 
                  parameter CNT_WIDTH=8 //% @param 2**CNT_WIDTH must be greater than WIDTH.
    )(
    input clk, //% module's internal control clock.
    input rst, //% reset
    input[CNT_WIDTH-1:0] count, //% internal counter of SR_Control.v 
    input start, //% make clk_sr re_running
    output clk_sr //% shift register's control clock
    );

reg flag;    
reg [2:0] current_state, next_state;
parameter s0 = 3'b001;
parameter s1 = 3'b010;
parameter s2 = 3'b100;

always@(posedge clk or posedge rst)
  begin   
    if(rst)
    begin  current_state <= s0; end
    else
    begin  current_state <= next_state; end    
  end

always@(current_state or rst or count or start)
  begin
    if(rst)
    begin next_state = s0; end
    else
    begin
        case(current_state)
            //s0:next_state=(count==WIDTH)?s1:s0;
            //s1:next_state=(start==1)?s2:s1;
            s0:next_state=(start==1)?s1:s0;
            s1:next_state=(count==WIDTH)?s2:s1;
            s2:next_state=s0;
            default:next_state=s0;
        endcase
    end
  end

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin flag<=1; end
  else
  begin
    case(next_state)
        s0:begin flag<=1; end
        s1:begin flag<=0; end
        s2:begin flag<=1; end
        default:begin flag<=1; end   
    endcase 
  end 
end

assign clk_sr=rst||~rst&&~clk||~rst&&clk&&flag;    
// always@(clk or rst or load_sr or count)
//  begin
//   if(rst)
//    begin
//     clk_sr=1'b0;
//    end
//   else
//    begin
//      if(count==WIDTH)
//        begin
//        clk_sr=clk_sr;
//        end
//       else
//        begin
//        clk_sr=~clk;
//        end
//      end
//     end
//  end
endmodule
