module turn_LEFT(
    input wire clk,
    input wire rst,
    input wire enL,
    input wire [2:0]detect, // tracker
    input wire [1:0]count,
    output reg doneL,
    output reg error
  );

  reg checkpoint;
  reg control_s,control;
  reg [1:0]counterLeft;
  
  always @(posedge clk)begin
      control_s <= control;
      if(enL && detect == 3'b111)begin
          control <= 1;
      end else control <= 0;
  end

  always @(posedge clk) begin
    if(rst) checkpoint <=0;
    else if (enL && detect != 3'b111) checkpoint <= 1;
    else checkpoint <= 0;
  end


  always @(posedge clk)begin
      if(enL && checkpoint && detect == 3'b111)begin
          if(control && !control_s)
              counterLeft <= counterLeft +1;
          
          if(counterLeft >= count) doneL <= 1;
      end else begin 
          counterLeft <= 0;
          doneL <= 0;
      end
  end
endmodule