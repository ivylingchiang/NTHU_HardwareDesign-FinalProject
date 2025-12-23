module clockDriver2(
  input wire clk,
  input wire countEnable,
  output reg flash
  );

  reg [31:0] num ;

  always @(posedge clk) begin
    if (countEnable) begin
      if (num >= 20_000_000 - 1) begin
        num <= 0;
        flash <= ~flash;
      end else begin
        num <= num + 1;
      end

    end else begin
      num <= 0;
      flash <= 0;
    end
  end

endmodule
