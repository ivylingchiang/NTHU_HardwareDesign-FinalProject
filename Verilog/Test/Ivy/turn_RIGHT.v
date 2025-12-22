module turn_LEFT(
    input wire clk,
    input wire rst,
    input wire enR,
    input wire [2:0]detect, // tracker
    input wire [1:0]count,
    output reg doneR,
    output reg error
  );

  reg checkpoint;
  reg control_s,control;
  reg [1:0]counterRIGHT;
  
  always @(posedge clk)begin
      control_s <= control;
      if(enR && detect == 3'b111)begin
          control <= 1;
      end else control <= 0;
  end

  always @(posedge clk) begin
    if(rst) checkpoint <=0;
    else if (enR && detect != 3'b111) checkpoint <= 1;
    else checkpoint <= 0;
  end


  always @(posedge clk)begin
      if(enR && checkpoint && detect == 3'b111)begin
          if(control && !control_s)
              counterRIGHT <= counterRIGHT +1;
          
          if(counterRIGHT >= count) doneR <= 1;
      end else begin 
          counterRIGHT <= 0;
          doneR <= 0;
      end
  end
endmodule