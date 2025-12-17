module stack(
    input wire clk,
    input wire rst,
    input wire en,
    input wire push,
    input wire push_val,
    input wire pop,
    output reg [1:0] pop_val
);
    reg [4:0] index;
    logic [1:0] mem [0:49];
    integer rst_index;

    reg push_s;
    reg pop_s;
    reg push_en;
    reg pop_en;

    // one pulse
    always@(posedge clk)begin
        push_s <= push;
        pop_s <= pop;
    end

    always@(*)begin
        push_en = 0;
        pop_en = 0;
        if(push && !push_s) push_en = 1;
        if(pop && !pop_s) pop_en = 1;
    end


    always@(posedge clk, posedge rst)begin
        if(rst)begin
            index <= 0;
            for(rst_index = 0; rst_index <= 49 ; rst_index = rst_index + 1)begin
                mem[rst_index] <= 2'b00;
            end
        end
        else if(en)begin
            if(push_en)begin
                if(index < 49)begin
                    mem[index] <= push_val;
                    index <= index + 1;
                end
            end
            
            if(pop_en)begin
                if(index > 0)begin
                    mem[index] <= 2'b00;
                    index <= index - 1;
                    pop_val <= mem[index];
                end
            end
            else pop_val <= 2'b0;

        end
    end
endmodule