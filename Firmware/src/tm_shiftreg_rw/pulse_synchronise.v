//% @file pulse_synchronise.v
//% @brief clock domain crossing pulse's synchronisation.
//% @author pyxiong
//%  
//% pulse_in is in clk_in domain, pulse_out is in clk_out domain. 
`timescale 1ns / 1ps

module pulse_synchronise(
    input pulse_in, //% input pulse 
    input clk_in, //% pulse_in control clock
    input clk_out, //% pulse_out control clock
    input rst, //% module reset
    output reg pulse_out //% output pulse
    );
 reg set;
 reg in_reg1,in_reg2,in_reg3;
 reg set_reg1,set_reg2,set_reg3;
 reg en,en_reg1,en_reg2,en_reg3;
 
 always@(posedge clk_in or posedge rst)
  begin
   if(rst)
    begin
    in_reg1<=0;
    in_reg2<=0;
    in_reg3<=0;
    set_reg1<=0;
    set_reg2<=0;
    set_reg3<=0;
    en<=0;
    end
   else
    begin
     in_reg1<=pulse_in;
     in_reg2<=in_reg1;
     in_reg3<=in_reg2;
     set_reg1<=set;
     set_reg2<=set_reg1;
     set_reg3<=set_reg2;
     if(in_reg2==1'b1&&in_reg3==1'b0)
      begin en<=1; end
     else if(set_reg2==1'b1&&set_reg3==1'b0)
      begin en<=0; end
     else begin en<=en; end
    end
  end
 
 always@(posedge clk_out or posedge rst)
  begin
   if(rst)
    begin
     en_reg1<=0;
     en_reg2<=0;
     en_reg3<=0;
     set<=0;
     pulse_out<=0;
    end
   else
    begin
     en_reg1<=en;
     en_reg2<=en_reg1;
     en_reg3<=en_reg2;
     if(en_reg2==1'b1&&en_reg3==1'b0)
      begin 
       pulse_out<=1;
       set<=1;
      end
     else 
      begin
       if(en_reg2==1'b0&&en_reg3==1'b1)
        begin
         pulse_out<=0;
         set<=0;
        end
       else
        begin
         pulse_out<=0;
         set<=set;
        end
      end
    end
  end   
  
endmodule
