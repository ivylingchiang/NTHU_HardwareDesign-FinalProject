module tracker_sensor(clk, reset, left_track, right_track, mid_track, detect_road);
    input clk;
    input reset;
    input left_track, right_track, mid_track;
    output reg [2:0] detect_road;

    // TODO: Receive three tracks and create your own policy.
    // Hint: You can use output state to change your action.
    always@(posedge clk)begin
        //blocked
        case({left_track,mid_track,right_track})
            3'd0: detect_road <= 3'd7;
            3'd1: detect_road <= 3'd6;
            3'd2: detect_road <= 3'd5;
            3'd3: detect_road <= 3'd4;
            3'd4: detect_road <= 3'd3;
            3'd5: detect_road <= 3'd2;
            3'd6: detect_road <= 3'd1;
            3'd7: detect_road <= 3'd0;
            default:detect_road <= detect_road;
        endcase  
    end
endmodule
