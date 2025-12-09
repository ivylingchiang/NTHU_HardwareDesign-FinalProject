module clockDriver(
  input wire clk,
  input wire countEnable,
  output reg countFinish,
  output reg flash
  );

  reg [31:0]num;
  reg [1:0]counter;
  always @(posedge clk)begin
    if(countEnable)begin
      if(num +1 >= 100000000)begin
        num <= 32'd0;
        counter <= counter +1;
        flash <= ~flash;

        if(counter == 2'd3) countFinish <= 1'd1;
        else countFinish <= 1'd0;
      end else begin
        num <= num + 1;
      end
    end else begin
      num <= 32'd0;
      countFinish <= 1'd0;
      counter <= 2'd0;
      flash <= 0;
    end
  end
endmodule