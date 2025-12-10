module counter #(
    parameter timeLength = 1// timeLength * 0.1sec
)(
    input wire en,
    input wire clk,
    output reg finish
);

    reg [25:0] cnt;

    always@(posedge clk)begin
        if(!en)begin
            cnt <= 0;
            finish <= 0;
        end
        else begin
            if(cnt < 10_000_000 * timeLength - 1)begin
                cnt <= cnt + 1;
            end
            else begin
                cnt <= 0;
                finish <= 1;
            end
        end
    end
endmodule