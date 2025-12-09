module clockDriver(
  input wire clk,
  input wire countEnable,
  output reg countFinish = 0,
  output reg flash = 0
  );

  reg [31:0] num = 0;
  reg [1:0] counter = 0;

  always @(posedge clk) begin
    if (countEnable) begin
      if (num >= 100_000_000 - 1) begin
        num <= 0;
        flash <= ~flash;

        if (counter == 2'd3) begin
          countFinish <= 1;
          counter <= 0;
        end else begin
          counter <= counter + 1;
          countFinish <= 0;
        end

      end else begin
        num <= num + 1;
      end

    end else begin
      num <= 0;
      counter <= 0;
      flash <= 0;
      countFinish <= 0;
    end
  end

endmodule
